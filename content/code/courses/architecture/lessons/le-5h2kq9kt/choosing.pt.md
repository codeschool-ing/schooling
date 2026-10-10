---
title: Escolhendo, e juntando com a aula 11
version: 1
---

As aulas 11 e 12 são uma caixa de ferramentas só, e cada ferramenta responde uma pergunta diferente:

| a pergunta | a ferramenta | a aula |
| --- | --- | --- |
| quanto tempo espero por uma resposta? | um timeout | 5 |
| esta falha merece outra tentativa? | um retry, com backoff, jitter e orçamento | 11 |
| devo parar de chamar um serviço que está claramente fora? | um circuit breaker | 11 |
| quanto da minha capacidade uma dependência pode segurar? | um bulkhead | 12 |
| com que frequência um cliente pode pedir? | um limite de taxa, respondido com `429` | 12 |
| o que acontece com o trabalho que ainda não consigo fazer? | uma fila limitada, e back pressure | 12 |

Para uma chamada do checkout da Quitanda ao serviço de estoque, eles se encaixam. O **retry** fica por
fora e decide se faz outra tentativa. Cada tentativa então passa pelo resto: o **breaker** decide se vale
a pena fazê-la, o **bulkhead** se há espaço para ela, e o **timeout** quanto ela pode demorar. O arranjo
padrão do Resilience4j é esse, com o retry por fora e o bulkhead junto da chamada, para um retry estar
sujeito a todo limite a que a primeira tentativa esteve.

O fio comum da aula inteira é que **cada um deles diz não**, cedo e barato, a parte do trabalho, para o
resto ser feito. Um sistema que aceita tudo não atende mais gente. Atende todo mundo mal, e depois
ninguém.

Quando terminar, pare o laboratório:

```sh
docker compose down
```
