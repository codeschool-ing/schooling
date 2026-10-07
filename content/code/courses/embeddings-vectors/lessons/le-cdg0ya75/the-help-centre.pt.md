---
title: A central de ajuda
version: 1
---

O curso trabalha sobre os arquivos da **Marginalia**, uma livraria online que não existe. A sua
central de ajuda, as perguntas que os clientes digitam e as mensagens que eles mandam foram
escritas para o curso, em inglês, com algumas em português. As aulas as buscam, as classificam e
medem o quanto um modelo as entende. São arquivos JSON Lines: um objeto JSON por linha, que o Python
lê uma linha de cada vez com `json.loads`.

Cada bloco abaixo escreve um arquivo. Copie-o inteiro, cole no terminal e aperte Enter: a linha do
`cat` começa o arquivo, e o `EOF` do fim o fecha.

## Os 40 artigos

`help.jsonl` é a central de ajuda: 40 artigos, cada um com um `id`, uma `category`, um idioma, a
data da última atualização, um `title` e um `body`. A maioria das aulas faz buscas nele.

```bash
cat > ~/emb/data/help.jsonl <<'EOF'
{"id": "h01", "category": "orders", "lang": "en", "updated": "2026-03-02", "title": "Changing an order after you have placed it", "body": "You can change the delivery address or remove an item while the order still says Received. Once it says Packed, the parcel has left the shelf and the order can no longer be edited. Cancel it instead and place a new one."}
{"id": "h02", "category": "orders", "lang": "en", "updated": "2026-01-15", "title": "Cancelling an order", "body": "Open the order in your account and choose Cancel order. If the order has already shipped, the button is gone and you will need to send the parcel back when it arrives. A cancelled order is refunded to the card it was paid with."}
{"id": "h03", "category": "orders", "lang": "en", "updated": "2025-11-20", "title": "Ordering a book that is not yet published", "body": "Pre-orders are charged on the day the book is released, not on the day you order it. The publisher sets the release date and sometimes moves it; we email you if it changes. You can cancel a pre-order at any time before it is charged."}
{"id": "h04", "category": "orders", "lang": "en", "updated": "2026-02-10", "title": "Buying books as a gift", "body": "Tick This is a gift at checkout to hide the prices on the packing slip and add a message of up to 300 characters. Gift wrapping costs 2.50 per book. The person receiving it can exchange the book without telling you."}
{"id": "h05", "category": "orders", "lang": "en", "updated": "2026-04-01", "title": "Orders for schools and libraries", "body": "Institutions buying twenty or more copies of one title receive 15% off the cover price and can pay by invoice within 30 days. Send the list of titles and quantities from an institutional email address to schools@marginalia.example."}
{"id": "h06", "category": "orders", "lang": "en", "updated": "2025-09-08", "title": "Where to find your order number", "body": "The order number starts with MG- followed by eight digits, for example MG-20481937. It is in the subject line of the confirmation email and at the top of every order in your account. Quote it whenever you write to us about an order."}
{"id": "h07", "category": "shipping", "lang": "en", "updated": "2026-03-18", "title": "Delivery times and costs", "body": "Standard delivery takes three to five working days and is free on orders over 40. Below that it costs 4.90. Express delivery arrives the next working day if you order before 2 pm and costs 9.90."}
{"id": "h08", "category": "shipping", "lang": "en", "updated": "2026-02-27", "title": "Tracking a parcel", "body": "When the parcel leaves our warehouse we email you a tracking link from the carrier. The link may show nothing for the first twelve hours, until the carrier scans the parcel at its depot. After that it updates at each step of the journey."}
{"id": "h09", "category": "shipping", "lang": "en", "updated": "2026-01-30", "title": "A parcel marked as delivered that never arrived", "body": "Check with neighbours and around the building first, because carriers often leave parcels in a safe place. If it has not turned up after 48 hours, tell us and we will open a claim with the carrier and send a replacement or a refund, whichever you prefer."}
{"id": "h10", "category": "shipping", "lang": "en", "updated": "2025-12-12", "title": "Shipping outside the country", "body": "We ship to 31 countries. International parcels take seven to fifteen working days, and the recipient may have to pay import duties or taxes on arrival, which we do not collect at checkout. The full list of countries is on the checkout page."}
{"id": "h11", "category": "shipping", "lang": "en", "updated": "2026-03-05", "title": "Collecting your order from a pickup point", "body": "Choose a pickup point at checkout and the parcel waits there for ten days. You will need the collection code from the email and a photo ID. After ten days the parcel comes back to us and we refund the order minus the delivery cost."}
{"id": "h12", "category": "shipping", "lang": "en", "updated": "2026-04-14", "title": "Damaged books on arrival", "body": "If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days. We replace damaged books at no cost and you do not need to send the damaged copy back."}
{"id": "h13", "category": "shipping", "lang": "en", "updated": "2025-10-03", "title": "One order arriving in several parcels", "body": "Books that come from different warehouses are sent separately, so one order can arrive in two or three parcels on different days. Each parcel has its own tracking link. You pay delivery only once."}
{"id": "h14", "category": "returns", "lang": "en", "updated": "2026-02-02", "title": "How to return a book", "body": "You have 30 days from delivery to return a printed book in the condition you received it. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office. Returns are free."}
{"id": "h15", "category": "returns", "lang": "en", "updated": "2026-02-02", "title": "When your refund arrives", "body": "We refund within three working days of the return reaching our warehouse. The money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. Gift cards are refunded as store credit."}
{"id": "h16", "category": "returns", "lang": "en", "updated": "2025-11-11", "title": "Exchanging a book for a different edition", "body": "To swap a paperback for the hardback, or one translation for another, return the first book and order the one you want. We do not hold exchanges, so the new order is charged when you place it and the refund for the old one follows the usual timing."}
{"id": "h17", "category": "returns", "lang": "en", "updated": "2026-03-21", "title": "Items that cannot be returned", "body": "Personalised and signed copies, opened jigsaw puzzles and anything bought in the clearance section cannot be returned unless they arrive damaged. E-books follow their own rules, described in the e-books section."}
{"id": "h18", "category": "returns", "lang": "en", "updated": "2026-01-08", "title": "Returning a gift", "body": "The person who received the gift can return it with the gift receipt and gets store credit for the price paid, without the buyer being told. To get the money back on the original card instead, the buyer has to start the return."}
{"id": "h19", "category": "returns", "lang": "en", "updated": "2025-12-20", "title": "Wrong book in the parcel", "body": "If we sent a different title from the one you ordered, keep the parcel closed if you can and tell us within 14 days. We send the right book at once and a prepaid label for the wrong one. You are not charged twice."}
{"id": "h20", "category": "payments", "lang": "en", "updated": "2026-03-30", "title": "Payment methods we accept", "body": "We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery."}
{"id": "h21", "category": "payments", "lang": "en", "updated": "2026-02-18", "title": "A payment that was declined", "body": "A declined card is almost always a decision by the bank, which does not tell us the reason. Check that the billing address matches the one your bank has, then try again or use another method. Your basket is kept for 24 hours."}
{"id": "h22", "category": "payments", "lang": "en", "updated": "2026-01-25", "title": "Charged twice for one order", "body": "When a payment fails and you try again, the bank sometimes holds both amounts for a few days. Only one is collected and the other disappears without action from you within seven days. If both are still there after that, send us the order number and a bank statement."}
{"id": "h23", "category": "payments", "lang": "en", "updated": "2026-04-05", "title": "Invoices and receipts", "body": "A receipt is attached to the shipping confirmation email. For an invoice with a company name and tax number, add them under Billing details before you order; we cannot reissue an invoice to a different company after the order has shipped."}
{"id": "h24", "category": "payments", "lang": "en", "updated": "2025-10-27", "title": "Using a gift card", "body": "Enter the sixteen-digit code at checkout. A gift card can pay for part of an order and the rest can go on a card. Gift cards are valid for two years from purchase and cannot be exchanged for cash."}
{"id": "h25", "category": "payments", "lang": "en", "updated": "2026-03-12", "title": "Prices and price changes", "body": "Prices are shown with tax included. A price can change after you put a book in your basket but before you pay; the price you pay is the one on the checkout page. We do not refund the difference if a price drops after your order."}
{"id": "h26", "category": "account", "lang": "en", "updated": "2026-02-24", "title": "Resetting your password", "body": "Choose Forgot password on the sign-in page and we email you a link that works for one hour. If the email does not arrive, check the spam folder and make sure you are using the address the account was opened with."}
{"id": "h27", "category": "account", "lang": "en", "updated": "2026-03-09", "title": "Changing the email address on your account", "body": "Go to Account settings and enter the new address. We send a confirmation link to the new address and a notice to the old one, and the change takes effect only when the link is clicked. Your orders and e-books stay with the account."}
{"id": "h28", "category": "account", "lang": "en", "updated": "2026-01-19", "title": "Closing your account", "body": "You can close your account from Account settings. Closing it deletes your reading lists and reviews, and you lose access to e-books in your library, so download them first. Order records are kept for five years because tax law requires it."}
{"id": "h29", "category": "account", "lang": "en", "updated": "2025-12-01", "title": "Two-step sign-in", "body": "Turn on two-step sign-in under Security to be asked for a code from an authenticator app each time you sign in on a new device. Save the recovery codes we show you; without them, losing your phone means proving who you are to support."}
{"id": "h30", "category": "account", "lang": "en", "updated": "2026-04-09", "title": "Newsletters and notifications", "body": "Choose which emails you receive under Notifications. Order and shipping emails cannot be turned off because they are part of the service. Unsubscribing from the newsletter takes effect within 48 hours."}
{"id": "h31", "category": "account", "lang": "en", "updated": "2026-02-14", "title": "Seeing what we know about you", "body": "Under Privacy you can download a copy of everything we hold about you: account details, orders, reviews and reading lists. The file is ready within 24 hours and the download link works for seven days."}
{"id": "h32", "category": "ebooks", "lang": "en", "updated": "2026-03-27", "title": "Reading e-books on your devices", "body": "E-books open in the Marginalia app for phones and tablets and in any reader that supports EPUB with Adobe DRM. You can use the same account on up to six devices. Kindle readers cannot open our e-books."}
{"id": "h33", "category": "ebooks", "lang": "en", "updated": "2026-02-06", "title": "Refunds for e-books", "body": "An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. Once it has been downloaded, the sale is final, as the law allows for digital content delivered with your consent."}
{"id": "h34", "category": "ebooks", "lang": "en", "updated": "2026-01-12", "title": "An e-book that will not download", "body": "Downloads fail most often because the device is out of space or the app is out of date. Update the app, free some space and try again from your library. If the file still will not open, send us the title and the device model."}
{"id": "h35", "category": "ebooks", "lang": "en", "updated": "2025-11-29", "title": "Lending and sharing e-books", "body": "E-books are licensed to your account and cannot be lent, resold or shared with another account. Family members can read them on a device signed in to your account, within the six-device limit."}
{"id": "h36", "category": "ebooks", "lang": "en", "updated": "2026-04-11", "title": "Changing the font and layout of an e-book", "body": "In the app, tap the middle of the page and choose Aa to change the typeface, the size, the spacing and the background colour. Books with fixed layouts, such as comics and cookbooks, can only be zoomed."}
{"id": "h37", "category": "ebooks", "lang": "en", "updated": "2026-03-03", "title": "Audiobooks", "body": "Audiobooks are sold separately from e-books and play only in the Marginalia app, online or downloaded for offline listening. Playback speed goes from 0.5 to 3 times. Audiobooks can be refunded within 14 days if less than 10% has been played."}
{"id": "h38", "category": "returns", "lang": "pt", "updated": "2026-02-02", "title": "Como devolver um livro", "body": "Você tem 30 dias a partir da entrega para devolver um livro impresso no estado em que o recebeu. Comece a devolução pelo pedido na sua conta, imprima a etiqueta pré-paga e deixe o pacote em qualquer agência dos Correios. A devolução é gratuita."}
{"id": "h39", "category": "shipping", "lang": "pt", "updated": "2026-03-18", "title": "Prazos e custos de entrega", "body": "A entrega padrão leva de três a cinco dias úteis e é grátis em pedidos acima de 40. Abaixo disso custa 4,90. A entrega expressa chega no dia útil seguinte se você comprar antes das 14h e custa 9,90."}
{"id": "h40", "category": "account", "lang": "pt", "updated": "2026-02-24", "title": "Como redefinir sua senha", "body": "Escolha Esqueci a senha na página de entrada e enviaremos um link que funciona por uma hora. Se o e-mail não chegar, olhe a pasta de spam e confira se está usando o endereço com que a conta foi aberta."}
EOF
```

## As perguntas, e as respostas que elas deveriam encontrar

`queries.jsonl` guarda 24 perguntas que um cliente poderia digitar. Ao lado de cada uma está
`relevant`: o artigo ou os artigos que a respondem, decididos por uma pessoa, e não por um modelo. É
contra isso que a aula 3 dá nota a uma busca.

```bash
cat > ~/emb/data/queries.jsonl <<'EOF'
{"id": "q01", "text": "how do I get my money back", "relevant": ["h15", "h14"]}
{"id": "q02", "text": "the box never showed up", "relevant": ["h09"]}
{"id": "q03", "text": "can I pay in three parts", "relevant": ["h20"]}
{"id": "q04", "text": "my book came wet and torn", "relevant": ["h12"]}
{"id": "q05", "text": "I can't remember my login", "relevant": ["h26"]}
{"id": "q06", "text": "does it work on Kindle", "relevant": ["h32"]}
{"id": "q07", "text": "they took the payment two times", "relevant": ["h22"]}
{"id": "q08", "text": "send books to another country", "relevant": ["h10"]}
{"id": "q09", "text": "get rid of my profile for good", "relevant": ["h28"]}
{"id": "q10", "text": "I got the wrong title", "relevant": ["h19"]}
{"id": "q11", "text": "fix a mistake in the delivery address", "relevant": ["h01"]}
{"id": "q12", "text": "how fast is shipping", "relevant": ["h07"]}
{"id": "q13", "text": "give my e-book to a friend", "relevant": ["h35"]}
{"id": "q14", "text": "the download keeps failing", "relevant": ["h34"]}
{"id": "q15", "text": "make the letters bigger when reading", "relevant": ["h36"]}
{"id": "q16", "text": "the bank refused my card", "relevant": ["h21"]}
{"id": "q17", "text": "where is my parcel right now", "relevant": ["h08"]}
{"id": "q18", "text": "a receipt with my company details", "relevant": ["h23"]}
{"id": "q19", "text": "my order came in pieces", "relevant": ["h13"]}
{"id": "q20", "text": "stop the marketing emails", "relevant": ["h30"]}
{"id": "q21", "text": "discount for a classroom set", "relevant": ["h05"]}
{"id": "q22", "text": "listening to books in the car", "relevant": ["h37"]}
{"id": "q23", "text": "I bought an e-book by mistake", "relevant": ["h33"]}
{"id": "q24", "text": "change the email I log in with", "relevant": ["h27"]}
EOF
```

## 150 mensagens com rótulo

`tickets.jsonl` guarda 150 mensagens que clientes mandaram, cada uma com um de cinco rótulos.
`split` diz quais 100 um programa pode usar para aprender e em quais 50 ele é testado; a aula 4
explica por que as duas coisas nunca podem se misturar.

```bash
cat > ~/emb/data/tickets.jsonl <<'EOF'
{"id": "t001", "label": "shipping", "split": "train", "text": "My order was supposed to arrive on Tuesday and it's now Friday. Where is it?"}
{"id": "t002", "label": "shipping", "split": "train", "text": "The tracking page has said 'label created' for four days."}
{"id": "t003", "label": "shipping", "split": "train", "text": "Do you deliver to Portugal and how long does it take?"}
{"id": "t004", "label": "shipping", "split": "train", "text": "The courier says he left the box with a neighbour but nobody here has it."}
{"id": "t005", "label": "shipping", "split": "train", "text": "How much is next-day delivery?"}
{"id": "t006", "label": "shipping", "split": "train", "text": "I only got two of the three books I ordered. Is the third one coming separately?"}
{"id": "t007", "label": "shipping", "split": "train", "text": "The book arrived with the cover ripped and the corners all crushed."}
{"id": "t008", "label": "shipping", "split": "train", "text": "Can I pick my parcel up somewhere instead of having it sent home? I'm never in."}
{"id": "t009", "label": "shipping", "split": "train", "text": "I had to pay customs fees when the package came. Nobody told me about that."}
{"id": "t010", "label": "shipping", "split": "train", "text": "Is free postage still over 40 or did that change?"}
{"id": "t011", "label": "shipping", "split": "train", "text": "Package shows delivered at 10:14 but my mailbox is empty."}
{"id": "t012", "label": "shipping", "split": "train", "text": "It rained and the parcel was left outside; the pages are all wavy now."}
{"id": "t013", "label": "shipping", "split": "train", "text": "Can you send it by express? I need it for a birthday on Saturday."}
{"id": "t014", "label": "shipping", "split": "train", "text": "The tracking number you gave me doesn't work on the carrier's site."}
{"id": "t015", "label": "shipping", "split": "train", "text": "Why is my order coming in two different boxes?"}
{"id": "t016", "label": "shipping", "split": "train", "text": "I'm moving next week. Will the books still reach me if they're late?"}
{"id": "t017", "label": "shipping", "split": "train", "text": "The pickup point closed before I could collect my parcel."}
{"id": "t018", "label": "shipping", "split": "train", "text": "Has my order even left the warehouse yet? It's been six days."}
{"id": "t019", "label": "shipping", "split": "train", "text": "What carrier do you use for deliveries to Chile?"}
{"id": "t020", "label": "shipping", "split": "train", "text": "Box arrived open and one book is missing."}
{"id": "t021", "label": "shipping", "split": "test", "text": "Still waiting for my books, ordered almost two weeks ago."}
{"id": "t022", "label": "shipping", "split": "test", "text": "The delivery man never rang the bell, he just left a card."}
{"id": "t023", "label": "shipping", "split": "test", "text": "How long do parcels take to get to Germany?"}
{"id": "t024", "label": "shipping", "split": "test", "text": "My copy came with a big dent in the spine from the box being squashed."}
{"id": "t025", "label": "shipping", "split": "test", "text": "The tracking hasn't moved since yesterday morning."}
{"id": "t026", "label": "shipping", "split": "test", "text": "Is there a cheaper postage option for a single paperback?"}
{"id": "t027", "label": "shipping", "split": "test", "text": "I was charged for delivery twice on one order that came in two boxes."}
{"id": "t028", "label": "shipping", "split": "test", "text": "The parcel locker code from your email isn't being accepted."}
{"id": "t029", "label": "shipping", "split": "test", "text": "It says delivered to reception but my office has no record of it."}
{"id": "t030", "label": "shipping", "split": "test", "text": "Could you hold the order until I'm back from holiday on the 20th?"}
{"id": "t031", "label": "returns", "split": "train", "text": "I'd like to send back a book I bought last week, it's not what I expected."}
{"id": "t032", "label": "returns", "split": "train", "text": "Where do I get the return label?"}
{"id": "t033", "label": "returns", "split": "train", "text": "I returned the parcel ten days ago and still haven't had my money back."}
{"id": "t034", "label": "returns", "split": "train", "text": "You sent me the Spanish edition instead of the English one."}
{"id": "t035", "label": "returns", "split": "train", "text": "Can I swap the paperback for the hardcover?"}
{"id": "t036", "label": "returns", "split": "train", "text": "My aunt gave me a book I already have. Can I return it without her finding out?"}
{"id": "t037", "label": "returns", "split": "train", "text": "Is it too late to return something I got 35 days ago?"}
{"id": "t038", "label": "returns", "split": "train", "text": "The signed copy I ordered has someone else's name in it."}
{"id": "t039", "label": "returns", "split": "train", "text": "Do I have to pay for the postage to send it back?"}
{"id": "t040", "label": "returns", "split": "train", "text": "I bought this in the clearance sale and changed my mind, can I return it?"}
{"id": "t041", "label": "returns", "split": "train", "text": "The return was received according to tracking but my account says pending."}
{"id": "t042", "label": "returns", "split": "train", "text": "I ordered one book and got a completely different title."}
{"id": "t043", "label": "returns", "split": "train", "text": "Can I get a refund to my card instead of store credit?"}
{"id": "t044", "label": "returns", "split": "train", "text": "I accidentally ordered two copies. How do I return one of them?"}
{"id": "t045", "label": "returns", "split": "train", "text": "I want to return the puzzle, I only opened it to check the pieces."}
{"id": "t046", "label": "returns", "split": "train", "text": "My refund came as a voucher but I paid by card."}
{"id": "t047", "label": "returns", "split": "train", "text": "Which post offices accept your prepaid returns?"}
{"id": "t048", "label": "returns", "split": "train", "text": "The book I received is a different translation from the one on the website."}
{"id": "t049", "label": "returns", "split": "train", "text": "How long after you receive my return will I get refunded?"}
{"id": "t050", "label": "returns", "split": "train", "text": "I lost the return label, can you send it again?"}
{"id": "t051", "label": "returns", "split": "test", "text": "This isn't the book I ordered, can you sort it out?"}
{"id": "t052", "label": "returns", "split": "test", "text": "I want my money back for a novel I didn't enjoy."}
{"id": "t053", "label": "returns", "split": "test", "text": "Can I exchange this for the large-print version?"}
{"id": "t054", "label": "returns", "split": "test", "text": "I sent the book back two weeks ago, where is my refund?"}
{"id": "t055", "label": "returns", "split": "test", "text": "The returns page won't let me select the item."}
{"id": "t056", "label": "returns", "split": "test", "text": "Got a duplicate in my order, I only wanted one."}
{"id": "t057", "label": "returns", "split": "test", "text": "Can a gift be returned by the person who received it?"}
{"id": "t058", "label": "returns", "split": "test", "text": "Is the 30-day limit from when I ordered or from when it arrived?"}
{"id": "t059", "label": "returns", "split": "test", "text": "My personalised copy has a typo in the dedication, can I send it back?"}
{"id": "t060", "label": "returns", "split": "test", "text": "Please cancel my return, I've decided to keep the book."}
{"id": "t061", "label": "payments", "split": "train", "text": "My card keeps getting declined at checkout."}
{"id": "t062", "label": "payments", "split": "train", "text": "I've been charged twice for the same order."}
{"id": "t063", "label": "payments", "split": "train", "text": "Can I pay with Pix?"}
{"id": "t064", "label": "payments", "split": "train", "text": "I need an invoice with my company's tax number on it."}
{"id": "t065", "label": "payments", "split": "train", "text": "The gift card code says it's invalid."}
{"id": "t066", "label": "payments", "split": "train", "text": "Can I split the payment into instalments?"}
{"id": "t067", "label": "payments", "split": "train", "text": "The price went down the day after I bought it. Can I get the difference?"}
{"id": "t068", "label": "payments", "split": "train", "text": "Do you take American Express?"}
{"id": "t069", "label": "payments", "split": "train", "text": "My bank statement shows a charge from you I don't recognise."}
{"id": "t070", "label": "payments", "split": "train", "text": "Can I use two gift cards on one order?"}
{"id": "t071", "label": "payments", "split": "train", "text": "PayPal shows the payment as pending for three days."}
{"id": "t072", "label": "payments", "split": "train", "text": "Is tax included in the prices on the website?"}
{"id": "t073", "label": "payments", "split": "train", "text": "The checkout page shows a different total from the basket."}
{"id": "t074", "label": "payments", "split": "train", "text": "Can I pay cash when the courier comes?"}
{"id": "t075", "label": "payments", "split": "train", "text": "My gift card has expired, is there anything you can do?"}
{"id": "t076", "label": "payments", "split": "train", "text": "Please send me a receipt for my last order, I can't find the email."}
{"id": "t077", "label": "payments", "split": "train", "text": "The payment failed but the money left my account anyway."}
{"id": "t078", "label": "payments", "split": "train", "text": "Can the school pay by bank transfer after the books arrive?"}
{"id": "t079", "label": "payments", "split": "train", "text": "Why was I charged before my pre-order was released?"}
{"id": "t080", "label": "payments", "split": "train", "text": "I want to change the company name on an invoice you already sent."}
{"id": "t081", "label": "payments", "split": "test", "text": "Transaction refused, but my card works everywhere else."}
{"id": "t082", "label": "payments", "split": "test", "text": "There are two identical charges on my credit card for one order."}
{"id": "t083", "label": "payments", "split": "test", "text": "Do you accept debit cards?"}
{"id": "t084", "label": "payments", "split": "test", "text": "How do I add my VAT number for business purchases?"}
{"id": "t085", "label": "payments", "split": "test", "text": "Gift card balance shows zero but I haven't used it."}
{"id": "t086", "label": "payments", "split": "test", "text": "Can I pay half now and half next month?"}
{"id": "t087", "label": "payments", "split": "test", "text": "I was billed in the wrong currency."}
{"id": "t088", "label": "payments", "split": "test", "text": "The total jumped by 5 at the last step of checkout."}
{"id": "t089", "label": "payments", "split": "test", "text": "Do you have a payment plan with no interest?"}
{"id": "t090", "label": "payments", "split": "test", "text": "I need a proper invoice, not just the receipt, for my expenses."}
{"id": "t091", "label": "account", "split": "train", "text": "I forgot my password and the reset email never comes."}
{"id": "t092", "label": "account", "split": "train", "text": "How do I change the email on my account?"}
{"id": "t093", "label": "account", "split": "train", "text": "Please delete my account and all my data."}
{"id": "t094", "label": "account", "split": "train", "text": "I lost my phone and can't get the sign-in code."}
{"id": "t095", "label": "account", "split": "train", "text": "Stop sending me newsletters, I've unsubscribed twice."}
{"id": "t096", "label": "account", "split": "train", "text": "Someone else logged into my account, I didn't place these orders."}
{"id": "t097", "label": "account", "split": "train", "text": "I want a copy of all the personal data you hold on me."}
{"id": "t098", "label": "account", "split": "train", "text": "The site says my email is already registered but I never made an account."}
{"id": "t099", "label": "account", "split": "train", "text": "How do I turn on two-factor authentication?"}
{"id": "t100", "label": "account", "split": "train", "text": "My reading lists disappeared from my profile."}
{"id": "t101", "label": "account", "split": "train", "text": "Can I merge my two accounts into one?"}
{"id": "t102", "label": "account", "split": "train", "text": "The password reset link says it has expired."}
{"id": "t103", "label": "account", "split": "train", "text": "I'd like to change the name shown on my reviews."}
{"id": "t104", "label": "account", "split": "train", "text": "I keep getting logged out every few minutes."}
{"id": "t105", "label": "account", "split": "train", "text": "How do I stop the order confirmation emails?"}
{"id": "t106", "label": "account", "split": "train", "text": "My account is locked after too many attempts."}
{"id": "t107", "label": "account", "split": "train", "text": "I no longer have access to the email I signed up with."}
{"id": "t108", "label": "account", "split": "train", "text": "Where can I see the recovery codes again?"}
{"id": "t109", "label": "account", "split": "train", "text": "Can I have my reviews removed without closing my account?"}
{"id": "t110", "label": "account", "split": "train", "text": "Why do you need my date of birth?"}
{"id": "t111", "label": "account", "split": "test", "text": "Can't sign in, it says wrong password but I'm sure it's right."}
{"id": "t112", "label": "account", "split": "test", "text": "I want to close my account permanently."}
{"id": "t113", "label": "account", "split": "test", "text": "Got a new phone, how do I move my authenticator?"}
{"id": "t114", "label": "account", "split": "test", "text": "Please take me off your mailing list."}
{"id": "t115", "label": "account", "split": "test", "text": "I think my account was hacked, the address was changed."}
{"id": "t116", "label": "account", "split": "test", "text": "How do I update my username?"}
{"id": "t117", "label": "account", "split": "test", "text": "Do you keep my order history after I delete my account?"}
{"id": "t118", "label": "account", "split": "test", "text": "The verification link for my new email address doesn't work."}
{"id": "t119", "label": "account", "split": "test", "text": "What information do you store about me?"}
{"id": "t120", "label": "account", "split": "test", "text": "My wishlist is empty after I signed in on my laptop."}
{"id": "t121", "label": "ebooks", "split": "train", "text": "The e-book I bought won't open on my Kindle."}
{"id": "t122", "label": "ebooks", "split": "train", "text": "The download stops at 80% every time."}
{"id": "t123", "label": "ebooks", "split": "train", "text": "Can I share my e-books with my husband's account?"}
{"id": "t124", "label": "ebooks", "split": "train", "text": "I bought the wrong e-book by mistake, can I get a refund? I haven't opened it."}
{"id": "t125", "label": "ebooks", "split": "train", "text": "How many devices can I read my e-books on?"}
{"id": "t126", "label": "ebooks", "split": "train", "text": "The text in the app is too small and I can't find how to change it."}
{"id": "t127", "label": "ebooks", "split": "train", "text": "The audiobook stops playing when my screen locks."}
{"id": "t128", "label": "ebooks", "split": "train", "text": "My e-book library is empty on my new tablet."}
{"id": "t129", "label": "ebooks", "split": "train", "text": "Can I read your e-books on a Kobo?"}
{"id": "t130", "label": "ebooks", "split": "train", "text": "The comic I bought can't be resized, it's tiny on my phone."}
{"id": "t131", "label": "ebooks", "split": "train", "text": "The app says I've reached the device limit."}
{"id": "t132", "label": "ebooks", "split": "train", "text": "Can I listen to audiobooks without internet?"}
{"id": "t133", "label": "ebooks", "split": "train", "text": "The e-book has missing chapters, it jumps from 4 to 9."}
{"id": "t134", "label": "ebooks", "split": "train", "text": "Is there a dark mode for reading at night?"}
{"id": "t135", "label": "ebooks", "split": "train", "text": "I downloaded the e-book but now I want a refund."}
{"id": "t136", "label": "ebooks", "split": "train", "text": "Adobe Digital Editions says the file is not authorised."}
{"id": "t137", "label": "ebooks", "split": "train", "text": "Can I lend an e-book to a friend for a week?"}
{"id": "t138", "label": "ebooks", "split": "train", "text": "The app crashes whenever I open a book."}
{"id": "t139", "label": "ebooks", "split": "train", "text": "Can I speed up the narration of the audiobook?"}
{"id": "t140", "label": "ebooks", "split": "train", "text": "Do you sell e-books without DRM?"}
{"id": "t141", "label": "ebooks", "split": "test", "text": "My e-reader says the format is not supported."}
{"id": "t142", "label": "ebooks", "split": "test", "text": "The e-book downloaded but shows a blank page."}
{"id": "t143", "label": "ebooks", "split": "test", "text": "Can my kids read my e-books on their own tablet?"}
{"id": "t144", "label": "ebooks", "split": "test", "text": "I'd like a refund on an e-book I haven't downloaded yet."}
{"id": "t145", "label": "ebooks", "split": "test", "text": "How do I change the background colour when reading?"}
{"id": "t146", "label": "ebooks", "split": "test", "text": "The audiobook skips back to the start every time I pause it."}
{"id": "t147", "label": "ebooks", "split": "test", "text": "Can I transfer my e-books to another app?"}
{"id": "t148", "label": "ebooks", "split": "test", "text": "The app won't sync my place between my phone and tablet."}
{"id": "t149", "label": "ebooks", "split": "test", "text": "Is it possible to print pages from an e-book?"}
{"id": "t150", "label": "ebooks", "split": "test", "text": "My purchased e-book isn't showing in the library."}
EOF
```

## Conferindo os arquivos

```
ana@lab:~/emb$ wc -l data/help.jsonl data/queries.jsonl data/tickets.jsonl
   40 data/help.jsonl
   24 data/queries.jsonl
  150 data/tickets.jsonl
  214 total
```

40, 24 e 150 linhas. Um número diferente costuma querer dizer que um bloco foi colado sem a última
linha, ou duas vezes; apague o arquivo com `rm` e cole o bloco de novo. As aulas 5 e 6 acrescentam
mais quatro arquivos, cada um na aula que o usa primeiro.
