# Setting up Vault with TLS:
This outlines the process for setting up a quick Vault cluster with TLS enabled.

## Steps:
### 1. Create test directory
```bash
mkdir -p ~/vault-tls-test && cd ~/vault-tls-test
```

### 2. Generate certificates and add the CA to the local mac keychain
```bash
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -out ca.crt -subj "/CN=Vault CA"
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=localhost"
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1")
```

Open Keychain Access > Right click and select Get Info, then expand Trust and set "When using this cert" to "Always Trust"

Restart the browser

### 3. Create the Vault config
```hcl
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
  tls_disable = "false"
}

api_addr = "https://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true
```

### 4. Create the Vault data directory and start the Vault server
```bash
mkdir vault-data

./vault server -config=config.hcl >> vault.log 2>&1 &
```

# set addr and init vault
```bash
export VAULT_ADDR='https://127.0.0.1:8200' VAULT_CACERT='./ca.crt'
vault operator init -key-shares=1 -key-threshold=1 -format=json > init.json
vault operator unseal <KEY>
```

# initializing and unsealing vault, followed by a status should show the HA cluster as https
```bash
export VAULT_TOKEN <TOKEN>
```

# Verify TLS works
```bash
curl --cacert ca.crt https://127.0.0.1:8200/v1/sys/health
```

# Check sanitized config
```bash
curl --cacert ca.crt -H "X-Vault-Token: $VAULT_TOKEN" https://127.0.0.1:8200/v1/sys/config/state/sanitized | jq '.data.listeners'

[
  {
    "config": {
      "address": "127.0.0.1:8200",
      "tls_cert_file": "./server.crt",
      "tls_client_ca_file": "./ca.crt",
      "tls_disable": "false",
      "tls_key_file": "./server.key",
      "tls_min_version": "tls12"
    },
    "type": "tcp"
  }
]
```bash