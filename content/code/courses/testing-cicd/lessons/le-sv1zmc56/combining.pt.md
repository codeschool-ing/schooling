---
title: Cobertura de várias execuções
version: 1
---

Num pipeline, a suíte raramente roda como um comando só. A aula 1 seção 11 a dividiu numa camada
rápida e numa lenta, e a aula 5 vai rodá-la em três versões do Python e dois fusos horários. Cada uma
dessas execuções vê parte do código, e **a cobertura que importa é a união de todas elas**.

`coverage run -p` grava um arquivo de dados com nome único em vez de sobrescrever `.coverage`, e
`coverage combine` junta todos esses arquivos num só. Eis as duas camadas do `shipquote`, medidas em
separado e depois combinadas:

```
ana@laptop:~/shipquote$ coverage run -p -m pytest -q -m "not functional and not acceptance" | tail -1
37 passed, 2 skipped, 4 deselected in 0.65s
ana@laptop:~/shipquote$ coverage run -p -m pytest -q -m "functional or acceptance" | tail -1
4 passed, 39 deselected in 1.31s
ana@laptop:~/shipquote$ ls .coverage.* | wc -l
2
ana@laptop:~/shipquote$ coverage combine
Combined 2 files
ana@laptop:~/shipquote$ coverage report | tail -1
TOTAL                     164     32     24      4    81%
```

A camada rápida rodou 37 testes e a lenta 4. Dois arquivos de dados foram gravados, o `combine` os
juntou, e o relatório mostra **81%**, exatamente o número da execução única da seção 02. Nenhuma das
duas sozinha cobre o que as duas cobrem juntas: os testes funcionais são os únicos que alcançam
`app.py`, e os unitários alcançam regras que os testes HTTP nunca pedem.

## Num pipeline

O arranjo usual, que a aula 6 escreve como workflow, é:

1. todo job que roda testes os roda sob `coverage run -p` e guarda o arquivo de dados como
   **artefato**, um arquivo que o pipeline salva quando o job termina;
2. um último job, depois de todos os outros, baixa os artefatos, roda `coverage combine` e
   `coverage report`, e publica o resultado.

Dois detalhes fazem isso funcionar. Os arquivos de dados guardam caminhos absolutos, então jobs que
fazem checkout do código em diretórios diferentes precisam de uma seção `[paths]` na configuração
que os mapeie para um lugar só. E o relatório combinado deve ser produzido **mesmo quando um job de
teste falhou**, porque uma execução com falha é exatamente quando alguém vai querer saber o que as
outras cobriram.

## Cobertura como leitura, daqui em diante

Da aula 5 em diante, o pipeline roda os testes, e pode produzir este relatório a cada push. O que as
aulas 1 a 4 somam é como lê-lo: **linhas sem cobertura são uma lista de lugares que ninguém conferiu;
linhas cobertas são uma lista de lugares que alguém talvez tenha conferido.** Uma suíte ganha
confiança pelas verificações, pelas bordas e pelos dublês mantidos honestos, e a cobertura é o jeito
barato de achar onde nada disso chegou ainda.
