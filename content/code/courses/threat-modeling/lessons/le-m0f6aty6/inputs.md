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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l06-two-inputs\" aria-label=\"Two inputs through the four questions. The payment webhook: anyone can reach it, it changes money, its body is trusted, and nothing limits how often it is called. The exam upload: patients reach it after signing in, it changes the patient’s exams and the storage, a PDF library parses it, which is T14, and it has no size limit, which is T10.\"><text x=\"355.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">payment webhook</text><text x=\"585.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">exam upload</text><rect x=\"20.0\" y=\"35.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reach without a credential?</text><rect x=\"250.0\" y=\"35.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">anyone</text><rect x=\"470.0\" y=\"35.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">patients after sign-in</text><rect x=\"20.0\" y=\"87.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what does it change?</text><rect x=\"250.0\" y=\"87.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">money: a booking paid</text><rect x=\"470.0\" y=\"87.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the patient’s exams, storage</text><rect x=\"20.0\" y=\"139.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what parses it?</text><rect x=\"250.0\" y=\"139.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a body that is trusted</text><rect x=\"470.0\" y=\"139.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a PDF library (T14)</text><rect x=\"20.0\" y=\"191.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">how large, how often?</text><rect x=\"250.0\" y=\"191.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nothing limits the calls</text><rect x=\"470.0\" y=\"191.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no size limit (T10)</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">amber: the answer that puts an input near the top of the list</text></svg>", "caption": "The webhook answers all four questions badly, which is why it tops the list before any detailed analysis."}
```

### The spreadsheet

The last row is the one people laugh at and should not. Every month somebody exports the list of
clinics and physiotherapists from a spreadsheet and loads it into the database. The spreadsheet is
shared with an outside accountant. A cell containing something the loader did not expect is an
input from somebody outside Vereda, arriving with the database owner's permissions. It is not on
the DFD because it is a manual step, and a manual step is a flow like any other.
