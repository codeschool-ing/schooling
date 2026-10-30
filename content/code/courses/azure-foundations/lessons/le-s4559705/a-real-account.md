---
title: A real account, and the order to protect it in
version: 1
---

**You do not need an Azure account for any lesson in this course.** This section is for later, or
for the student who wants to see the real portal beside the lab. **None of it was run for the
course**, because there is no account behind it. So there are no transcripts here, only the steps
and the reasons for their order. The screens they mention are Microsoft's, and Microsoft redesigns
them; the names of the settings change less often than their places.

## Before the account exists

Signing up for Azure asks for a Microsoft account or a GitHub account, a phone number that receives
a code, and a payment card. **Three things are created at that moment, and only one of them is
called an account**:

- **a tenant**, an instance of Microsoft Entra ID, the directory that will hold every identity;
  lesson 2 draws it;
- **a subscription**, the unit Azure bills and the container your resources will live in;
- **you, as the first identity**, made Global Administrator of the tenant and Owner of the
  subscription: the two most powerful roles there are, held by one person who has not yet set a
  second factor.

Two decisions are cheap now and dear later:

- **Sign up with an identity that is not tied to one person's job.** Whoever signs up owns the
  tenant. A company should do it with an address it controls, so that the day the person who opened
  it leaves is not the day the company loses the keys.
- **Know which offer you are choosing.** At the time this course was written, Microsoft offered a
  **free account**: a sum of credit to spend within the first month, a list of services free for
  twelve months up to a monthly amount, and others free for good up to a limit. **The free account
  is one possibility, not a promise**: the amounts and the list have changed before and will again.
  Read the current page before relying on any number in it, and never rely on a number from a
  course. The other common offer is **pay as you go**, billed monthly for what was used.

## The first hour, in this order

1. **Protect the identity that owns everything with multifactor authentication.** Microsoft has made
   a second factor compulsory for signing in to the Azure portal, and then to the CLI and the other
   tools, so a new account is asked to register one; do it with an authenticator app or a passkey,
   not a text message. New tenants also start with **security defaults** switched on, a fixed set of
   protections lesson 11 explains. Leave them on until lesson 11's conditional access can replace
   them.
2. **Create a budget with an alert, before anything that can cost money.** In the portal it is under
   *Cost Management*, *Budgets*: a monthly budget of a few dollars for the subscription, with an
   e-mail alert at 80% of the actual cost and another at 100% of the forecast. Lesson 13 writes the
   same budget in Bicep and says what each kind of alert means. **An alert does not stop
   spending**; it tells you, which is why it comes first, while the amount is still small.
3. **Keep the spending limit, if the offer has one.** Subscriptions bought with credit, the free
   account's among them, stop their resources when the credit runs out, unless somebody removes the
   limit. Pay as you go has none, and nothing will stop it but you.
4. **Make an everyday identity, and stop using the owner.** Lesson 6 creates a user in Entra ID, and
   lesson 9 gives it a role on one resource group instead of the whole subscription. From then on
   the owner's credentials go somewhere safe and are used only for what needs them.

## Pointing the lab at it, and back

The CLI you installed keeps its sign-ins in `AZURE_CONFIG_DIR`, which `env.sh` sets to
`~/azure/.azure`. **Use a separate terminal that never reads `env.sh`** and sign in there with
`az login`: that CLI keeps its memory in `~/.azure`, and the lab's stays empty. Two terminals with
two memories are harder to confuse than one terminal whose variables you have to remember. Before
any command that creates something, `az account show` names the subscription it will land in; read
it every time, because a tenant with two subscriptions is one mistyped default away from billing
the wrong one.

Everything this course compiles, Azure will run and bill. A virtual machine is charged by the second
while it runs and its disk for as long as it exists; a public IP address, a VPN gateway, an Azure
Firewall and an Application Gateway are charged by the hour from the moment they exist, whether or
not anything uses them. **Put everything you create for practice in one resource group, and delete
the group the same day**: `az group delete --name <the group>` removes every resource inside it.
Then look at *Cost analysis* the next morning. It is the one screen that tells you what you forgot.
