---
title: Estilos de distribuição, e a slice que faz todo o trabalho
version: 1
---

**O estilo de distribuição de uma tabela decide em que slice cada linha mora**, e com isso duas coisas
de que a velocidade de uma consulta depende: se toda slice tem a mesma quantidade de trabalho, e se
um join encontra as linhas correspondentes na mesma slice ou precisa movê-las pela rede antes. São
quatro estilos, e o errado não falha. Ele faz uma slice carregar a maior parte do trabalho enquanto as
outras esperam, e só aparece como uma consulta mais lenta do que deveria.

| estilo | para onde vai uma linha | serve para |
|---|---|---|
| `AUTO` | o Redshift escolhe, e muda a escolha conforme a tabela cresce | o padrão, e um começo razoável |
| `EVEN` | distribuída entre as slices em rodízio | uma tabela que nunca sofre join por uma coluna |
| `KEY` | a slice que um hash de uma coluna indica | duas tabelas grandes ligadas por join naquela coluna |
| `ALL` | uma cópia inteira em cada nó | uma tabela pequena ligada a tudo |

**O `AUTO` começa uma tabela pequena como `ALL` e a passa para `EVEN` conforme cresce**, e a AWS
documenta que ele pode mudar para `KEY` quando vê por qual coluna a tabela sofre join. É um padrão
sensato, e os outros três existem para quando você conhece os joins melhor do que as estatísticas.

## As tabelas, por escrito

O data warehouse da Quitanda começa com três tabelas: as lojas, algumas dezenas de linhas; os
clientes; e os pedidos, a grande. O DDL diz como cada uma é organizada, `orders.sql`:

```sql
CREATE TABLE stores (
    store_id     SMALLINT     NOT NULL,
    name         VARCHAR(64)  NOT NULL,
    district     VARCHAR(32)  NOT NULL
)
DISTSTYLE ALL;

CREATE TABLE customers (
    customer_id  VARCHAR(8)   NOT NULL,
    district     VARCHAR(32)  NOT NULL,
    signed_up    DATE         NOT NULL
)
DISTSTYLE KEY
DISTKEY (customer_id);

CREATE TABLE orders (
    order_id     VARCHAR(16)  NOT NULL,
    customer_id  VARCHAR(8)   NOT NULL,
    store_id     SMALLINT     NOT NULL,
    total_cents  INTEGER      NOT NULL,
    dt           DATE         NOT NULL
)
DISTSTYLE KEY
DISTKEY (customer_id)
COMPOUND SORTKEY (dt, customer_id);
```

**`stores` é `ALL`**: é minúscula e todo relatório faz join com ela, então cada nó guarda uma cópia e
nenhum join com ela move linha nenhuma. O preço é que toda carga de `stores` é gravada uma vez por nó,
o que não é nada com quarenta linhas e seria muito com quarenta milhões. **`customers` e `orders` são
ambas `KEY` em `customer_id`**, então um pedido e o cliente que o fez caem pelo hash na mesma slice, e
o join entre eles não move nada. A sort key é o assunto da próxima seção.

Enviado ao moto, o arquivo é aceito como o comando da seção anterior foi, e nada dele roda:

```
ana@laptop:~/aws$ aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql file://orders.sql --query Id --output text
8622c371-a211-4ad9-9815-0c2369cfbedd
ana@laptop:~/aws$ aws redshift-data describe-statement --id 8622c371-a211-4ad9-9815-0c2369cfbedd --query '[Status,HasResultSet]' --output text
STARTED	False
```

O que uma chave faz com as linhas ainda pode ser medido, com um modelo: um programa que põe dez mil
pedidos em quatro slices do jeito que um hash poria. **É um modelo da aritmética, não o Redshift**, e
é pequeno o bastante para ser lido inteiro. Salve-o como `~/aws/slices.py`:

```schooling-example
{"language": "python", "file": "slices.py", "parts": [{"code": "import hashlib\nimport random\n\nSLICES = 4\nrng = random.Random(14)\norders = []\nfor n in range(10_000):\n    if rng.random() < 0.4:\n        customer = 'c-01'\n    else:\n        customer = f'c-{rng.randint(2, 500):02d}'\n    orders.append((f'o-{n:05d}', customer))\n\n\n", "note": "Dez mil pedidos, gerados do mesmo jeito em toda execução porque o gerador aleatório tem semente. **Dois em cada cinco são de `c-01`**, uma rede de restaurantes que compra para todas as cozinhas; o resto se espalha por 499 residências. Quatro slices, como em dois nós `ra3.xlplus`."}, {"code": "def slice_of(value):\n    return int(hashlib.md5(value.encode()).hexdigest(), 16) % SLICES\n\n\n", "note": "Onde um valor da chave cai: um hash dele, módulo o número de slices. O Redshift usa uma função de hash própria; o MD5 faz o papel dela aqui, e qualquer hash mostra a mesma coisa."}, {"code": "def show(label, placed):\n    counts = [placed.count(s) for s in range(SLICES)]\n    mean = len(placed) / SLICES\n    cells = '  '.join(f'{c:>5}' for c in counts)\n    print(f'{label:<22}{cells}   max/mean {max(counts) / mean:.2f}')\n\n\n", "note": "Conta as linhas de cada slice e as imprime com a razão entre a slice mais cheia e a média. 1.00 é perfeitamente igual."}, {"code": "print(f'{\"\":<22}' + '  '.join(f'sl {s:>2}' for s in range(SLICES)))\nshow('DISTSTYLE EVEN', [n % SLICES for n in range(len(orders))])\nshow('DISTKEY (order_id)', [slice_of(o) for o, _ in orders])\nshow('DISTKEY (customer_id)', [slice_of(c) for _, c in orders])\n\n", "note": "Três jeitos de pôr os mesmos pedidos. `EVEN` os distribui em rodízio. Uma chave em `order_id` faz o hash de um valor diferente em cada linha. Uma chave em `customer_id` faz o hash de um valor que `c-01` repete quatro mil vezes."}, {"code": "moved = sum(slice_of(o) != slice_of(c) for o, c in orders)\nprint(f'join on customer_id, orders keyed on order_id: {moved:,} of {len(orders):,} rows move')\n", "note": "Um join destes pedidos com uma tabela `customers` distribuída em `customer_id`. Um pedido só fica ao lado do cliente se os dois caíram na mesma slice; toda outra linha precisa ser mandada pela rede antes de o join rodar."}]}
```

```
ana@laptop:~/aws$ python3 slices.py
                      sl  0  sl  1  sl  2  sl  3
DISTSTYLE EVEN         2500   2500   2500   2500   max/mean 1.00
DISTKEY (order_id)     2543   2469   2439   2549   max/mean 1.02
DISTKEY (customer_id)  5420   1506   1731   1343   max/mean 2.17
join on customer_id, orders keyed on order_id: 7,449 of 10,000 rows move
```

**`EVEN` e a chave em `order_id` saíram equilibrados, e a chave em `customer_id` não**: a slice 0 tem
5.420 linhas e a slice 3 tem 1.343, então a slice mais cheia tem 2,17 vezes a média. Toda consulta
que varre `orders` espera pela slice 0, e o cluster roda mais ou menos na velocidade de um cluster com
metade das slices. Uma chave só espalha as linhas por igual quando a coluna tem muitos valores, cada
um mais ou menos tão comum quanto os outros. `customer_id` passa nesse teste com as residências da
Quitanda e falha no dia em que um cliente é uma rede de restaurantes.

**A chave em `order_id` fica equilibrada e move as linhas no lugar.** Fazer o join desses pedidos com
`customers` em `customer_id` exigiu mandar 7.449 das 10.000 linhas para outra slice antes, cerca de
três em quatro, que é o que um hash que ignora a coluna do join dá com quatro slices. No plano do
próprio Redshift esse movimento é um passo chamado `DS_DIST_INNER` ou `DS_DIST_BOTH`, em que um ou os
dois lados são redistribuídos para a consulta, ou `DS_BCAST_INNER`, em que uma tabela inteira é
copiada para todo nó; um join sem nada a mover é `DS_DIST_NONE`. Esses nomes vêm da documentação do
`EXPLAIN` da AWS, não de uma execução.

**Então a escolha é uma troca entre as duas falhas**, e é feita tabela por tabela: ponha a chave das
tabelas grandes na coluna pela qual elas sofrem join, desde que nenhum valor dela domine; faça as
pequenas `ALL`; e use `EVEN` numa tabela grande sem join dominante. Num cluster de verdade, a view de
sistema `SVV_TABLE_INFO` tem uma coluna `skew_rows`, a razão entre a slice mais cheia e a mais vazia,
e conferi-la depois da primeira carga é como uma chave como `customer_id` é pega antes que um
relatório a pegue.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os dez mil pedidos do modelo slices.py em quatro slices, em três layouts. DISTSTYLE EVEN põe 2.500 linhas em cada slice. DISTKEY em order_id põe entre 2.439 e 2.549. DISTKEY em customer_id põe 5.420 linhas na slice 0 e entre 1.343 e 1.731 nas outras, 2,17 vezes a média, porque o cliente c-01 tem dois de cada cinco pedidos.\" data-fig=\"l14-skew-pt\"><text x=\"16\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DISTSTYLE EVEN</text><text x=\"16\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max/mean 1.00</text><rect x=\"200\" y=\"22\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 0</text><text x=\"375.6\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.500</text><rect x=\"200\" y=\"41\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 1</text><text x=\"375.6\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.500</text><rect x=\"200\" y=\"60\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"67\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 2</text><text x=\"375.6\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.500</text><rect x=\"200\" y=\"79\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 3</text><text x=\"375.6\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.500</text><text x=\"16\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DISTKEY (order_id)</text><text x=\"16\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max/mean 1.02</text><rect x=\"200\" y=\"114\" width=\"172.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 0</text><text x=\"378.6\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.543</text><rect x=\"200\" y=\"133\" width=\"167.5\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 1</text><text x=\"373.5\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.469</text><rect x=\"200\" y=\"152\" width=\"165.5\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"159\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 2</text><text x=\"371.5\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.439</text><rect x=\"200\" y=\"171\" width=\"173.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 3</text><text x=\"379.0\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2.549</text><text x=\"16\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DISTKEY (customer_id)</text><text x=\"16\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max/mean 2.17</text><rect x=\"200\" y=\"206\" width=\"367.8\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"213\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 0</text><text x=\"573.8\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">5.420</text><rect x=\"200\" y=\"225\" width=\"102.2\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 1</text><text x=\"308.2\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1.506</text><rect x=\"200\" y=\"244\" width=\"117.5\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"251\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 2</text><text x=\"323.5\" y=\"251\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1.731</text><rect x=\"200\" y=\"263\" width=\"91.1\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 3</text><text x=\"297.1\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1.343</text><polyline points=\"369.6428571428571,16 369.6428571428571,284\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"373.6428571428571\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">média, 2.500 linhas</text></svg>", "caption": "Uma chave com um valor dominante põe a maior parte do trabalho numa slice só. Contagens do modelo, não do Redshift."}
```
