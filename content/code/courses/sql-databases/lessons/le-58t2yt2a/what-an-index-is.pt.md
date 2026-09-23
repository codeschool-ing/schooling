---
title: O que um índice de fato é
version: 2
---

```sql
CREATE INDEX ON customers (email);
```

Essa instrução faz algo físico. Ela constrói **uma segunda cópia da coluna `email`, mantida em
ordem, com um ponteiro ao lado de cada valor para a linha de onde ele veio.**

Não é uma configuração. Não é uma dica para o planejador. É uma estrutura, em disco, que precisa ser
escrita e mantida em dia, e é por isso que todo o resto desta aula é uma troca e não uma melhoria de
graça.

> **A tabela `orders` muda de forma daqui em diante.** As aulas 1 a 7 rodaram contra uma loja com
> algumas linhas, onde `ordered_on` é um `date` e toda consulta responde na hora — que é o certo
> quando o que se ensina é o que um join significa. Um índice só aparece contra volume, então esta
> aula e as duas seguintes rodam contra a mesma loja com um milhão de pedidos e um
> `placed_at timestamptz` no lugar de `ordered_on`. A saída capturada daqui em diante é desse
> banco. Nada muda no SQL; o que muda é que uma varredura passa a custar algo que dá para ler no
> relógio.

## Por que estar em ordem é o truque inteiro

Sem ela, achar `ana@example.com` em um milhão de linhas significa ler um milhão de linhas. Não há
atalho, porque dado fora de ordem não tem atalho — a linha que você quer pode estar em qualquer
lugar.

Com ela, o banco abre a cópia ordenada no meio, compara, e joga metade fora. Depois metade daquilo.
Vinte desses passos chegam a uma linha em um milhão, e trinta chegam a uma em um bilhão.

| linhas | passos, mais ou menos |
|---|---|
| 1.000 | 10 |
| 1.000.000 | 20 |
| 1.000.000.000 | 30 |

Olhe essa tabela por um segundo, porque ela explica o formato de tudo o que vem depois: **mil vezes
mais dado custa dez passos a mais.** Uma varredura da mesma tabela custa mil vezes mais trabalho.
Essa distância é o que um índice compra, e é por isso que o ganho cresce com a tabela em vez de
ficar igual.

## A árvore B, rapidamente

A cópia ordenada não é uma lista plana — uma lista plana teria que ser reescrita toda vez que uma
linha fosse inserida no meio. É uma **árvore B**: uma árvore rasa de blocos, em que cada bloco
guarda uma faixa de valores e ponteiros para os blocos de baixo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"Um índice em árvore B sobre a coluna de e-mail. No alto, um bloco raiz com três letras separadoras: f, m e s. Quatro setas partem dele para quatro blocos folha, cobrindo de a a e, de f a l, de m a r e de s a z, desenhados em ordem da esquerda para a direita. A seta para a primeira folha e a própria folha estão acesas, e abaixo dela essa folha está aberta: três endereços de e-mail em ordem alfabética, cada um com um ponteiro ao lado. Uma seta tracejada sai do primeiro ponteiro e atravessa até um bloco separado à direita que guarda a linha em si, rotulado como uma leitura aleatória. Embaixo: mil linhas custam cerca de dez passos, um milhão cerca de vinte, um bilhão cerca de trinta, e três ou quatro níveis bastam para centenas de milhões de linhas, cada nível custando a leitura de um bloco.\"><text x=\"14\" y=\"20\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">CREATE INDEX ON customers (email)</text><rect x=\"250\" y=\"38\" width=\"220\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M323 38 L323 68\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M396 38 L396 68\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"286\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">f</text><text x=\"359\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">m</text><text x=\"432\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">s</text><text x=\"240\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">raiz</text><path d=\"M360 68 L96 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><rect x=\"14\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"96\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">a … e</text><path d=\"M360 68 L272 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"190\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">f … l</text><path d=\"M360 68 L448 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"366\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"448\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">m … r</text><path d=\"M360 68 L624 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"542\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">s … z</text><text x=\"706\" y=\"146\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">folhas, em ordem</text><path d=\"M96 132 L96 158\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><rect x=\"14\" y=\"158\" width=\"250\" height=\"82\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ana@example.com</text><text x=\"24\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">anders@example.com</text><text x=\"24\" y=\"214\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bea@example.com</text><circle cx=\"244\" cy=\"174\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"244\" cy=\"194\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"244\" cy=\"214\" r=\"3\" fill=\"var(--amber)\"></circle><text x=\"24\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">valor + ponteiro</text><path d=\"M250 174 L452 174\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><path d=\"M452 174 L444 170 L444 178 Z\" fill=\"var(--amber)\"></path><text x=\"351\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">uma leitura aleatória</text><rect x=\"456\" y=\"158\" width=\"250\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"466\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana  ana@example.com  BR</text><text x=\"466\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a linha no disco</text><path d=\"M14 258 L706 258\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"14\" y=\"274\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 000 rows ~10 steps   ·   1 000 000 ~20   ·   1 000 000 000 ~30</text><text x=\"14\" y=\"292\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três ou quatro níveis para centenas de milhões de linhas, e cada nível é uma leitura de bloco</text></svg>", "caption": "Cada nível custa a leitura de um bloco, então a profundidade quase não se mexe conforme a tabela cresce. A seta tracejada é o segundo passo, e é o caro."}
```

Três ou quatro níveis bastam para centenas de milhões de linhas, e cada nível é a leitura de um
bloco. Uma inserção vai para o bloco certo, e só divide um bloco quando ele está cheio — então a
árvore se mantém equilibrada sem ser reconstruída.

É este o tipo de índice padrão em todos os bancos deste curso, e quando alguém diz "um índice" sem
qualificar, é dele que está falando.

## O que ele consegue responder

Como a cópia está em ordem, ela serve a mais de um formato de pergunta:

```sql
WHERE email = 'ana@example.com'      -- find one value
WHERE email > 'm'                    -- find a position, then read forwards
WHERE created_at BETWEEN … AND …     -- find the start, read until the end
ORDER BY email                        -- read it in order, no sorting needed
WHERE email LIKE 'ana%'               -- a prefix is a range: 'ana' up to 'anb'
```

Este último vale guardar. `LIKE 'ana%'` é uma varredura de faixa e é rápido; `LIKE '%ana'` não é,
porque a cópia está ordenada pelo começo da string e nada sobre o fim dela está em ordem. É o mesmo
fato, e a seção depois da próxima é uma lista de coisas que são esse mesmo fato disfarçado.

## E o que custa seguir o ponteiro

Uma entrada de índice guarda o valor e um ponteiro, então responder a `SELECT * FROM customers WHERE
email = …` são dois passos: achar a entrada, e depois buscar a linha para a qual ela aponta. Essa
segunda busca é uma leitura aleatória em outro lugar do disco, e numa consulta que devolve muitas
linhas é a parte cara.

O que prepara duas coisas a que esta aula volta. **Uma consulta que só quer as colunas indexadas
pode pular o segundo passo por completo** — isso é o índice de cobertura. E **uma consulta que
teria que seguir o ponteiro para metade da tabela sai melhor lendo a tabela**, que é a razão honesta
de um planejador ignorar um índice perfeitamente bom.
