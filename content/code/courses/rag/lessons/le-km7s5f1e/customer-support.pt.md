---
title: Atendimento ao cliente
version: 2
---

O atendimento ao cliente é onde a maioria dos sistemas de recuperação se paga, e onde a maioria deles
é julgada em público. Os documentos são a central de ajuda e as políticas por trás dela; quem lê é um
cliente que quer uma coisa, agora, nas próprias palavras, e que não vai abrir a fonte para conferir.
Esse último fato muda o projeto mais que qualquer outro.

## A central de ajuda já é um corpus de recuperação

O `embeddings-vectors` buscou na central de ajuda da Marginalia por significado, e a mesma busca é a
metade de recuperação de um assistente de atendimento. A central de ajuda são quarenta artigos curtos,
uma linha JSON cada. Salve isto como `~/rag/help.sh` e rode:

```sh
#!/bin/sh
# help.sh: writes data/help.jsonl, Marginalia's help centre: forty short articles
set -e
mkdir -p data
cat > data/help.jsonl <<'EOF'
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

```
ana@vm:~/rag$ sh help.sh
ana@vm:~/rag$ wc -l data/help.jsonl
40 data/help.jsonl
```

O `help_search.py` é a busca, sobre esses quarenta artigos:

```schooling-example
{
  "language": "python",
  "file": "help_search.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nfrom vectors import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nvectors = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Cada artigo vira embedding uma vez, título e corpo juntos, porque o título é o melhor resumo do que um artigo responde."
    },
    {
      "code": "scores = vectors @ embed(sys.argv[1])[0]\nfor i in scores.argsort()[::-1][:3]:\n    print(f\"{scores[i]:.3f}  {help[i]['id']} {help[i]['lang']}  {help[i]['title']}\")",
      "note": "Os três artigos mais próximos, com nota, id e idioma. Não há chamada ao modelo: é só a busca."
    }
  ]
}
```

```
ana@vm:~/rag$ python help_search.py "how do I send a book back"
0.723  h14 en  How to return a book
0.625  h12 en  Damaged books on arrival
0.613  h16 en  Exchanging a book for a different edition
```

**Artigos curtos escritos para clientes são o material mais fácil que um sistema de recuperação vai
receber.** Cada um responde a uma pergunta, no vocabulário do cliente, sob um título que diz o que
responde. As políticas por trás deles são o oposto: longas, precisas, escritas para quem tem de
aplicá-las. Um assistente de atendimento em geral precisa dos dois, o artigo para responder e a
política para acertar os casos de borda, e a aula 12 trata de pôr os dois num prompt sem afogar o
primeiro no segundo.

## Uma pergunta em outra língua

A Marginalia vende no Brasil, e parte dos clientes escreve em português. A central de ajuda tem três
artigos em português, traduções de três em inglês:

```
ana@vm:~/rag$ python help_search.py "como devolvo um livro"
0.717  h38 pt  Como devolver um livro
0.426  h40 pt  Como redefinir sua senha
0.324  h39 pt  Prazos e custos de entrega
ana@vm:~/rag$ python help_search.py "quanto custa a entrega expressa"
0.647  h39 pt  Prazos e custos de entrega
0.513  h40 pt  Como redefinir sua senha
0.352  h38 pt  Como devolver um livro
```

As duas perguntas em português acharam o artigo em português primeiro. Repare, porém, no que veio em
segundo e terceiro: **os outros dois artigos em português, seja qual for o assunto.** Uma pergunta sobre
devolução pôs um artigo sobre redefinir senha acima de qualquer um dos trinta e sete artigos em inglês,
vários deles sobre devolução. O all-MiniLM-L6-v2 foi treinado em inglês, e para ele um texto em
português é um conjunto de pedaços de palavra que se parecem sobretudo com outros textos em português.
Ele liga português a português pela grafia, não pelo significado, e não consegue levar uma pergunta em
português até uma resposta em inglês.

Para um assistente de atendimento isso é um requisito duro, não um detalhe: **o modelo de embeddings
tem de cobrir todas as línguas em que os clientes escrevem**, ou cada documento tem de existir em cada
uma delas. A aula 1 do `embeddings-vectors` mostrou o que este modelo faz com um título em português e
por que um modelo multilíngue põe uma tradução ao lado do original, e a aula 10 dele pesou os modelos
multilíngues entre os quais uma loja como esta escolheria.

## O que o atendimento pede de um pipeline

- **Respostas curtas primeiro.** O cliente quer sim ou não e o número; o manual de atendimento do
  corpus diz o mesmo sobre como os atendentes escrevem, "the answer first and the explanation after it".
- **As palavras do cliente, não as da política.** As pessoas perguntam "mandar um livro de volta",
  "dinheiro de volta", "a caixa nunca chegou". A busca tem de fazer a ponte entre isso e o vocabulário
  da política, e é nisso que os embeddings são bons.
- **Uma recusa é melhor que um chute.** Uma resposta errada a um cliente vira uma promessa que a loja
  talvez tenha de cumprir, e um print dela pode circular. A aula 7 faz da recusa uma regra.
- **Uma saída para uma pessoa.** O manual lista os casos que vão para um líder de equipe: um reembolso
  acima do limite do atendente, uma terceira mensagem sobre o mesmo problema, a menção a um advogado.
  Um assistente que responde a esses sozinho está fazendo um trabalho que ninguém lhe deu.
- **Atualidade.** Preços de frete e prazos de entrega mudam várias vezes por ano, e os clientes
  perguntam sobre eles todo dia. O índice tem de ser refeito quando um documento muda, e a aula 5 torna
  isso barato.
