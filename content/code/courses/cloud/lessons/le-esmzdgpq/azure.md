---
title: "Azure: where the company already runs Microsoft"
version: 1
---

The common misreading is that **Azure is the cloud for Windows**. It sells Linux machines as a
matter of course, Ubuntu, Red Hat and Debian among its images, and its managed PostgreSQL and MySQL
are ordinary products. The misreading is wrong about the machines and right about something else:
Azure's strongest argument is aimed at companies that already run Microsoft, and that argument is
about identity and licences more than about operating systems.

Microsoft opened it in 2010 as Windows Azure and renamed it Microsoft Azure in 2014, which is where
the misreading comes from.

## Identity first

Most offices sign their staff in with Microsoft: e-mail, documents and meetings through Microsoft
365, and behind it a directory of people and groups that Microsoft now calls **Entra ID**. It was
called Azure Active Directory until 2023, and you will meet the old name in older documentation and
in people's mouths. Many of those offices also run the older, on-premises Active Directory, joined
to Entra ID, which is the hybrid arrangement lesson 2 described.

Azure uses that same directory for its own access control. So **the account a person already uses
for e-mail is the account that signs in to the cloud**, and when somebody leaves the company,
disabling them in one place closes both. At a provider with a separate identity system that is two
steps, and the second is the one somebody forgets. Lesson 7 is about identity and access in
general; here the point is that Azure starts with the directory the company already has.

Licences are the second half. A company that already owns Windows Server and SQL Server licences can
apply them to Azure machines, under a programme Microsoft calls Azure Hybrid Benefit, instead of
paying for the licence again inside the hourly price. For a company with a room full of Windows
servers, that is often the largest number in the comparison.

## Tenant, subscription, resource group

Azure has more boxes than AWS, and each one does a different job:

- the **tenant** is the Entra ID directory itself: the people, the groups, the organisation;
- a **subscription** is where the bill attaches, and a boundary of access. A company keeps several,
  one per environment or per department, the way it keeps several AWS accounts;
- a **resource group** is a folder inside a subscription. Every resource belongs to exactly one.

The resource group is the box with no equivalent in the other two. The intended use is to put together the resources that live and die together: an
application's machine, its disk, its database and its network. **Deleting a resource group deletes
everything in it**, which is exactly what you want when a test environment is finished, and exactly
what you do not want when a production database was put in the wrong group.

Regions have names rather than codes on the screen: the one in São Paulo state is **Brazil South**,
and others read like East US or West Europe. Command-line tools use a compact spelling of the same
name, `brazilsouth`.

## What else it is known for

Beyond identity, Azure is where Microsoft's own products are sold as managed services: Azure SQL
Database is SQL Server run for you, and Microsoft's development tools, Visual Studio and GitHub
among them, connect to it with little setup. Its own language for describing infrastructure is
Bicep, which compiles to the older ARM templates. The `iac` course uses Terraform instead, which
speaks to all three providers.

The `azure-foundations` course builds on this one with the portal, the CLI and the governance of
many subscriptions. What to keep from here: **a company already inside Microsoft 365 starts its
Azure comparison with a head start in identity and licences**, and that head start is real money and real safety.
