# Policy for a DR batch token used to run raft peer commands on a DR secondary.
# Write this policy on the PRIMARY; it replicates to the DR secondary.

path "sys/storage/raft/configuration" {
  capabilities = ["update"]
}

path "sys/storage/raft/remove-peer" {
  capabilities = ["update"]
}
