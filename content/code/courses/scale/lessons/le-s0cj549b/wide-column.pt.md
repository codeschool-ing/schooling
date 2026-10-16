---
title: Coluna larga, linhas ordenadas dentro de uma partição
version: 1
---

O nome **coluna larga** engana, porque a ideia útil não é a largura. Uma tabela desta família tem
uma **chave de partição**, que decide qual servidor guarda uma linha, como no sharding da aula 2, e
uma **chave de agrupamento** (*clustering key*), que mantém as linhas dentro de uma partição
**ordenadas no disco**. Uma consulta nomeia uma partição e lê uma fatia dela em ordem, de um
servidor, sem ordenar nada.

O terceiro padrão de acesso da seção 03 é o encaixe clássico: ingressos lidos na portaria, milhares
por minuto numa noite de show, lidos de volta por show em ordem de tempo. A tabela é desenhada em
torno dessa leitura:

```
CREATE TABLE scans (
  show_id    text,
  scanned_at timestamp,
  ticket     text,
  gate       text,
  PRIMARY KEY ((show_id), scanned_at, ticket)
) WITH CLUSTERING ORDER BY (scanned_at DESC);
```

Os parênteses duplos marcam a chave de partição, `show_id`; o que vem depois, `scanned_at` e
`ticket`, é a chave de agrupamento. Toda leitura do show 1 está numa partição, da mais nova para a
mais velha, então "as últimas 50 leituras do show 1" é uma leitura num servidor que para depois de
50 linhas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três servidores. A chave de partição show_id decide o servidor: o show 1 no primeiro, o show 2 no segundo, o show 3 no terceiro. Dentro da partição do show 1, as leituras de portaria ficam ordenadas por hora, da mais nova para a mais velha, e uma consulta pelas três últimas lê o topo dessa lista.\"><rect x=\"20\" y=\"20\" width=\"210\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">servidor 1</text><text x=\"125\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show_id = 1</text><rect x=\"40\" y=\"74\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">21:04:09  T-100</text><rect x=\"40\" y=\"101\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">21:04:07  T-107</text><rect x=\"40\" y=\"128\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">21:04:02  T-114</text><rect x=\"40\" y=\"155\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:58  T-121</text><rect x=\"40\" y=\"182\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:51  T-128</text><rect x=\"255\" y=\"20\" width=\"210\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">servidor 2</text><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show_id = 2</text><rect x=\"275\" y=\"74\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:09  T-101</text><rect x=\"275\" y=\"101\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:07  T-108</text><rect x=\"275\" y=\"128\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:02  T-115</text><rect x=\"275\" y=\"155\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:58  T-122</text><rect x=\"275\" y=\"182\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:51  T-129</text><rect x=\"490\" y=\"20\" width=\"210\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">servidor 3</text><text x=\"595\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show_id = 3</text><rect x=\"510\" y=\"74\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:09  T-102</text><rect x=\"510\" y=\"101\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:07  T-109</text><rect x=\"510\" y=\"128\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:02  T-116</text><rect x=\"510\" y=\"155\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:58  T-123</text><rect x=\"510\" y=\"182\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:51  T-130</text><text x=\"125\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">LIMIT 3: o topo de uma partição</text></svg>", "caption": "A chave de partição escolhe o servidor; a chave de agrupamento mantém as linhas em ordem dentro dele."}
```

## Por que escreve rápido

Uma leitura de portaria é um acréscimo. Os armazenamentos desta família, o Cassandra sendo o mais
conhecido, gravam numa tabela na memória e num log de commits, e descarregam no disco em arquivos
grandes e ordenados que nunca são modificados, só fundidos em segundo plano. **Nenhuma escrita lê
nada antes**, então as escritas continuam rápidas à medida que os dados crescem, e um cluster de
muitos servidores absorve uma enxurrada delas. É feito para o contrário da venda da bilheteria:
muitas escritas, poucos tipos de leitura.

## O que ele pede de você

- **Uma tabela por consulta.** "Toda leitura no portão B esta noite" não é respondida por esta
  tabela, porque `gate` não está na chave, e o armazenamento recusa uma consulta que leria todas as
  partições a menos que se diga explicitamente que pode. A resposta é uma segunda tabela,
  `scans_by_gate`, gravada junto.
- **Partições de tamanho limitado.** Uma partição mora num servidor. Toda leitura de um show numa
  partição está bem; toda leitura de todo show de sempre, sob uma chave como `'all'`, faz um
  servidor guardar tudo, que é de novo o shard quente da aula 2.
- **A consistência da aula 3, escolhida por consulta.** O Cassandra deixa cada leitura e cada
  escrita nomear o seu quórum: `ONE`, `QUORUM`, `ALL`. A aritmética de W + R > N é como ler essas
  palavras.

A aula 5 cria esta tabela no Cassandra e roda a consulta.
