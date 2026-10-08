---
title: Os documentos
version: 1
---

Um sistema de busca só é tão interessante quanto aquilo de onde ele busca. **Os documentos da
Marginalia são o acervo em que toda aula procura**, e você os escreve na sua máquina com um script.
Salve o bloco abaixo como `~/rag/docs.sh` e rode; ele é longo porque carrega cada palavra de treze
documentos, e não faz nada além de escrevê-los.

```sh
#!/bin/sh
# docs.sh: writes the thirteen documents of Marginalia, the shop this course is about, into data/docs
set -e
mkdir -p data/docs
cat > data/docs/affiliate-api.md <<'EOF'
---
id: affiliate-api
title: Affiliate API reference
audience: developers
owner: platform
updated: 2026-02-10
version: 2.3
status: current
---

# Affiliate API reference

The affiliate API lets partner sites look up books, build tracked links and read their commission
reports. This is version 2.3 of the reference.

## Base URL and authentication

Every request goes to the base URL below and carries the affiliate key in a header:

    https://api.marginalia.example/affiliate/v2
    X-Affiliate-Key: <your key>

Keys are issued in the partner dashboard. A key belongs to one partner site; a request with a key
from another site is refused with E-4101. Keys do not expire, but can be revoked from the dashboard
at any time.

## Rate limits

A key may make 120 requests per minute. A request over the limit is refused with HTTP 429 and the
error E-4102, and the header Retry-After says how many seconds to wait. Report requests count
double.

## Endpoints

### GET /products/{isbn}

Returns one book by its ISBN-13: title, authors, price, availability and the URL of its cover. An
ISBN that is not in the catalogue returns E-4103.

    GET /products/9780141439518

### GET /search

Searches the catalogue. Parameters: q, the text to search for; lang, a two-letter language code;
page, starting at 1. Each page holds 20 results, and at most 50 pages are returned.

    GET /search?q=persuasion&lang=en&page=1

### POST /links

Builds a tracked link to a product page. The body names the ISBN and an optional campaign label of
at most 40 characters:

    {"isbn": "9780141439518", "campaign": "spring-newsletter"}

The link carries the partner's identifier and the campaign, and is valid for as long as the key.

### GET /reports/commissions

Returns the commissions earned in one calendar month. Parameter: month, as YYYY-MM. Months more
than 24 months in the past, or in the future, return E-4104.

    GET /reports/commissions?month=2026-01

## Commission

A partner earns 6% of the price of printed books and 3% of the price of e-books and audiobooks
bought through a tracked link. A purchase counts when it happens within 30 days of the click, from
the same browser. Commissions on orders that are returned or refunded are cancelled.

Commissions are paid monthly, 45 days after the end of the month in which the order was placed, when
the amount owed is at least 25.

## Errors

Errors are returned as JSON with a code and a message:

    {"error": {"code": "E-4103", "message": "unknown ISBN"}}

| code | HTTP | meaning |
| --- | --- | --- |
| E-4101 | 401 | the key is missing, revoked or belongs to another site |
| E-4102 | 429 | more than 120 requests in the last minute |
| E-4103 | 404 | the ISBN is not in the catalogue |
| E-4104 | 400 | the month is out of range or not in the form YYYY-MM |
| E-4105 | 400 | the campaign label is longer than 40 characters |
| E-5001 | 500 | an error on our side; retry after a few seconds |

## Changes in 2.3

Version 2.3, released on 10 February 2026, added the lang parameter to /search and the error E-4105.
Version 2.2 is still served at the same URL and ignores lang.
EOF
cat > data/docs/ebooks-and-audiobooks.md <<'EOF'
---
id: ebooks-and-audiobooks
title: E-books and audiobooks
audience: public
owner: digital
updated: 2026-03-27
version: 5
status: current
---

# E-books and audiobooks

How digital books are delivered, where they can be read and played, and when they can be refunded.

## Where e-books can be read

E-books open in the Marginalia app for phones and tablets and in any reader that supports EPUB with
Adobe DRM. Kindle readers cannot open our e-books, because Amazon's devices do not support that
protection. A small number of titles are sold without DRM; their product page says DRM-free, and
they open on any EPUB reader, Kindle included after conversion.

You can use the same account on up to six devices at a time. To add a seventh, remove one under
Account settings, Devices. A device can be removed at most four times in a year.

## Downloading

An e-book appears in your library as soon as the payment is confirmed, usually within a minute.
Downloads fail most often because the device is out of space or the app is out of date. Update the
app, free some space and try again from your library. If the file still will not open, send us the
title, the device model and the version of the app, which is under Settings, About.

## Reading

In the app, tap the middle of the page and choose Aa to change the typeface, the size, the spacing
and the background colour. Books with fixed layouts, such as comics, cookbooks and illustrated
children's books, can only be zoomed. Notes and highlights are kept with your account and appear on
every device.

## Lending and sharing

E-books are licensed to your account and cannot be lent, resold or shared with another account.
Family members can read them on a device signed in to your account, within the six-device limit.

## Refunds for e-books

An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in
the app. Once it has been downloaded, the sale is final, as the law allows for digital content
delivered with your consent. You give that consent when you tick the box at checkout.

An e-book that is faulty, for example with missing chapters or text that cannot be displayed, is
refunded or replaced at any time, downloaded or not.

## Audiobooks

Audiobooks are sold separately from e-books and play only in the Marginalia app, online or
downloaded for offline listening. Playback speed goes from 0.5 to 3 times. A bookmark is kept for
each audiobook on every device.

An audiobook can be refunded within 14 days of purchase if less than 10% of it has been played.
The app records how much has been played; skipping ahead counts as played.

## When an account is closed

Closing your account removes access to every e-book and audiobook in your library, because the
licence belongs to the account. Download the DRM-free titles first; the others cannot be kept.
EOF
cat > data/docs/finance-refund-controls.md <<'EOF'
---
id: finance-refund-controls
title: Refund controls and chargebacks
audience: finance
owner: finance
updated: 2026-03-03
version: 4
status: current
classification: confidential
---

# Refund controls and chargebacks

For the finance team only. Do not share the thresholds in this document with support agents,
sellers or customers: an agent who knows them can be talked into working around them.

## Finance reviews

Support opens a finance review when a refund or credit is above the agent's or lead's limit, or when
fraud is suspected. Reviews are answered within one working day, oldest first.

A refund of more than 500 on one order always needs a second approver from finance, whoever
requested it.

## Automatic holds

The payment provider gives every order a fraud score from 0 to 1. An order with a score of 0.82 or
more is held before dispatch and goes to manual review. An order between 0.65 and 0.82 is dispatched
only to the billing address.

A customer who has received more than three refunds in 90 days is flagged, and every further refund
on that account goes to finance review regardless of the amount.

## Goodwill budget

Goodwill credit across the whole support team is capped at 4,000 a month. When 80% of the budget is
used, the head of support is told, and from then on only team leads may give goodwill credit.

## Chargebacks

A chargeback is a payment reversed by the customer's bank. When the provider notifies us of one we
have seven calendar days to dispute it, with the proof of delivery and the order history.

We do not dispute a chargeback when the parcel was treated as lost, or when the customer had already
asked us for a refund and not received it within the policy's time. Paying back in those cases costs
less than the dispute fee, which is 15 per chargeback.

Our chargeback rate must stay below 0.6% of card orders in any month, or the payment provider may
raise our fees. The rate for February 2026 was 0.31%.

## Month end

Refunds issued after 6 pm on the last working day of the month are booked in the following month.
EOF
cat > data/docs/gift-cards.md <<'EOF'
---
id: gift-cards
title: Gift card terms
audience: public
owner: finance
updated: 2025-10-27
version: 2
status: current
---

# Gift card terms

## Buying a gift card

Marginalia gift cards are sold in any whole value from 10 to 500. An e-mail gift card is sent at
the date and time the buyer chooses; a printed card is posted with an order and costs nothing
extra.

## Using a gift card

Each card has a sixteen-digit code. Enter it at checkout, or add it to your account under Gift
cards to keep the balance there. A gift card can pay for part of an order and the rest can go on a
card or Pix. Gift cards can be used on books sold by Marginalia and by marketplace sellers, but not
to buy other gift cards.

## Validity

A gift card is valid for two years from the day it was bought. The expiry date is printed on the
card and shown in the account. Unused balance is lost when the card expires.

## Cash and refunds

Gift cards cannot be exchanged for cash or transferred to a bank account. When an order paid by
gift card is refunded, the amount comes back as store credit, which never expires.

## Lost and stolen cards

A gift card added to an account can be replaced if it is lost or stolen, as long as the balance has
not been spent. A card that was never added to an account cannot be replaced, because whoever holds
the code can spend it. We will never ask you for a gift card code by phone or email.
EOF
cat > data/docs/payments-and-invoices.md <<'EOF'
---
id: payments-and-invoices
title: Payments, invoices and gift cards
audience: public
owner: finance
updated: 2026-03-30
version: 7
status: current
---

# Payments, invoices and gift cards

## Payment methods

We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. We do not
accept cash on delivery or bank transfer, except for schools and libraries paying by invoice.

A card payment can be split into up to three instalments with no interest on orders over 120. The
instalments are charged by your bank on your statement dates; we receive the full amount at once,
so a refund of an instalment order is made in full to the card, and your bank cancels the
instalments that have not been charged yet.

Pix payments must be completed within 30 minutes of the code being shown, or the order is
cancelled and the books return to stock.

## Declined payments

A declined card is almost always a decision by the bank, which does not tell us the reason. Check
that the billing address matches the one your bank has, then try again or use another method. Your
basket is kept for 24 hours.

## Charged twice

When a payment fails and you try again, the bank sometimes holds both amounts for a few days. Only
one is collected and the other disappears without action from you within seven days. If both are
still there after that, send us the order number and a bank statement showing both amounts.

## Prices

Prices are shown with tax included. A price can change after you put a book in your basket but
before you pay; the price you pay is the one on the checkout page. We do not refund the difference
if a price drops after your order.

## Receipts and invoices

A receipt is attached to the shipping confirmation email. For an invoice with a company name and tax
number, add them under Billing details before you order; we cannot reissue an invoice to a
different company after the order has shipped.

Schools and libraries buying twenty or more copies of one title receive 15% off the cover price and
can pay by invoice within 30 days. Send the list of titles and quantities from an institutional
email address to schools@marginalia.example.

## Gift cards

Gift cards are sold in values from 10 to 500, as an email or as a printed card posted with an order.
Each has a sixteen-digit code. Enter the code at checkout; a gift card can pay for part of an order
and the rest can go on a card.

Gift cards are valid for two years from purchase and cannot be exchanged for cash. A gift card that
was registered to an account can be replaced if it is lost; an unregistered one cannot, because
whoever holds the code can spend it.

Refunds for orders paid by gift card are made as store credit, which never expires.
EOF
cat > data/docs/privacy-notice.md <<'EOF'
---
id: privacy-notice
title: Privacy notice
audience: public
owner: legal
updated: 2026-01-05
version: 6
status: current
---

# Privacy notice

How Marginalia collects and uses personal data, how long it keeps it and how to exercise your
rights. Marginalia processes personal data under the Brazilian General Data Protection Law (LGPD).

## What we collect

- **Account data**: your name, email address, password (stored as a hash), and the addresses you
  save.
- **Order data**: what you bought, when, the delivery address and how you paid. We never store a
  full card number; the payment provider gives us the last four digits and the card brand.
- **Reading data**: your library, reading lists, reviews, and the notes and highlights you make in
  the app.
- **Support data**: the messages you send us and our replies, in email and chat.
- **Technical data**: the country your requests come from and the device you use. We do not store
  your IP address.

## Why we use it

We use account and order data to sell and deliver books, which is the contract between us. We use
reading data to keep your library on every device and, if you agree, to recommend books. We use
support data to answer you and to improve the help centre.

Support conversations are used to improve the help centre search only after names, email addresses,
order numbers and addresses have been removed from them. The text is kept for this purpose for two
years.

## How long we keep it

| data | kept for |
| --- | --- |
| order records | five years after the order, because tax law requires it |
| support messages | two years after the conversation ends |
| account and reading data | until you close the account |
| technical data | 90 days |

When you close your account we delete the account and reading data within 30 days. Order records
stay for the five years the law requires, without being linked to an account you can sign in to.

## Who we share it with

We share the delivery address and your name with the carrier, payment data with the payment
provider, and, for marketplace orders, your name and address with the seller, who must delete them
90 days after delivery. We do not sell personal data.

Some of our providers process data outside Brazil. When they do, we use contracts that give the
data the protection the LGPD requires.

## Your rights

You can ask to see, correct, delete or take away the personal data we hold about you. Under
Privacy, in your account, you can download a copy of everything we hold: the file is ready within
24 hours and the download link works for seven days.

To exercise any other right, write to our data protection officer at privacy@marginalia.example. We
answer within 15 days. You can also complain to the national data protection authority, the ANPD.
EOF
cat > data/docs/returns-policy-2025.md <<'EOF'
---
id: returns-policy-2025
title: Returns policy (2025)
audience: public
owner: customer-support
updated: 2025-03-01
version: 3
status: superseded
superseded_by: returns-policy
---

# Returns policy

This policy applies to orders placed from 1 March 2025.

## Returning a book

You may return a printed book within 14 days of delivery if it is unread and in the condition in
which you received it. Books that show signs of reading, such as a creased spine, cannot be
accepted and will be sent back to you.

To return a book, write to us with your order number and the titles you want to return. We reply
with a returns authorisation number, which you must write clearly on the outside of the parcel.
Parcels that arrive without one may be refused.

## Return postage

Return postage is paid by the customer. You can use our returns label, which costs 4.50 and is
deducted from your refund, or send the parcel by any tracked service at your own cost. We do not
accept parcels sent without tracking.

## Refunds

We refund within ten working days of receiving the returned books. The refund is made to the
original payment method. Delivery costs are not refunded.

Orders paid with a gift card are refunded to a new gift card, which is valid for one year.

## Damaged books

If a book arrives damaged, send it back within 14 days using our returns label, which is free in
this case. When it reaches us we send a replacement, or a refund if the title is out of stock.

## Exceptions

Signed copies, personalised copies and clearance items cannot be returned. E-books cannot be
refunded once purchased.

## Marketplace items

Items sold by marketplace sellers are returned to the seller under the seller's own conditions.
Marginalia does not handle these returns.
EOF
cat > data/docs/returns-policy.md <<'EOF'
---
id: returns-policy
title: Returns and refunds policy
audience: public
owner: customer-support
updated: 2026-02-02
version: 4
status: current
supersedes: returns-policy-2025
---

# Returns and refunds policy

This policy applies to every order placed on marginalia.example from 2 February 2026. Orders placed
before that date follow the policy that was in force on the day of the order. It covers printed
books, gifts and items sold by Marginalia itself. E-books and audiobooks have their own section
below, and items sold by marketplace sellers follow the seller's own policy.

## The return window

You have 30 days from delivery to return a printed book in the condition you received it. The 30
days start on the day the carrier records the parcel as delivered, not on the day you placed the
order. For an order that arrived in several parcels, each parcel has its own 30 days.

A book is in the condition you received it when it has no writing, no broken spine and no missing
pages, and when any shrink-wrap that came on it is still closed. Reading a book carefully does not
stop you returning it. A book damaged after it arrived can be refused, and we send it back to you at
our cost with an email explaining why.

The statutory right of withdrawal is seven days from delivery. This policy gives you more than the
law requires, and nothing in it reduces your statutory rights.

## How to start a return

1. Open the order in your account and choose Return items.
2. Select the books you are sending back and a reason. The reason helps us; it does not change
   whether the return is accepted.
3. Print the prepaid label we email you. If you cannot print, choose QR code and show it at the
   post office counter instead.
4. Pack the books so that they cannot move in the box, and drop the parcel at any post office.

Returns are free. You do not pay for the label, whatever the reason for the return. Keep the
receipt the post office gives you until the refund arrives: it is the only proof that the parcel
was sent.

## Refunds

We refund within three working days of the return reaching our warehouse. The money goes back to
the card or account you paid with, and your bank may take another five to ten days to show it.
Delivery costs are refunded when you return the whole order; when you return part of it, they are
not.

Orders paid with a gift card are refunded as store credit, which is added to your account and
never expires. Orders paid partly by gift card and partly by card are refunded to each in the same
proportion.

If the refund has not appeared after fifteen working days from the day you posted the parcel, write
to us with the order number and the post office receipt.

## Damaged, faulty and wrong items

If a book arrives with a torn cover, bent corners or water damage, photograph it next to the
packaging and send the pictures within 14 days of delivery. We replace damaged books at no cost and
you do not need to send the damaged copy back.

If we sent a different title from the one you ordered, tell us within 14 days. Keep the parcel
closed if you can. We send the right book at once with a prepaid label for the wrong one, and you
are not charged twice.

A printed book with a fault from the printer, such as pages bound upside down or missing, can be
returned for a refund or a replacement within 30 days, like any other return. If the fault only
shows up later, for example pages coming loose, write to us within one year of delivery.

## Items that cannot be returned

The following cannot be returned unless they arrive damaged or faulty:

- personalised copies and copies signed by the author;
- jigsaw puzzles and games whose packaging has been opened;
- anything bought in the clearance section;
- newspapers and magazines.

## Gifts

The person who received a gift can return it with the gift receipt and gets store credit for the
price paid, without the buyer being told. To get the money back on the original card instead, the
buyer has to start the return from their own account.

## E-books and audiobooks

An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in
the app. Once it has been downloaded, the sale is final, as the law allows for digital content
delivered with your consent.

An audiobook can be refunded within 14 days of purchase if less than 10% of it has been played.

## Items sold by marketplace sellers

Items marked Sold by, followed by a seller's name, are returned to the seller and not to us. Every
seller must accept returns for at least 14 days from delivery, and many accept them for longer. The
seller's own policy is on their page. If a seller does not answer a return request within two
working days, open a claim from the order and we decide it.

## Schools and libraries

Institutional orders paid by invoice follow the same 30-day window. The refund is issued as a credit
note against the invoice, not as a payment, unless the invoice has already been paid.
EOF
cat > data/docs/seller-agreement.md <<'EOF'
---
id: seller-agreement
title: Marketplace seller agreement
audience: sellers
owner: legal
updated: 2025-11-03
version: 3
status: current
---

# Marketplace seller agreement

This agreement is between Marginalia and every seller who lists items on the Marginalia marketplace.
Version 3, in force from 3 November 2025.

## 1. Listing

1.1 A seller may list new and second-hand books, and only books. Each listing states the condition
of the copy using the grades in the seller centre: new, as new, very good, good or acceptable.

1.2 A listing must describe the copy that will be sent. Photographs must be of that copy, not of
another one.

1.3 Marginalia may remove a listing that breaks this agreement, without notice, and tells the seller
why within two working days.

## 2. Fees

2.1 Marginalia charges a commission of 12% of the item price, plus 0.50 for each item sold.

2.2 The commission is not charged on the delivery cost the buyer pays.

2.3 When an item is refunded, the commission is returned to the seller, but the fixed fee of 0.50 is
not.

## 3. Dispatch

3.1 A seller dispatches each order within two working days of receiving it, with a tracked service.

3.2 A seller whose late dispatch rate is above 4% over 30 days receives a warning. Above 8%, new
listings are paused until the rate falls.

## 4. Payouts

4.1 Payouts are made every 14 days to the bank account registered in the seller centre.

4.2 The money from an order is held for seven days after the order is delivered, and paid in the
first payout after that.

4.3 Marginalia may hold a payout while a claim from a buyer is open.

## 5. Returns

5.1 A seller accepts returns for at least 14 days from delivery. A seller may offer a longer period
and says so on the seller page.

5.2 A seller answers a return request within two working days. If the seller does not answer, the
buyer may open a claim and Marginalia decides it.

5.3 When Marginalia decides a claim in favour of the buyer, it refunds the buyer and deducts the
amount from the seller's next payout.

## 6. Messages and service

6.1 A seller answers messages from buyers within two working days.

6.2 A seller never asks a buyer to pay outside Marginalia, and never asks for the buyer's payment
details.

## 7. Ratings

7.1 Buyers may rate a seller from one to five stars after delivery. A seller whose average over the
last 100 orders falls below 3.5 is reviewed by Marginalia.

## 8. Personal data of buyers

8.1 A seller receives the name and delivery address of each buyer only to send the order, and
deletes them 90 days after delivery.

## 9. Ending the agreement

9.1 Either party may end the agreement with 30 days' notice.

9.2 Marginalia may end it at once when a seller sends counterfeit books or asks buyers for payment
outside the marketplace.

9.3 Payouts owed when the agreement ends are paid after the last return period has passed.
EOF
cat > data/docs/shipping-and-delivery.md <<'EOF'
---
id: shipping-and-delivery
title: Shipping and delivery
audience: public
owner: operations
updated: 2026-03-18
version: 6
status: current
---

# Shipping and delivery

Everything about how an order reaches you: the options at checkout, what they cost, how long they
take, and what happens when a parcel goes missing.

## Delivery options and costs

| option | time | cost |
| --- | --- | --- |
| standard | three to five working days | 4.90, free on orders over 40 |
| express | next working day if ordered before 2 pm | 9.90 |
| pickup point | three to five working days | 2.90, free on orders over 40 |
| international | seven to fifteen working days | from 14.00, shown at checkout |

The threshold of 40 is the value of the books in the order after any discount, with tax included
and gift wrapping excluded. Express delivery is not free at any order value.

Express orders placed after 2 pm, or on a Saturday, Sunday or public holiday, leave the warehouse
on the next working day and arrive the working day after that.

## When an order leaves the warehouse

Books in stock leave the warehouse within one working day. A book shown as Dispatched in 3 to 5
days is ordered from the publisher, and the whole order waits for it unless you choose Send what is
ready at checkout. That option costs one extra delivery fee for the second parcel.

Books that come from different warehouses are sent separately, so one order can arrive in two or
three parcels on different days. Each parcel has its own tracking link, and you pay delivery only
once.

## Tracking

When the parcel leaves our warehouse we email you a tracking link from the carrier. The link may
show nothing for the first twelve hours, until the carrier scans the parcel at its depot. After
that it updates at each step of the journey.

## Parcels that are late or lost

A standard parcel whose tracking has not changed for 10 working days is treated as lost. For
express, the limit is 5 working days. When a parcel is treated as lost we send a replacement at no
cost or refund the order, whichever you prefer, and we deal with the carrier ourselves.

A parcel the carrier marks as delivered that you have not received is different: check with
neighbours and around the building first, because carriers often leave parcels in a safe place. If
it has not turned up after 48 hours, tell us and we open a claim with the carrier and send a
replacement or a refund.

## Addresses

You can change the delivery address while the order still says Received. Once it says Packed, the
parcel has left the shelf and the address can no longer be changed; the carrier's own website may
let you redirect it once it is on its way.

Express delivery is not available to post office boxes, because the carrier cannot deliver to them
on the next day. Standard parcels can be sent to a post office box.

## Pickup points

Choose a pickup point at checkout and the parcel waits there for ten days. You need the collection
code from the email and a photo ID. After ten days the parcel comes back to us and we refund the
order minus the delivery cost.

## International delivery

We ship to 31 countries; the list is on the checkout page. International parcels take seven to
fifteen working days, and the person receiving the parcel may have to pay import duties or taxes on
arrival, which we do not collect at checkout. A parcel refused because of duties comes back to us
and is refunded minus the delivery cost.

International parcels are treated as lost after 25 working days without a tracking update.

## Damage in transit

If a parcel arrives visibly damaged, you may refuse it at the door; it comes back to us and we
send a new one. If you accept it and the books inside are damaged, the returns and refunds policy
explains what to do.
EOF
cat > data/docs/support-handbook.md <<'EOF'
---
id: support-handbook
title: Customer support handbook
audience: staff
owner: customer-support
updated: 2026-04-02
version: 12
status: current
---

# Customer support handbook

For everybody who answers customers at Marginalia, in email and in chat. It says what you may decide
on your own, what you hand on, and how we write.

## Answering times

We answer an email within four working hours and a chat within two minutes, between 8 am and 8 pm
on working days. A chat that arrives outside those hours becomes an email. The clock starts when the
message arrives, not when it is assigned.

## Checking who you are talking to

Before changing anything on an account or an order, confirm two things: the order number, which
starts with MG- followed by eight digits, and the email address the order was placed with. A name
alone is never enough.

Never ask a customer for a password, a full card number, the code on the back of a card or a gift
card code. Nobody at Marginalia needs any of those to help. If a customer sends one anyway, delete
the message from the ticket and tell them you have done so.

## What you can decide on your own

| decision | support agent | team lead |
| --- | --- | --- |
| refund an order or part of one | up to 50 | up to 200 |
| goodwill credit, per contact | up to 10 | up to 30 |
| replace a damaged or lost book | any value | any value |
| extend a return window | up to 15 extra days | up to 60 extra days |

Above those amounts, open a finance review from the ticket. Finance answers within one working day.
Do not promise the customer an outcome while the review is open; tell them when to expect an answer.

A replacement for a book that arrived damaged needs the customer's photographs, and nothing else:
you do not need a lead's approval and the customer does not send the book back.

## Escalation

Tier 1 is everybody on support. Hand a ticket to tier 2, the team leads, when:

- the customer asks for a refund or credit above your limit;
- the customer has written three times about the same problem;
- the customer mentions a lawyer, a consumer protection body or the press;
- the case involves a marketplace seller who has not answered in two working days.

Hand a ticket to the privacy team, not to tier 2, when the customer asks to see, correct or delete
their data, or asks what we know about them. Privacy requests have a legal deadline of 15 days and
are logged separately.

## Suspected fraud

If an order looks wrong to you, for example a new account ordering many copies of one expensive
title to an address that is not the billing address, do not accuse the customer and do not cancel
the order yourself. Open a finance review with the reason fraud and continue to answer the customer
normally. Finance decides, and finance tells you what to say.

## How we write

Write the answer first and the explanation after it. A customer asking whether they can return a
book wants yes or no in the first line.

Use the customer's name once, at the start. Do not apologise more than once in a message. Say what
will happen next and when, with a date if you have one.

Quote the policy in your own words and link the help centre article. Do not paste paragraphs of the
terms of sale into a reply; if a customer asks for the legal text, send the link to the clause.

Never guess. If you do not know, say that you will find out and when you will write again, and then
write again.

## Macros

Macros are saved replies for the twenty most common questions. Use them as a start and edit them for
the customer in front of you. A macro sent without reading the question is the most common cause of
a third message from the same customer.

## Handing over at the end of a shift

Before you sign off, every open chat is either closed or turned into an email with a note saying
what the customer asked, what you did and what is still open. The next person must be able to
continue without asking the customer to repeat anything.
EOF
cat > data/docs/terms-of-sale.md <<'EOF'
---
id: terms-of-sale
title: Terms of sale
audience: public
owner: legal
updated: 2026-01-05
version: 9
status: current
---

# Terms of sale

These terms apply to every purchase made on marginalia.example by a consumer. Version 9, in force
from 5 January 2026.

## 1. Who we are

Marginalia is an online bookshop operated at marginalia.example. You can reach us through the
contact form in your account or at help@marginalia.example.

## 2. Placing an order

2.1 An order is an offer to buy the books in it at the prices shown at checkout.

2.2 The contract is formed when we send the email confirming that your order has been dispatched.
The email confirming that we received the order is not an acceptance.

2.3 We may refuse an order, before dispatch, when a book is out of stock, when the price shown was
an obvious error, or when the payment is not confirmed. If we refuse an order we refund any amount
already taken within three working days.

## 3. Prices

3.1 Prices include tax. Delivery costs are shown separately before you pay.

3.2 The price that applies is the one shown on the checkout page when you pay.

## 4. Payment

4.1 Payment is taken when you place the order, except for pre-orders, which are charged on the day
the book is released.

4.2 Instalments are offered by your card issuer under its own terms.

## 5. Delivery

5.1 Delivery times are estimates. If an order has not arrived 30 days after the latest estimated
date, you may cancel it and receive a full refund, including delivery costs.

5.2 The risk of loss passes to you when the parcel is delivered to the address you gave or collected
from a pickup point.

## 6. The right of withdrawal

6.1 You may withdraw from a purchase within seven days of delivery without giving a reason, as the
consumer protection law guarantees.

6.2 Our returns and refunds policy extends this period to 30 days for printed books. The longer
period is a commercial undertaking and does not limit the statutory right in 6.1.

6.3 The right of withdrawal does not apply to digital content once its download has begun with your
express consent, nor to personalised goods.

## 7. Faulty goods

7.1 Goods that are faulty, damaged or not as described may be returned for repair, replacement or a
refund within 90 days of delivery for an apparent fault, as the law provides, whatever our returns
policy says about the condition of returned items.

7.2 A hidden fault may be reported within 90 days of the day it becomes apparent.

## 8. Digital content

8.1 E-books and audiobooks are licensed to the account that bought them for personal use. They are
not sold, and the licence cannot be transferred.

8.2 Refunds for digital content follow the e-books and audiobooks section of the returns and refunds
policy.

## 9. Liability

9.1 We are responsible for the books we deliver being as described and fit for their purpose.

9.2 We are not responsible for delays caused by events outside our control, such as strikes at the
carrier or extreme weather, but you keep the right to cancel under 5.1.

## 10. Personal data

10.1 How we use your personal data is described in the privacy notice.

## 11. Changes to these terms

11.1 We may change these terms. The terms that apply to an order are the ones in force on the day
the order was placed.

## 12. Complaints and disputes

12.1 Write to help@marginalia.example first. We answer complaints within five working days.

12.2 These terms are governed by Brazilian law, and a dispute may be brought in the courts of the
place where you live.
EOF
cat > data/docs/warehouse-runbook.md <<'EOF'
---
id: warehouse-runbook
title: Warehouse on-call runbook
audience: staff
owner: operations
updated: 2026-02-20
version: 8
status: current
---

# Warehouse on-call runbook

For whoever is on call for the warehouse and for dispatch. It says how to rate an incident, who to
call and what to do for the incidents we have had before.

## Severity

| severity | meaning | first response |
| --- | --- | --- |
| SEV-1 | no orders can be dispatched | within 15 minutes, any time |
| SEV-2 | dispatch is slowed or one carrier is down | within 1 hour in working hours |
| SEV-3 | a problem with a workaround | next working day |

When in doubt, rate it higher. Downgrading an incident costs nothing; discovering at 6 pm that a
SEV-3 was a SEV-1 costs a day of orders.

## Who to call

Post every incident in the operations channel first. For SEV-1, also phone the operations manager
on call; the number is on the rota pinned in the channel. The carrier account managers' numbers are
on the same rota.

## A carrier is down

1. Check the carrier's status page and confirm with their account manager.
2. Switch new standard orders to the second carrier in the dispatch settings. Express orders cannot
   be switched, because only the first carrier delivers next day.
3. Ask support to add the banner Delays with deliveries to the help centre.
4. When the carrier is back, switch the setting back and remove the banner.

## The label printer has stopped

Restart the print server from the dispatch console before touching the printer. If labels still do
not print after ten minutes, print them from the backup laptop at packing station 3, which has its
own printer. Rate it SEV-2 if it lasts more than an hour.

## Stock does not match

When a picker finds fewer copies than the system shows, mark the shelf location for a count and
pick the order from the overflow area if the title is there. If not, the order goes to Awaiting
stock and support is told automatically. Never edit the stock level by hand during a shift; the
count at the end of the day corrects it.

## After an incident

Every SEV-1 and SEV-2 gets a short review within five working days: what happened, when it was
noticed, what was done and what will change. The review blames no person.
EOF
```

```
ana@vm:~/rag$ sh docs.sh
ana@vm:~/rag$ ls data/docs
affiliate-api.md
ebooks-and-audiobooks.md
finance-refund-controls.md
gift-cards.md
payments-and-invoices.md
privacy-notice.md
returns-policy-2025.md
returns-policy.md
seller-agreement.md
shipping-and-delivery.md
support-handbook.md
terms-of-sale.md
warehouse-runbook.md
ana@vm:~/rag$ wc -w data/docs/*.md | tail -1
 6843 total
ana@vm:~/rag$ grep -c "14 days" data/docs/*.md | grep -v ":0"
data/docs/ebooks-and-audiobooks.md:2
data/docs/returns-policy-2025.md:2
data/docs/returns-policy.md:5
data/docs/seller-agreement.md:2
```

Eles foram escritos para o curso com três propriedades contra as quais um sistema de busca precisa
ser testado. **São longos o bastante para serem cortados**: só a política de devolução já é mais longa
do que o modelo de embeddings consegue ler de uma vez, e a aula 4 mede isso. **São ambíguos onde
documentos de verdade são**: há duas políticas de devolução, a que vale e a que ela substituiu, e
"14 days" aparece onze vezes em quatro documentos, para e-books, audiolivros, pacotes danificados,
títulos errados, vendedores do marketplace e o antigo prazo de devolução. **São estruturados**, com
títulos e cláusulas numeradas, então uma citação pode apontar para algo menor que um documento
inteiro. Três deles são só para a equipe, e um só para o financeiro; a aula 14 trata de mantê-los
assim.

Os documentos estão em inglês, como todo o código do curso, e as perguntas que as aulas fazem a eles
também.

```
ana@vm:~/rag$ head -12 data/docs/returns-policy.md
---
id: returns-policy
title: Returns and refunds policy
audience: public
owner: customer-support
updated: 2026-02-02
version: 4
status: current
supersedes: returns-policy-2025
---

# Returns and refunds policy
```

O bloco entre as linhas `---` é o **front matter** do documento: quem pode ler, quem é o dono, quando
mudou e se ainda vale. A aula 5 guarda cada campo dele ao lado de cada trecho, e as aulas 7 e 14
dependem disso.

## As perguntas

O segundo script escreve as perguntas com que o curso se mede. Salve como `~/rag/questions.sh` e
rode:

```sh
#!/bin/sh
# questions.sh: writes the questions the course measures retrieval with
set -e
mkdir -p data
cat > data/eval.jsonl <<'EOF'
{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": [["returns-policy", "The return window"]], "facts": ["30 days from delivery"]}
{"id": "e02", "question": "Who pays for the return postage?", "gold": [["returns-policy", "How to start a return"]], "facts": ["Returns are free"]}
{"id": "e03", "question": "How long after my return arrives will I get the refund?", "gold": [["returns-policy", "Refunds"]], "facts": ["within three working days"]}
{"id": "e04", "question": "Can I return a signed copy?", "gold": [["returns-policy", "Items that cannot be returned"]], "facts": ["signed by the author"]}
{"id": "e05", "question": "My e-book was downloaded yesterday, can I still get my money back?", "gold": [["returns-policy", "E-books and audiobooks"], ["ebooks-and-audiobooks", "Refunds for e-books"]], "facts": ["Once it has been downloaded"]}
{"id": "e06", "question": "How much is express delivery?", "gold": [["shipping-and-delivery", "Delivery options and costs"]], "facts": ["9.90"]}
{"id": "e07", "question": "Above what order value is standard delivery free?", "gold": [["shipping-and-delivery", "Delivery options and costs"]], "facts": ["free on orders over 40"]}
{"id": "e08", "question": "When is a standard parcel considered lost?", "gold": [["shipping-and-delivery", "Parcels that are late or lost"]], "facts": ["10 working days"]}
{"id": "e09", "question": "Can express orders go to a post office box?", "gold": [["shipping-and-delivery", "Addresses"]], "facts": ["not available to post office boxes"]}
{"id": "e10", "question": "How long does a pickup point keep my parcel?", "gold": [["shipping-and-delivery", "Pickup points"]], "facts": ["waits there for ten days"]}
{"id": "e11", "question": "On how many devices can I read my e-books?", "gold": [["ebooks-and-audiobooks", "Where e-books can be read"]], "facts": ["up to six devices"]}
{"id": "e12", "question": "Will my e-books open on a Kindle?", "gold": [["ebooks-and-audiobooks", "Where e-books can be read"]], "facts": ["Kindle readers cannot open"]}
{"id": "e13", "question": "When can an audiobook be refunded?", "gold": [["ebooks-and-audiobooks", "Audiobooks"], ["returns-policy", "E-books and audiobooks"]], "facts": ["less than 10%"]}
{"id": "e14", "question": "Can I pay in instalments?", "gold": [["payments-and-invoices", "Payment methods"]], "facts": ["up to three instalments"]}
{"id": "e15", "question": "How long is a gift card valid?", "gold": [["gift-cards", "Validity"], ["payments-and-invoices", "Gift cards"]], "facts": ["valid for two years"]}
{"id": "e16", "question": "Can I get an invoice in my company's name after the order has shipped?", "gold": [["payments-and-invoices", "Receipts and invoices"]], "facts": ["before you order"]}
{"id": "e17", "question": "When is the contract of sale formed?", "gold": [["terms-of-sale", "2. Placing an order"]], "facts": ["has been dispatched"]}
{"id": "e18", "question": "How long is the statutory right of withdrawal?", "gold": [["terms-of-sale", "6. The right of withdrawal"], ["returns-policy", "The return window"]], "facts": ["seven days from delivery", "seven days of delivery"]}
{"id": "e19", "question": "What commission does Marginalia take from a marketplace seller?", "gold": [["seller-agreement", "2. Fees"]], "facts": ["12% of the item price"]}
{"id": "e20", "question": "How often are sellers paid?", "gold": [["seller-agreement", "4. Payouts"]], "facts": ["every 14 days"]}
{"id": "e21", "question": "What does error E-4102 mean in the affiliate API?", "gold": [["affiliate-api", "Errors"], ["affiliate-api", "Rate limits"]], "facts": ["120 requests"]}
{"id": "e22", "question": "What commission do affiliates earn on e-books?", "gold": [["affiliate-api", "Commission"]], "facts": ["3% of the price of e-books"]}
{"id": "e23", "question": "How long do you keep my order history?", "gold": [["privacy-notice", "How long we keep it"]], "facts": ["five years"]}
{"id": "e24", "question": "Do you store my IP address?", "gold": [["privacy-notice", "What we collect"]], "facts": ["do not store your IP address"]}
{"id": "e25", "question": "What is the most a support agent can refund without approval?", "gold": [["support-handbook", "What you can decide on your own"]], "facts": ["up to 50"]}
{"id": "e26", "question": "What must I check before changing a customer's order?", "gold": [["support-handbook", "Checking who you are talking to"]], "facts": ["the order number, which starts with MG-"]}
{"id": "e27", "question": "Do you have a shop in Porto Alegre where I can pick up books?", "gold": [], "facts": []}
{"id": "e28", "question": "Can I place an order by phone?", "gold": [], "facts": []}
{"id": "e29", "question": "Which carrier do you use in Portugal?", "gold": [], "facts": []}
{"id": "e30", "question": "Is there a student discount?", "gold": [], "facts": []}
EOF
cat > data/identifiers.jsonl <<'EOF'
{"id": "i01", "question": "What does error E-4104 mean?", "facts": ["the month is out of range"]}
{"id": "i02", "question": "What does error E-4105 mean?", "facts": ["longer than 40 characters"]}
{"id": "i03", "question": "What does error E-4101 mean?", "facts": ["missing, revoked or belongs to another site"]}
{"id": "i04", "question": "What is a SEV-2 incident?", "facts": ["one carrier is down"]}
{"id": "i05", "question": "What does the endpoint GET /reports/commissions return?", "facts": ["commissions earned in one calendar month"]}
{"id": "i06", "question": "What is clause 6.1 of the terms of sale?", "facts": ["You may withdraw from a purchase within seven days"]}
EOF
```

```
ana@vm:~/rag$ sh questions.sh
ana@vm:~/rag$ wc -l data/*.jsonl
  30 data/eval.jsonl
   6 data/identifiers.jsonl
  36 total
ana@vm:~/rag$ head -1 data/eval.jsonl
{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": [["returns-policy", "The return window"]], "facts": ["30 days from delivery"]}
```

O `eval.jsonl` tem trinta perguntas que um cliente poderia fazer, cada uma com os trechos que a
respondem e as palavras que uma resposta certa contém; quatro delas não têm resposta nos documentos,
de propósito. A aula 3 usa as perguntas pela primeira vez e a aula 8 explica como um conjunto assim é
montado. O `identifiers.jsonl` tem mais seis, cuja resposta depende de um código ou número exato,
para a aula 6.

As outras aulas que precisam de dados próprios entregam os dados do mesmo jeito, quando precisam: a
aula 2 a central de ajuda, as aulas 13 e 15 as conversas de dois clientes, a aula 16 uma página de
anúncios do marketplace e a aula 17 uma semana de perguntas.
