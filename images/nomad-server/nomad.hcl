name       = "nomad-server"
data_dir   = "/var/lib/nomad"
bind_addr  = "0.0.0.0"
log_level  = "INFO"

server {
  enabled          = true
  bootstrap_expect = 1
}

vault {
  enabled = true

  default_identity {
    aud  = ["vault.io"]
    env  = false
    file = true
    ttl  = "1h"
  }
}
