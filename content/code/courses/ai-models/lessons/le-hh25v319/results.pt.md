---
title: Lendo as notas
version: 1
---

O `evalkit report` lê uma execução de volta e imprime uma linha por modelo:

```
ana@desk:~/desk$ python lab/evalkit.py report runs/triage.jsonl
model           strict   loose     loose, 95%  p50 s  $ per 1k
standin-large    38/40   38/40     83% to  99%   0.70    0.2001
standin-small    32/40   34/40     71% to  93%   0.21    0.0167
standin-local    32/40   32/40     65% to  90%   1.04    0.0000
```

Leia da esquerda para a direita.

**strict e loose.** O standin-large classificou 38 de 40, e escreveu toda resposta de forma limpa.
O standin-small escolheu certo 34 vezes e escreveu 32 delas exatamente na forma que o programa
quer. O standin-local escolheu certo 32 vezes, de forma limpa.

**O intervalo.** 38 de 40 é 95%, e com quarenta casos a afirmação honesta é que a taxa verdadeira
está **em algum lugar entre 83% e 99%**. Esse é o intervalo de Wilson com 95% de confiança, a função
`wilson` da seção 05, e é a coluna mais importante da tabela. Os 34 do standin-small ficam entre 71% e
93%, os 32 do standin-local entre 65% e 90%. **Os três intervalos se sobrepõem.** Com quarenta casos
esses números não provam que nenhum dos três é melhor que os outros.

**Velocidade e custo**: o tempo mediano por requisição e o custo de mil requisições pelos preços do
curso. O standin-large custa umas doze vezes o que o standin-small custa por requisição; o
standin-local não custa nada por requisição porque o custo dele é uma máquina (aula 3).

## Fazendo a pergunta mais afiada

Os intervalos respondem "quão bom é cada modelo". Uma pergunta mais afiada é "**nos mesmos casos,
qual ganha**", porque os dois modelos responderam aos mesmos quarenta e-mails. A maioria dos casos
está certa para os dois ou errada para os dois e não diz nada sobre a diferença. Só os casos em que
exatamente um acertou dizem:

```
ana@desk:~/desk$ python lab/evalkit.py compare runs/triage.jsonl standin-large standin-small
only standin-large right: 4 ['c22', 'c26', 'c31', 'c37']
only standin-small right: 0 []
chance of a split at least this uneven if they were equally good: 0.125
```

Quatro casos em que só o standin-large acertou, nenhum no sentido contrário. Se os dois modelos fossem
igualmente bons, cada um desses quatro seria cara ou coroa, e quatro caras seguidas saem **uma vez em
oito**: o `0.125` da última linha. Isso sugere, mas não conclui; a convenção é querer uma vez em vinte,
ou mais raro, antes de chamar de diferença. A mesma comparação entre o modelo pequeno e o local:

```
ana@desk:~/desk$ python lab/evalkit.py compare runs/triage.jsonl standin-small standin-local
only standin-small right: 3 ['c06', 'c30', 'c34']
only standin-local right: 1 ['c37']
chance of a split at least this uneven if they were equally good: 0.625
```

Três a um. Divisões assim acontecem por acaso na maior parte das vezes (`0.625`), então nestes casos
os dois **não se distinguem**, mesmo um tendo tirado 34 e o outro 32.

## O que a ana tira disso

- **O standin-large provavelmente é melhor** em classificar que o standin-small, por uma margem que
  quarenta casos não conseguem fixar. Quatro casos em quarenta são 10%; se a caixa de entrada fosse
  como o conjunto, seriam quarenta dos 400 e-mails do dia movidos à mão.
- **Mais casos resolveriam, devagar.** Um intervalo estreita com a raiz quadrada do número de casos:
  quatro vezes mais casos cortam a largura pela metade. O movimento mais barato muitas vezes é
  acrescentar casos parecidos com aqueles em que os modelos discordam, que são os que os separam.
- **A decisão não é só acurácia.** A seção 10 põe o preço e o piso da aula 4 de volta ao lado destes
  números.
