---
title: The billing account, and the people around it
version: 1
---

**A Cloud Billing account is what pays.** It holds the payment method, receives the invoices, and is
where every cost of every project linked to it is added up. It is **not part of the resource hierarchy**:
a billing account sits beside the tree of lesson 2 rather than in it, and one billing account may pay for
projects in any folder, or in more than one organisation.

| kind | how it pays | who it suits |
|---|---|---|
| **self-serve**, also called online | a card or a bank account, charged automatically each month, or when spending crosses a threshold | most accounts, and every new one |
| **invoiced**, also called offline | a monthly invoice, paid by transfer on terms | larger companies, after a credit check and a request to Google |

A billing account's id looks like `012345-6789AB-CDEF01`: three groups of six characters. It is the number
to give support, and the one Terraform names.

## The roles, which are not project roles

Billing has its own roles, granted **on the billing account**, and they are deliberately separate from
Owner and Editor:

| role | what it lets its holder do |
|---|---|
| `roles/billing.admin` | everything: payment methods, roles on the account, closing it |
| `roles/billing.user` | **link projects to this account**, which is spending its money |
| `roles/billing.costsManager` | budgets and exports, lessons 12 and 14 |
| `roles/billing.viewer` | read costs and invoices |

On the project side, `roles/billing.projectManager` lets its holder link and unlink the project, and
nothing else. **Linking needs both sides**: a role on the account that allows associating resources with
it, and a role on the project that allows creating its billing assignment. Owner of a project holds the
second, so an Owner with `billing.user` on an account can point the project at it.

That split is the control worth noticing. **Whoever holds `billing.user` on the company's account decides
which projects the company pays for.** A developer who can create projects and link them can run anything
on the company's card, and the role to keep scarce is that one, more than Owner on any single project.

## A finance person's view

The people who read invoices rarely need any project role at all. `billing.viewer` on the account shows
every cost and every invoice, across every project, without letting its holder see one resource inside any
of them. That is the right grant for an accountant: they see the money and nothing the money paid for.

Nothing in this section ran. The Cloud Billing API answers only to an authenticated caller, and the lab asks
it once in the next section, to be refused.
