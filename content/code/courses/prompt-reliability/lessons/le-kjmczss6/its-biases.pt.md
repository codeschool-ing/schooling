---
title: Ordem e comprimento
version: 1
---

O kappa diz que o juiz é fraco. Não diz por quê. Os dois vieses que o substituto declara podem ser
medidos de fora, sem ler o código dele, e é assim que você os encontraria num juiz real.

## Posição

`--swap` faz cada pergunta duas vezes, a segunda com as respostas na ordem inversa, e traduz a
segunda resposta de volta:

```
ana@lab:~/triage$ pl judge cases/pairs.jsonl --swap
j01  human b  judge a  swapped a
j02  human b  judge b  swapped b
j03  human a  judge a  swapped b  FLIP
j04  human a  judge a  swapped a
j05  human b  judge b  swapped b
j06  human a  judge a  swapped a
j07  human b  judge a  swapped b  FLIP
j08  human a  judge a  swapped b  FLIP
j09  human b  judge b  swapped b
j10  human a  judge a  swapped b  FLIP
j11  human b  judge a  swapped b  FLIP
j12  human a  judge a  swapped a
j13  human b  judge a  swapped b  FLIP
j14  human b  judge b  swapped b
j15  human a  judge b  swapped b
j16  human a  judge b  swapped b

agrees with the human on 10 of 16
Cohen's kappa 0.25
changes its mind when the order is swapped: 6 of 16
agrees AND keeps its verdict: 7 of 16
```

Seis de dezesseis vereditos viram: `j03`, `j07`, `j08`, `j10`, `j11` e `j13`. Em todos o juiz
escolheu `a` quando `a` vinha primeiro e `b` quando `b` vinha primeiro. **Um veredito que muda quando
só a ordem muda é um veredito sobre a ordem.** Três desses seis, `j03`, `j08` e `j10`, tinham
concordado com a pessoa na primeira execução, e essa concordância foi um acaso de lugar.

## Comprimento

Os dez vereditos que sobrevivem à troca concordam com a pessoa sete vezes. Os três que sobrevivem e
continuam errados são `j01`, `j15` e `j16`:

```
ana@lab:~/triage$ python3 -c 'import json; [print(p["id"], p["human"], len(p["a"]), len(p["b"])) for p in map(json.loads, open("cases/pairs.jsonl"))]'
j01 b 274 137
j02 b 22 158
j03 a 151 220
j04 a 134 23
j05 b 225 135
j06 a 126 62
j07 b 199 47
j08 a 153 115
j09 b 24 177
j10 a 153 286
j11 b 231 115
j12 a 123 30
j13 b 211 113
j14 b 37 220
j15 a 107 187
j16 a 92 209
ana@lab:~/triage$ grep '"j16"' cases/pairs.jsonl
{"id": "j16", "message": "Do you buy second-hand books?", "a": "We don't, sorry, but the Bookswap in Market Street does, and it's two minutes from the shop.", "b": "Thank you for thinking of us! We're always delighted to hear from book lovers. Second-hand books are a wonderful way to give stories a new life, and there are many good places in town where you can sell yours.", "human": "a"}
```

Nos três a pessoa escolheu a resposta mais curta e o juiz a mais longa: 274 caracteres contra 137 em
`j01`, 187 contra 107 em `j15`, 209 contra 92 em `j16`. Em `j16`, `a` responde à pergunta e manda o
cliente a um lugar útil; `b` é calorosa e não diz nada. **Nenhuma troca pega esse viés, porque a
resposta mais longa é mais longa nas duas ordens.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas barras de 16 pares. Julgando numa ordem só, o juiz concorda com a pessoa em 10 e discorda em 6. Julgando nas duas ordens, ele muda de veredito com a ordem em 6; dos 10 que mantém, concorda em 7 e discorda em 3, e nos três escolheu a resposta mais longa.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o juiz do substituto em 16 pares com veredito humano</text><text x=\"138\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma ordem</text><rect x=\"150\" y=\"50\" width=\"298\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"50\" width=\"178\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"640\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16</text><text x=\"138\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as duas ordens</text><rect x=\"150\" y=\"112\" width=\"208\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"360\" y=\"112\" width=\"88\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"450\" y=\"112\" width=\"178\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"640\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M360 146 L360 152 L448 152 L448 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"404.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as três: a resposta mais longa</text><rect x=\"150\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"168\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">concorda com a pessoa</text><rect x=\"330\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"348\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">discorda</text><rect x=\"510\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"528\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">muda com a ordem</text></svg>", "caption": "Trocar a ordem remove os vereditos que dependiam da posição. Os três que sobrevivem e continuam errados são aqueles em que o juiz preferiu a resposta mais longa, o que nenhuma troca pega."}
```

## O que a literatura encontrou

Os vieses do substituto foram postos ali de propósito, e foram escolhidos porque juízes reais se
mostraram com eles. *Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena* (Zheng e outros, 2023)
documentou o viés de posição, a preferência pela resposta numa certa posição, e o viés de verbosidade,
a preferência pela resposta mais longa, em modelos de linguagem usados como juízes. O mesmo artigo
relatou que os vereditos de um modelo forte concordavam com as preferências humanas mais ou menos tanto
quanto as pessoas concordavam entre si, o que explica por que a técnica se espalhou, e por que os
vieses dela importam.

## O que os reduz

- **Pergunte nas duas ordens e fique só com os vereditos que concordam.** Trate uma virada como
  ausência de veredito. Aqui isso deixa dez vereditos, sete certos, em vez de dezesseis com dez certos.
- **Calibre contra pessoas antes**, na tarefa que o juiz vai fazer, e informe o kappa em vez da
  concordância bruta.
- **Meça a preferência por comprimento diretamente.** Conte com que frequência o juiz escolhe a
  resposta mais longa e compare com a frequência das pessoas; aqui o juiz escolheu a mais longa nos
  três erros estáveis.
- **Mantenha uma pessoa lendo uma amostra** dos vereditos do juiz enquanto ele estiver em uso, porque
  os hábitos de um juiz podem mudar quando o modelo dele muda.
