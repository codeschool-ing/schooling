---
title: Trocar, não acrescentar
version: 1
---

O `fact_sales.sql` de verdade, rodado duas vezes no mesmo dia:

```
ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales.sql
psql:load/fact_sales.sql:10: NOTICE:  relation "fact_sales" already exists, skipping
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   448 | c5aa6b634e10684f652731525f1e420f
(1 row)

ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales.sql
psql:load/fact_sales.sql:10: NOTICE:  relation "fact_sales" already exists, skipping
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   448 | c5aa6b634e10684f652731525f1e420f
(1 row)
```

448 linhas, a mesma impressão digital de antes da carga ingênua, e a mesma de novo depois de uma
segunda execução — o dia carregado três vezes incluído, já que o primeiro `DELETE` tirou as 1.344
linhas. (O `NOTICE` é o `CREATE TABLE IF NOT EXISTS` do topo do arquivo encontrando a tabela lá.) A
carga é idempotente por causa de uma decisão: **ela não acrescenta o dia, ela o troca**. Apagar tudo o
que a carga vai escrever, depois escrever, numa transação.

Essa é uma das três formas que uma carga idempotente pode ter, e entre elas cobrem quase toda carga
deste curso:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l15-shapes\" aria-label=\"Três formas de carga idempotente, cada uma rodada duas vezes. Apagar e depois inserir: a fatia de que a execução é dona é tirada e escrita de novo, então a segunda execução deixa a mesma fatia. Upsert: cada linha é escrita pela chave, então a segunda execução atualiza as linhas para os valores que elas já têm. Reconstruir e trocar: o resultado inteiro é construído ao lado do antigo e posto no lugar dele, então a segunda execução constrói o mesmo resultado de novo.\"><rect x=\"20.0\" y=\"20.0\" width=\"216.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"128.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">apagar, depois inserir</text><text x=\"128.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pela fatia de que a execução é dona</text><text x=\"128.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">fact_sales.sql · delete+insert</text><text x=\"128.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segunda execução:</text><text x=\"128.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a mesma fatia de novo</text><rect x=\"252.0\" y=\"20.0\" width=\"216.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">upsert pela chave</text><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">INSERT … ON CONFLICT</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">dim_book</text><text x=\"360.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segunda execução:</text><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cada chave já está lá</text><rect x=\"484.0\" y=\"20.0\" width=\"216.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"592.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">reconstruir e trocar</text><text x=\"592.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">construir ao lado, depois renomear</text><text x=\"592.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a table do dbt</text><text x=\"592.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segunda execução:</text><text x=\"592.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a mesma tabela de novo</text></svg>", "caption": "Cada forma responde à mesma pergunta: por que uma segunda execução escreveria as mesmas linhas, e não mais?"}
```

- **Apagar, depois inserir**, por uma chave que nomeia tudo de que a execução é responsável: o dia no
  `fact_sales.sql`, o `order_date` no `delete+insert` do dbt. Certo quando uma execução é dona de uma
  fatia inteira — um dia, uma loja, um arquivo.
- **Upsert**, pela chave da própria linha: `INSERT … ON CONFLICT DO UPDATE`, como o `dim_book` faz
  desde a lição 7. Certo quando as linhas chegam uma a uma e cada uma tem identidade. Uma segunda
  execução acha cada chave já lá e a atualiza para o valor que ela já tem.
- **Reconstruir e trocar**: construir o resultado inteiro ao lado do antigo, depois substituí-lo num
  passo só, como uma `table` do dbt faz com o seu `__dbt_tmp`. Certo quando o resultado é pequeno o
  bastante para construir inteiro, e a mais simples das três de acertar.

O que as três evitam é o `INSERT` puro de linhas que talvez já estejam lá. A pergunta a fazer a
qualquer carga é: **se isto rodasse uma segunda vez, agora, o que faria escrever as mesmas linhas em
vez de mais?** Se a resposta for *nada*, a carga não é idempotente, por mais cuidado com que tenha
sido escrita.
