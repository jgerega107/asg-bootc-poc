datacenter         = "dc1"
data_dir           = "/var/lib/consul"
server             = false
# Select the private address on the default route when multiple interfaces are
# present (for example, the Compose bridge or a Tailscale interface).
bind_addr          = "{{ GetPrivateIP }}"
client_addr        = "127.0.0.1"
log_level          = "INFO"
leave_on_terminate = true
