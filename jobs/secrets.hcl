job "secrets" {
  datacenters = ["dc1"]
  type = "batch"
  group "secrets" {
    network {
      mode = "bridge"
    }
    task "secrets" {
      driver = "docker"
      restart {
        attempts = 1
        mode     = "fail"
      }
      config {
        image = "alpine"
        command = "/bin/sh"
        args = [
          "-c", "test $SECRET1_FOO = \"bar\""
        ]
      }
      vault {
        policies = ["read-secret"]
      }
      template {
        data = <<EOH
          SECRET1_FOO="{{with secret "secret/secret-1"}}{{.Data.data.foo}}{{end}}"
          EOH
        destination = "local/file.env"
        env = true
      }
    }
  }
}
