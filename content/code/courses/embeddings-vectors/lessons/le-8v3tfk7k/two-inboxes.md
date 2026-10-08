---
title: Two inboxes
version: 1
---

This lesson looks for messages that do not belong, so it needs two inboxes on top of the
tickets from lesson 1. Paste each block into the terminal, in `~/emb`.

## One ordinary day

`inbox.jsonl` holds the 40 messages of one day. `odd` marks the 8 that do not belong, and `kind`
says why: spam, a job application, questions about nothing the shop does, a line of keyboard
noise, and two messages in other languages. **That is the answer key.** The scores in this lesson are
computed from the text alone, and the key only counts afterwards what they caught.

```bash
cat > ~/emb/data/inbox.jsonl <<'EOF'
{"id": "m01", "odd": false, "text": "My parcel has been stuck at the depot since Monday."}
{"id": "m02", "odd": false, "text": "I want to return a cookbook, the recipes are not what I hoped."}
{"id": "m03", "odd": false, "text": "Card declined three times, but there is money in the account."}
{"id": "m04", "odd": false, "text": "How do I reset my password? The link has expired again."}
{"id": "m05", "odd": false, "text": "The e-book opens but the images are missing."}
{"id": "m06", "odd": false, "text": "Can you deliver on a Saturday?"}
{"id": "m07", "odd": false, "text": "I received a damaged hardback, the cover is scratched all over."}
{"id": "m08", "odd": false, "text": "Where is my refund for the book I sent back on the 3rd?"}
{"id": "m09", "odd": false, "text": "I need an invoice in my company's name for last month's order."}
{"id": "m10", "odd": false, "text": "Please remove my address from your marketing emails."}
{"id": "m11", "odd": false, "text": "The audiobook won't download on my phone."}
{"id": "m12", "odd": false, "text": "The tracking says out for delivery since yesterday."}
{"id": "m13", "odd": false, "text": "Can I return a book if I've written my name in it?"}
{"id": "m14", "odd": false, "text": "Do you accept Pix for orders under 20?"}
{"id": "m15", "odd": false, "text": "I can't sign in after changing my email address."}
{"id": "m16", "odd": false, "text": "How do I read an e-book on my laptop?"}
{"id": "m17", "odd": false, "text": "The courier left my books in the rain."}
{"id": "m18", "odd": false, "text": "I was sent the second volume instead of the first."}
{"id": "m19", "odd": false, "text": "My gift card was only partly used, where is the rest?"}
{"id": "m20", "odd": false, "text": "Two-factor codes from my app are always rejected."}
{"id": "m21", "odd": false, "text": "The font in the reading app is impossible to change."}
{"id": "m22", "odd": false, "text": "How long does shipping to Argentina take?"}
{"id": "m23", "odd": false, "text": "I'd like to exchange a hardback for the paperback."}
{"id": "m24", "odd": false, "text": "Why does the checkout total include a fee I didn't choose?"}
{"id": "m25", "odd": false, "text": "Please download all my data and send it to me."}
{"id": "m26", "odd": false, "text": "Can I share an audiobook with my partner?"}
{"id": "m27", "odd": false, "text": "My order hasn't shipped and it's been a week."}
{"id": "m28", "odd": false, "text": "The returns label printed blank."}
{"id": "m29", "odd": false, "text": "I've been charged for a pre-order that was cancelled."}
{"id": "m30", "odd": false, "text": "My account shows somebody else's orders."}
{"id": "m31", "odd": false, "text": "The e-book is in French but I bought the English one."}
{"id": "m32", "odd": false, "text": "Can I have the parcel sent to my office instead?"}
{"id": "m33", "odd": true, "kind": "spam", "text": "Congratulations!!! You have been selected to receive a free iPhone, click here to claim your prize now"}
{"id": "m34", "odd": true, "kind": "another language", "text": "Meu pedido ainda não chegou e já faz duas semanas, alguém pode me ajudar?"}
{"id": "m35", "odd": true, "kind": "off-topic", "text": "What is the boiling point of water at the top of Mount Everest?"}
{"id": "m36", "odd": true, "kind": "noise", "text": "asdf qwer zxcv 12345 lkjh"}
{"id": "m37", "odd": true, "kind": "job application", "text": "Dear hiring manager, please find attached my CV for the warehouse assistant position."}
{"id": "m38", "odd": true, "kind": "off-topic", "text": "Can you recommend a good recipe for vegetable lasagne?"}
{"id": "m39", "odd": true, "kind": "spam", "text": "Increase your website traffic by 500% with our proven SEO packages, reply for prices"}
{"id": "m40", "odd": true, "kind": "another language", "text": "Je n'arrive pas à me connecter à mon compte depuis ce matin."}
EOF
```

## The week something changed

`week2.jsonl` holds 20 messages from the week Marginalia launched a subscription, Marginalia
Unlimited. Nothing in the help centre or in the tickets mentions it yet.

```bash
cat > ~/emb/data/week2.jsonl <<'EOF'
{"id": "w01", "text": "How do I cancel my Marginalia Unlimited subscription?"}
{"id": "w02", "text": "I was charged for Unlimited after the free trial, I thought it would remind me first."}
{"id": "w03", "text": "Which books are included in the Unlimited subscription?"}
{"id": "w04", "text": "My parcel hasn't arrived yet, it's been five days."}
{"id": "w05", "text": "Can I share my Unlimited plan with my family?"}
{"id": "w06", "text": "The Unlimited catalogue doesn't show up in the app."}
{"id": "w07", "text": "Does the monthly subscription include audiobooks?"}
{"id": "w08", "text": "I'd like to return a book that arrived damaged."}
{"id": "w09", "text": "Will I keep the books I borrowed with Unlimited if I stop paying?"}
{"id": "w10", "text": "How much is the annual subscription compared to monthly?"}
{"id": "w11", "text": "I can't reset my password."}
{"id": "w12", "text": "The subscription renewed even though I turned off auto-renew."}
{"id": "w13", "text": "Can I pause my subscription while I'm travelling?"}
{"id": "w14", "text": "My card was declined when renewing the Unlimited plan."}
{"id": "w15", "text": "Why did a book disappear from my Unlimited library?"}
{"id": "w16", "text": "Is there a student discount on the subscription?"}
{"id": "w17", "text": "The e-book won't download to my tablet."}
{"id": "w18", "text": "How many books can I borrow at once on Unlimited?"}
{"id": "w19", "text": "Upgrade from monthly to yearly, how?"}
{"id": "w20", "text": "Where is my tracking number?"}
EOF
```

## Checking the files

```
ana@lab:~/emb$ wc -l data/inbox.jsonl data/week2.jsonl
  40 data/inbox.jsonl
  20 data/week2.jsonl
  60 total
```

40 and 20 lines. A different number means a block went in short or twice; lesson 1's
*The help centre* says how to put it right.
