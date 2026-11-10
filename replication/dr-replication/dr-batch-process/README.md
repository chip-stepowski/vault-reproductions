# DR batch token: running raft commands on a DR secondary

Normal Vault tokens can't be used on a DR secondary. Raft commands such as `vault operator raft list-peers` and `remove-peer` need a token passed with `-dr-token`.

The usual way to get one is to generate a DR operation token, using `generate-root -dr-token` and the primary's recovery keys. A simpler option is to **create a batch token on the primary** and use it on the secondary:

- The **policy** is written on the primary and replicates to the secondary.
- The **batch token** is not stored anywhere. It's a self-contained, encrypted token, and the secondary can validate it because a DR secondary shares the primary's keys.
- **No recovery keys** are needed.

## Tested on

| Item | Value |
|---|---|
| Vault | 2.1.2+ent |
| Topology | Integrated Storage (raft) primary, with a DR secondary |
| Commands verified | `raft list-peers`, `raft remove-peer` on the DR secondary |

## Prerequisites

- DR replication is set up and the secondary is connected (`vault read sys/replication/dr/status` on both clusters).
- A token on the **primary** that can write policies and create tokens.
- The policy file in this folder: [`dr-batch.hcl`](./dr-batch.hcl).

## Steps

### On the PRIMARY

**1. Write the policy**

```bash
export VAULT_ADDR=https://<primary-active-node>:8200
vault policy write dr-batch dr-batch.hcl
```

`dr-batch.hcl`:

```hcl
path "sys/storage/raft/configuration" {
  capabilities = ["update"]
}

path "sys/storage/raft/remove-peer" {
  capabilities = ["update"]
}
```

**2. Create the batch token**

```bash
vault token create -type=batch -orphan -policy=dr-batch -ttl=1h
```

The token is the `token` value in the output and starts with `hvb.`.

- **`-ttl`:** set this to cover your change window. Without it, the token gets the default TTL (768h in testing).
- **`-orphan`:** keeps the token valid if the token that created it is revoked.

### On the DR SECONDARY

**3. Point the CLI at the secondary and store the token**

```bash
export VAULT_ADDR=https://<secondary-active-node>:8200
export DR_TOKEN=<hvb. token from step 2>
```

**4. Run raft commands with `-dr-token`**

```bash
# List peers
vault operator raft list-peers -dr-token="$DR_TOKEN"

# Remove a peer
vault operator raft remove-peer -dr-token="$DR_TOKEN" <node_id>

# Confirm the removal
vault operator raft list-peers -dr-token="$DR_TOKEN"
```

Expected output:

```
$ vault operator raft remove-peer -dr-token="$DR_TOKEN" raftauto5
Peer removed successfully!
```
