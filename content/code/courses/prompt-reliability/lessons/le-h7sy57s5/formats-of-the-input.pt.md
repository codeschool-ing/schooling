---
title: O formato do que você põe no prompt
version: 2
---

A redação das instruções é uma coisa que você pode variar. Os dados que você põe no prompt são a
outra: um registro de pedido, uma lista de produtos, as últimas três mensagens do mesmo cliente. **Os
mesmos fatos podem entrar como prosa, como tabela ou como JSON**, e não custam o mesmo:

```
ana@lab:~/triage$ echo 'Order 4471: 2 paperbacks, paid 24.50 on 2026-08-03, sent by courier.' | python3 tokens.py -
28 tokens, 11 words, 69 characters
ana@lab:~/triage$ echo '{"order": "4471", "items": 2, "format": "paperback", "paid": 24.50, "date": "2026-08-03", "sent": "courier"}' | python3 tokens.py -
46 tokens, 12 words, 109 characters
ana@lab:~/triage$ printf 'order,items,format,paid,date,sent\n4471,2,paperback,24.50,2026-08-03,courier\n' | python3 tokens.py -
33 tokens, 2 words, 76 characters
```

Um pedido, de três jeitos, em tokens do `llama3.2:3b`: 28 como frase, 46 como JSON e 33 como tabela
com uma linha de cabeçalho. O JSON paga por cada chave e cada aspa, em cada registro. Uma tabela paga
pelo cabeçalho uma vez, então a parte dele cai a cada linha que você acrescenta. A prosa é a mais
barata aqui e a mais difícil de manter consistente em mil registros, e um campo que falta numa frase
é difícil de notar.

## Escolhendo

**Escolha um formato que o modelo e uma pessoa consigam ler**, porque uma pessoa vai estar depurando
o prompt quando ele falhar. Para registros com os mesmos campos, uma tabela é compacta. Para dados
aninhados, ou valores com vírgulas e quebras de linha, o JSON diz exatamente onde cada valor termina.
Para um contexto curto, uma frase basta.

Depois, se a escolha puder importar, meça, do mesmo jeito das duas últimas seções: uma mudança, o
mesmo conjunto de teste, os mesmos parâmetros, `pl compare`, e o `--answers` além do total. A seção
anterior é o motivo da última parte: **uma diferença que você não testou é uma diferença que você
não conhece**, e o total é justamente onde uma mudança de formato se esconde.
