---
title: The system this course models
version: 1
---

A threat model of no system in particular teaches the vocabulary and nothing else, so every lesson
of this course works on the same one. **Vereda Fisioterapia** is a small chain of four
physiotherapy clinics in São Paulo, invented for this course and the `cryptography` course before
it. About nine thousand patients have an account on its portal, and the clinics run some 1,800
sessions a week.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-portal\" aria-label=\"A sketch of Vereda’s patient portal, before any notation. Patients reach the portal over the internet; clinic staff reach a separate staff console from the clinics. Both read and write the records database, and both reach the exam files where uploaded PDFs are kept. A reminder worker reads tomorrow’s bookings from the database and asks an SMS provider to send a message. The portal charges sessions through a payment gateway, which calls back with a webhook.\"><rect x=\"20.0\" y=\"40.0\" width=\"130.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">patients</text><text x=\"85.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(browser, phone)</text><rect x=\"20.0\" y=\"240.0\" width=\"130.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">clinic staff</text><text x=\"85.0\" y=\"268.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(reception, physios)</text><rect x=\"250.0\" y=\"40.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">portal</text><text x=\"320.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">portal.vereda.example</text><rect x=\"250.0\" y=\"240.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">staff console</text><rect x=\"470.0\" y=\"140.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">records</text><text x=\"530.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">database</text><rect x=\"470.0\" y=\"240.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exam files</text><text x=\"530.0\" y=\"268.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(PDFs)</text><rect x=\"470.0\" y=\"40.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">reminder</text><text x=\"530.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">worker</text><rect x=\"610.0\" y=\"40.0\" width=\"100.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SMS</text><text x=\"660.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provider</text><rect x=\"250.0\" y=\"140.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">payment gateway</text><text x=\"320.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(Pix, card)</text><path d=\"M150.0 62.0 L250.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 262.0 L250.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M320.0 84.0 L320.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390 62 L430 62 L430 150 L470 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390 262 L430 262 L430 172 L470 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390.0 252.0 L470.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390 74 L415 74 L415 280 L470 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M530.0 84.0 L530.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M590.0 62.0 L610.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Lesson 2 turns this sketch into a data flow diagram.</text></svg>", "caption": "Vereda’s portal as somebody would draw it on a whiteboard. Every lesson of the course models this system."}
```

### What it does

- **Patients** sign in at `portal.vereda.example`, book and cancel sessions, pay for them by Pix or
  card, and upload the PDFs of exams their doctor asked for: an X-ray report, an MRI.
- **Clinic staff** (receptionists and physiotherapists) use a separate **staff console** at
  `console.vereda.example`. Receptionists manage the agenda; physiotherapists read the exams and
  write clinical notes after each session.
- A **reminder worker** runs every evening, reads tomorrow's bookings and asks an **SMS provider**
  to send each patient a reminder.
- A **payment gateway** takes the money. When a payment clears, the gateway calls the portal back
  with a webhook, and the portal marks the booking paid.
- The **records database** holds accounts, bookings and clinical notes. The **exam files** are kept
  in object storage beside it.

### What you already know about it

Four facts from the people who built it, which the lessons will come back to:

1. The portal and the staff console run in Vereda's cloud account and answer from the internet.
   The console is supposed to be reachable only from the clinics' network.
2. The database and the file storage sit in a private network inside the same cloud account.
3. The reminder worker connects to the database with the database owner's password, because that
   was the password that worked on the day it was written.
4. The webhook handler marks a booking paid when a request says so. Nobody has checked whether it
   verifies that the request came from the gateway.

That list already contains threats. Lesson 2 draws the system properly, lesson 3 finds what can go
wrong with it, and by lesson 12 each of those facts has either been fixed or has a signed decision
saying why it has not.

### The people

Four people at Vereda will appear in the examples, and their roles matter more than their names:

| | role | what they know |
|---|---|---|
| ana | developer, wrote most of the portal | the code, and where the shortcuts are |
| bruno | operations, part time | the cloud account, the networks, the backups |
| carla | security consultant, two days a month | the threats, and how other systems got hurt |
| daniel | runs the clinics' operations | what the business can live with, and what it cannot |

daniel is in the list on purpose. Deciding which risks Vereda accepts is a business decision, and
lesson 12 is about getting the person who owns it to sign it.
