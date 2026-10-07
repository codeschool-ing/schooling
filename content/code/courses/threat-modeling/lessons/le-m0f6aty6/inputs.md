---
title: Inputs
version: 1
---

The obvious inputs are forms and API endpoints. **The ones that cause incidents are usually the
ones nobody listed as inputs**, because they did not feel like one when they were built. A map of
inputs at Vereda went through five kinds, and only the first kind was on anybody's list before.

| kind | at the portal | who can send it |
|---|---|---|
| **requests from people** | sign-in, booking, cancelling, the profile page | anyone for sign-in; patients after it |
| **files** | the exam PDF upload | patients after sign-in |
| **calls from other systems** | the payment webhook | anyone who knows the address, today |
| **staff tools** | the console's agenda, notes and exam viewer | staff, and today anyone who reaches the sign-in page |
| **configuration and data you load** | environment variables, the clinic list imported from a spreadsheet each month | bruno, and whoever edits that spreadsheet |

### Questions for each input

Four questions are enough to rank inputs before any detailed analysis:

1. **Who can reach it without a credential?** Anyone on the internet, any signed-in patient, staff
   only, one named vendor.
2. **What does it change?** Nothing (a read), the sender's own data, other people's data, money.
3. **What parses it?** A form field read as a string is simple. A PDF parsed by a library is a
   large amount of somebody else's code running on attacker-chosen bytes, which is T14.
4. **How large and how often?** An upload with no size limit is T10; a booking form that sends an
   SMS each time is T11.

The webhook answers the four questions as badly as any input at Vereda: anyone can reach it, it
changes money, its body is trusted, and nothing limits how often it is called. Its position at the
top of the list is not a surprise, but the map makes it visible to somebody who was not in the
room for lesson 3.

### The spreadsheet

The last row is the one people laugh at and should not. Every month somebody exports the list of
clinics and physiotherapists from a spreadsheet and loads it into the database. The spreadsheet is
shared with an outside accountant. A cell containing something the loader did not expect is an
input from somebody outside Vereda, arriving with the database owner's permissions. It is not on
the DFD because it is a manual step, and a manual step is a flow like any other.
