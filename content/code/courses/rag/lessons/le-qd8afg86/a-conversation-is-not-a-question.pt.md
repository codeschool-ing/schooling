---
title: Uma conversa não é uma pergunta
version: 1
---

Todo pipeline deste curso até aqui respondeu uma pergunta de cada vez. Um chat de atendimento não é
isso. É um cliente contando uma história em várias mensagens, e as mensagens de depois se apoiam nas
de antes: "o outro pacote", "ele", "meu número de pedido de novo". O `data/chat-a.jsonl` são doze
mensagens de Beatriz Costa sobre o pedido MG-20481937, escritas para o curso: um exemplar danificado
de *Persuasion*, o livro errado no lugar de *Middlemarch*, um pedido de contato só por e-mail, e
quatro perguntas perto do fim.

O `chat.py` reproduz a conversa turno a turno com uma escolha de memória. A primeira é nenhuma: cada
mensagem passa pelo pipeline da aula 7 como se fosse a única.

```
ana@lab:~/rag$ python chat.py chat-a alone
 1     0 tokens
 2   163 tokens
 3     0 tokens
 4     0 tokens
 5     0 tokens
 6     0 tokens
 7   164 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. [1]
 8     0 tokens
 9   220 tokens  Do I need to send the damaged copy back to you?
   first document: 0.618  If a book arrives with a torn cover, bent ...
   We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
10     0 tokens  How do I send back Mansfield Park?
   no document above the floor
   I could not find that in our documents.
11   273 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   We refund within three working days of the return reaching our warehouse. [1]
12     0 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   I could not find that in our documents.
820 prompt tokens over 12 turns
```

Para cada turno, os tokens que o prompt custou (0 quando o piso recusou sem chamar o modelo), e para
cada pergunta, o primeiro documento que a busca achou e a resposta. **Três das cinco perguntas
funcionam sozinhas**, porque trazem o próprio assunto: capas danificadas, um exemplar danificado, um
reembolso. Duas não.

- **O turno 10, "How do I send back Mansfield Park?"**, não acha nada acima do piso. *Mansfield Park*
  é um título, e nenhuma política o menciona; o que torna a pergunta respondível é o turno 3, em que
  Beatriz disse que era o livro errado.
- **O turno 12, "what was my order number again?"**, não acha nada, porque a resposta não está em
  documento nenhum. Está no turno 1.

As duas recusas estão certas pela regra da aula 7, e as duas fariam um cliente fechar o chat: o
assistente ouviu tudo o que precisava, e se comporta como se não tivesse ouvido nada. O resto da aula
são três jeitos de lhe dar uma memória, e o que cada um custa.
