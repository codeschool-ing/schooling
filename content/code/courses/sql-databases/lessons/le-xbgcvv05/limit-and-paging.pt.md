---
title: LIMIT, e por que a paginação de todo mundo está errada
version: 2
---

```sql
SELECT name, price FROM products ORDER BY id LIMIT 10;
```

Dez linhas. O `LIMIT` roda por último, depois da ordenação, então pega as dez primeiras de um
resultado arrumado — que é por que a seção anterior insistiu que o arranjo não pode empatar.

```sql
LIMIT 10 OFFSET 20      -- skip 20, take 10
FETCH FIRST 10 ROWS ONLY -- the standard spelling, rarely seen
```

E é assim que essencialmente toda aplicação do mundo escreve paginação:

```sql
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 0;      -- page 1
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 20;     -- page 2
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 40;     -- page 3
```

Funciona, é óbvio, e tem dois defeitos que só aparecem num tamanho que você não tem enquanto
constrói.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Duas fileiras de seis linhas de resultado cada, rotuladas como a consulta que buscou a página um e a consulta que buscou a página dois. Quatro das linhas compartilham o horário 12:00. Uma linha tracejada depois da terceira caixa marca onde a página um termina e a dois começa. Na segunda consulta as linhas empatadas voltaram em outra ordem, então C cai nas duas páginas e D não cai em nenhuma. Uma nota diz: C aparece duas vezes e D não aparece nenhuma.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Quatro linhas compartilham um horário. Nada promete qual delas vem primeiro, e as duas páginas são duas consultas separadas.</text><text x=\"14\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a consulta que buscou a página 1</text><rect x=\"14\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"64\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">A  12:00</text><rect x=\"122\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"172\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">B  12:00</text><rect x=\"230\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">C  12:00</text><rect x=\"338\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"388\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">D  12:00</text><rect x=\"446\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">E  12:01</text><rect x=\"554\" y=\"72\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"604\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">F  12:01</text><path d=\"M332 68 L332 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"326\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">página 1</text><text x=\"338\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">página 2</text><text x=\"14\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a consulta que buscou a página 2</text><rect x=\"14\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"64\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">B  12:00</text><rect x=\"122\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"172\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">A  12:00</text><rect x=\"230\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">D  12:00</text><rect x=\"338\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">C  12:00</text><rect x=\"446\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">E  12:01</text><rect x=\"554\" y=\"148\" width=\"100\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"604\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">F  12:01</text><path d=\"M332 144 L332 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"326\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">página 1</text><text x=\"338\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">página 2</text><text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">C aparece duas vezes — está na página 1 e de novo na 2 — e D não aparece nenhuma.</text><text x=\"14\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O conserto não é uma página maior: é um ORDER BY que não pode empatar.</text></svg>", "caption": "OFFSET conta linhas numa arrumação que ninguém prometeu. Entre duas consultas o empate pode cair para o outro lado, e uma linha fica nas duas páginas ou em nenhuma."}
```

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
-- first page
SELECT * FROM products ORDER BY id LIMIT 20;

-- the next page, given that the last row you showed had id 4711
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
SELECT * FROM products ORDER BY price DESC LIMIT 1;    -- the most expensive
SELECT * FROM products LIMIT 100;                      -- a look at the table
```

O primeiro é o jeito comum de pedir a linha de máximo, e é melhor do que parece: com um índice em
`price`, o banco caminha uma entrada.

O segundo serve num terminal e é bug num programa. Sem `ORDER BY` são cem linhas arbitrárias de um
arranjo arbitrário, o que serve para olhar uma tabela e não significa nada como resposta — e é onde
esta seção começou.
