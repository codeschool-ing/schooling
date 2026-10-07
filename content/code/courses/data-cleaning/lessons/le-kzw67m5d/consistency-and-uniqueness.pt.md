---
title: Coerência e unicidade: uma coisa, de um jeito, uma vez
version: 1
---

**A coerência pergunta se o mesmo fato é registrado do mesmo jeito em todo lugar em que aparece.**
Dentro de uma coluna, isso quer dizer uma grafia por valor e um formato por tipo. Entre arquivos,
quer dizer que dois registros da mesma coisa concordam. A **unicidade** é parente próxima: cada
coisa do mundo aparece uma vez no dado que diz listá-la.

## Dentro de uma coluna

A Quitanda Verde atende cinco cidades. O arquivo de clientes discorda:

```
ana@lab:~/clean$ psql -c "SELECT count(DISTINCT city) AS spellings FROM raw.customers"
 spellings 
-----------
        28
(1 row)

ana@lab:~/clean$ psql -c "SELECT normalize(city, NFC) AS city_as_shown, octet_length(city) AS bytes, count(*) FROM raw.customers WHERE city ILIKE '%paulo%' GROUP BY city ORDER BY count(*) DESC"
 city_as_shown | bytes | count 
---------------+-------+-------
 São Paulo     |    10 |   458
 São Paulo     |    11 |   213
 Sao Paulo     |     9 |    96
 SAO PAULO     |     9 |    59
 são paulo     |    10 |    37
 S. Paulo      |     8 |    33
 São Paulo     |    11 |    25
 SÃ£o Paulo    |    12 |     9
 são paulo     |    11 |     9
 São Paulo     |    12 |     9
 sÃ£o paulo    |    12 |     1
(11 rows)
```

Vinte e oito grafias para cinco cidades, onze delas só para São Paulo. Algumas diferenças se veem —
`SAO PAULO`, `S. Paulo`, `Sao Paulo` — e outras não. **As duas primeiras linhas parecem idênticas e
são textos diferentes**, dez bytes contra onze. O aplicativo guarda o acento do `ã` como um
caractere separado depois do `a`, então os bytes diferem enquanto a tela mostra a mesma palavra; a
aula 6 desmonta isso. (A consulta passa a coluna por `normalize()` só para imprimi-la, porque o
acento separado desalinharia esta própria tabela.) Um espaço no fim é o mesmo truque no fim da
palavra: a linha de 25 é `São Paulo ` com onze bytes. `SÃ£o Paulo` é o que uma migração em 2023
deixou para trás depois de ler UTF-8 como se fosse Latin-1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 346\" role=\"img\" data-fig=\"l01-sao-paulo\" aria-label=\"Um gráfico de barras das 11 maneiras como a coluna city do customers.csv escreve São Paulo, 949 clientes ao todo. A grafia certa tem 458 linhas; o resto se divide entre acento decomposto, sem acento, maiúsculas, abreviação, espaço no fim e texto estragado por uma migração.\"><text x=\"200.0\" y=\"49.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo&quot;</text><rect x=\"210.0\" y=\"40.0\" width=\"260.0\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"476.0\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">458</text><text x=\"500.0\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a grafia que todo mundo quer dizer</text><text x=\"200.0\" y=\"75.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo&quot;</text><rect x=\"210.0\" y=\"66.0\" width=\"120.9\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"336.9\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">213</text><text x=\"500.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acento guardado à parte</text><text x=\"200.0\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Sao Paulo&quot;</text><rect x=\"210.0\" y=\"92.0\" width=\"54.5\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270.5\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">96</text><text x=\"500.0\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem acento</text><text x=\"200.0\" y=\"127.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;SAO PAULO&quot;</text><rect x=\"210.0\" y=\"118.0\" width=\"33.5\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"249.5\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">59</text><text x=\"500.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem acento, maiúsculas</text><text x=\"200.0\" y=\"153.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;são paulo&quot;</text><rect x=\"210.0\" y=\"144.0\" width=\"21.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"237.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">37</text><text x=\"500.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">maiúsculas</text><text x=\"200.0\" y=\"179.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;S. Paulo&quot;</text><rect x=\"210.0\" y=\"170.0\" width=\"18.7\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"234.7\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33</text><text x=\"500.0\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abreviado</text><text x=\"200.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo &quot;</text><rect x=\"210.0\" y=\"196.0\" width=\"14.2\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"230.2\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25</text><text x=\"500.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um espaço depois</text><text x=\"200.0\" y=\"231.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;SÃ£o Paulo&quot;</text><rect x=\"210.0\" y=\"222.0\" width=\"5.1\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"221.1\" y=\"231.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><text x=\"500.0\" y=\"231.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acento estragado em 2023</text><text x=\"200.0\" y=\"257.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo &quot;</text><rect x=\"210.0\" y=\"248.0\" width=\"5.1\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"221.1\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><text x=\"500.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acento guardado à parte, um espaço depois</text><text x=\"200.0\" y=\"283.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;são paulo&quot;</text><rect x=\"210.0\" y=\"274.0\" width=\"5.1\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"221.1\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><text x=\"500.0\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acento guardado à parte, maiúsculas</text><text x=\"200.0\" y=\"309.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;sÃ£o paulo&quot;</text><rect x=\"210.0\" y=\"300.0\" width=\"0.6\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"216.6\" y=\"309.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><text x=\"500.0\" y=\"309.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acento estragado em 2023, maiúsculas</text><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">city, no customers.csv</text><text x=\"500.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que muda</text></svg>", "caption": "Uma cidade, 11 valores. Só a primeira barra é o que um GROUP BY chamaria de São Paulo."}
```

Qualquer `GROUP BY city` sobre esta coluna informa onze cidades onde há uma, e a maior delas, a
grafia certa, tem 458 das 949 linhas. Um gráfico de clientes por cidade mostraria São Paulo com
menos da metade do tamanho, e nada na consulta pareceria errado.

Datas são o mesmo problema com consequências piores, porque uma data no formato errado continua
ordenando:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, min(signed_up), max(signed_up) FROM raw.customers GROUP BY signup_channel"
 signup_channel |    min     |    max     
----------------+------------+------------
 site           | 2023-01-19 | 2025-12-10
 app            | 01/02/2024 | 12/31/2024
 import-2023    | 01/06/2023 | 25/08/2023
 store          | 01/01/2024 | 31/12/2024
(4 rows)
```

O site escreve `2025-12-10`, o aplicativo escreve `12/31/2024` com o mês primeiro, e as lojas
escrevem `31/12/2024` com o dia primeiro. Como texto, `max()` compara caracteres, então a data mais
recente do aplicativo sai `12/31/2024`, embora o aplicativo tenha cadastrado gente o ano de 2025
inteiro: uma data como `12/05/2025` fica abaixo de `12/31/2024`, porque `0` vem antes de `3`.
**Uma coluna com três formatos de data não falha; responde a uma pergunta diferente da que você
fez.** A aula 7 as converte.

## Unicidade

Um número de pedido deveria identificar um pedido:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS rows, count(DISTINCT order_id) AS order_ids FROM raw.orders"
 rows  | order_ids 
-------+-----------
 28551 |     28526
(1 row)
```

28.551 linhas e 28.526 números de pedido: 25 pedidos aparecem duas vezes. O aplicativo reenvia um
pedido quando não recebe resposta a tempo, e as duas cópias chegaram à exportação. Cada uma delas
contou duas vezes na receita da seção anterior. A aula 5 é sobre achar duplicados, e estes são do
tipo fácil — mesma chave, mesma linha. O tipo difícil é a mesma pessoa sob duas chaves, que uma
contagem de ids distintos não enxerga de jeito nenhum.

## Entre arquivos

O total do pedido deveria ser igual aos seus itens, menos o desconto, mais o frete. Os pedidos
deveriam pertencer a clientes que o arquivo de clientes conhece. As duas coisas são coerência entre
dois arquivos, e as duas falham aqui: a aula 9 acha os totais que discordam dos próprios itens, e a
próxima seção conta os pedidos que não pertencem a ninguém.
