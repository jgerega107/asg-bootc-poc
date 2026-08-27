ui = true
disable_mlock = true

api_addr     = "http://vault:8200"
cluster_addr = "http://vault:8201"

storage "raft" {
  path    = "/var/lib/vault/data"
  node_id = "vault-compose"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = true
}
