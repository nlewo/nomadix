job "helloworld" {
  datacenters = ["dc1"]

  group "example" {
    network {
      mode = "bridge"
    }
    service {
      name = "helloworld"
      port = 5678
      connect {
        sidecar_service {}
      }
      tags = [
        "http-ingress-connect.enable=true",
        "http-ingress-connect.consulCatalog.connect",
        "http-ingress-connect.http.routers.helloworld.rule=Host(`helloworld.nomad`)",
        "http-ingress-connect.http.routers.helloworld.entrypoints=web"
      ]
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo"
        ports = ["http"]
        args = [
          "-listen",
          ":5678",
          "-text",
          "hello world",
        ]
      }
    }
  }
}
