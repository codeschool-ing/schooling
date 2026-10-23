# What a run of linkbox's pipeline on main may do in Vault: read the
# password of the signing key. Not list the secrets beside it, not write
# this one, not read any other path.
path "secret/data/linkbox/signing" {
  capabilities = ["read"]
}
