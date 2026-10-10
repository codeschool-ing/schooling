---
title: Para onde vai o log
version: 1
---

**Todo processo do PostgreSQL escreve as suas linhas de log na saída de erro padrão**, e o que
acontece com elas depois depende de um parâmetro e de quem subiu o servidor. No Ubuntu, quem sobe é
o `pg_ctlcluster`, e a resposta é um único arquivo em `/var/log/postgresql`. Boa parte do que se
escreve sobre o log do PostgreSQL descreve o outro arranjo, com arquivos dentro do diretório de
dados, então vale ver qual dos dois o seu servidor usa antes de ler qualquer conselho.

Os parâmetros que decidem isso, e os que o resto desta lição muda, como o pacote os deixou:

@@1@@

**`logging_collector` está desligado e `log_destination` é `stderr`**: o servidor não faz nada com
o seu log além de escrevê-lo na saída de erro. O `pg_current_logfile()` só responde por arquivos
que o próprio servidor abriu, então não devolve nada. Do resto, só o `log_checkpoints` está ligado,
que o PostgreSQL 16 tornou padrão; todas as outras linhas da tabela são tipos de evento que este
servidor ainda não registra.

## O arquivo, e quem o abriu

@@2@@

A primeira linha do `postmaster.pid` é o id de processo do postmaster, e `/proc/<pid>/fd/2` é para
onde aponta a saída de erro dele: **é aquele arquivo**. Não foi o servidor que o escolheu. O
`pg_ctlcluster` subiu o servidor com `pg_ctl -l`, que abre o arquivo e o entrega como saída de
erro, e todo backend que o postmaster inicia o herda. O arquivo pertence a `postgres` e ao grupo
`adm`, e é por isso que há um `sudo` na frente de todo comando que o lê.

O journal do systemd tem a unit subindo e nada de dentro do servidor:

@@3@@

Isso surpreende quem espera a saída de todo serviço no journal. Ela só vai para lá quando um
servidor escreve na saída de erro e ninguém a redirecionou, e não é assim que o pacote do Ubuntu o
sobe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Diagrama. O postmaster e todo processo que ele inicia escrevem as suas linhas de log na saída de erro padrão. Com logging_collector desligado, o padrão do Ubuntu, o pg_ctlcluster subiu o servidor com pg_ctl -l, então a saída de erro é o arquivo /var/log/postgresql/postgresql-16-main.log, cortado toda semana pelo logrotate com copytruncate. Com logging_collector ligado, um processo logger recolhe cada linha e escreve arquivos em log/ dentro do diretório de dados, no formato stderr, csvlog ou jsonlog, e o próprio servidor os gira por idade e tamanho.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"220\" y=\"16\" width=\"280\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o postmaster e todo processo que ele inicia</text><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">escrevem no stderr</text><path d=\"M 300 72 L 190 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><path d=\"M 420 72 L 530 120\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><text x=\"190\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">logging_collector = off (o padrão do Ubuntu)</text><text x=\"530\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">logging_collector = on</text><rect x=\"20\" y=\"152\" width=\"340\" height=\"132\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o pg_ctlcluster sobe o servidor com pg_ctl -l</text><text x=\"36\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/var/log/postgresql/</text><text x=\"48\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">postgresql-16-main.log</text><text x=\"36\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cortado toda semana pelo logrotate, copytruncate</text><rect x=\"380\" y=\"152\" width=\"320\" height=\"132\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"396\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um processo logger recolhe cada linha</text><text x=\"396\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/var/lib/postgresql/16/main/log/</text><text x=\"408\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">postgresql-…json  (.csv, .log)</text><text x=\"396\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cortado pelo servidor: log_rotation_age, log_rotation_size</text></svg>", "caption": "Dois caminhos para as mesmas linhas chegarem ao disco. O Ubuntu escolhe o primeiro; o segundo é o que jsonlog e csvlog exigem.", "same": ["logging_collector = on"]}
```

## O outro arranjo

Com **`logging_collector = on`** o servidor sobe um processo a mais, o logger, que lê a saída de
erro de todos os outros e escreve os seus próprios arquivos em `log_directory`, por padrão `log`
dentro do diretório de dados. Ele os nomeia por data com `log_filename`, começa um arquivo novo
por idade ou tamanho, e é o único arranjo que consegue escrever `csvlog` ou `jsonlog`. Ligá-lo
exige um restart. A última seção desta lição faz isso para JSON e desfaz depois.

Não há nada de errado na escolha do Ubuntu. Um arquivo só, girado pela mesma ferramenta que todo
outro log da máquina, é fácil de achar às três da manhã. **O que importa é saber qual dos dois você
tem**, porque num servidor montado do outro jeito o `/var/log/postgresql` guarda duas linhas de
partida e o log de verdade está num lugar onde você não olhou.
