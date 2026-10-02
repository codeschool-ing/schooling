---
title: O que a amostragem quebra
version: 1
---

Toda ligação que a aula 1 descreveu supõe que o rastro está lá. A amostragem tira a maioria deles, e as
ligações falham em silêncio, com uma resposta vazia que parece uma ferramenta quebrada.

**Um exemplar nomeia um rastro que pode não existir.** Os exemplares que o `orders` anexa ao histograma
dele são escolhidos pelo histograma, a requisição mais recente de cada bucket, sem ideia do que o
Collector vai guardar. Quatro deles, dos últimos dois minutos, abertos no Jaeger:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/0a8b800ccc00dbc576a69bdcd97dd588 | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
ana@obs:~/shop$ curl -s localhost:16686/api/traces/f1f82b5b65b25d8c97e5618fff901f70 | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
ana@obs:~/shop$ curl -s localhost:16686/api/traces/77729df5a3c72f5bf3988b63edda48de | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
ana@obs:~/shop$ curl -s localhost:16686/api/traces/953fe3b1cd4be851296dc0b06e6cd6ee | jq -r 'if .data then "\(.data[0].spans | length) spans" else .errors[0].msg end'
trace not found
```

Quatro exemplares, quatro rastros que não existem. Com 12% dos rastros guardados, esse é o resultado
comum. Com amostragem na cabeça existe uma correção, porque a decisão é conhecida enquanto a
requisição roda: anexar um exemplar só quando o span é amostrado. O `web.py` do laboratório verifica
só que existe um span, e acrescentar `ctx.trace_flags.sampled` a esse teste faria todo exemplar apontar
para um rastro guardado; o SDK de métricas do próprio OpenTelemetry faz isso por padrão, com o filtro
de exemplares `trace_based`. Com amostragem na cauda nada no momento da medição sabe a resposta, e um
exemplar é um palpite.

**Uma linha de log nomeia um rastro que pode não existir.** A seção da amostragem na cabeça mostrou: toda
linha leva um trace id, e nove em dez deles não levam a lugar nenhum. As linhas de uma requisição que
falhou são as que alguém segue, mais um motivo para guardar os erros na cauda.

**Uma busca só vê o que foi guardado.** Uma busca por checkouts lentos com amostragem na cabeça acha um
em dez deles, e o resultado parece completo. Com amostragem na cauda ela acha todos, mas uma busca por
*checkouts do produto `kettle`* acha 5% dos comuns.

**Contar a partir de rastros está errado com qualquer amostragem.** As span metrics da seção anterior são
as contagens; os rastros são exemplos do que as contagens descrevem.

Um armazenamento amostrado é um conjunto de exemplos escolhidos por regras, e as regras pertencem à
documentação do sistema: quem lê um rastro, ou não acha um, precisa saber que requisições podem ter
sido descartadas.
