name      = "nomad-client"
data_dir  = "/var/lib/nomad"
bind_addr = "0.0.0.0"
log_level = "INFO"

leave_on_interrupt = true
leave_on_terminate = true

client {
  enabled = true

  drain_on_shutdown {
    deadline           = "5m"
    force              = false
    ignore_system_jobs = false
  }
}

plugin "docker" {
  config {
    endpoint = "unix:///var/run/docker.sock"

    volumes {
      enabled      = true
      selinuxlabel = "z"
    }

    allow_privileged = false
  }
}
