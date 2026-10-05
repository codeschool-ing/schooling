---
title: Anotar os limites
version: 1
---

Antes de olhar um único modelo, a ana anota o que qualquer modelo precisa fazer. É um arquivo curto
no projeto, e é a única defesa contra escolher pela tabela que ela calhar de ler primeiro:

| exigência | por quê | tipo |
|---|---|---|
| devolve JSON válido segundo um esquema | a tarefa de extração alimenta outro programa | limite |
| janela de pelo menos 32.000 tokens | a tarefa de rascunho manda a política da loja, uns 5.000 tokens, e conversas longas | limite |
| processamento permitido para e-mail de cliente pelos termos da loja | aula 2 seção 07 | limite |
| lê e escreve bem em português | os clientes escrevem nele | limite, medido na aula 5 |
| classifica pelo menos 35 de 40 casos como uma pessoa classificaria | abaixo disso, uma pessoa precisa conferir tudo de qualquer jeito | limite, medido na aula 5 |
| custa o menos possível | a loja é pequena | ordenação |
| responde rápido o bastante para um atendente esperando um rascunho não desistir | fica na frente de uma pessoa | ordenação, com teto |

Algumas dessas dá para conferir na tabela na hora. O `sheet pick` filtra toda entrada de chat com
preço; `--needs` e `--min-window` aplicam dois dos limites dela:

```
ana@desk:~/desk$ sheet pick | sed -n 2p
2990 entries pass
ana@desk:~/desk$ sheet pick --needs response_schema --min-window 32000 | sed -n 2p
1617 entries pass
ana@desk:~/desk$ sheet pick --needs response_schema --min-window 32000 --max-in 1 | sed -n 2p
893 entries pass
```

De 2.990 entradas de chat com preço, os dois limites deixam **1.617**: saída estruturada e uma janela
de 32.000 tiram quase metade. O terceiro comando acrescenta um teto de US$ 1 por milhão de tokens de
entrada, que não é um dos limites dela e está ali para mostrar o que acontece quando uma preferência
vira filtro: **893**, e os mais baratos dessa lista são entradas de que ela nunca ouviu falar, a
preços que parecem erro.

## O que a tabela não consegue filtrar

Três das sete linhas acima não estão em tabela nenhuma: se os termos permitem o uso dela, se o
português é bom, e a acurácia nos casos dela. A primeira é um documento a ler para cada provedor
(aula 2). As outras duas são medições, e as 1.617 entradas da tabela são demais para medir.

Então a ana estreita à mão até uma **lista curta**: um punhado de modelos de provedores cujos termos
ela leu, pelo menos um modelo de pesos abertos pela opção que a aula 3 pediu para ela manter,
espalhados em faixas de preço. A seção 08 mostra a dela. A lista curta é um julgamento, e é o único
lugar deste método em que julgamento é o certo: a medição que vem depois corrige uma má escolha de
candidatos, desde que sejam vários.
