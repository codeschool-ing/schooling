---
title: Onde os registros vivem, e como são acordados
version: 1
---

**Os registros vivem no repositório, ao lado do código sobre o qual decidem, como texto puro, e são
acordados pela mesma revisão por que o código passa.** Esse arranjo sozinho resolve quase tudo o que
dá errado com logs de decisões guardados em qualquer outro lugar.

## No repositório

A Carcará os guarda em cada repositório em `docs/decisions/`, um arquivo Markdown por registro,
nomeado com o número e um slug: `0014-refund-late-approvals.md`. Decisões que cruzam repositórios
vão para o repositório de arquitetura, que todo time consegue ler. Três razões por que isso ganha de
uma wiki:

- **Eles são encontrados.** Uma engenheira lendo o código de bloqueio de assento acha
  `docs/decisions` ao lado dele; uma página de wiki precisa que alguém saiba que ela existe.
- **Eles são versionados com o código.** Fazer checkout do código do ano passado traz as decisões do
  ano passado, e assim os dois sempre combinam.
- **Eles são revisados.** Um registro proposto num pull request recebe comentários das mesmas pessoas
  que revisam o código, e o merge é o momento em que ele passa a *aceito*.

## Propondo um registro

1. Escreva o registro com status *Proposto* e abra um pull request só com ele, ou com um pequeno
   spike que mostre que a opção funciona.
2. Peça revisão, pelo nome, a quem é dono do que ele muda. Para um registro entre times, isso quer
   dizer um revisor por time afetado.
3. Discuta no pull request e mude o texto à medida que a discussão o melhora. O registro proposto é
   o único documento que pode mudar.
4. Faça o merge com o status em *Aceito* e a data. Se a resposta for não, faça o merge como
   *Rejeitado*: o raciocínio continua valendo a pena guardar.

## Ferramentas, nenhuma obrigatória

Arquivos de texto e um editor bastam, e é por isso que a aula 1 não listou mais nada. As ferramentas
existem para poupar digitação: o **adr-tools**, um conjunto de scripts de shell de Nat Pryce, cria
arquivos numerados a partir de um template e atualiza os links de *substituído*; o **Log4brains**
gera um site navegável a partir de uma pasta de registros. As duas são opcionais, e as duas
trabalham sobre os mesmos arquivos Markdown, então escolher uma nunca prende os registros.

## Apontando a partir do código

O último hábito fecha o ciclo: onde o código encarna uma decisão, um comentário curto aponta para
ela.

```kotlin
// Holds live in Redis with a 10-minute expiry: see docs/decisions/0009-seat-holds-in-redis.md
val held = redis.opsForValue().setIfAbsent("hold:$tripId:$seat", bookingId, Duration.ofMinutes(10))
```

A próxima pessoa a se perguntar *por que Redis?* está a um clique da resposta, e a resposta inclui o
custo que foi aceito.
