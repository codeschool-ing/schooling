---
title: Encerrando um incidente
version: 2
---

Um incidente acaba quando **os usuários não são mais afetados e o sistema está estável**, não quando a
causa é entendida. Muitas vezes essas duas coisas estão separadas por horas ou dias, e manter o
incidente aberto até a causa ser conhecida segura as pessoas num modo de resposta que já não ajuda
ninguém.

O que encerrar envolve:

- **Uma condição, verificada.** O page foi resolvido, a taxa de queima voltou para baixo de 1, e a taxa
  de erros está onde estava antes. Cada uma é um número, e o IC as lê em voz alta antes de declarar o
  fim.
- **Uma última atualização**, na mesma forma das outras, dizendo que acabou, o que os usuários devem
  saber, e que uma revisão virá.
- **As pendências escritas, com donos.** Durante a resposta, as pessoas dizem *a gente devia* muitas
  vezes: acrescentar um alerta, consertar a nova tentativa, documentar a reversão. Cada uma vira um
  ticket antes de o canal ficar quieto, porque na manhã seguinte ninguém lembra metade delas.
- **Um postmortem agendado**, para todo SEV-1 ou SEV-2, e para um SEV-3 que ensinou alguma coisa. A aula
  18 é sobre escrevê-lo.

Mais uma decisão pertence ao encerramento: **se a correção que acabou com o incidente pode ficar.** Uma
reversão é segura; uma configuração editada à mão, um cluster aumentado ou uma funcionalidade desligada
é um estado provisório que alguém precisa desfazer ou tornar permanente, e precisa de um dono como
qualquer outra pendência.

Antes da próxima aula, tire de novo as regras e o override da aula 16:

```sh
rm prometheus/rules/burn.yml compose.override.yaml
curl -s -X POST localhost:9090/-/reload
docker compose up -d alertmanager
```
