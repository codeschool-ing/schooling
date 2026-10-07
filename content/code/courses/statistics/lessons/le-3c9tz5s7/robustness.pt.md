---
title: Um erro de digitação e dois resumos
version: 1
---

Alguém digita a cesta do pedido H-1048 como R$ 2.126,00 em vez de R$ 212,60: uma vírgula fora do lugar. O
que acontece com os resumos das doze cestas?

| | correto | com o erro |
|---|---|---|
| média | R$ 79,17 | R$ 238,62 |
| mediana | R$ 68,20 | R$ 68,20 |

A média triplica. A mediana não se mexe, porque H-1048 era a maior cesta antes do erro e continua sendo
a maior depois. A mediana só se importa com ela estar acima do meio.

## O ponto de ruptura

Os estatísticos medem essa resistência com o **ponto de ruptura**: a fração dos dados que precisaria
estar errada, em qualquer quantidade, para que um resumo pudesse ser empurrado tão longe quanto se
quisesse.

- **A média rompe com um valor.** Faça uma única cesta grande o bastante e a média vai para onde você
  empurrar. Com *n* valores, o ponto de ruptura é 1 em *n*, que encolhe rumo a zero conforme os dados
  crescem.
- **A mediana rompe na metade.** Para arrastá-la para qualquer lugar seria preciso corromper metade dos
  valores. Menos que isso, por mais absurdos que sejam, e a mediana fica entre os honestos.

Um resumo com ponto de ruptura alto se chama **robusto**. A mediana é o exemplo padrão; a próxima seção
apresenta um meio-termo entre os dois.

## Robusto não é o mesmo que melhor

A robustez protege contra valores que não deveriam estar ali: erros de digitação, um sensor que falhou,
um pedido de teste que alguém esqueceu de apagar. Ela também ignora valores que deveriam estar ali. O
salário do fundador é real, e a folha precisa pagá-lo. A cesta de R$ 421,78 é dinheiro de verdade no
caixa.

Então a pergunta nunca é só "qual é mais robusto?". É **"os valores extremos são erros, ou fazem parte do
que estou tentando descrever?"** A aula 9 trata de responder isso, um valor suspeito de cada vez. Até lá,
uma distância grande entre média e mediana é um motivo para olhar, não uma ordem para trocar.
