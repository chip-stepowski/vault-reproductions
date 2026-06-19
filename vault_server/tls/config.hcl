storage "raft" { 
    path = "./vault-data"
    node_id = "node1" 
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_client_ca_file = "./ca.crt"
  tls_cert_file = "./server.crt"
  tls_key_file = "./server.key"
  tls_min_version = "tls12"
  
}

api_addr = "https://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true