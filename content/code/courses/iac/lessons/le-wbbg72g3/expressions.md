---
title: Expressions, and the console to try them in
version: 1
---

Everything to the right of an `=` is an expression, and an expression is anything that produces a
value. The literal `"10.20.0.0/16"` is the simplest one. The interesting ones compute: they read
another value, compare two, choose between them, or build a string out of pieces.

**`terraform console` is where you try them.** It reads the configuration in the current
directory and the state beside it, evaluates whatever you give it, and prints the value. It
creates nothing and changes nothing. In these lessons the expression is piped in with `echo`, so
each command and its answer sit on two lines; typed at a terminal, the console waits at a `>`
prompt instead. The variables it reads are in a new file, which the types section of this lesson
takes apart:

```hcl
variable "environment" {
  type        = string
  default     = "dev"
  description = "dev or prod."
}

variable "network" {
  type = object({
    cidr   = string
    azs    = list(string)
    public = optional(bool, false)
  })
  default = {
    cidr = "10.20.0.0/16"
    azs  = ["sa-east-1a", "sa-east-1c"]
  }
}
```

```
ana@laptop:~/shop$ echo 'var.environment' | terraform console
"dev"
ana@laptop:~/shop$ echo 'var.environment == "prod" ? 3 : 1' | terraform console
1
ana@laptop:~/shop$ echo '"shop-${var.environment}"' | terraform console
"shop-dev"
ana@laptop:~/shop$ echo 'aws_vpc.shop.cidr_block' | terraform console
(known after apply)
```

**A reference names a value declared somewhere else.** `var.environment` is an input variable,
`local.name` will be a local, and `aws_vpc.shop.cidr_block` is an attribute of a resource:
the type, the name, then the attribute. Lesson 2 showed that a reference between two resources
is also an order, because the subnet cannot be created before the VPC whose id it reads. Data
sources are referenced as `data.…`, in lesson 5, and modules as `module.…`, in lesson 10.

The last answer is the one to notice. **The console answers from the state, not from the file**,
and nothing has been applied yet, so even a value Ana typed literally is `(known after apply)`.
That phrase is not an error. It is how Terraform writes a value that will exist only once the
resource does, and plans are full of it.

The operators are the ones you would guess. Arithmetic is `+ - * / %`, comparison is `==`, `!=`,
`<`, `>`, `<=` and `>=`, and logic is `&&`, `||` and `!`. The conditional `condition ? a : b` is
the only way to choose: there is no `if` statement, because there are no statements. Both
branches must produce the same type, or types Terraform can convert to one.

## Strings that are built

`"shop-${var.environment}"` is a **template**: the `${…}` holds an expression, and its value is
written into the string. A second form, `%{…}`, holds a directive instead, `if` or `for`, and
decides what text appears:

```
ana@laptop:~/shop$ echo '"shop-${var.environment}%{ if var.environment == "prod" } (reviewed)%{ endif }"' | terraform console
"shop-dev"
ana@laptop:~/shop$ echo '"shop-${var.environment}%{ if var.environment == "prod" } (reviewed)%{ endif }"' | terraform console -var environment=prod
"shop-prod (reviewed)"
```

The same expression gives two strings, because `-var` changed the variable it reads. A
directive inside a one-line string is hard to read past this size, and when a condition chooses
a whole value the conditional operator says it more plainly.

For text that runs over several lines there is the **heredoc**, which Ana uses for a short
start-up script:

```hcl
locals {
  boot_script = <<-EOT
    #!/bin/sh
    echo "shop ${var.environment}" > /etc/motd
    echo "owner: ${var.owner}" >> /etc/motd
  EOT
}
```

```
ana@laptop:~/shop$ echo 'local.boot_script' | terraform console
<<EOT
#!/bin/sh
echo "shop dev" > /etc/motd
echo "owner: ana" >> /etc/motd

EOT
```

`<<-EOT` strips the indentation common to every line, so the script can be indented with the
code around it; plain `<<EOT` keeps every space. The console prints the result as a heredoc too,
with the newline that ends the last line. One warning: a heredoc is a string, and a policy
written as JSON inside one is a string as well, unchecked until AWS reads it. `jsonencode()`,
from the next section, builds the same JSON from a real value and cannot produce a missing
comma.
