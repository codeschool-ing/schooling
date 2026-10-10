---
title: A menor reprodução
version: 1
---

**Um defeito que não se reproduz não pode ser corrigido com confiança nenhuma, porque ninguém consegue
dizer se a correção funcionou.** Então o último passo de uma investigação é reduzi-la ao menor conjunto de
passos que mostra o defeito, toda vez, na máquina de qualquer pessoa. Isso é uma **reprodução**, e as
pequenas valem muito mais que as longas.

## Menor é melhor, e eis quão pequena

A compra da família envolvia quatro pessoas, duas idades, um domingo, uma sessão e um site. A evidência
mostrou que só uma dessas coisas importava. A menor reprodução que a Lia escreveu para o Rafael foi esta:

```
lia@lab:~/aurora$ python tickets.py 35 no thu 09:30
R$ 28,00
lia@lab:~/aurora$ python tickets.py 35 no thu 9:30
R$ 36,00
```

Dois comandos. Um adulto, qualquer dia, o mesmo momento escrito de dois jeitos, dois preços diferentes.
Tudo o que não importava foi removido: as crianças, o domingo, a família, o site. **Cada coisa que você
remove é uma hipótese que você descartou**, e quem lê uma reprodução de duas linhas sabe que os outros
detalhes foram conferidos e eram irrelevantes.

Um teste útil para uma reprodução: alguém que nunca ouviu falar do problema conseguiria rodá-la e vê-lo sem
te fazer uma pergunta? O Rafael conseguiu. A história da família, entregue do jeito que chegou, teria
começado uma conversa.

## O que vai junto

Uma reprodução é o centro de um relato de defeito, não ele inteiro. O resto é curto e cada parte se paga:

- **o que você esperava**, e por quê: *R$ 28,00 para os dois, porque os dois são antes das 17:00 e a regra
  diz que uma sessão antes das 17:00 é matinê;*
- **o que aconteceu no lugar**, copiado, nunca parafraseado: *R$ 36,00 para `9:30`*;
- **de onde veio**, para que alguém possa julgar quanto importa: *uma família foi cobrada R$ 24,00 a mais no
  domingo; toda sessão antes das 10:00 é afetada, e daqui em diante há uma todo domingo;*
- **o que você descartou**, em poucas palavras: *não é o dia, não é a idade, não é a hora em si.*

Escrever um relato de defeito completo, com severidade, prioridade e os campos pelos quais os times os
acompanham, é a aula 15 de `manual-testing`. O que cabe aqui é o hábito por baixo disso: **evidência
primeiro, copiada exatamente, e a menor versão dela que você conseguir achar.**

## Quando não reproduz

Alguns defeitos acontecem uma vez em dez, ou só numa máquina, ou só no primeiro domingo do mês. O método
não muda; a evidência fica mais difícil de juntar.

- **Conte em vez de descrever.** "Às vezes falha" não é evidência. "Falhou 3 vezes em 50 execuções" é, e
  permite dizer depois se uma mudança o tornou mais raro.
- **Procure o que difere entre as execuções que falham e as que passam.** A hora do dia, a ordem dos
  passos, os dados que já estavam lá, o que mais estava rodando. Cada diferença é uma hipótese.
- **Anote o que você tentou mesmo quando não reproduziu.** Um registro do que foi descartado poupa a
  próxima pessoa de descartar de novo.

Um defeito que se recusa a reproduzir não é prova de que ele é imaginário. A Célia viu o que viu. É prova
de que uma das condições ainda não foi achada, e o trabalho de quem testa é continuar procurando com
experimentos que possam provar que ela está errada.
