---
title: LIMIT, e por que a paginação de todo mundo está errada
version: 1
---

```sql
SELECT name, price FROM products ORDER BY id LIMIT 10;
```

Dez linhas. O `LIMIT` roda por último, depois da ordenação, então pega as dez primeiras de um
resultado arrumado — que é por que a seção anterior insistiu que o arranjo não pode empatar.

```sql
LIMIT 10 OFFSET 20       -- pule 20, pegue 10
FETCH FIRST 10 ROWS ONLY -- a grafia do padrão, raramente vista
```

E é assim que essencialmente toda aplicação do mundo escreve paginação:

```sql
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 0;      -- página 1
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 20;     -- página 2
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 40;     -- página 3
```

Funciona, é óbvio, e tem dois defeitos que só aparecem num tamanho que você não tem enquanto
constrói.

## Defeito um: fica mais lento quanto mais fundo você vai

**`OFFSET 100000` não pula para a linha 100.000. Ele lê 100.020 linhas e joga 100.000 fora.**

Não há como não ser: para saber qual linha é a centésima milésima numa ordem, o banco tem que
produzir as noventa e nove mil novecentas e noventa e nove antes dela.

Então o custo de uma página cresce com a profundidade. A página 1 é instantânea, a 500 é lenta, a
5.000 estoura o tempo — e as consultas são idênticas exceto por um número, que é por que ninguém
desconfia da consulta. O que leva a culpa é o tamanho da tabela, e a tabela está bem.

## Defeito dois: mostra a mesma linha duas vezes

Alguém está lendo a página 1 enquanto um produto novo é inserido e ordena acima de tudo que essa
pessoa viu. Ela clica para a página 2. Tudo deslocou uma posição para baixo, então o `OFFSET 20`
agora começa na linha que era a última da página 1.

**Ela vê aquela linha duas vezes, e a linha que seria a primeira da página 2 nunca é mostrada.** Sem
erro, sem nada num log, e é irreproduzível porque depende do momento de outra pessoa.

Numa tabela movimentada isso não é caso raro. É o que acontece o dia inteiro, em silêncio.

## Paginação por chave conserta os dois

Em vez de contar linhas para pular, lembre onde a última página **terminou** e peça o que vem depois:

```sql
-- primeira página
SELECT * FROM products ORDER BY id LIMIT 20;

-- a próxima, dado que a última linha mostrada tinha id 4711
SELECT * FROM products WHERE id > 4711 ORDER BY id LIMIT 20;
```

A segunda consulta é uma varredura de faixa numa coluna indexada. **Ela custa o mesmo seja a página 2
ou a 20.000**, porque o banco salta para dentro do índice em 4711 e caminha vinte entradas. E inserir
uma linha acima de 4711 não muda nada sobre o que vem depois, então ninguém vê duplicata.

Com mais de uma chave de ordenação, compare a tupla inteira:

```sql
SELECT * FROM products
WHERE  (created_at, id) < ('2026-03-07 10:00:00+00', 4711)
ORDER BY created_at DESC, id DESC
LIMIT  20;
```

Comparação de tupla — `(a, b) < (x, y)` — é SQL padrão e faz exatamente o que a aritmética sugere,
comparando da esquerda para a direita. Escrever como `created_at < x OR (created_at = x AND id < y)`
significa o mesmo e é mais difícil de acertar.

## O que a paginação por chave custa

Não é de graça, e a troca merece ser dita com clareza:

- **Não existe "pular para a página 57".** Você vai adiante e volta, não para um número arbitrário,
  porque uma página é definida por onde a anterior terminou e não por uma contagem.
- **O cursor tem que viajar** — na URL, na resposta — em vez de ser um número de página.
- **A ordenação tem que ser total**, terminando em algo único, exatamente pela razão da seção
  anterior.

O primeiro é o que as pessoas contestam, e vale perguntar quanto ele custa de verdade: quase ninguém
usa o salto por número além das primeiras páginas, e as páginas fundas eram justamente as quebradas.

> **Paginação por offset para uma lista curta e estável que alguém vai ler inteira. Por chave para
> qualquer coisa que cresce ou muda enquanto é lida.**

## `LIMIT` na natureza

Mais dois usos, e um deles é armadilha:

```sql
SELECT * FROM products ORDER BY price DESC LIMIT 1;    -- o mais caro
SELECT * FROM products LIMIT 100;                      -- uma olhada na tabela
```

O primeiro é o jeito comum de pedir a linha de máximo, e é melhor do que parece: com um índice em
`price`, o banco caminha uma entrada.

O segundo serve num terminal e é bug num programa. Sem `ORDER BY` são cem linhas arbitrárias de um
arranjo arbitrário, o que serve para olhar uma tabela e não significa nada como resposta — e é onde
esta seção começou.
