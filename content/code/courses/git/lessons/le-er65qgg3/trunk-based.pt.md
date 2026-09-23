---
title: Trunk based: mudanças pequenas, no mesmo dia
version: 1
---

*Trunk* (tronco) é um nome antigo para o branch principal. **Desenvolvimento trunk based quer dizer que
todo mundo integra no `main` pelo menos uma vez por dia**, seja fazendo commit direto nele, seja por um
branch que vive algumas horas e um pull request revisado no mesmo dia.

Ele leva a lição da seção anterior até o fim. Se branches longos causam merges grandes, mantenha todo
branch curto o bastante para o merge ser sempre pequeno. Conflitos continuam acontecendo, mas do
tamanho de uma tarde de trabalho, e enquanto o trabalho ainda está fresco na cabeça de todo mundo.

## Fazendo merge de trabalho que não terminou

A objeção óbvia: uma funcionalidade leva duas semanas, então como fazer merge dela todo dia? A
resposta é que **ter entrado não é o mesmo que estar ligado.** O trabalho inacabado entra no `main`
atrás de uma *feature flag*, uma configuração que o programa lê para decidir se mostra a novidade:

```conf
# features.conf, read by the app when it starts
sunday_hours = off
pickup_times = on
```

O `sunday_hours` está no `main` e em produção, desligado. Ninguém vê. Ele é terminado em pedaços
pequenos, cada um com o próprio merge e a própria revisão, e no dia em que fica pronto alguém muda
`off` para `on`, sem merge nenhum. Se algo der errado, o `on` volta para `off`, o que é mais rápido que
qualquer revert.

## O que isso pede de uma equipe

Trunk based não funciona em todo lugar, e vale saber por quê antes de escolher:

- **Pede checks que peguem erros rápido.** Quando o `main` muda vinte vezes por dia, um teste quebrado
  tem de ser achado em minutos, por uma máquina, não por uma pessoa na semana que vem. A aula 17 é
  sobre os checks e sobre o que *pronto* quer dizer em volta deles.
- **Pede que mudanças pequenas sejam possíveis**, o que é uma habilidade de dividir trabalho que leva
  prática.
- **Pede que as flags sejam removidas** quando uma funcionalidade fica toda ligada, senão o código
  enche de chaves de que ninguém lembra.

O que ele devolve é o que a maioria das equipes quer e poucas conseguem: um `main` sempre perto do que
está rodando, e nenhum merge que alguém tema.
