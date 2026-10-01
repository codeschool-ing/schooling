---
title: Um histórico, não uma pilha de cópias
version: 1
---

A segunda execução, um minuto depois, não acha nada para fazer:

```
ana@ctl:~$ cd net && python backup.py
no change since the last backup
```

**Nenhum commit, nenhum arquivo com data nova, nada.** Isso importa mais do que parece. Um job de
backup que gravasse uma cópia datada toda noite, `edge1-2026-10-01.conf` ao lado de
`edge1-2026-09-30.conf`, produziria trezentos e sessenta e cinco arquivos por ano por roteador,
quase todos idênticos, e achar a noite em que algo mudou significaria compará-los dois a dois. No
Git, a noite em que algo mudou é um commit, e as noites em que nada mudou estão ausentes.

O Git também traz as ferramentas que funcionam sobre qualquer histórico: `git log` lista as
mudanças, `git log -p
edge1.conf` mostra cada mudança de um roteador, `git diff` compara quaisquer dois pontos, e
`git show` recupera qualquer arquivo como ele estava em qualquer commit. Nada disso foi escrito para
esta aula; é o que escolher o Git como armazenamento compra.

A mensagem de commit é montada a partir dos arquivos que mudaram, `backup: edge1`, então
`git log --oneline` já é um resumo legível de quais roteadores mudaram e quando. Rodado por um
agendador, o autor e a data são os do próprio job; a aula 14 o roda a partir de um pipeline, onde
cada execução também deixa um log.
