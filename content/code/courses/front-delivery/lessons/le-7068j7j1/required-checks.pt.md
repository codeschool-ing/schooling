---
title: Conferências obrigatórias, para vermelho querer dizer sem merge
version: 1
---

**Uma conferência que ninguém é obrigado a esperar é uma sugestão.** O CI ficar vermelho num pull request
só importa se o pull request então não puder ser mergeado, e isso é uma configuração do repositório, não
parte do workflow.

No GitHub isso é um **ruleset de branch**, ou a antiga **regra de proteção de branch**, no `main`. Em
**Settings** do repositório, em **Rules**, um ruleset para o branch padrão com duas regras ligadas faz o
serviço:

- **Require a pull request before merging**, para ninguém enviar direto ao `main` e pular as
  conferências;
- **Require status checks to pass**, com `CI / check` acrescentado à lista, para o botão de merge ficar
  cinza até esse job estar verde no commit mais recente do pull request.

**Isso não foi executado para este curso**; precisa de um repositório no GitHub, e as telas são do GitHub
para rearranjar. O que dura é o formato: uma conferência com nome, obrigatória, no branch de onde todo
mundo publica.

## Três jeitos de uma conferência obrigatória ser contornada

Cada um destes é um jeito real de código vermelho chegar ao `main`, e cada um tem uma configuração ou um
hábito contra:

| como | contra isso |
|---|---|
| um administrador faz o merge assim mesmo, porque a regra deixa | desligar a exceção para administradores, ou manter uma lista de quem pode passar por cima e por quê |
| o nome da conferência muda, a regra fica esperando uma conferência que nunca mais roda, e alguém a remove | dar nomes aos jobs de propósito e mudá-los raramente; um job renomeado é uma mudança na regra também |
| o pull request estava verde, mas o `main` andou desde então, e a junção dos dois está quebrada | exigir que o branch esteja atualizado antes do merge, ou usar a fila de merge do GitHub, que confere o próprio merge |

## As conferências e o deploy

O build do host da aula 1 é um segundo pipeline, separado. Vercel, Netlify e Cloudflare Pages relatam cada
um o seu deploy como uma conferência no pull request também, ao lado de `CI / check`. **Torne a sua
obrigatória e deixe a deles informativa**: o build de um host falhar diz que o deploy falharia, enquanto a
sua conferência diz que o código está errado, e só a segunda é motivo para bloquear um merge que o host
poderia tentar de novo.
