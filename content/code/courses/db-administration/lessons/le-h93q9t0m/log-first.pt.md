---
title: Escreva primeiro
version: 1
---

A imagem óbvia de um commit é que a sua linha vai para o arquivo da tabela e então o `COMMIT`
responde. **Um commit não escreve a sua linha no arquivo da tabela.** Ele altera uma cópia da
página da tabela na memória compartilhada, escreve uma descrição da alteração no **write-ahead log**
e garante que essa descrição chegou ao disco. Só então o `COMMIT` responde. O arquivo da tabela é
atualizado depois, por um processo que não tem nada a ver com a sua sessão.

Essa é a regra inteira, e o nome diz: o log é escrito *antes* dos dados. **Nenhuma alteração chega
a um arquivo de tabela antes de a descrição dela ter chegado ao log.** Todo o resto desta lição e
da próxima sai dessa frase. O log é chamado de WAL, e os arquivos dele ficam em `pg_wal`, o
diretório que a lição 4 encontrou ocupando mais espaço que os dados.

Por que dar a volta mais longa? Porque as duas escritas têm formatos diferentes. Uma alteração de
linha mexe numa página de 8 kB em algum lugar de um arquivo com milhares delas, e uma transação que
atualiza dez linhas pode mexer em dez páginas em dez lugares. Forçar tudo isso para o disco a cada
commit é esperar por escritas espalhadas. O log é acrescentado no fim, então um commit espera por
uma única escrita sequencial de algumas dezenas de bytes. Se o servidor morrer antes de as páginas
serem gravadas, **o log tem o suficiente para refazer cada uma dessas alterações**. A lição 8 mata
o servidor para ver isso acontecer.

## A sua linha, antes de estar na tabela

Dá para ver a regra só com `grep`. Crie uma tabela pequena em `shop` e coloque uma linha nela:

```
shop=# CREATE TABLE notes (id int PRIMARY KEY, body text);
CREATE TABLE

shop=# INSERT INTO notes VALUES (1, 'written down first');
INSERT 0 1

shop=# SELECT pg_relation_filepath('notes');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)
```

`pg_relation_filepath` dá o arquivo da tabela dentro do diretório de dados, como a lição 4 mostrou.
A linha já foi confirmada. Procure o texto dela nesse arquivo, e depois procure o mesmo texto no
diretório do log:

```
ana@db:~$ sudo grep -c 'written down first' /var/lib/postgresql/16/main/base/16386/16420
0
ana@db:~$ sudo grep -rl 'written down first' /var/lib/postgresql/16/main/pg_wal
/var/lib/postgresql/16/main/pg_wal/000000010000000000000015
```

**O arquivo da tabela não contém a linha**, e um dos arquivos de `pg_wal` contém. `grep -c` contou
zero ocorrências no primeiro; `grep -rl` deu o nome do arquivo onde achou no segundo. O commit foi
confirmado com a linha na memória e no log, e em nenhum outro lugar. Os números do caminho podem
ser outros na sua máquina: pergunte ao `pg_relation_filepath` e use o que ele responder.

A página continua na memória, marcada como **suja**: alterada desde que foi lida, e ainda não
gravada de volta. Ela chega ao arquivo no próximo checkpoint, ou antes, se o lugar dela na memória
for preciso para outra página. A lição 8 é sobre o checkpoint, e roda este mesmo `grep` depois de
um.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Um commit altera a página da tabela na memória compartilhada e escreve nos buffers de WAL um registro que descreve a alteração. No COMMIT o WAL é gravado em pg_wal no disco antes da resposta; a página chega ao arquivo da tabela depois, num checkpoint.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">memória compartilhada</text><rect x=\"10\" y=\"180\" width=\"700\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">disco</text><rect x=\"30\" y=\"50\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">INSERT … ; COMMIT</text><text x=\"105\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a sua sessão</text><rect x=\"270\" y=\"50\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a página da tabela</text><text x=\"355\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">alterada, não gravada: suja</text><rect x=\"530\" y=\"50\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">buffers de WAL</text><text x=\"610\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um registro que a descreve</text><rect x=\"270\" y=\"215\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">base/16386/16420</text><text x=\"355\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o arquivo da tabela</text><rect x=\"530\" y=\"215\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">pg_wal/</text><text x=\"610\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o log, acrescentado no fim</text><line x1=\"180\" y1=\"75\" x2=\"266\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"223\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"bold\">1</text><line x1=\"440\" y1=\"75\" x2=\"526\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"483\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"bold\">2</text><line x1=\"610\" y1=\"120\" x2=\"610\" y2=\"211\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"598\" y=\"148\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">3 gravado no COMMIT,</text><text x=\"598\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">antes da resposta</text><line x1=\"355\" y1=\"120\" x2=\"355\" y2=\"211\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#arr)\"></line><text x=\"367\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 gravada depois,</text><text x=\"367\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">por um checkpoint (lição 8)</text></svg>", "caption": "Duas cópias de uma alteração. Só a do log precisa estar no disco antes de o COMMIT responder."}
```

## Quem escreve o log

Dois tipos de processo gravam WAL no disco, e nenhum deles grava páginas de tabela.

**A sessão que faz o commit grava o log ela mesma** quando os registros dela ainda não estão no
disco, e essa gravação é a espera dentro do `COMMIT`. O **walwriter**, um dos processos de fundo
que a lição 3 listou, acorda a cada `wal_writer_delay` — 200 ms, a menos que alguém tenha mudado — e
grava o que tiver se acumulado nos buffers de WAL. Essa gravação em segundo plano é o que torna
possível o `synchronous_commit = off`, e a lição 8 mede o que ele compra e o que ele arrisca.

As páginas de tabela são gravadas por outros dois processos da mesma lista: o **checkpointer**, que
é o assunto da lição 8, e o **background writer**, que grava algumas páginas sujas antes do momento
em que a memória delas vai ser precisa. A ordem entre os dois mundos é garantida pelo servidor:
antes de qualquer página suja ser gravada, o log é gravado pelo menos até o último registro que a
alterou.
