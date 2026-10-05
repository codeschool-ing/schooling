---
title: Quando ele se paga
version: 1
---

Uma máquina é paga por hora, ocupada ou não. Uma API é paga por token e não custa nada quando
ninguém a chama. Então a comparação não é "qual é mais barato", e sim **em que volume os dois custam
o mesmo**.

Primeiro, o tamanho das requisições da ana. O programa dela manda cada um dos quarenta casos ao
substituto e lê o `usage` que a API devolve, que conta os tokens que a requisição de fato usou:

```
ana@desk:~/desk$ python lab/volume.py
40 e-mails: 58.7 tokens in, 1.6 out, on average
```

Uns 59 tokens de entrada (o prompt de três linhas dela mais um e-mail) e menos de dois de saída,
porque um rótulo é uma palavra ou duas. As respostas do substituto foram escritas pelo curso; **as
contagens são reais**, feitas com o mesmo tokenizador para todos os casos.

O `lab/breakeven.py` pega esses números, arredondados para cima, 59 de entrada e 2 de saída, os
preços de um modelo na tabela e o custo mensal de uma máquina. A Lantern Books recebe uns 400
e-mails por dia, e a máquina custa US$ 1.500 por mês: os dois são suposições do curso, redondas
o bastante para serem lidas como tais.

```
ana@desk:~/desk$ python lab/breakeven.py claude-haiku-4-5 1500
claude-haiku-4-5: $69 per million requests
  ana's 400 a day: $0.83 a month
  a $1,500 machine pays for itself at 724,638 requests a day
```

**Oitenta e três centavos de dólar por mês.** A 400 e-mails por dia, toda a carga de classificação da
Lantern Books custa menos que um café no modelo mais barato que a tabela lista para a Anthropic, e
uma máquina teria de classificar **724.638 e-mails por dia** para custar o mesmo. Agora o Claude Opus
5.5, a que a tabela dá quatro vezes esse preço por token:

```
ana@desk:~/desk$ python lab/breakeven.py claude-opus-5-5 1500
claude-opus-5-5: $276 per million requests
  ana's 400 a day: $3.31 a month
  a $1,500 machine pays for itself at 181,159 requests a day
```

Quatro vezes o custo por requisição, e ainda **US$ 3,31 por mês**. O volume de equilíbrio cai para
181.159 por dia, que é umas 450 vezes o que a loja recebe.

## O formato da resposta

A conta aqui é sobre uma tarefa pequena: poucos tokens de entrada, quase nenhum de saída. Mude
qualquer um deles e o equilíbrio se move:

- **prompts longos ou respostas longas** multiplicam o custo por requisição, e o volume de
  equilíbrio cai na mesma proporção;
- **volume alto e constante** mantém a máquina ocupada, que é o único jeito de ela sair barata por
  token (seção 05);
- **uma carga em rajadas** pede uma máquina dimensionada para o pico e paga no vale.

Para a ana, a resposta em dinheiro nem chega perto. **Auto-hospedar ainda pode ser certo para ela**,
mas não pelo custo, e a seção 08 lista os motivos que não são sobre dinheiro.
