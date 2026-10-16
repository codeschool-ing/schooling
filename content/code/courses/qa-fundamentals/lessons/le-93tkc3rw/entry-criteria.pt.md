---
title: Critérios de entrada, ou quando o teste pode começar
version: 1
---

**Um ciclo de teste é um trecho de teste com começo e fim: os dois dias da Lia antes da entrega de sexta são um.**
Critérios de entrada dizem o que precisa ser verdade antes de ele começar; critérios de saída, a próxima seção, dizem o
que precisa ser verdade antes de ele poder terminar. Os dois são escritos com antecedência, para nenhum desses momentos
ser decidido por quem estiver mais impaciente.

A aula 13 encontrou a mesma ideia num quadro Kanban, como política para sair de uma coluna. Aqui ela é aplicada a um
ciclo inteiro.

## Por que o teste não deve começar cedo demais

Começar um ciclo antes de a coisa a testar estar pronta parece sair na frente. Em geral é o contrário. Testar um build
a que metade das mudanças ainda não chegou é testá-lo duas vezes. Testar numa máquina que não está configurada como a
da bilheteria produz defeitos que na verdade são de configuração, e desperdiça um dia em cada um. Testar sem os
critérios de aceitação é testar contra palpites.

## Os critérios de entrada do Cine Aurora

O ciclo da Lia começa na quarta de manhã, e só quando os cinco forem verdade:

| critério | por quê |
|---|---|
| as seis mudanças estão num build só | testar meia entrega é testá-la duas vezes |
| as verificações automatizadas passam nesse build | um build que falha nas próprias verificações ainda não vale o tempo de uma pessoa |
| o build está instalado na máquina de teste configurada como o terminal da bilheteria | os defeitos devem ser do programa, não da máquina |
| toda história tem seus critérios de aceitação escritos | senão não há contra o que testar |
| os dados de teste incluem a programação de uma semana real, com a sessão das 9:30 de domingo | os defeitos de ontem vivem nos dados de ontem |

Nenhum desses é exótico. Cada um existe porque um ciclo em algum lugar, muitas vezes no Cine Aurora, começou sem ele e
perdeu um dia.

## Um teste de fumaça

O segundo critério é conferido com um **teste de fumaça** (*smoke test*): uma execução curta e rápida das verificações
mais básicas, para ver se o build vale a pena ser testado. O nome vem do hardware, em que o primeiro teste de uma placa
nova era ligá-la e ver se saía fumaça. Um teste de fumaça não procura defeitos sutis. Procura um build tão quebrado que
qualquer teste a mais seria desperdício.

No laboratório, o teste de fumaça do Cine Aurora são três comandos: os testes de unidade da aula 15, os cenários das
aulas 16 e 17, e um ingresso comum pela linha de comando:

```
lia@lab:~/aurora$ python -m unittest
....
----------------------------------------------------------------------
Ran 4 tests in 0.000s

OK
lia@lab:~/aurora$ behave --format progress
USING RUNNER: behave.runner:Runner
features/coupons.feature  ....
features/prices.feature  ......

2 features passed, 0 failed, 0 skipped
10 scenarios passed, 0 failed, 0 skipped
36 steps passed, 0 failed, 0 skipped
Took 0min 0.003s
lia@lab:~/aurora$ python tickets.py 35 no thu 20:00
R$ 36,00
```

Toda verificação passa e um ingresso da noite custa R$ 36,00, então o build cumpre seu critério de entrada e o ciclo
pode começar. Se qualquer um dos três tivesse falhado, a Lia não começaria. Devolveria o build com a falha anexada, e o
ciclo começaria quando um build passasse.

## Quem confere os critérios de entrada

A Lia os confere, mas não os decide sozinha, e não decide sozinha pular um. Se o Rafael tivesse perguntado na quarta de
manhã se o teste podia começar sem o botão de reembolso, por ele não estar terminado, a resposta não seria da Lia para
dar em silêncio. Ou o botão de reembolso sai desta entrega, o que é decisão da Joana, ou o ciclo espera. Um ciclo que
começa mesmo assim, com uma nota de "testar reembolsos quando chegarem", tem uma data de saída que já está errada.
