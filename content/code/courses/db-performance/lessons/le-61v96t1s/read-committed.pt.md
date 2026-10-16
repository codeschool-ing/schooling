---
title: Read committed, e o update que sumiu
version: 1
---

Um nível de isolamento decide o que uma transação consegue ver das outras que rodam ao mesmo tempo.
A aula 8 de `sql-databases` deu nome aos quatro que o padrão define e às anomalias que cada um
permite; esta aula roda os três que o PostgreSQL implementa no `market`, com duas janelas e depois
com o pgbench, e conta o que cada um deixa passar. A crença para largar primeiro: **que uma
transação protege o que ela lê.** No nível padrão do PostgreSQL ela não protege nada do que lê, só o
que escreve.

## Read committed, numa frase

`READ COMMITTED` é o padrão: **cada comando vê os dados como estavam confirmados no momento em que
esse comando começou.** Dois `SELECT` na mesma transação podem ver valores diferentes se alguém
confirmou no meio, e ter lido uma linha não impede ninguém de mudá-la.

## Uma atualização perdida, à mão

Duas pessoas da equipe aumentam o preço do produto 1 em 100 centavos no mesmo momento, por uma
aplicação que lê o preço, soma 100 e escreve o resultado. Abra duas janelas com `psql market`. Na
janela A:

```
market=# BEGIN;
BEGIN
Time: 0.377 ms

market=*# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9290
(1 row)

Time: 2.034 ms
```

A janela B lê a mesma linha:

```
market=# BEGIN;
BEGIN
Time: 0.528 ms

market=*# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9290
(1 row)

Time: 1.321 ms
```

A janela A escreve o novo preço, 9290 + 100:

```
market=*# UPDATE products SET price_cents = 9390 WHERE id = 1;
UPDATE 1
Time: 0.918 ms
```

A janela B escreve o novo preço dela, também 9290 + 100, e espera, porque a janela A segura a trava
(lock) da linha:

```
market=*# UPDATE products SET price_cents = 9390 WHERE id = 1;
```

A janela A confirma:

```
market=*# COMMIT;
COMMIT
Time: 5.784 ms
```

E a janela B passa:

```
market=*# UPDATE products SET price_cents = 9390 WHERE id = 1;
UPDATE 1
Time: 5880.543 ms (00:05.881)

market=*# COMMIT;
COMMIT
Time: 0.941 ms

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9390
(1 row)

Time: 0.462 ms
```

**Dois aumentos de 100, e o preço foi de 9290 para 9390.** Nenhum erro, nenhum aviso, e as duas
janelas fizeram exatamente o que mandaram. A janela B até esperou 5881 ms pela trava da janela A, e
não adiantou, porque o valor que ela ia escrever já tinha sido decidido pelo `SELECT` dela, antes da
espera:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Uma linha do tempo de duas transações em read committed. A janela A lê o preço 9290, depois a janela B lê 9290. A janela A escreve 9390, calculado a partir da leitura dela. A janela B tenta escrever 9390, calculado a partir da própria leitura, e espera a trava de linha de A. A confirma. O update de B passa e escreve 9390 por cima do 9390 de A. Foram feitos dois aumentos de 100, e o preço subiu 100: um se perdeu.\"><text x=\"14\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela A</text><text x=\"14\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela B</text><path d=\"M110 56 L706 56\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M110 136 L476 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M634 136 L706 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><circle cx=\"150\" cy=\"56\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"150\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SELECT → 9290</text><text x=\"150\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">lê</text><circle cx=\"260\" cy=\"136\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"260\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SELECT → 9290</text><text x=\"260\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">lê o mesmo</text><circle cx=\"370\" cy=\"56\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"370\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SET 9390</text><text x=\"370\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9290 + 100</text><rect x=\"480\" y=\"126\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"555\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">espera a trava de A</text><text x=\"480\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">SET 9390</text><circle cx=\"480\" cy=\"136\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"630\" cy=\"56\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"630\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">COMMIT</text><path d=\"M630 60 L630 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></path><circle cx=\"640\" cy=\"136\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">preço depois dos dois commits:</text><text x=\"200\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">9390</text><text x=\"250\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dois aumentos de 100 foram feitos, e um deles sumiu</text></svg>", "caption": "A atualização perdida. Esperar a trava de linha não ajudou a janela B, porque o valor que ela escreveu foi decidido por uma leitura feita antes da espera."}
```

Essa é a **atualização perdida** (lost update), e o `READ COMMITTED` a permite toda vez que a
aplicação lê um valor, calcula com ele e escreve o resultado de volta.

## Dois consertos que funcionam em read committed

**Deixe a conta para o banco.** Se o novo valor é calculado dentro do `UPDATE`, a partir da linha
como o `UPDATE` a encontra, não há leitura velha para calcular:

```
market=# BEGIN;
BEGIN
Time: 0.260 ms

market=*# UPDATE products SET price_cents = price_cents + 100 WHERE id = 1;
UPDATE 1
Time: 0.613 ms

market=*# COMMIT;
COMMIT
Time: 1.565 ms
```

```
market=# BEGIN;
BEGIN
Time: 0.241 ms

market=*# UPDATE products SET price_cents = price_cents + 100 WHERE id = 1;
UPDATE 1
Time: 4263.991 ms (00:04.264)

market=*# COMMIT;
COMMIT
Time: 1.190 ms

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9590
(1 row)

Time: 0.528 ms
```

A janela B esperou 4264 ms de novo, e desta vez a espera fez diferença: quando a janela A
confirmou, o `UPDATE` da janela B **releu a linha pela qual tinha esperado** e somou os 100 dela a
9490, não a 9390. **9390 + 100 + 100 = 9590**, os dois aumentos mantidos. `SET price_cents =
price_cents + 100`, `SET stock = stock - 1` e afins são sempre seguros em `READ COMMITTED`, e devem
ser a primeira coisa a que você recorre.

**Trave a linha quando a ler.** Quando o novo valor precisa de uma lógica que não cabe no `UPDATE`,
leia com `FOR UPDATE`, como a aula 12 fez, para que o segundo leitor espere **antes** de ler:

```
market=# BEGIN;
BEGIN
Time: 0.194 ms

market=*# SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
 price_cents 
-------------
        9590
(1 row)

Time: 0.547 ms
```

```
market=# BEGIN;
BEGIN
Time: 0.272 ms

market=*# SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
```

A janela A escreve 9590 + 100 e confirma:

```
market=*# UPDATE products SET price_cents = 9690 WHERE id = 1;
UPDATE 1
Time: 0.641 ms

market=*# COMMIT;
COMMIT
Time: 1.834 ms
```

```
market=*# SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
 price_cents 
-------------
        9690
(1 row)

Time: 4371.858 ms (00:04.372)

market=*# UPDATE products SET price_cents = 9790 WHERE id = 1;
UPDATE 1
Time: 0.519 ms

market=*# COMMIT;
COMMIT
Time: 140.777 ms

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
        9790
(1 row)

Time: 0.495 ms
```

A leitura da janela B esperou 4372 ms e então devolveu **9690**, o preço depois do aumento da janela
A, então a escrita dela, 9790, manteve os dois. O custo é que todo leitor daquela linha naquele
caminho do código espera na fila, que é o custo certo quando a linha é um preço que alguém está
prestes a mudar.

## A mesma coisa alguns milhares de vezes por segundo

Duas janelas mostram o mecanismo. Uma carga mostra o tamanho. Este script do pgbench é a aplicação
acima: lê um de dez preços e o escreve de volta um centavo mais alto. Grave-o ao lado da carga da
aula 2:

```sh
cat > ~/workload/price-bump.sql <<'SQL'
-- price-bump.sql: read a price, then write it back one cent higher,
-- the way an application that computes the new value itself does.
\set p random(1, 10)
BEGIN;
SELECT price_cents FROM products WHERE id = :p \gset
UPDATE products SET price_cents = :price_cents + 1 WHERE id = :p;
COMMIT;
SQL
```

Então, no `psql market`, guarde a soma desses dez preços, rode oito clientes por dez segundos e veja
quantos centavos foram de fato somados. Toda transação que deu certo queria somar exatamente um:

```
market=# SELECT sum(price_cents) AS before FROM products WHERE id <= 10 \gset
Time: 1.516 ms

market=# \! pgbench -n -c 8 -j 4 -T 10  -f ~/workload/price-bump.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/price-bump.sql
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 55802
number of failed transactions: 0 (0.000%)
latency average = 1.434 ms
initial connection time = 8.344 ms
tps = 5578.479039 (without initial connection time)

market=# SELECT sum(price_cents) - :before AS cents_added FROM products WHERE id <= 10;
 cents_added 
-------------
       37821
(1 row)

Time: 0.803 ms
```

**55.802 transações confirmadas, e os preços subiram 37.821 centavos. 17.981 aumentos, quase um
terço, sumiram**, e o pgbench relata `0` transações com falha, porque do ponto de vista do servidor
nada falhou. Oito clientes em dez linhas é muita disputa, de propósito; numa tabela de verdade com
milhares de linhas a perda é mais rara, e isso a torna pior, não melhor: vira um número que não
fecha uma vez por semana, e que ninguém consegue reproduzir.

Os dois consertos acima a eliminam. A próxima seção mostra um terceiro: um nível de isolamento mais
alto, que não impede a corrida, mas se recusa a deixar o perdedor confirmar.
