---
title: Ordem e comprimento
version: 2
---

O kappa diz que o juiz é fraco. Não diz por quê. Dois vieses são conhecidos em modelos juízes, e
cada um pode ser medido de fora, sem ler nada além dos vereditos, que é como você os acharia em
qualquer juiz.

## Posição

O `--swap` faz cada pergunta duas vezes, a segunda com as respostas na outra ordem, e traduz a
segunda resposta de volta para a resposta que ela escolheu:

```
ana@lab:~/triage$ python3 judge.py cases/pairs.jsonl --swap
j01  human b  judge b  swapped a  FLIP
j02  human b  judge b  swapped b
j03  human a  judge b  swapped a  FLIP
j04  human a  judge a  swapped a
j05  human b  judge b  swapped a  FLIP
j06  human a  judge b  swapped a  FLIP
j07  human b  judge b  swapped a  FLIP
j08  human a  judge b  swapped a  FLIP
j09  human b  judge b  swapped ?  FLIP
j10  human a  judge b  swapped a  FLIP
j11  human b  judge b  swapped a  FLIP
j12  human a  judge ?  swapped a  FLIP
j13  human b  judge b  swapped a  FLIP
j14  human b  judge b  swapped b
j15  human a  judge b  swapped a  FLIP
j16  human a  judge b  swapped b

agrees with the human on 9 of 16
Cohen's kappa 0.18
changes its mind when the order is swapped: 12 of 16
agrees AND keeps its verdict: 3 of 16
```

**Doze de dezesseis vereditos mudam.** Leia as duas colunas juntas: na primeira ordem o juiz
escolheu `b`, a resposta mostrada em segundo, treze vezes; com a ordem trocada escolheu `a`, que agora
era a mostrada em segundo, doze vezes. O que quer que ele esteja lendo, está lendo sobretudo a
posição. **Um veredito que muda quando só a ordem muda é um veredito sobre a ordem.** Dos oito
pares em que ele concordou com a pessoa na primeira execução, só três mantêm o veredito nas duas
ordens.

Olhe a coluna `judge` também. Ela é a primeira pergunta feita de novo, o mesmo prompt com
temperatura 0, e deveria ser a execução de cima linha por linha. Não é: o `j05` foi `?` da primeira
vez e `b` desta vez, então a concordância foi de 8 para 9 e o kappa de 0,11 para 0,18. É o achado da
aula 8 sobre a temperatura 0, dentro de um instrumento de medida. Um juiz cujo veredito sobre um par
depende do que lhe perguntaram logo antes é um juiz cujos números têm uma margem, e dezesseis pares
não bastam para ver de que tamanho.

## Comprimento

Quatro vereditos sobrevivem à troca: `j02`, `j04`, `j14` e `j16`. Estes são os comprimentos das
respostas:

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
```

Nos quatro, o juiz escolheu a resposta mais longa: 158 caracteres contra 22 no `j02`, 134 contra 23
no `j04`, 220 contra 37 no `j14`, 209 contra 92 no `j16`. A pessoa concordou três vezes, porque em
três desses pares a resposta longa era a útil. O `j16` é o quarto:

```
ana@lab:~/triage$ grep '"j16"' cases/pairs.jsonl
{"id": "j16", "message": "Do you buy second-hand books?", "a": "We don't, sorry, but the Bookswap in Market Street does, and it's two minutes from the shop.", "b": "Thank you for thinking of us! We're always delighted to hear from book lovers. Second-hand books are a wonderful way to give stories a new life, and there are many good places in town where you can sell yours.", "human": "a"}
```

O `a` responde à pergunta e manda o cliente a um lugar útil; o `b` é caloroso e não diz nada.
**Nenhuma troca consegue pegar esse viés, porque a resposta mais longa é mais longa nas duas
ordens.** Quatro vereditos estáveis são pouquíssimos para medi-lo: o conjunto tem nove pares em que
a resposta mais longa é a pior, e só o `j16` sobreviveu à troca.

## O que a literatura achou

*Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena* (Zheng e outros, 2023) documentou o viés
de posição, uma preferência pela resposta numa certa posição, e o viés de prolixidade, uma
preferência pela resposta mais longa, em modelos de linguagem usados como juízes. O mesmo artigo
relatou que os vereditos de um modelo forte concordavam com preferências humanas mais ou menos tanto
quanto pessoas concordavam entre si, que é por que a técnica se espalhou, e por que os vieses dela
importam. Um modelo de três bilhões de parâmetros não é o modelo forte que aquele artigo mediu, e
esta aula mostra como fica essa diferença.

## O que os reduz

- **Pergunte nas duas ordens e fique só com os vereditos que concordam.** Trate uma troca como
  nenhum veredito. Aqui isso deixa quatro vereditos, três deles certos, em vez de dezesseis com
  oito certos.
- **Calibre contra pessoas primeiro**, na tarefa que o juiz vai fazer, e relate o kappa em vez da
  concordância bruta.
- **Meça a preferência por comprimento diretamente.** Conte quantas vezes o juiz escolhe a resposta
  mais longa, e compare com quantas vezes as pessoas escolhem.
- **Leia as respostas do juiz, não só as letras dele.** Um juiz mandado responder *A ou B e nada
  mais* ainda respondeu com nenhuma das duas duas vezes, e o parser dele tem de dizer o que faz
  nesse caso.
- **Mantenha uma pessoa lendo uma amostra** dos vereditos do juiz enquanto ele estiver em uso,
  porque os hábitos de um juiz podem mudar quando o modelo dele muda.
