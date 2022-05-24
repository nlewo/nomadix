To run the VM:

```
nix run .#
```

To terminate the VM, hit `C-a c` and type `quit`.

From another terminal, run Nomad jobs:

```
export NOMAD_ADDR=http://127.0.0.1:34646
nomad run jobs/helloworld.hcl
nomad run jobs/traefik.hcl
```

Then, SSH to the VM and curl treafik:

```
ssh  root@127.0.0.1 -p 30022
[root@nixos:~]# curl -L http://helloworld.nomad:8901
hello world
```

# Using Vault

    export VAULT_ADDR=http://127.0.0.1:38200
    export VAULT_TOKEN=root
    vault status
