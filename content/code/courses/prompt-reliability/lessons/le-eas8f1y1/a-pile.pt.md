---
title: Uma pilha de regras
version: 1
---

Um prompt em produção junta regras do jeito que o prompt da aula 2 juntou linhas. Um resumo volta
com um nome, então alguém acrescenta *Do not put the customer's name in the summary*. Um reembolso
urgente é marcado como normal, então alguém acrescenta uma regra sobre dinheiro. **Cada regra
corrige a resposta que a motivou**, e ninguém relê a lista inteira. Treze delas ficam assim:

```
ana@lab:~/triage$ cat -n prompts/v8-rules.txt
     1	You sort customer messages for Folio, an online bookshop.
     2	
     3	Answer with only a JSON object with three fields:
     4	- "category": one of billing, delivery, returns, account, other
     5	- "urgency": one of low, normal, high
     6	- "summary": one sentence saying what the customer needs
     7	
     8	Rules:
     9	- Keep the summary short.
    10	- Do not use the category other unless you have to.
    11	- Do not guess.
    12	- NEVER mark a question as high urgency.
    13	- ALWAYS mark a message about money as high urgency.
    14	- Do not put the customer's name in the summary.
    15	- Do not repeat the message word for word.
    16	- Do not mention refunds unless the customer does.
    17	- A refund is billing.
    18	- A refund for a returned book is returns.
    19	- Do not use the word "customer" in the summary.
    20	- Include every detail the customer gives in the summary.
    21	- Do not add fields.
    22	
    23	<message>
    24	{{message|xml}}
    25	</message>
```

Leia como o modelo leria, de cima para baixo, com uma mensagem na mão, e veja o quanto disso ajuda a
decidir alguma coisa. Oito das treze dizem só o que não fazer. Duas estão em maiúsculas. A linha 9
quer o resumo curto e a linha 20 quer todos os detalhes nele. O linter da aula 2 encontra quase
tudo isso:

```
ana@lab:~/triage$ pl lint prompts/v8-rules.txt
prompts/v8-rules.txt:6: contradiction (length): lines 6,9 against lines 20
prompts/v8-rules.txt:9: 13 separate rules; the reader keeps fewer
prompts/v8-rules.txt:10: 8 rules say only what not to do: lines 10,11,12,14,15,16,19,21
prompts/v8-rules.txt:12: 2 lines shout: 12,13
199 tokens
```

## O que um "não faça" deixa em aberto

Uma proibição diz ao leitor uma coisa que está errada, e nada sobre o que está certo. *Do not use the
category other unless you have to* diz que `other` é suspeita. Não diz quando é preciso usá-la, nem
que categoria usar no lugar. *Do not guess* proíbe algo que toda resposta a uma mensagem ambígua
precisa fazer. **Oito regras desse tipo demarcam o que evitar e não dizem qual é o alvo**, e o
leitor — modelo ou pessoa — preenche a lacuna com o que parecer razoável.

## A contradição que o linter não viu

As linhas 12 e 13 são regras de urgência, e o linter as apontou só como gritaria. Esta é uma mensagem
à qual as duas se aplicam:

```
ana@lab:~/triage$ grep t22 cases/all.jsonl
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
```

É uma pergunta, então a linha 12 diz que nunca pode ser high. É sobre dinheiro, então a linha 13 diz
que tem de ser sempre high. **As duas regras são absolutas e não podem valer juntas**, e nada no
prompt diz qual delas cede. A pessoa que rotulou o caso disse low, por um motivo que nenhuma das duas
regras menciona: ninguém perdeu nada ainda, e a resposta pode esperar um dia. O linter deixou o
conflito passar pelo motivo que a aula 2 deu: ele casa palavras, e *never* e *always* não
estão na lista de opostos dele.

As linhas 17 e 18 têm a mesma forma, mais discreta. Reembolso é billing; reembolso de um livro
devolvido é returns. Um reembolso de livro devolvido que foi para o cartão errado é as duas coisas, e
a última seção desta aula volta a ele.
