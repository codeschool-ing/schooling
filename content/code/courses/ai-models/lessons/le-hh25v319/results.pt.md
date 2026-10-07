---
title: Lendo as notas
version: 1
---

O `evalkit report` lê uma execução de volta e imprime uma linha por modelo:

```
ana@desk:~/desk$ python evalkit.py report runs/triage.jsonl
model         strict   loose     loose, 95%  p50 s  out tok
llama3.2:3b    18/40   19/40     33% to  63%   0.92      4.9
qwen2.5:3b     30/40   30/40     60% to  86%   0.84      2.7
llama3.2:1b     4/40    5/40      5% to  26%   0.86      9.2
```

Leia da esquerda para a direita.

**strict e loose.** O qwen2.5:3b classificou 30 de 40, todos escritos certinho. O llama3.2:3b
escolheu o rótulo certo 19 vezes e escreveu 18 deles exatamente na forma que o programa quer. O
llama3.2:1b acertou 5. A coluna **out tok** é uma pista para a seção 07: um rótulo é um ou dois
tokens, e os dois modelos Llama escreveram bem mais que isso em média, então estavam escrevendo
outra coisa que não um rótulo.

**O intervalo.** 30 de 40 é 75%, e com quarenta casos o honesto é dizer que a taxa verdadeira está
**em algum ponto entre 60% e 86%**. Esse é o intervalo de Wilson a 95% de confiança, a função
`wilson` da seção 05, e é a coluna mais importante da tabela. Os 19 do llama3.2:3b ficam entre 33%
e 63%, e os 5 do llama3.2:1b entre 5% e 26%. **O intervalo do qwen2.5:3b não encosta no do
llama3.2:1b**, então essa diferença é real; o dele e o do llama3.2:3b se sobrepõem de 60% a 63%,
então a tabela sozinha não resolve essa.

**Velocidade**: o tempo mediano por requisição, abaixo de um segundo para os três nesta máquina. A
aula 4 seção 06 mediu os mesmos modelos escrevendo rascunhos, em que a resposta é longa e a
diferença aparece; uma resposta de um rótulo é curta demais para o tamanho pesar.

## Fazendo a pergunta mais afiada

Os intervalos respondem "quão bom é cada modelo". Uma pergunta mais afiada é "**nos mesmos casos,
qual ganha**", porque os modelos responderam os mesmos quarenta e-mails. A maioria dos casos é
certa para os dois ou errada para os dois e não diz nada sobre a diferença. Só os casos em que
exatamente um acertou dizem:

```
ana@desk:~/desk$ python evalkit.py compare runs/triage.jsonl qwen2.5:3b llama3.2:3b
only qwen2.5:3b right: 16 ['c04', 'c07', 'c09', 'c13', 'c14', 'c15', 'c16', 'c19', 'c21', 'c22', 'c28', 'c29', 'c33', 'c37', 'c38', 'c39']
only llama3.2:3b right: 5 ['c01', 'c06', 'c11', 'c36', 'c40']
chance of a split at least this uneven if they were equally good: 0.027
```

Dezesseis casos em que só o qwen2.5:3b acertou, cinco ao contrário. Se os dois modelos fossem
igualmente bons, cada um desses vinte e um seria cara ou coroa, e uma divisão pelo menos tão
desigual sai **umas três vezes em cem**: o `0.027` da última linha. A convenção é querer uma vez em
vinte, 0,05, ou mais raro antes de chamar de diferença, e isto passa. A mesma comparação entre os
dois modelos Llama:

```
ana@desk:~/desk$ python evalkit.py compare runs/triage.jsonl llama3.2:3b llama3.2:1b
only llama3.2:3b right: 16 ['c02', 'c03', 'c05', 'c06', 'c08', 'c12', 'c17', 'c18', 'c20', 'c23', 'c25', 'c27', 'c30', 'c31', 'c36', 'c40']
only llama3.2:1b right: 2 ['c15', 'c16']
chance of a split at least this uneven if they were equally good: 0.001
```

Dezesseis a dois, `0.001`: o 3b é melhor que o 1b, por uma margem que quarenta casos resolvem.

## O que a ana tira disso

- **O qwen2.5:3b classifica melhor que o llama3.2:3b**, nestes casos, por uma margem que a
  comparação pareada sustenta mesmo com os intervalos se tocando. O modelo que o curso instala para
  tudo não é o melhor classificador dos e-mails da Lantern Books, e só os casos dela podiam dizer
  isso.
- **Nenhum dos três chega ao piso dela.** A aula 4 o escreveu como 35 de 40; o melhor aqui é 30. A
  seção 10 diz o que isso significa.
- **Mais casos estreitariam todos os intervalos, devagar.** Um intervalo estreita com a raiz
  quadrada do número de casos: quatro vezes mais casos cortam a largura pela metade. O movimento
  mais barato costuma ser acrescentar casos como os que dividem os modelos, que são os que os
  separam.
