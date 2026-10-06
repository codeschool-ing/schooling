---
title: Reescrevendo a pergunta
version: 1
---

A busca precisa de uma pergunta que se sustente sozinha. A correção comum é uma **reescrita**: antes
de buscar, pedir a um modelo que transforme a última mensagem e a conversa até ali numa pergunta que
não precise de histórico. O motor de chat do LlamaIndex que faz isso leva a instrução como template:

```
ana@lab:~/rag$ python condense.py
Given a conversation (between Human and Assistant) and a follow up message from Human, rewrite the message to be a standalone question that captures all relevant context from the conversation.

<Chat History>
{chat_history}

<Follow Up Message>
{question}

<Standalone question>
```

"How do I send back Mansfield Park?" voltaria como algo parecido com "Como devolvo um livro enviado no
lugar do que pedi?", e isso busca bem. O LangChain tem o mesmo passo com o nome de recuperador ciente
do histórico. O preço é uma segunda chamada ao modelo em todo turno, antes de a busca poder começar, e
um lugar novo para errar: uma reescrita que perde um detalhe, ou acrescenta um, busca uma pergunta que
o cliente não fez. O teste da aula 8 é como uma equipe descobre qual dos dois.

O extract-1 não consegue reescrever nada; ele copia frases. Então este laboratório faz uma versão mais
barata, sem modelo nenhum: **achar o turno anterior mais parecido com a mensagem nova, e pô-lo na
frente para a busca**. É uma recuperação, o mesmo tipo de busca da aula 6, sobre os turnos do próprio
cliente:

```
ana@lab:~/rag$ python recalled.py chat-a A-1001 10 11 12
turn 10: How do I send back Mansfield Park?
   0.579  turn 3: The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park.
   0.373  turn 7: I have photographs of the damaged cover next to the box. Where do I send them?
turn 11: How long will the refund for Middlemarch take?
   0.427  turn 5: For Persuasion I would like a replacement, not a refund.
   0.682  turn 6: For Middlemarch I want my money back. I bought it somewhere else in the meantime.
turn 12: Sorry, what was my order number again? I need it for my notes.
   0.492  turn 1: Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.
   0.325  turn 2: The order had two books. Persuasion arrived with water damage on the cover.
```

Para cada pergunta, os dois turnos anteriores mais próximos dela. **O turno 10 recupera o turno 3**, o
livro errado, com 0,579, e **o turno 11 recupera o turno 6**, "For Middlemarch I want my money back",
com 0,682. São os turnos que uma reescrita teria usado. O segundo turno recuperado é mais fraco todas
as vezes, então o `chat.py` pega só o mais próximo, e só quando ele chega ao `LIKE`, 0,5; o melhor
casamento do turno 12, o turno 1, tem 0,492 e fica de fora, o que a seção sobre estado retoma. Um
turno recuperado que não se parece em nada com a pergunta desviaria a busca do que foi perguntado,
que é o mesmo desvio que uma reescrita descuidada causa.

O turno recuperado vai para a busca e **não para o prompt**. O modelo recebe a pergunta do cliente
como ele a escreveu. As palavras da própria Beatriz não são fonte: são o que ela disse, e não o que a
política da Marginalia diz, e uma resposta que as cita cita a cliente para ela mesma, que é o turno 10
da seção anterior.
