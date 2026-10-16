---
title: Depois de um defeito, antes de a correção ser esquecida
version: 1
---

**A análise de causa raiz é o trabalho de descobrir por que um defeito foi possível, para o próximo parecido não
ser.** Corrigir um defeito o remove. Entender por que ele aconteceu remove as condições que o produziram, e essas
condições em geral continuam lá, esperando para produzir o próximo em outra parte do programa.

É a prevenção da aula 1, aplicada depois do fato. Todo defeito que escapou é evidência sobre como o time trabalha,
e a aula 12 pôs a pergunta no centro da retrospectiva: **por que isso foi possível?** Esta aula dá a essa pergunta
dois métodos, os cinco porquês e o diagrama de Ishikawa.

## Nem todo defeito merece uma

Uma análise de causa raiz toma uma ou duas horas de várias pessoas. O Cine Aurora a faz para defeitos que cumprem
qualquer uma de três condições:

- **chegou a um cliente**, como a sessão das 9:30 de domingo da aula 4;
- **custou dinheiro ou confiança**, como os pedidos recusados que ainda contavam no relatório noturno de assentos
  da aula 8;
- **é o segundo do seu tipo**, o que diz que a causa sobreviveu à primeira correção.

Um erro de digitação pego na revisão é corrigido e esquecido, e isso está certo. Uma análise que roda sobre tudo
vira um formulário que as pessoas preenchem, e um formulário que as pessoas preenchem não acha nada.

## Sem culpados, ou sem utilidade

A regra mais importante da análise de causa raiz é sobre pessoas: **a análise procura causas no sistema, não alguém
para culpar.** Não é gentileza. É método.

Pergunte "quem escreveu a linha que comparou horários como texto?" e a resposta é *o Rafael*, e a análise acabou. O
Rafael vai tomar mais cuidado por um mês, e as condições que deixaram um desenvolvedor razoável escrever aquela linha
continuam intactas. Pergunte "por que era razoável escrever aquela linha?" e a análise está só começando: ninguém
tinha dito como os horários das sessões eram digitados, nenhum exemplo tinha hora de um dígito, e a pessoa que
digitava a programação nunca esteve na conversa.

A culpa também destrói a evidência. Um time punido por defeitos aprende a escondê-los, relatá-los tarde, ou discutir
se são mesmo defeitos. Um time a quem se pergunta *como o nosso processo deixou isso passar?* fala do que aconteceu,
que é o único material que uma análise tem.

## Comece com uma declaração precisa do problema

Uma análise começa com uma frase que diz o que deu errado, em fatos, sem causas dentro. Compare:

| vaga | precisa |
|---|---|
| "os preços estavam quebrados" | "no primeiro domingo da sessão das 9:30, um pedido de quatro ingressos foi cobrado pelo preço da noite, R$ 108,00 em vez de R$ 84,00" |
| "o código do Rafael tinha um bug" | "`price()` devolve o preço da noite para qualquer horário de sessão escrito com hora de um dígito" |

A versão precisa diz o quê, quando, quanto e com que frequência, e não nomeia ninguém. Cada passo seguinte se confere
contra ela.
