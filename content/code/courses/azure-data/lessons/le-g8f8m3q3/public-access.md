---
title: Anonymous access, one setting away
version: 1
---

**A container can be made readable by anybody on the internet with one setting, and no signature of
any kind.** Blob Storage calls it the container's public access level, and it has three values:
`off`, which is private; `blob`, where anybody who knows a blob's name can read it; and `container`,
where anybody can also list the names. It exists for good reasons, such as the product images of a
public website, and it is the shape behind most of the storage leaks that made the news. The setting
is on the container, so a container made public on Friday afternoon for a quick test is public on
Monday.

## On Azurite

@@CAP public@@

**`blob` made the export readable by a `curl` with no credentials**, and refused the listing: with
that level, a stranger has to know the exact name. `container` added the listing, and the listing
handed over the name. Setting it back to `off` closed both. On Azurite, as on Azure, the setting
takes effect on the next request.

**Knowing the name is not protection.** Names in a lake are predictable by design: lesson 2 chose
`exports/2026/10/orders-2026-10-29.csv` so that a program could find the next day's file by itself,
and a stranger can find it the same way. Level `blob` is public for every name somebody can guess.

## The switch above the container

On Azure there is one more layer, which Azurite does not have: **the account's setting for anonymous
access**, `allowBlobPublicAccess`. When it is false, no container in the account can be public,
whatever its own level says, and a request to set a level is refused. Microsoft's documentation says
new storage accounts are created with it set to false by default, which closes the commonest leak
for anybody who does nothing, and leaves it open in older accounts that were created before the
change and in any account where somebody turned it on.

That makes anonymous access a decision taken twice, once on the account and once on the container,
and the safe arrangement keeps the account switch false everywhere except an account made for public
files and nothing else. The last section declares it with Terraform.
