---
title: "SaaS: you use the application, and some of it is still yours"
version: 1
---

With **software as a service** you do not run an application at all. You use one somebody else runs:
webmail, a shared calendar, a customer database, a helpdesk, a hosted online shop, a video call.
Google Workspace, Microsoft 365, Salesforce, Shopify and Slack are all SaaS. You sign in through a
browser or an app, and the provider runs every layer of the stack, **including the application
itself**. You do not choose its version, patch it or restart it; it changes when the provider
changes it, for everybody at once.

The common belief is that this leaves nothing for you to do. It leaves less, and what it leaves is
the part that goes wrong most visibly.

## What is still yours

**The data is still yours.** The provider stores it and keeps copies against its own failures, a disk dying or a
building flooding. What those copies do not protect you from is your own side: an employee who deletes
a folder, a script that overwrites a thousand contacts, an account taken over by somebody who empties
it. Many services keep deleted items for a limited window and then remove them for good, and the
length of that window is written in their documentation rather than chosen by you.

**So is the question of who has access.** The accounts in the service are yours to manage: who has one, which of them are
administrators, whether signing in needs a second factor, and whether the person who left in March
still has a working login in October. The provider checks the password it is given; **it has no way
to know the person typing it should have been removed**.

**So is the configuration.** A SaaS product is full of settings that decide who sees what. Take a folder of
contracts in a document service, shared as *anyone with the link can view*. The provider's security
can be flawless, the storage encrypted and the building guarded, and the contracts are still public,
because the setting you chose says so. The same shape turns up as a calendar
published to the whole internet, or a shop's staff account that can issue refunds when it only
needed to see orders.

**And so is the way out.** At some point you may want to leave: a better product, a price rise, a provider
that closes. What you take with you is whatever the service lets you export, in whatever format it
exports. A shop's orders as a spreadsheet file are useful; its product pages, theme and discount rules
may have no export at all. **Find out what the export gives you before you need it**, while leaving is
still a choice rather than an emergency.

## Where the line sits

On the stack from earlier in this lesson, SaaS moves the line past the application and stops just
below the data. Two rows are left above it, the data and identity and access, and the configuration of
the application sits right on the line, a setting in the provider's software that you are the one to
choose.

That is the least work any model leaves you, and the same two rows turn up in the next section on
every model at once. **They are the part of the stack you cannot hand over, because nobody else knows
what they should be.** A provider can run your mail server better than you would; it cannot know which
of your employees should read the finance mailbox.
