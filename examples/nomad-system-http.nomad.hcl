job "nomad-system-http" {
  datacenters = ["dc1"]
  type        = "system"

  group "http" {
    network {
      port "http" {
        to = 5678
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:1.0"
        ports = ["http"]

        args = [
          "-listen=:5678",
          "-text=hello from ${NOMAD_ALLOC_ID}",
        ]
      }

      resources {
        cpu    = 100
        memory = 64
      }

      service {
        name     = "nomad-system-http"
        provider = "consul"
        port     = "http"
        tags     = ["nomad", "system"]

        check {
          name     = "http"
          type     = "http"
          port     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
