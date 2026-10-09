---
title: Como um juiz funciona
version: 2
---

A aula 12 terminou onde as regras acabam: se uma resposta responde à pergunta, se soa como alguém
que se importa. O próximo passo óbvio é perguntar a um modelo. **Um juiz é um prompt como qualquer
outro, e o veredito dele é uma resposta como qualquer outra**, com formato, taxa de erro e hábitos.
O erro comum é tratá-lo como um leitor neutro de fora do sistema, quando ele é mais uma parte do
sistema que precisa ser medida.

## O prompt

Este prompt mostra a mensagem de um cliente e duas respostas, e pergunta qual é melhor. Salve-o
como `prompts/judge.txt`:

```
You compare two replies to a customer of Folio, an online bookshop.

<message>
{{message}}
</message>

<reply_a>
{{reply_a}}
</reply_a>

<reply_b>
{{reply_b}}
</reply_b>

Which reply answers the customer better? Answer A or B and nothing else.
```

Ele pede uma comparação em vez de uma nota de zero a dez. Uma comparação tem uma pergunta só, *qual
destas duas*, onde uma nota também precisa de um sentido combinado para 7. Ela também precisa de
pares: uma mensagem, duas respostas a ela, e o veredito que uma pessoa deu antes de qualquer modelo
ser consultado. Estes dezesseis foram escritos pelo curso, respostas e vereditos. Salve-os como
`cases/pairs.jsonl`:

```
{"id": "j01", "message": "I was charged twice for order 4471.", "a": "Thank you for contacting Folio. We take billing very seriously and our team is committed to resolving every issue our customers raise. Please be assured that your message has been passed to the relevant department, who will review your account and be in touch in due course.", "b": "Sorry about that. I can see two payments for order 4471 and I've refunded the second one; it will reach your card in 3 to 5 working days.", "human": "b"}
{"id": "j02", "message": "My parcel hasn't arrived and tracking stopped on Friday.", "a": "We're looking into it.", "b": "Sorry for the wait. The courier's tracking stopped at their depot on Friday; I've opened a trace with them and will email you by Thursday with what they find.", "human": "b"}
{"id": "j03", "message": "Can I return a book I didn't like?", "a": "Yes. You have 30 days from delivery to return any book in the condition it arrived. Start the return from your order page and we'll email a free label.", "b": "Yes, absolutely! Returns are something we're always happy to help with here at Folio, and we want every customer to love what they read. You have 30 days from delivery. Start from your order page and we'll email a label.", "human": "a"}
{"id": "j04", "message": "I can't log in and the reset email never comes.", "a": "Sorry about this. Reset emails sometimes land in spam; if it isn't there, reply to this message and I'll reset the password from here.", "b": "Please try again later.", "human": "a"}
{"id": "j05", "message": "Do you have signed copies of the new Carla Mendes novel?", "a": "Thank you for your question! Signed copies are always a lovely thing to own, and we're delighted that you're interested in Carla Mendes's work. We do have some signed hardbacks at the moment, so do have a look on the website.", "b": "We do, while they last: there are 14 signed hardbacks. You can order one from the book's page; the signed edition is listed separately.", "human": "b"}
{"id": "j06", "message": "The cover was torn when the book arrived.", "a": "Sorry it arrived like that. I've sent a replacement today by first-class post, and there's no need to return the damaged copy.", "b": "Sorry about the cover. Send us a photo and we'll look into it.", "human": "a"}
{"id": "j07", "message": "Are you open on the bank holiday?", "a": "Thanks for asking! Our opening hours over bank holidays vary from year to year and from shop to shop, so the best thing to do is to keep an eye on our website and social media, where we post updates.", "b": "Yes, 10:00 to 16:00 on the bank holiday Monday.", "human": "b"}
{"id": "j08", "message": "Please delete my account and all my data.", "a": "Done. Your account and order history were deleted today, and you'll get one email confirming it. Records we must keep for tax are held without your name.", "b": "We're sorry to see you go! Before you leave, have you seen our new loyalty scheme? Members get 10% off every order.", "human": "a"}
{"id": "j09", "message": "I paid £15 but the website said £12.", "a": "Sorry for the confusion.", "b": "Sorry about that. The £3 difference was delivery, which the product page didn't show. I've refunded it as a goodwill gesture; it will appear on your card in 3 to 5 working days.", "human": "b"}
{"id": "j10", "message": "The courier says my address is wrong.", "a": "Sorry about this. Could you reply with the address as it appears on your order? I'll compare it with what the courier has and correct whichever is wrong.", "b": "Thank you so much for getting in touch with us about your delivery. We completely understand how frustrating it can be when a courier has trouble with an address. Our team is always here to help and we'll do our very best to get to the bottom of this for you as soon as we possibly can.", "human": "a"}
{"id": "j11", "message": "How do I turn off the marketing emails?", "a": "Sorry for any trouble! We'd hate for you to miss our offers, but of course we respect your choice. If you'd like to stop hearing from us, please find the unsubscribe link at the very bottom of any of the emails that we send to you.", "b": "There's an unsubscribe link at the foot of every email, or untick 'news and offers' under Settings in your account.", "human": "b"}
{"id": "j12", "message": "Two pages are missing from chapter 3.", "a": "That's a printing fault. Sorry. A replacement is on its way and the order page has a free return label for the faulty copy.", "b": "Thank you for letting us know.", "human": "a"}
{"id": "j13", "message": "Why do I need an account to buy a book?", "a": "Great question! Having an account with us brings lots of benefits, including order history, saved addresses, faster checkout, wish lists and early access to some of our events and promotions throughout the year.", "b": "You don't: choose 'checkout as guest' on the basket page. An account only keeps your order history and addresses.", "human": "b"}
{"id": "j14", "message": "My card was declined but the money left my account.", "a": "That's usually a hold, not a payment.", "b": "Sorry for the worry. When a card is declined, the bank sometimes holds the amount for up to 5 working days and then releases it. I've checked and we received no payment from you, so nothing needs refunding from our side.", "human": "b"}
{"id": "j15", "message": "Is it possible to change the delivery address on an order from an hour ago?", "a": "Yes, while it hasn't been dispatched. I've put a hold on it: reply with the new address and I'll update it.", "b": "Thank you for your message. Unfortunately, address changes can be complicated once an order is in our system, as many different teams and processes are involved. We'll see what we can do.", "human": "a"}
{"id": "j16", "message": "Do you buy second-hand books?", "a": "We don't, sorry, but the Bookswap in Market Street does, and it's two minutes from the shop.", "b": "Thank you for thinking of us! We're always delighted to hear from book lovers. Second-hand books are a wonderful way to give stories a new life, and there are many good places in town where you can sell yours.", "human": "a"}
```

No `j01` a pessoa escolheu `b`: diz o que aconteceu e o que foi feito. O `a` é um parágrafo de
tranquilização em que nada acontece. Metade dos pares vai para cada lado, oito `a` e oito `b`, então
um juiz que respondesse sempre a mesma letra concordaria com a pessoa exatamente metade das vezes.

O juiz nesta aula é o próprio `llama3.2:3b`, o modelo que faz a triagem, com temperatura 0. Usar o
mesmo modelo para avaliar o próprio tipo de saída é comum, porque é o modelo que você já tem. Se ele
é bom nisso é a pergunta que as duas próximas seções respondem, medindo-o contra os vereditos da
pessoa.
