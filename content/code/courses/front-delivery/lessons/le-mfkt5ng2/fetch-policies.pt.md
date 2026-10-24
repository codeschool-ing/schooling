---
title: Fetch policies
version: 1
---

**Uma fetch policy diz ao cliente, consulta por consulta, se deve responder pelo cache, pelo servidor ou
pelos dois.** O passo 2 pediu exatamente o que o passo 1 tinha pedido, e o log do servidor mostra que ele
nunca chegou: a política padrão, `cache-first`, achou no cache todos os campos de que precisava e
respondeu dali.

| política | lê o cache | pergunta ao servidor | para |
|---|---|---|---|
| `cache-first` | sim, e para se tudo estiver lá | só pelo que falta | o padrão; dados que mudam pouco |
| `cache-and-network` | sim, na hora | sempre, e depois atualiza | uma tela que deve mostrar algo já e a verdade um instante depois |
| `network-only` | não | sempre, e grava a resposta no cache | dados que precisam estar em dia, como depois de uma mudança feita em outro lugar |
| `no-cache` | não | sempre, e não guarda nada | uma resposta que não pode ser guardada |
| `cache-only` | sim | nunca | dados que você sabe que estão lá, ou uma tela offline |

O passo 5 usou `network-only`, e por isso chegou ao servidor, e o passo 2 não.

## Qual o planner quer

Os dados do planner mudam de dois jeitos: pelo próprio planner, por uma mutation cuja resposta vai para o
cache, e por outra pessoa, em outro aparelho. O `cache-first` dá conta do primeiro. Para o segundo, não
há configuração certa sem conhecer o produto: um planner usado num celular e num notebook pela mesma pessoa
poderia usar `cache-and-network` quando uma página abre, para desenhar na hora a partir da memória e se
corrigir um instante depois. O planner desta aula fica com o padrão.

## Desatualizado é uma decisão

Um cache responde rápido porque não pergunta, o que quer dizer que ele pode estar errado. Toda política,
menos `network-only` e `no-cache`, aceita que uma tela mostre algo que o servidor já mudou. É a troca que
todo cache faz, o de um navegador e o de uma CDN inclusive, e merece a mesma pergunta: **quão velho isso
pode estar antes de enganar alguém?** Os minutos de uma sessão podem ter uma hora. Um saldo bancário, não.
