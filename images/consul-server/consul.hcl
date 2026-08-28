datacenter         = "dc1"
data_dir           = "/var/lib/consul"
server             = true
bootstrap_expect   = 1
# Select the private address on the default route when multiple interfaces are
# present (for example, the Compose bridge or a Tailscale interface).
bind_addr          = "{{ GetPrivateIP }}"
retry_join         = ["{{ GetPrivateIP }}"]
client_addr        = "0.0.0.0"
log_level          = "INFO"
leave_on_terminate = true

ui_config {
  enabled = true
}
