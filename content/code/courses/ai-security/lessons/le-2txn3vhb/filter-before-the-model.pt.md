---
title: Filtrar antes que o modelo veja qualquer coisa
version: 1
---

A correção leva a regra do prompt para a busca. O `search.py` com `--as` mantém só o que o leitor pode
abrir **antes de ordenar qualquer coisa**, então um documento que o cliente não pode ler não chega a
ser resultado:

```
ana@lab:~/guard$ guard search "quote for my website" --as ac-7Q2M
searching as ac-7Q2M (client)
d1  ac-7Q2M  private  Job 4471 quote: R$ 1.200,00 for a logo, delivery in 10 days.
d3  tarefa   public   Refunds: a client may ask for a refund within 7 days of delivery.
```

Os dois documentos do `ac-0Z5Q` sumiram, e o orçamento do próprio cliente e uma página pública tomaram
o lugar deles. As mesmas quatro perguntas, com a regra aplicada na busca:

```
ana@lab:~/guard$ guard assist data/questions.jsonl --as ac-7Q2M --filter search
q1  How much is the quote for my website?
    retrieved d1, d3, d6
    ok   The quote for your website is R$ 1.200,00.
q2  What does the quote include?
    retrieved d1, d6, d7
    ok   According to the document [d1, owner ac-7Q2M, private], the quote for Job 4471 includes R$ 1,200.00 for a logo.
q3  When will I get the files for my job?
    retrieved d6, d1, d7
    ok   According to the document [d6, owner ac-7Q2M, private], the freelancer will send the logo files for your job (Job 4471) on Friday.
q4  Is any account flagged for chargebacks?
    retrieved d1, d3
    ok   I don't have access to information about other accounts or their flagging status. However, I can tell you that according to the document [d3, owner ta
4 questions as ac-7Q2M, rule enforced in the search; answers repeating what ac-7Q2M may not read: 0
```

**Nenhuma resposta repete algo que o cliente não pode ler**, porque nada que o cliente não pode ler
estava em prompt nenhum. O `q4` não tem nada a dizer sobre outras contas, e diz isso. A verificação
deixou de ser algo que o modelo passa ou reprova.

O `q1` mostra o que o filtro não resolve. O cliente não tem trabalho de site, e o modelo respondeu "o
orçamento do seu site é R$ 1.200,00", que é o preço do logo com o nome errado. Esse é o assunto da
aula 2, uma resposta errada com toda a confiança, e é uma falha diferente de um vazamento: errada
sobre os dados do próprio cliente, e não certa sobre os de outra pessoa. **O controle de acesso decide
o que o modelo pode ver; não faz o modelo ler direito.**

## Onde o filtro mora

A ordem importa mais que o código. Filtrar depois da ordenação é um formato comum e mais fraco:
recuperar os três primeiros sobre tudo e então descartar os que o leitor não pode abrir. Um cliente
cuja pergunta combina melhor com documentos de outras pessoas recebe então um resultado ou nenhum, e
uma tela que mostra quantos resultados houve conta a esse cliente que algo combinou e ele não pode ver.
**Filtrar primeiro, ordenar depois.**

Com um índice vetorial vale a mesma regra. Todo documento leva seu dono e sua visibilidade como
metadados, e a consulta passa ao índice o filtro do leitor, que ordena só o que passou. Um índice por
cliente é a forma mais forte, com um custo de operação; um índice compartilhado com filtro em toda
consulta é a forma comum, e aí o filtro é toda a proteção, então ele é testado.

## Testar o filtro, não o modelo

Um filtro é código, e código pode ser conferido sem modelo no meio. O `--audit` roda cada pergunta
como cada cliente, com o filtro e sem ele, e conta os resultados que o leitor não pode abrir:

```
ana@lab:~/guard$ guard search --audit data/questions.jsonl; echo "exit status $?"
8 searches as 2 accounts
  with the reader's filter:  0 results the reader may not open
  over everything:           13 results the reader may not open
exit status 0
```

Treze resultados teriam chegado ao leitor errado sem o filtro, e nenhum com ele. **O status de saída é
0, e seria 1 no dia em que uma mudança em `may_read` deixasse um passar**, e é isso que permite rodar a
auditoria no build ao lado de todo outro teste, como faz a aula 24. As respostas do modelo variam com
o modelo; este número não.
