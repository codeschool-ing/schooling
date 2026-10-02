---
title: Types, and the shape of a variable
version: 1
---

A variable with no `type` accepts anything, and that sounds convenient until a wrong value gets
through. Somebody passes `"sa-east-1a"` where a list of zones was meant, and the error arrives
three resources later, inside an argument, naming a subnet rather than the input that caused it.
**A type constraint moves that error to the door**, where it names the variable.

HCL has three families of type.

| family | types | holds |
| --- | --- | --- |
| primitive | `string`, `number`, `bool` | one value |
| collection | `list(T)`, `set(T)`, `map(T)` | any number of values, all of type `T` |
| structural | `object({...})`, `tuple([...])` | a fixed shape, each part with its own type |

The difference between the last two rows is the one to keep. **A collection has one element
type and any length**: a `list(string)` of zones may hold one or six. **A structural type has a
fixed shape**: an object names its attributes, each with a type of its own, and a tuple fixes the
type at each position. `any` exists too, and means "work it out from the value", which puts the
door back where it was.

Ana's `network` variable, from the file shown in the expressions section, is an object of three
attributes: a string, a list of strings, and a boolean marked **`optional(bool, false)`**. Its
default leaves `public` out, and the console shows what Terraform made of it:

```
ana@laptop:~/shop$ echo 'var.network' | terraform console
{
  "azs" = tolist([
    "sa-east-1a",
    "sa-east-1c",
  ])
  "cidr" = "10.20.0.0/16"
  "public" = false
}
ana@laptop:~/shop$ echo 'type(var.network)' | terraform console
object({
    azs: list(string),
    cidr: string,
    public: bool,
})
```

`public` is there with the value `false`, filled in from the `optional()` declaration, so the
subnets can read `var.network.public` without checking whether anybody set it. The zones came out
as `tolist([...])`: the default was written as a tuple, and Terraform converted it to the list
the type asks for. `type()` is a function only the console has, and it is the quickest way to
see what a value is.

## Conversion, and where it stops

Terraform converts between types when the conversion cannot lose anything:

```
ana@laptop:~/shop$ echo '"5" + 1' | terraform console
6
ana@laptop:~/shop$ echo 'tonumber("three")' | terraform console
╷
│ Error: Invalid function argument
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ Invalid value for "v" parameter: cannot convert "three" to number; given
│ string must be a decimal representation of a number.
╵

ana@laptop:~/shop$ echo 'toset(["sa-east-1c", "sa-east-1a", "sa-east-1c"])' | terraform console
toset([
  "sa-east-1a",
  "sa-east-1c",
])
```

`"5" + 1` is `6`, because `"5"` is a number written as a string. `"three"` is not, and
`tonumber` says so. A set is a collection with no order and no duplicates, so `toset` dropped the
second `sa-east-1c` and printed what was left sorted. That last property matters in lesson 4,
where `for_each` takes a set or a map and not a list.

## The error at the door

A `.tfvars` file that gives `azs` one string instead of a list:

```hcl
network = {
  cidr = "10.20.0.0/16"
  azs  = "sa-east-1a"
}
```

```
ana@laptop:~/shop$ terraform plan -var-file=wrong.tfvars
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for input variable
│ 
│   on wrong.tfvars line 1:
│    1: network = {
│    2:   cidr = "10.20.0.0/16"
│    3:   azs  = "sa-east-1a"
│    4: }
│ 
│ The given value is not suitable for var.network declared at
│ variables.tf:7,1-19: attribute "azs": list of string required, but have
│ string.
╵
```

**The error names the file, the variable, the attribute and both types**: list of string
required, string given. Nothing was planned. Without the constraint, this value would have
reached `var.network.azs[0]` in `network.tf`, and the first complaint would have come from
there, in a file the person who wrote the `.tfvars` may never have opened.

A type says what shape a value has. It cannot say that `azs` should name zones of São Paulo, or
that the environment is one of two words. That is a validation rule, and it is the last section
of this lesson.
