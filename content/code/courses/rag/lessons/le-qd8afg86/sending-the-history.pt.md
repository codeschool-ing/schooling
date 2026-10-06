---
title: Mandando o histórico inteiro
version: 1
---

A memória mais simples é mandar tudo de novo. APIs de chat são feitas para isso: uma requisição leva
uma lista de mensagens, e uma aplicação que guarda a conversa pode pôr cada mensagem anterior de volta
na frente da nova.

```schooling-example
{
  "language": "python",
  "file": "chat.py",
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
ana@lab:~/rag$ python chat.py chat-a history
 1    98 tokens
 2   220 tokens
 3   211 tokens
 4   242 tokens
 5   271 tokens
 6   305 tokens
 7   407 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. [1] If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. [1]
 8   440 tokens
 9   598 tokens  Do I need to send the damaged copy back to you?
   first document: 0.618  If a book arrives with a torn cover, bent ...
   We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
10   504 tokens  How do I send back Mansfield Park?
   no document above the floor
   The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park.
11   725 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   For Middlemarch I want my money back. We refund within three working days of the return reaching our warehouse. [1]
12   588 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   I could not find that in our documents.
4609 prompt tokens over 12 turns
```

**O prompt cresce a cada turno**, de 98 tokens na primeira mensagem a 725 na décima primeira, e a
conversa custou 4.609 tokens de prompt onde responder cada turno sozinho custou 820. Cada turno paga
de novo por todos os anteriores, então uma conversa com o dobro do tamanho custa mais ou menos o
quádruplo. O orçamento da aula 12 acaba na décima mensagem de um chat longo.

E ela não respondeu as duas perguntas. A resposta do turno 10 é **"The other parcel had the wrong book:
I ordered Middlemarch and got Mansfield Park."**, a frase da própria Beatriz lida de volta para ela,
sem citação: o extract-1 lê os turnos anteriores como fontes sem número e, sem documento acima do
piso, a frase mais próxima que ele tinha era a dela. A verificação de citações da aula 7 a marcaria
como sem citação. O turno 12 foi recusado mesmo com o turno 1 no prompt, porque a busca continuou
vendo só o turno 12 e não achou documento, e a frase com o número do pedido não estava perto o
bastante da pergunta para o extract-1. Um modelo de linguagem leria o histórico de outro jeito que
este substituto; o que não muda com o modelo é que **a busca só vê a mensagem atual**. Histórico no
prompt não faz nada pela metade da recuperação.
