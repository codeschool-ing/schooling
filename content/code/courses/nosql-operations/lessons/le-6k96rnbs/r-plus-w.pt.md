---
title: R + W > RF, e os níveis para mais de um data center
version: 1
---

"Consistência forte" no Cassandra não é um modo que se liga. **É uma soma.** Se uma escrita espera W
réplicas e uma leitura pergunta a R réplicas, de RF cópias, e R + W é maior que RF, então as réplicas
que a leitura consulta e as que a escrita esperou precisam ter ao menos um nó em comum. Esse nó tem a
escrita, a leitura ouve dele, e o valor mais novo vence. Então a leitura vê a escrita.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Dois painéis, cada um com três réplicas de uma partição. À esquerda, escrita e leitura em QUORUM: a escrita é confirmada pelas réplicas 1 e 2, a leitura pergunta às réplicas 2 e 3, e a réplica 2 está nas duas, então a leitura encontra a escrita mais nova. R mais W dá 4, mais que 3. À direita, ONE e ONE: a escrita é confirmada pela réplica 1 e a leitura pergunta só à réplica 3, que ainda não a recebeu. R mais W dá 2, não mais que 3, e a leitura pode perder a escrita.\"><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">escrita QUORUM, leitura QUORUM</text><rect x=\"40\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 1</text><rect x=\"140\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"185.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 2</text><rect x=\"240\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 3</text><rect x=\"40\" y=\"62\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a escrita esperou</text><rect x=\"140\" y=\"182\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">a leitura consultou</text><text x=\"175\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">W 2 + R 2 = 4 &gt; 3</text><text x=\"175\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma réplica em comum: a leitura vê a escrita</text><text x=\"525\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">escrita ONE, leitura ONE</text><rect x=\"390\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 1</text><rect x=\"490\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 2</text><rect x=\"590\" y=\"110\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 3</text><rect x=\"390\" y=\"62\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a escrita esperou</text><rect x=\"590\" y=\"182\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">a leitura consultou</text><text x=\"525\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">W 1 + R 1 = 2 ≤ 3</text><text x=\"525\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nenhuma réplica em comum: a leitura pode perdê-la</text></svg>", "caption": "Por que a regra é R + W > RF. Quando as réplicas que a leitura consulta e as que a escrita esperou precisam ter ao menos um nó em comum, a leitura sempre encontra a escrita confirmada mais nova."}
```

Com RF 3, as combinações que passam merecem ser sabidas de cor:

| escrita | leitura | R + W | a leitura vê a última escrita confirmada? |
| --- | --- | --- | --- |
| `QUORUM` (2) | `QUORUM` (2) | 4 | sim, e as duas aguentam um nó caído |
| `ALL` (3) | `ONE` (1) | 4 | sim; leituras baratas, e qualquer nó caído para toda escrita |
| `ONE` (1) | `ALL` (3) | 4 | sim; escritas baratas, e qualquer nó caído para toda leitura |
| `ONE` (1) | `ONE` (1) | 2 | não; o mais rápido, e uma leitura pode devolver um valor mais velho |
| `ONE` (1) | `QUORUM` (2) | 3 | não; 3 não é maior que 3 |

**`QUORUM` nos dois é o padrão habitual para dados que importam**, porque é o único par que vê a
última escrita e continua funcionando com um nó caído. A última linha é o erro comum: uma equipe sobe
as leituras para `QUORUM`, deixa as escritas em `ONE` e acredita que comprou consistência. Não comprou
nada; a única réplica que recebeu a escrita pode ser justamente a que a leitura pulou.

## O que a soma não promete

A regra trata de uma escrita e das leituras depois que ela foi confirmada. Três coisas ficam em
aberto, cada uma com uma aula que trata dela:

- **Uma escrita que falhou ainda pode estar em algumas réplicas.** Uma escrita em `QUORUM` que estoura
  o tempo com uma confirmação não foi desfeita naquela réplica, e uma leitura posterior pode achá-la.
  O Cassandra não tem rollback para uma escrita isolada.
- **Dois clientes gravando a mesma célula ao mesmo tempo** são resolvidos pelo timestamp mais novo, a
  última escrita vence, como a aula 5 descreveu. A soma garante que você lê uma escrita recente, não
  que as escritas foram aplicadas numa ordem que você escolheu. A próxima seção é a ferramenta para
  isso.
- **As cópias que perderam uma escrita ficam para trás** até algo as atualizar. A aula 19 trata dos
  três mecanismos que fazem isso.

## Mais de um data center

`QUORUM` conta réplicas no cluster inteiro. Com dois data centers de três cópias cada, RF é 6 e um
quórum é 4, então **todo pedido em `QUORUM` espera ao menos uma resposta do outro data center**: a
ida e volta pelo oceano do PACELC da aula 1, paga em toda consulta. Existem outros níveis para esse
formato:

| nível | o que espera | usado para |
| --- | --- | --- |
| `LOCAL_QUORUM` | um quórum das réplicas do data center do próprio coordenador | o nível do dia a dia de um cluster em várias regiões: consistente dentro da região, rápido, e ainda funcionando se a outra região ficar isolada |
| `EACH_QUORUM` | um quórum em cada data center | escritas que precisam estar duráveis em todas as regiões antes de o cliente ouvir sim |
| `LOCAL_ONE` | uma réplica no data center local | o equivalente ao `ONE` em várias regiões, que nunca cruza para a outra região |

`LOCAL_QUORUM` em leituras e escritas dá R + W > RF **dentro de cada data center**, que é a troca
habitual: um cliente em São Paulo lendo as cópias da própria região vê as escritas da sua região na
hora e as de Lisboa quando chegam. O laboratório tem um data center só, `dc1`, então ali esses níveis
se comportam como suas formas simples, e não foram rodados para esta aula. Nomear o data center no
`NetworkTopologyStrategy`, como a seção anterior fez, é o que os torna possíveis depois.
