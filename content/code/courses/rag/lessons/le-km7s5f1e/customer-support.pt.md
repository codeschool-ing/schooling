---
title: Atendimento ao cliente
version: 1
---

O atendimento ao cliente é onde a maioria dos sistemas de recuperação se paga, e onde a maioria deles
é julgada em público. Os documentos são a central de ajuda e as políticas por trás dela; quem lê é um
cliente que quer uma coisa, agora, nas próprias palavras, e que não vai abrir a fonte para conferir.
Esse último fato muda o projeto mais que qualquer outro.

## A central de ajuda já é um corpus de recuperação

O `embeddings-vectors` buscou na central de ajuda da Marginalia por significado, e a mesma busca é a
metade de recuperação de um assistente de atendimento. O `help_search.py` é essa busca, sobre os
quarenta artigos curtos de `data/help.jsonl`:

```
ana@lab:~/rag$ python help_search.py "how do I send a book back"
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
ana@lab:~/rag$ python help_search.py "como devolvo um livro"
0.717  h38 pt  Como devolver um livro
0.426  h40 pt  Como redefinir sua senha
0.325  h39 pt  Prazos e custos de entrega
ana@lab:~/rag$ python help_search.py "quanto custa a entrega expressa"
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
