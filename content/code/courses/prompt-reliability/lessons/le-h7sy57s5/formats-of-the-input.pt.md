---
title: O formato do que você coloca dentro
version: 1
---

A redação das instruções é uma coisa que você pode variar. Os dados que você põe no prompt são a
outra: um registro de pedido, uma lista de produtos, as três últimas mensagens do mesmo cliente.
**Os mesmos fatos podem entrar como prosa, como tabela ou como JSON**, e não custam o mesmo.

```
ana@lab:~/triage$ echo 'Order 4471: 2 paperbacks, paid 24.50 on 2026-08-03, sent by courier.' | pl tokens -
21 tokens, 11 words, 69 characters
ana@lab:~/triage$ echo '{"order": "4471", "items": 2, "format": "paperback", "paid": 24.50, "date": "2026-08-03", "sent": "courier"}' | pl tokens -
51 tokens, 12 words, 109 characters
ana@lab:~/triage$ printf 'order,items,format,paid,date,sent\n4471,2,paperback,24.50,2026-08-03,courier\n' | pl tokens -
28 tokens, 2 words, 76 characters
```

Um pedido, de três jeitos, em tokens do laboratório: 21 como frase, 51 como JSON e 28 como tabela com
linha de cabeçalho. O JSON paga por cada chave e cada aspa, em cada registro. Uma tabela paga o
cabeçalho uma vez, então a parte dele cai a cada linha que você acrescenta. A prosa é a mais barata
aqui e a mais difícil de manter consistente em mil registros, e um campo que falta numa frase é
difícil de notar.

## Escolher

**Escolha um formato que o modelo e uma pessoa consigam ler**, porque uma pessoa vai depurar o
prompt quando ele falhar. Para registros com os mesmos campos, uma tabela é compacta. Para dados
aninhados, ou valores que contêm vírgulas e quebras de linha, o JSON diz exatamente onde cada valor
termina. Para um trecho curto de contexto, uma frase basta.

Depois, se a escolha puder importar, meça, do mesmo jeito das duas últimas seções: uma mudança, o
mesmo conjunto de teste, os mesmos parâmetros, e `pl compare`. **Este laboratório não consegue
mostrar o efeito de um formato de entrada nas respostas**, porque o substituto classifica por
palavras-chave e lê um valor do mesmo jeito, seja qual for o entorno. Modelos reais não são tão
indiferentes. *Quantifying Language Models' Sensitivity to Spurious Features in Prompt Design*
(Sclar e outros, 2023) mudou só a formatação de prompts few-shot, como separadores, espaçamento e
maiúsculas, e relatou diferenças de acurácia de até 76 pontos num modelo, o LLaMA-2-13B. A
recomendação dos autores foi relatar o desempenho de um prompt numa faixa de formatos plausíveis, e
não no único que alguém por acaso escreveu.

É a lição dos blocos de código do substituto numa escala maior: **uma diferença que você não testou
é uma diferença que você não conhece**, e uma mudança de formato é uma mudança.
