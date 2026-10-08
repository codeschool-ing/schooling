---
title: Mandando o histórico inteiro
version: 2
---

A memória mais simples é mandar tudo de novo. APIs de chat são feitas para isso: uma requisição leva
uma lista de mensagens, e uma aplicação que guarda a conversa pode pôr cada mensagem anterior de volta
na frente da nova.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def ask(sources, question, past=()):\n    messages = [{\"role\": \"system\", \"content\": SYSTEM}, *past,\n                {\"role\": \"user\", \"content\": f\"{numbered(sources)}\\n\\nQuestion: {question}\"}]\n    return (*call(messages), sources)",
      "note": "O prompt da aula 7, com espaço para mensagens anteriores entre as instruções e a pergunta nova."
    },
    {
      "code": "def history(text, past, account, name):\n    \"\"\"Every earlier turn, the customer's and the assistant's, sent again as messages.\"\"\"\n    return ask(sources_for(text), text, past)",
      "note": "A conversa inteira até ali, os turnos do cliente e as respostas do assistente, entra de novo a cada turno. A busca continua vendo só este turno."
    }
  ]
}
```

```
ana@vm:~/rag$ python chat.py chat-a history
 1   119 tokens
 2   299 tokens
 3   358 tokens
 4   393 tokens
 5   426 tokens
 6   577 tokens
 7   684 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   According to our returns and refunds policy [1], you can send the photographs of the damaged cover next to the packaging to our customer service email address. Please reply to this email with the photos, and we will process a replacement for Persuasion.

Regarding the incorrect book, Middlemarch, I will need to escalate this issue to our customer service team. They will contact you to discuss a refund or replacement options.
 8   734 tokens
 9  1025 tokens  Do I need to send the damaged copy back to you?
   first document: 0.617  If a book arrives with a torn cover, bent ...
   According to our returns and refunds policy [1], you do not need to send the damaged copy of Persuasion back to us. We will replace it at no cost.

However, I must correct my previous response regarding the shipping address. Since you are moving house, we will need to update your address with our system. Please allow a few extra days for the replacement to be processed and shipped to your new address.

I will also make a note to contact you regarding the incorrect book, Middlemarch, as soon as possible.
10  1019 tokens  How do I send back Mansfield Park?
   no document above the floor
   I could not find that in our documents.
11  1235 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   According to our returns and refunds policy [1], [2], and [3], since you are returning the incorrect book, Middlemarch, within 14 days of receiving it, we will send the correct book immediately with a prepaid label for the wrong one. You will not be charged twice.

As for the refund, it will be processed within three working days of the return reaching our warehouse. Since you are returning the book within the 14-day timeframe, the refund should be processed within the next 3 working days.

Please allow 15-20 working days for the refund to be processed and reflected in your account.
12  1201 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   Your order number is MG-20481937.
8070 prompt tokens over 12 turns
```

**O prompt cresce a cada turno**, de 119 tokens na primeira mensagem a 1.235 na décima primeira, e a
conversa custou 8.070 tokens de prompt onde responder cada turno sozinho custou 908. Cada turno paga
de novo por todos os anteriores, e pelas respostas do assistente a eles, então uma conversa com o dobro
do tamanho custa mais ou menos o quádruplo. O orçamento da aula 12 acaba na décima mensagem de um chat
longo.

**Ele respondeu o turno 12**: *Your order number is MG-20481937*, lido do turno 1, que estava no
prompt. É para isso que serve mandar o histórico, e é a única das três perguntas que precisavam do
passado que ele respondeu. O turno 10 foi recusado, porque a busca continuou vendo só o turno 10 e não
achou documento; **histórico no prompt não faz nada pela metade da recuperação**. E as respostas
cresceram com o histórico. A do turno 9 corrige um endereço de entrega que ninguém perguntou, e a do
turno 11 responde o reembolso com os três dias úteis certos e depois *Please allow 15-20 working days*,
um número que nenhuma fonte tem. As respostas anteriores do próprio modelo também estão no prompt, e
um modelo pequeno lendo uma conversa longa continua acrescentando a ela.
