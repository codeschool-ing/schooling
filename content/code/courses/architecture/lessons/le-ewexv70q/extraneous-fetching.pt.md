---
title: Busca desnecessária
version: 1
---

A lista do catálogo mostra cinquenta produtos, cada um com nome e preço. Escrita com `SELECT *`, a
consulta também traz a descrição de cada produto, que a lista nunca mostra:

```
ana@vm:~/lab/perf$ $P catalogue-star
catalogue-star: 1 queries, 50 rows, 1,000,775 bytes, 33 ms
ana@vm:~/lab/perf$ $P catalogue-columns
catalogue-columns: 1 queries, 50 rows, 775 bytes, 4 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas barras para a mesma lista de catálogo de cinquenta produtos. SELECT asterisco devolve cerca de um milhão de bytes, quase tudo descrições que a lista nunca mostra. Selecionar id, nome e preço devolve 775 bytes, uma barra curta demais para ver ao lado da outra.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">SELECT *</text><rect x=\"200\" y=\"36\" width=\"480\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1.000.775 bytes</text><text x=\"30\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">id, name, cents</text><rect x=\"200\" y=\"96\" width=\"4\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"214\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">775 bytes</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os mesmos cinquenta nomes e preços na tela</text></svg>", "caption": "Busca desnecessária: a página mostra a mesma coisa dos dois jeitos; uma consulta move mil vezes mais dados para mostrá-la."}
```

**Um milhão de bytes contra 775**, para os mesmos cinquenta nomes e preços na tela, e 33 milissegundos
contra 4. O banco leu as descrições do disco, a rede as levou, o driver as transformou em strings do
Python, e a página as jogou fora. Na máquina do laboratório são 29 milissegundos; em produção também é
banda cobrada entre zonas, memória em toda instância da aplicação, e um cache do banco cheio de descrições
que ninguém pediu.

`SELECT *` é a forma comum. As outras valem a pena reconhecer de vista:

| o hábito | o que ele move à toa |
| --- | --- |
| `SELECT *` numa tabela com uma coluna grande | a coluna grande |
| buscar toda linha e filtrar na aplicação | toda linha que depois é descartada |
| buscar todas as linhas de uma lista que ninguém pagina | tudo além da primeira página; use `LIMIT` e paginação por chave |
| uma API que devolve o objeto inteiro para todo uso | campos que quem chama ignora; a aula 3 do curso `apis` é sobre esse problema |
| carregar um agregado inteiro para mudar um campo | o agregado |

A correção é sempre pedir o que a tela usa. É também por isso que algumas equipes proíbem `SELECT *` no
código da aplicação: uma coluna acrescentada à tabela no ano que vem, uma grande, entraria em silêncio em
toda consulta que o usasse.
