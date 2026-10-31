---
title: Why the value never goes through Terraform
version: 1
---

**Anything Terraform manages is written into its state, in plain text, whatever the configuration calls it.**
`sensitive = true` hides a value from the plan's output and the terminal; it does not encrypt it in the state.
A `google_secret_manager_secret_version` with `secret_data` in Terraform therefore puts the password in the state
file, and the state bucket of lesson 6 becomes a second copy of every secret, readable by everybody who can read
the state. You can see it on your computer without Google: Terraform's built-in `terraform_data` stores whatever it
is given, like any resource would. Write this into `~/gcp/tf/leak/main.tf`:

```hcl
# tf/leak/main.tf
variable "db_password" {
  type      = string
  sensitive = true
}

resource "terraform_data" "connection" {
  input = "postgres://shop:${var.db_password}@10.0.0.5/shop"
}

output "connection" {
  value     = terraform_data.connection.output
  sensitive = true
}
```

Apply it with a practice password, the way a pipeline would pass a real one:

```
ana@laptop:~/gcp/tf/leak$ TF_VAR_db_password=k7-practice-only-9f terraform apply -auto-approve -input=false -no-color | grep -E "connection|Apply"
  # terraform_data.connection will be created
  + resource "terraform_data" "connection" {
  + connection = (sensitive value)
terraform_data.connection: Creating...
terraform_data.connection: Creation complete after 0s [id=63dedcf4-bd79-86d0-19fa-56ccb0240b0f]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
connection = <sensitive>
```

Everything on the screen says `(sensitive value)` and `<sensitive>`. Now ask for the output by name, and look in
the state:

```
ana@laptop:~/gcp/tf/leak$ terraform output connection
"postgres://shop:k7-practice-only-9f@10.0.0.5/shop"
ana@laptop:~/gcp/tf/leak$ grep -c k7-practice-only-9f terraform.tfstate
3
ana@laptop:~/gcp/tf/leak$ jq -r '.resources[0].instances[0].attributes.input.value' terraform.tfstate
postgres://shop:k7-practice-only-9f@10.0.0.5/shop
```

**The password is in the state three times**, and one command prints it. `sensitive` is a promise about the
terminal, not about the file. Moving the state to a bucket (lesson 6) moves the password there with it, and
`iac` lesson 12 is the general rule this is one case of.

So the shop's arrangement has two halves. Terraform creates the **secret**, its replication, its rotation and its
IAM, none of which is secret. A person or a rotation job adds the **versions** with `gcloud secrets versions add`,
reading the value from standard input. The value lives in Secret Manager and nowhere else, and the state holds only
the secret's name.

Delete `~/gcp/tf/leak` when you have read it. A file with a password in it is a file somebody copies.
