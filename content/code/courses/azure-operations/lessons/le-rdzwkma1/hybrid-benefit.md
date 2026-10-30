---
title: Azure Hybrid Benefit: licences you already own
version: 1
---

**Azure Hybrid Benefit lets an organisation use licences it already owns instead of paying for them again
in Azure's price.** A Windows Server VM's hourly rate includes the Windows licence; a SQL Server VM's or an
Azure SQL vCore database's rate includes SQL Server's. An organisation with those licences on-premises,
under an agreement that covers moving them (Software Assurance or an equivalent subscription), can switch
the benefit on and pay only for the compute.

It is a property, not a purchase: `licenseType: 'Windows_Server'` on a VM, or `licenseType:
'BasePrice'` on an Azure SQL vCore database, in the same Bicep as the resource. It combines with a
reservation: the reservation discounts the compute, and the benefit removes the licence.

Three things make it a decision rather than a switch:

- **you must hold the licences**, and count them: the benefit is an assertion your organisation makes, and
  a licence audit is where an assertion without licences is found;
- **it applies to Windows and SQL Server**, and to Red Hat and SUSE Linux under their own programmes; the
  shop's App Service on Linux and its open-source workers have nothing for it to remove;
- **the saving is the licence's share of the rate**, which is large for Windows and very large for SQL
  Server Enterprise, and is published per size.

For the shop, today, the benefit applies to one thing: `vm-reports`, a Windows VM for a reporting tool,
which lesson 23 is about to find doing very little.
