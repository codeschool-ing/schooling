---
title: Quando a recuperação é a ferramenta errada
version: 2
---

A recuperação responde a perguntas cuja resposta está escrita em algum lugar, num trecho curto o
bastante para ser achado. Uma parte surpreendente das perguntas que as pessoas fazem a um assistente de
empresa não é assim, e um sistema de recuperação que recebe uma delas não falha alto. Ele devolve três
trechos, os mais próximos que tem, e o gerador faz o que pode com eles.

## Uma pergunta sobre o corpus inteiro

```
ana@vm:~/rag$ python sections.py "Which documents mention a 14-day limit?"
[1] 0.414  privacy-notice > How long we keep it
[2] 0.409  returns-policy > The return window
[3] 0.348  terms-of-sale > 6. The right of withdrawal
None of the documents mention a 14-day limit. 

However, [3] terms-of-sale > 6. The right of withdrawal mentions a 7-day limit for withdrawal from a purchase, and [2] returns-policy > The return window mentions a 7-day limit for the statutory right of withdrawal, but also mentions a 30-day limit for printed books.
ana@vm:~/rag$ grep -l "14 days" data/docs/*.md
data/docs/ebooks-and-audiobooks.md
data/docs/returns-policy-2025.md
data/docs/returns-policy.md
data/docs/seller-agreement.md
```

O `grep` leu todos os documentos e respondeu com uma linha por ocorrência: quatro documentos. A busca
devolveu três seções, e nenhuma delas contém a expressão, porque **uma pergunta sobre quais documentos
dizem alguma coisa é uma pergunta sobre todos eles**, e uma busca devolve os poucos mais próximos. Nem
uma busca perfeita com k = 3 conseguiria listar quatro documentos, e nada na saída dela diz que a lista
foi cortada.

O modelo, lendo só essas três, fez a pior coisa disponível: respondeu a pergunta sobre o corpus inteiro
a partir de três seções dele. *None of the documents mention a 14-day limit*, dito com confiança, é
falso quatro vezes. Depois informou, corretamente, o prazo legal de arrependimento de sete dias e os
trinta dias para livros impressos, que ninguém perguntou. Quem lê não tem como ver pela resposta que
ela foi construída sobre três seções de noventa e duas.

## Uma pergunta sobre tudo

```
ana@vm:~/rag$ python sections.py "Summarise all of our policies"
[1] 0.272  support-handbook > How we write
[2] 0.227  terms-of-sale > 10. Personal data
[3] 0.202  privacy-notice > What we collect
Yes, you can return a book.

To summarize our policies, we use your personal data as described in our privacy notice, which includes account data, order data, reading data, support data, and technical data. We store this data to provide you with a personalized experience and to improve our services.

For more information on our policies, including our terms of sale, please refer to our help centre articles:

* [1] How we write: This article explains our communication style and how we respond to customer inquiries.
* [2] Terms of sale > 10. Personal data: This article describes how we use your personal data.
* [3] Privacy notice > What we collect: This article provides a detailed overview of the types of personal data we collect and how we use it.

If you have any further questions or concerns, please don't hesitate to ask. We will respond again on [insert date, if applicable].
```

A melhor correspondência marcou 0,272, perto do piso, e a resposta é uma bagunça com cara de
resposta. Começa respondendo uma pergunta que ninguém fez, *Yes, you can return a book*; resume as
seções de privacidade que recebeu como se fossem todas as políticas; e termina prometendo *respond
again on [insert date, if applicable]*. Um resumo de todas as políticas precisa de todas as políticas
lidas. A ferramenta para isso é um processamento em lote que lê cada documento, resume, depois resume
os resumos, rodado quando os documentos mudam e guardado como qualquer outro documento. A aula 15
constrói o passo de resumir para conversas, e o mesmo método serve para documentos.

## Três tipos de pergunta que pertencem a outro lugar

| a pergunta | do que precisa | para onde vai |
| --- | --- | --- |
| *Quantos reembolsos fizemos em fevereiro?* | uma contagem sobre registros | uma consulta ao banco de dados |
| *Quais documentos falam de um limite de 14 dias?* | todos os documentos, exatamente | uma busca lexical sem corte |
| *Qual é o status do pedido MG-20481937?* | dados vivos sobre um registro | uma chamada de API |
| *Resuma todas as políticas* | o corpus inteiro, lido uma vez | um processamento em lote, guardado como documento |

A primeira e a terceira nem são sobre texto. A contagem de reembolsos mora no banco de pagamentos e o
status do pedido no sistema de pedidos, e os dois mudam a cada minuto. Copiá-los para documentos para
que um sistema de recuperação os ache dá números velhos com citações. O projeto certo chama o banco ou
a API diretamente, muitas vezes como uma ferramenta que o modelo pode usar, que é o assunto do curso
depois deste, o `agents-mcp`.

## Separando uma coisa da outra na prática

Um sistema que atende perguntas reais encontra todos esses tipos, então o trabalho não é recusá-los, e
sim encaminhá-los. Três sinais ajudam.

**A melhor nota é baixa.** Todas as perguntas desta seção tiveram nota máxima abaixo de 0,42, contra
0,72 da pergunta sobre fraude e 0,698 da pergunta sobre a entrega expressa na aula 1. Uma nota máxima
baixa diz que nada combinou bem, que é o caso que a aula 6 ensina uma busca a relatar.

**A pergunta pede uma contagem, uma lista, um total ou tudo de alguma coisa.** *Quantos*, *quais*,
*cada*, *todos*. Palavras assim marcam uma pergunta sobre o corpus ou sobre um banco de dados, e um
classificador, ou uma regra simples, pode mandá-la para outro lugar antes de a recuperação rodar.

**A resposta seria um número que muda todo dia.** Se a resposta verdadeira na semana que vem for
diferente da de hoje sem que nenhum documento tenha sido editado, a resposta nunca esteve num
documento.
