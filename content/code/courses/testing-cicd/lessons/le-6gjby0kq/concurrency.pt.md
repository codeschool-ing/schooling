---
title: Execuções que se sobrepõem
version: 1
---

Faça push de três commits num branch em dez minutos e três execuções começam. As duas primeiras já
estão desatualizadas: ninguém vai fazer merge daqueles commits, só do último. Rodá-las até o fim gasta
runners e, pior, pode relatar um vermelho que não importa mais depois de um verde que importa. Um
**grupo de concorrência** diz ao serviço que execuções do mesmo grupo não devem se sobrepor.

O workflow deste repositório declara um:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

O grupo é o workflow e o branch, então execuções em branches diferentes nunca interferem, e
`cancel-in-progress` cancela a execução mais antiga quando uma mais nova começa no mesmo grupo. Eis
as execuções de um branch em 19 de setembro de 2026, da mais nova para a mais antiga:

```
ana@laptop:~$ curl -s "$A/workflows/ci.yml/runs?branch=claude/wonderful-cray-nrgjb2&created=2026-09-19&per_page=8" | jq -r ".workflow_runs[] | [.id, .conclusion, .run_started_at, .updated_at] | @tsv"
35432460022	success	2026-09-19T08:36:39Z	2026-09-19T08:43:22Z
35430039994	success	2026-09-19T07:42:08Z	2026-09-19T07:48:29Z
35426262104	success	2026-09-19T06:18:49Z	2026-09-19T06:25:29Z
35425738735	failure	2026-09-19T06:06:59Z	2026-09-19T06:10:43Z
35422745554	success	2026-09-19T04:59:39Z	2026-09-19T05:06:02Z
35422536691	cancelled	2026-09-19T04:54:33Z	2026-09-19T04:59:55Z
35422344961	cancelled	2026-09-19T04:50:03Z	2026-09-19T04:54:52Z
35415431885	success	2026-09-19T02:21:56Z	2026-09-19T02:28:06Z
```

Leia de baixo para cima. A execução `35422344961` começou às 04:50:03. Outro push iniciou a
`35422536691` às 04:54:33, e a primeira terminou **cancelada** às 04:54:52, dezenove segundos depois.
Cinco minutos depois, o mesmo aconteceu com a segunda: a execução `35422745554` começou às 04:59:39 e
a segunda terminou cancelada às 04:59:55. Aí a terceira pôde terminar, e deu certo. Mais acima, uma
execução falhou e o push seguinte a corrigiu; nada a cancelou, porque nada mais novo chegou enquanto
ela rodava.

## Quando cancelar é errado

Cancelar serve para verificações: uma verificação velha não vale nada quando há um commit mais novo.
É o comportamento errado para qualquer coisa que **muda o mundo**, como uma implantação. Um deploy
cancelado no meio pode deixar um banco migrado e um serviço na versão antiga. O workflow de release
deste repositório põe o job de deploy num grupo próprio com `cancel-in-progress: false`, então um
segundo release espera o primeiro em vez de interrompê-lo, e o comentário dele diz o que aceita em
troca: quando três releases entram na fila, o do meio é descartado antes de começar, que é a perda
certa, porque ele nunca seria o que fica servindo.

O workflow do `shipquote` cancela, porque só confere. A aula 7 acrescenta jobs que entregam, e eles
vão precisar da outra configuração.
