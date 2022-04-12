job "http-ingress-connect" {
  datacenters = ["dc1"]
  type        = "system"

  group "edge" {

    network {
      mode = "bridge"

      port "web" {
        static = 8901
        to     = 8901
      }

      port "websecure" {
        static = 8902
        to     = 8902
      }

      # Treafik dashboard
      port "api" {
        static = 8909
        to     = 8909
      }
    }

    # If you plan to expose different services (based on different port) using
    # the service-mesh, you *must* use the *same service name* for each
    # service stanza and *must* use a *uniq tag* for each service
    service {
      name = "http-ingress-connect"
      port = "web"
      tags = ["web"]

      connect {
        native = true
      }
    }

    service {
      name = "https-ingress-connect"
      port = "websecure"
      tags = ["websecure"]

    }

    task "traefik" {
      driver = "docker"
      config {
        image = "traefik:2.6"
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
  [entryPoints.web]
  address = ":8901"
  [entryPoints.websecure]
  address = ":8902"
  [entryPoints.traefik]
  address = ":8909"

[api]
  dashboard = true
  insecure  = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
  # create endpoint for service tag starting by npiatto-generic-http-ingress
  prefix           = "http-ingress-connect"
  # Do not expose/create route by default, it must be explicitly enable at
  # the service level
  exposedByDefault = false
  # Enable consul-connect support
  connectAware     = true
  # Use secure connection / mTLS by default
  connectbydefault = true
  # Register this service in consul, must match the service stanza name to
  # allow the user to create the consul-intention
  serviceName      = "http-ingress-connect"

[providers.file]
  directory = "local/traefik/"
  watch     = "true"

[tls.stores]
  [tls.stores.default]

# Enable Logging (default is to stdout)
[accessLog]

[log]
  level  = "debug"
  format = "json"
EOF
        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
