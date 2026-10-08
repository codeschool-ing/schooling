---
title: Uma pilha de regras
version: 2
---

Um prompt em produção junta regras do jeito que o prompt da aula 2 juntou linhas. Um resumo volta
com um nome dentro, então alguém acrescenta *Do not put the customer's name in the summary*. Um
reembolso urgente é marcado normal, então alguém acrescenta uma regra sobre dinheiro. **Cada regra
conserta a resposta que a motivou**, e ninguém relê a lista inteira. Assim ficam treze delas.
Salve-o como `prompts/v8-rules.txt`:

```
You sort customer messages for Folio, an online bookshop.

Answer with only a JSON object with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Rules:
- Keep the summary short.
- Do not use the category other unless you have to.
- Do not guess.
- NEVER mark a question as high urgency.
- ALWAYS mark a message about money as high urgency.
- Do not put the customer's name in the summary.
- Do not repeat the message word for word.
- Do not mention refunds unless the customer does.
- A refund is billing.
- A refund for a returned book is returns.
- Do not use the word "customer" in the summary.
- Include every detail the customer gives in the summary.
- Do not add fields.

<message>
{{message|xml}}
</message>
```

O `cat -n prompts/v8-rules.txt` o imprime com as linhas numeradas, e o resto desta aula se refere a
elas pelo número.

Leia como o modelo leria, de cima para baixo, com uma mensagem na mão, e veja quanto disso ajuda a
decidir alguma coisa. Oito das treze dizem só o que não fazer. Duas estão em maiúsculas. A linha 9
quer o resumo curto e a linha 20 quer todos os detalhes nele. O linter da aula 2 encontra quase tudo
isso:

```
ana@lab:~/triage$ python3 lint.py prompts/v8-rules.txt
prompts/v8-rules.txt:9: 13 separate rules; a reader keeps fewer
prompts/v8-rules.txt:10: 8 rules say only what not to do: lines 10,11,12,14,15,16,19,21
prompts/v8-rules.txt:12: 2 lines shout: 12,13
```

## O que um "não faça" deixa em aberto

Uma proibição diz ao leitor uma coisa que está errada, e nada sobre o que está certo. *Do not use the
category other unless you have to* diz que `other` é suspeita. Não diz quando é preciso, nem que
categoria usar no lugar. *Do not guess* proíbe algo que toda resposta a uma mensagem ambígua precisa
fazer. **Oito regras desse tipo marcam o que evitar e deixam o alvo sem dizer**, e o leitor, modelo
ou pessoa, preenche a lacuna com o que parecer razoável.

## A contradição que o linter não viu

As linhas 12 e 13 são as duas regras sobre urgência, e o linter as apontou só como grito. Aqui está
uma mensagem à qual as duas se aplicam:

```
ana@lab:~/triage$ grep t22 cases/dev.jsonl
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
```

É uma pergunta, então a linha 12 diz que ela nunca pode ser high. É sobre dinheiro, então a linha 13
diz que ela tem de ser sempre high. **As duas regras são absolutas e não podem valer ao mesmo
tempo**, e nada no prompt diz qual cede. A pessoa que rotulou o caso disse low, por um motivo que
nenhuma das regras menciona: ninguém perdeu nada ainda, e a resposta pode esperar um dia. O linter
deixou o conflito passar pelo motivo que a aula 2 deu: ele casa palavras, e *never* e *always* não
estão na lista de opostos dele.

As linhas 17 e 18 têm a mesma forma, mais discreta. Um reembolso é billing; um reembolso de um livro
devolvido é returns. Um reembolso de um livro devolvido que foi para o cartão errado é as duas
coisas, e a última seção desta aula volta a ele.
