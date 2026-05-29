# Updating the Vault license
A guide outlining the process for updating the license in a Vault cluster. This guide also outlines the process for a DR Secondary.

Prerequisites:
* Vault cluster running in K8s using Integrated Storage
* A Vault Enterprise license configured via a secret, with the key as "license"
* DR replication

## Steps
### 1. Primary Cluster
**Update the Kubernetes Secret**
```bash
export VAULT_LIC=$(base64 < "vault-2.hclic" | tr -d '\n')

kubectl patch secret vault-ent-license -n vault -p "{\"data\":{\"license\":\"${VAULT_LIC}\"}}"
```

**Reload the active node**
```bash
kubectl exec vault-0 n vault -- vault read sys/license/status

kubectl exec vault-0 -n vault -- vault write -f sys/config/reload/license
```