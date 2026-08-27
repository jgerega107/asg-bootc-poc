client {
  enabled = true
  servers = ["nomad-server:4647"]
}

vault {
  enabled = true
  address = "http://vault:8200"
}
