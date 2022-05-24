{ config, pkgs, lib, ... }: let
  vaultConfigFile = pkgs.writeText "vault.hcl" ''
    listener "tcp" {
      address = "10.0.2.15:8200"
      tls_disable = "true"
    }
  '';
  vaultRootToken = "root";
  vaultSecretReadPolicy = pkgs.writeText "vault-secret-read-policy.hcl" ''
    path "secret/*" {
      capabilities = ["read"]
    }
  '';
in
{
  config = {
    networking.firewall.enable = lib.mkForce false;
    users.extraUsers.root.password = "";
    services.openssh = {
      enable = true;
      permitRootLogin = "yes";
      extraConfig = "PermitEmptyPasswords yes";
      passwordAuthentication = lib.mkForce true;
    };

    # TODO make it a systemd service
    # socat VSOCK-LISTEN:22,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock
    # Then, from the host:
    # socat UNIX-LISTEN:/tmp/docker.sock,fork,reuseaddr,unlink-early,mode=777 VSOCK-CONNECT:3:22
    # docker -H unix:///tmp/docker.sock load -i /tmp/alpine.tgz

    # traefik:2.6
    # traefik@sha256:126443503c12ced877f806cad0c7bd82ea1fce5d5ff7ac8663c99cede85e961f

    environment.systemPackages = [pkgs.socat];
    virtualisation.docker.enable = true;
    virtualisation.forwardPorts = [
      { from = "host"; host.port = 30022; guest.port = 22; }
      # The nomad port
      { from = "host"; host.port = 34646; guest.port = 4646; }
      # The vault port
      { from = "host"; host.port = 38200; guest.port = 8200; }
    ];
    virtualisation = {
      qemu.options = ["-device vhost-vsock-pci,id=vhost-vsock-pci0,guest-cid=3"];
      graphics = false;
    };

    networking.extraHosts = ''
      127.0.0.1 helloworld.nomad
    '';

    services.consul = {
      enable = true;
      webUi = true;
      interface.bind = "eth0";
      interface.advertise = "eth0";
      extraConfig = {
        server = true;
        bootstrap_expect = 1;
        autopilot.min_quorum = 1;
        retry_join = ["10.0.2.15"];
        client_addr = "10.0.2.15";
        connect.enabled = true;
        ports.grpc = 8502;
      };
    };

    # We don't use the NixOS Vault service because we want to start it
    # in dev mode and this is not supported.
    # services.vault = {
    # enable = true; address = "10.0.2.15:8200"; };
    systemd.services.vault = {
      description = "Vault server daemon";
      wantedBy = ["multi-user.target"];
      after = [ "network-online.target" ];
      path = [ pkgs.glibc ];
      serviceConfig.ExecStart = "${pkgs.vault}/bin/vault server -dev -dev-root-token-id ${vaultRootToken} -config ${vaultConfigFile}";
    };

    systemd.services.vault-init = {
      description = "Vault server daemon";
      wantedBy = ["multi-user.target"];
      after = [ "vault.service" ];
      path = [ pkgs.vault ];
      environment = {
        VAULT_TOKEN = vaultRootToken;
        VAULT_ADDR = "http://127.0.0.1:8200";
      };
      script = ''
        while ! vault status;
        do
        sleep 1
        done

        echo vault policy write read-secret ${vaultSecretReadPolicy}
        vault policy write read-secret ${vaultSecretReadPolicy}

        echo vault kv put secret/secret-1 foo=bar
        vault kv put secret/secret-1 foo=bar
    '';
    };

    services.nomad = {
      enable = true;
      enableDocker = true;
      dropPrivileges = false;
      extraPackages = [ pkgs.cni-plugins pkgs.consul ];
      settings = {
        server = {
          enabled = true;
          bootstrap_expect = 1;
        };
        client = {
          enabled = true;
          cni_path = "${pkgs.cni-plugins}/bin/";

        };
        # FIXME: more generic way
        consul.address = "http://10.0.2.15:8500";
        vault = {
          address = "http://10.0.2.15:8200";
          token = vaultRootToken;
          enabled = true;
        };
      };
    };
  };
}
