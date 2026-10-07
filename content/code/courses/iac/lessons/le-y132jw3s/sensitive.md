---
title: What sensitive hides, and what it does not
version: 2
---

The first tool most people reach for is `sensitive = true`, and it is worth knowing exactly what it
buys. A variable or an output marked sensitive is a value Terraform agrees not to **print**. It is a
promise about the screen, and that is the whole of it.

Ana marks the password:

```
ana@laptop:~/shop$ sed -i 's/^  type        = string$/  type        = string\n  sensitive   = true/' main.tf
ana@laptop:~/shop$ sed -n "/^variable/,/^}/p" main.tf
variable "db_password" {
  type        = string
  sensitive   = true
  description = "The password the shop's application uses for its database."
}
```

And the plan stops showing it. The marking travels with the value: `user_data` was built from the
variable, so the whole argument is hidden now, and nothing else about the plan has changed:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "user_data  |^Plan"
      + user_data                            = (sensitive value)
Plan: 1 to add, 0 to change, 0 to destroy.
```

That takes care of copy two, the screen and the CI log. **The marking also spreads to everything
computed from the value**, and Terraform checks it at the one door through which a value leaves a
configuration on purpose. Ana adds an output, in `outputs.tf`, so that a colleague's script can fetch the password:

```hcl
output "db_password" {
  value = var.db_password
}
```

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Output refers to sensitive values
│ 
│   on outputs.tf line 1:
│    1: output "db_password" {
│ 
│ To reduce the risk of accidentally exporting sensitive data that was
│ intended to be only internal, Terraform requires that any root module
│ output containing sensitive data be explicitly marked as sensitive, to
│ confirm your intent.
│ 
│ If you do intend to export this data, annotate the output value as
│ sensitive by adding the following argument:
│     sensitive = true
╵
```

The refusal is the useful part. An output built from a secret has to say so itself, so a value
cannot become readable by accident three references away from where it was marked. She adds the
argument the message asks for:

```hcl
output "db_password" {
  value     = var.db_password
  sensitive = true
}
```

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 4

Outputs:

db_password = <sensitive>
```

## Hidden from a listing, not from a reader

`<sensitive>` is what a listing of the outputs shows. Asking for the value by name, or as JSON,
returns it:

```
ana@laptop:~/shop$ terraform output
db_password = <sensitive>
ana@laptop:~/shop$ terraform output -raw db_password; echo
s3cr3t-Shop-2026
ana@laptop:~/shop$ terraform output -json
{
  "db_password": {
    "sensitive": true,
    "type": "string",
    "value": "s3cr3t-Shop-2026"
  }
}
```

That is on purpose. An output exists to be read by something: a script, another configuration
(lesson 8), a pipeline step. `sensitive` stops it being printed when nobody asked for it, and gets
out of the way when somebody does.

## And the state does not care

After that apply, the state holds the password on two lines, and one of them is the
`user_data` the plan has stopped showing:

```
ana@laptop:~/shop$ grep -c s3cr3t-Shop-2026 terraform.tfstate
2
ana@laptop:~/shop$ jq -r ".resources[] | select(.type == \"aws_instance\") | .instances[0].attributes.user_data" terraform.tfstate
#!/bin/sh
echo "DB_PASSWORD=s3cr3t-Shop-2026" > /etc/shop.env
```

**`sensitive = true` changes nothing that is written to disk.** The state, the saved plan and the
git history from the last section are exactly as they were. Most providers already mark their
obviously secret arguments sensitive in their own schema, such as the `password` of a database or
the `secret_string` of a secret, which is why a plan rarely prints those. `user_data` is not one of
them, because most scripts are not secret, so it took Ana's marking to hide it.

The habit to keep is cheap: mark every variable and output that carries a secret, and let the output
check catch the ones you missed. The belief to drop is that a sensitive value is a protected one.
