---
title: Páginas sobre blocos
version: 1
---

Uma tabela não é guardada como linhas enfileiradas uma depois da outra. **O PostgreSQL lê e
escreve seus arquivos em páginas de 8192 bytes**, toda tabela e todo índice têm um número inteiro
delas, e uma linha mora dentro de uma página. O tamanho é fixado quando o PostgreSQL é compilado, e
tanto os arquivos de dados quanto o log de escrita antecipada (WAL) usam esse tamanho:

```
shop=# SHOW block_size;
 block_size 
------------
 8192
(1 row)

shop=# SHOW wal_block_size;
 wal_block_size 
----------------
 8192
(1 row)

shop=# SELECT relpages, pg_relation_size('customers') AS bytes,
shop-#        pg_relation_size('customers') / relpages AS bytes_per_page
shop-#   FROM pg_class WHERE relname = 'customers';
 relpages |  bytes  | bytes_per_page 
----------+---------+----------------
      568 | 4653056 |           8192
(1 row)
```

`relpages` é a contagem de páginas que o `ANALYZE` registrou quando a lição 4 carregou a tabela, e
o arquivo tem exatamente esse número de páginas. O PostgreSQL chama a configuração de `block_size`,
o que confunde, porque **o sistema de arquivos embaixo dele tem blocos próprios, e eles são
menores**:

```
ana@db:~$ stat --file-system --format="%T, block size %S" /var/lib/postgresql/16/main
ext2/ext3, block size 4096
```

O `stat` chama a família ext pelos seus membros mais antigos; o sistema de arquivos é ext4, como a
próxima seção mostra. O bloco dele tem 4096 bytes, e embaixo dele o disco tem de novo a sua própria
unidade, o setor, de 512 bytes em muitos discos e 4096 nos mais novos.

## Por que a diferença importa

Quando o PostgreSQL escreve uma página, o kernel transforma uma escrita de 8 kB em duas escritas de
bloco de 4 kB, e o disco transforma essas em escritas de setor. **Nada garante que todas cheguem,
nem que cheguem juntas.** Se a energia cair entre o primeiro bloco e o segundo, o arquivo fica com
uma página cuja primeira metade é nova e a segunda é antiga. Isso é uma **página rasgada** (torn
page), e nenhuma linha dela merece confiança.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 690 200\" role=\"img\" aria-label=\"Uma página de 8192 bytes do PostgreSQL ocupa dois blocos de 4096 bytes do sistema de arquivos, que ocupam dezesseis setores de 512 bytes do disco. Uma linha tracejada no meio marca uma queda de energia depois que o primeiro bloco foi escrito: a primeira metade da página é nova, a segunda ainda é antiga.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">página do PostgreSQL</text><rect x=\"150\" y=\"24\" width=\"520\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma página: 8192 bytes, escrita como unidade pelo PostgreSQL</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bloco do sistema de arquivos</text><rect x=\"150\" y=\"76\" width=\"256.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4096 bytes: novo</text><rect x=\"414.0\" y=\"76\" width=\"256.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4096 bytes: ainda antigo</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">setores do disco</text><rect x=\"151.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"183.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"216.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"248.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"281.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"313.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"346.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"378.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"411.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"443.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"476.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"508.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"541.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"573.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"606.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"638.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"166.25\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">512</text><line x1=\"410.0\" y1=\"18\" x2=\"410.0\" y2=\"166\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></line><text x=\"410.0\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a energia cai aqui: a página fica metade nova e metade antiga, uma página rasgada</text></svg>", "caption": "A página é a unidade que o PostgreSQL escreve, e ela é duas das unidades que o sistema de arquivos escreve. Nada faz os dois blocos chegarem juntos."}
```

O PostgreSQL não consegue impedir isso, então ele se organiza para consertar. Na primeira vez que
uma página muda depois de um checkpoint, a página inteira vai para o WAL, e a recuperação depois de
uma queda escreve essa cópia por cima de qualquer página meio escrita que encontrar. Isso é o
`full_page_writes`, que a lição 8 mediu e que é o motivo de ele continuar ligado. Um sistema de
arquivos que nunca rasga uma escrita, como o ZFS com seu desenho de cópia na escrita, é o único
caso em que é seguro desligá-lo, e mesmo assim só com a documentação desse sistema de arquivos
aberta.

## A configuração que você não muda

O `block_size` só muda compilando o PostgreSQL por conta própria e criando um cluster novo com o
resultado. Um tamanho de página diferente deixa todo arquivo de dados incompatível com toda versão
normal, então nenhum servidor de pacote, serviço gerenciado ou autor de extensão espera por ele.
**Trate 8192 como um fato sobre o PostgreSQL, e não como um parâmetro.** O que você escolhe é o
disco e o sistema de arquivos onde ele fica, que é o resto desta lição.
