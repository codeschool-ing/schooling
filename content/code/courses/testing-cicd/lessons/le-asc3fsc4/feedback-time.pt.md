---
title: Quanto uma execução pode levar
version: 1
---

Uma execução de CI é retorno, e retorno perde valor a cada minuto que leva. Uma execução que responde
em cinco minutos é lida por quem fez o push, com a mudança ainda na cabeça. Uma que responde em
quarenta é lida depois do almoço, por alguém que já começou outra coisa, e muitas vezes nem é lida.
**O tempo que um pipeline leva faz parte do desenho dele**, e não é uma propriedade que ele por acaso
tem.

O push da seção 07 rodou sob `time`, e as últimas linhas dele são a duração inteira do pipeline do
laboratório: `real 0m13.315s`, **13,3 segundos** do push ao veredito, seis células e as instalações
incluídas. Os relatórios JUnit dessa execução dizem para onde o tempo foi dentro das células:

```
ana@laptop:~/shipquote$ for f in ~/ci/runs/5/*.xml; do grep -o "<testsuite [^>]*>" $f | grep -oE "(tests|time)=\"[0-9.]+\"" | tr "\n" " "; echo "$(basename $f .xml)"; done
tests="43" time="1.960" py3.11-America-Sao_Paulo
tests="43" time="1.390" py3.11-UTC
tests="43" time="1.964" py3.12-America-Sao_Paulo
tests="43" time="1.418" py3.12-UTC
tests="43" time="2.048" py3.13-America-Sao_Paulo
tests="43" time="1.426" py3.13-UTC
```

Cada célula rodou 43 testes, os 41 aprovados e os 2 pulados, em algo entre um segundo e meio e dois.
Seis células, rodadas uma depois da outra, somam a maior parte dos 13 segundos; o resto é criar três
ambientes virtuais a partir do cache. Repare também que **toda célula de São Paulo levou cerca de meio
segundo a mais que a vizinha em UTC**, em todo Python. O laboratório não explica isso, e nada falhou,
mas uma matriz põe números assim lado a lado, onde alguém pode notar.

## Para onde o tempo vai, e o que fazer

| custo | remédio |
|---|---|
| células rodando uma depois da outra | rodá-las em paralelo, como os runners hospedados fazem: a execução leva o tempo da célula mais lenta |
| instalar dependências | guardá-las em cache com chave no arquivo de travamento (seção 08) |
| testes lentos rodando primeiro | ordenar os jobs para a camada rápida relatar antes (aula 1 seção 14) |
| tudo rodando a cada mudança | pular o que a mudança não afeta, sem pular em silêncio (seção 04) |
| uma suíte lenta | dividi-la entre várias máquinas, e medir a parte mais lenta |

Uma meta comum é **menos de dez minutos** para as verificações que liberam um merge. Não é lei, e o
número certo depende da equipe, mas passando de dez minutos as pessoas param de esperar o resultado
e começam a juntar mudanças, que é o oposto de integrar continuamente.

## Os números deste repositório

A execução do próprio workflow do repositório que o autor desta aula olhou, no commit que integrou o
curso anterior, começou às 15:34:36 UTC e terminou às 15:40:47. São pouco mais de seis minutos para
quatro jobs, entre eles uma suíte Go contra um PostgreSQL real e uma suíte de navegador. A aula 6 lê
essa execução job por job, a partir do registro do próprio serviço.
