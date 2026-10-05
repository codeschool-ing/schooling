---
title: Mude uma coisa e conte o que se move
version: 1
---

Taxas por grupo dizem que algo está desigual. Não dizem o que causa isso, e precisam de centenas de
decisões antes de dizer qualquer coisa. **Um teste contrafactual faz uma pergunta mais estreita sobre
cada decisão**: se esta pessoa fosse igual em tudo menos numa coisa, o sistema decidiria diferente?
Mude o campo, mantenha o resto, rode o sistema de novo e conte as decisões que mudam.

O `guard counterfactual` faz isso com os perfis da primeira seção. Ele leva todo CEP do Sudeste para
Recife, `50010-000`, e todo CEP do Nordeste para São Paulo, `01310-100`. A nota e o número de
trabalhos ficam como estavam:

```
ana@lab:~/guard$ guard counterfactual data/profiles.jsonl
who      region    cep        score   swapped    score
fr-0101  Sudeste   04538-133   6.70   50010-000   5.70  FLIP: shortlisted -> out
fr-0102  Sudeste   20040-020   5.70   50010-000   4.70
fr-0103  Sudeste   30130-010   6.15   50010-000   5.15  FLIP: shortlisted -> out
fr-0104  Sudeste   01310-100   6.30   50010-000   5.30  FLIP: shortlisted -> out
fr-0105  Sudeste   22071-900   5.50   50010-000   4.50
fr-0106  Sudeste   13010-111   5.60   50010-000   4.60
fr-0107  Sudeste   29010-120   5.30   50010-000   4.30
fr-0108  Sudeste   05407-002   7.70   50010-000   6.70
fr-0201  Nordeste  50010-000   5.55   01310-100   6.55  FLIP: out -> shortlisted
fr-0202  Nordeste  40020-000   4.90   01310-100   5.90
fr-0203  Nordeste  60060-440   6.15   01310-100   7.15
fr-0204  Nordeste  57020-050   5.50   01310-100   6.50  FLIP: out -> shortlisted
fr-0205  Nordeste  59012-300   4.20   01310-100   5.20
fr-0206  Nordeste  64000-020   5.05   01310-100   6.05  FLIP: out -> shortlisted
fr-0207  Nordeste  49010-030   5.60   01310-100   6.60  FLIP: out -> shortlisted
fr-0208  Nordeste  58013-420   6.90   01310-100   7.90
7 of 16 decisions changed when only the CEP did (Sudeste 3, Nordeste 4)
```

Sete decisões em dezesseis mudaram, e nada além do CEP mudou com elas. O `fr-0101` cai de 6.70 para
5.70 e sai da lista; o `fr-0207` sobe de 5.60 para 6.60 e entra. Essa frase é a prova de que um pedido
de revisão precisa, e ela nomeia a causa, coisa que as taxas por grupo nunca fizeram. Perfis longe do
limiar, como o `fr-0108` com 7.70, não mudam: o bônus moveu o score e não o resultado. Um teste que
contasse só as mudanças de decisão subestimaria o efeito, e é por isso que a ferramenta imprime os
dois scores.

## Rodando contra um modelo de linguagem

O scorer do laboratório é determinístico, então uma execução por perfil basta. Um modelo de linguagem
não é, e o mesmo teste precisa de três mudanças para valer alguma coisa contra um:

- **Pares que diferem numa coisa só.** Dois currículos idênticos menos o nome, com os nomes escolhidos
  para diferir no atributo testado e o mínimo possível no resto: tamanho parecido, frequência
  parecida. Um CEP, uma cidade ou uma expressão de uma região do Brasil são o mesmo teste mirando outro
  proxy.
- **Muitas amostras de cada.** Com amostragem ligada, um prompt dá respostas diferentes em execuções
  diferentes, então uma mudança isolada não prova nada. Cada lado do par roda muitas vezes e as duas
  distribuições são comparadas, com um teste que diz se a diferença é maior que o ruído entre
  execuções. A aula 13 automatiza testes adversariais exatamente nesse formato, e o curso
  `prompt-reliability` mede a variação entre execuções.
- **Uma decisão para contar.** "Pré-selecionado ou não", um score, uma categoria: algo em que o par
  possa discordar. Texto livre precisa ser reduzido a uma dessas coisas antes, ou a comparação vira
  questão de opinião.

Dois limites vêm com o método. Ele acha viés **pelo campo que você pensou em mudar**, então um proxy de
que ninguém suspeitou fica escondido; as taxas por grupo das seções anteriores é que pegam esses, por
olharem os resultados sem teoria. E um nome trocado pode mudar mais do que o atributo para o qual foi
escolhido, e é por isso que os pares são escolhidos com cuidado e os resultados são lidos como
evidência, não como prova.
