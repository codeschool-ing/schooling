---
title: Timelines: duas histórias depois de um ponto
version: 1
---

O servidor restaurado agora guarda uma história que nunca aconteceu no de produção: os cinco pedidos
e então, em vez de um `DELETE`, o que for escrito nele a seguir. O servidor de produção guarda a
outra história: o `DELETE`, e os três pedidos depois dele. As duas continuam do mesmo momento, e as
duas vão continuar escrevendo log. Esse momento é uma bifurcação, e o PostgreSQL dá a cada ramo um
número próprio:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha horizontal para a timeline 1, o servidor em produção: um backup full, as transações 737 a 741 com cinco pedidos, a transação 742, o DELETE, e depois 743 a 745 com mais três pedidos. Logo antes da 742, uma segunda linha se ramifica para baixo: a timeline 2, o servidor restaurado, que tem os cinco pedidos e não tem o DELETE, e segue com suas próprias escritas. Uma nota na bifurcação diz 0/415E8F0, antes da transação 742.\"><defs><marker id=\"l6f-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l6f-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">timeline 1: o servidor em produção</text><path d=\"M110 70 L392 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M468 70 L700 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6f-wi)\"></path><rect x=\"20\" y=\"52\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">backup full</text><circle cx=\"140\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"140\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">737</text><circle cx=\"180\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"180\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">738</text><circle cx=\"220\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"220\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">739</text><circle cx=\"260\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"260\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">740</text><circle cx=\"300\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"300\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">741</text><text x=\"220\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cinco pedidos</text><rect x=\"392\" y=\"52\" width=\"76\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">742</text><text x=\"430\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">DELETE</text><circle cx=\"510\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"510\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">743</text><circle cx=\"550\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"550\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">744</text><circle cx=\"590\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"590\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">745</text><text x=\"550\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três pedidos</text><path d=\"M360 70 L360 190 L700 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6f-ph)\"></path><text x=\"380\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">timeline 2: o servidor restaurado</text><text x=\"600\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">novas escritas</text><rect x=\"150\" y=\"150\" width=\"190\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"245\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bifurcação em 0/415E8F0,</text><text x=\"245\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">antes da transação 742</text><path d=\"M340 173 L354 173\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "A restauração parou antes da transação 742 e virou a timeline 2. O servidor em produção segue pela timeline 1 com o DELETE e os três pedidos depois dele; o arquivo de histórico registra onde os dois se separaram.", "same": ["DELETE"]}
```

Toda recuperação que para antes do fim do log começa uma nova **timeline**, ou linha do tempo. Os
nomes dos segmentos a carregam, nos oito primeiros dígitos:

```
ana@vm:~$ sudo ls /var/lib/postgresql/16/restore/pg_wal
000000010000000000000004
00000002.history
000000020000000000000004
000000020000000000000005
archive_status
ana@vm:~$ sudo cat /var/lib/postgresql/16/restore/pg_wal/00000002.history
1	0/415E8F0	before transaction 742
```

O `000000010000000000000004` é a timeline 1, a história que a cópia reaplicou. O
`000000020000000000000004` e o `…05` são a timeline 2, escritos pelo servidor restaurado desde que
foi promovido: a mesma posição no log, uma história diferente. E o `00000002.history` é o registro
da bifurcação, numa linha só: **a timeline 2 saiu da timeline 1 em `0/415E8F0`, antes da transação
742.**

As timelines são o que impede que duas histórias se confundam, e elas importam assim que existe mais
de uma recuperação:

- **Um segmento nunca é sobrescrito por outra história.** Se o servidor restaurado arquivasse no
  mesmo repositório, os segmentos dele levariam a timeline 2 no nome e não poderiam substituir os
  segmentos da timeline 1 do servidor de produção. O aviso sobre o archive-mode na lição 5 é sobre
  os casos em que os números sozinhos não te salvam.
- **Uma recuperação pode escolher o seu ramo.** O `recovery_target_timeline` tem `latest` como
  padrão: seguir os arquivos de histórico até o ramo mais novo. Uma segunda recuperação do mesmo
  backup seguiria a timeline 2, a não ser que alguém dissesse outra coisa, e é isso que você quer
  depois de uma restauração deliberada, e nem sempre depois de um ensaio.
- **Um arquivo de histórico é pequeno e essencial.** A recuperação o lê para saber onde cada ramo
  deixou o pai, e uma restauração que não acha um falha. O pgBackRest os arquiva junto com os
  segmentos.

A lição 15 reencontra as timelines, pelo outro lado: uma réplica promovida depois de uma falha
começa uma nova timeline exatamente assim, e o antigo primário, ainda na timeline 1, não consegue
mais segui-la.
