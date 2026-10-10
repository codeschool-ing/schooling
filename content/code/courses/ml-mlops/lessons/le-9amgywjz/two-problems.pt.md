---
title: Dois problemas com uma causa
version: 1
---

Duas lições terminaram no mesmo tipo de falha, e nenhuma levantou erro.

**Lição 3:** um modelo treinado com `recency_days` lido de uma tabela de resumo como ela estava na
última noite, e não como estava em cada corte. A nota de teste foi 0,994, e em produção ele apontou
2.450 de 3.130 membros.

**Lição 5:** o mesmo modelo salvo, alimentado com atributos que o site calculou no próprio código,
com dinheiro em reais em vez de centavos. A probabilidade de 160 membros se mexeu mais de 0,1.

**Os dois são um atributo calculado em mais de um lugar, ou para o momento errado.** O primeiro
precisa dos atributos de cada linha de treino como estavam na data da própria linha. O segundo
precisa que o serviço pegue os seus atributos do mesmo código que o treino usou. Uma **feature store**
é a peça da plataforma feita para dar as duas coisas: atributos calculados uma vez, guardados com o
dia em que eram verdade, e servidos ao treino e à produção do mesmo lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l06-between\" aria-label=\"A feature store entre o código que calcula os atributos e os dois leitores. O features.py, rodado em relação a cada dia, grava fotografias no armazenamento offline. O online é montado a partir do offline. O treino e a pontuação em lote leem o offline com uma junção no ponto do tempo; um serviço lê um membro do online.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"115.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">features.py</text><text x=\"100.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cada dia</text><rect x=\"230.0\" y=\"20.0\" width=\"260.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--amber)\">a feature store</text><rect x=\"255.0\" y=\"62.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">armazenamento offline</text><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo valor, com o seu dia</text><rect x=\"255.0\" y=\"180.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">armazenamento online</text><text x=\"360.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o valor mais novo por membro</text><path d=\"M180.0 130.0 L253.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M360.0 132.0 L360.0 178.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"540.0\" y=\"62.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">treino</text><text x=\"620.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em relação a cada linha</text><rect x=\"540.0\" y=\"180.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um serviço</text><text x=\"620.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um membro, agora</text><path d=\"M467.0 97.0 L538.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M467.0 215.0 L538.0 215.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path></svg>", "caption": "Um cálculo, duas faces. O treino pergunta sobre o passado e um serviço pergunta sobre agora, e os dois recebem valores calculados pelo mesmo código.", "same": ["features.py"]}
```

Ela fica entre os pipelines que produzem atributos e os dois tipos de leitor, e tem **duas faces
porque os dois leitores fazem perguntas diferentes**:

| | o **armazenamento offline** | o **armazenamento online** |
| --- | --- | --- |
| quem pergunta | o treino e a pontuação em lote | um serviço respondendo a um pedido |
| a pergunta | como estavam estes membros nestes dias? | como está este membro agora? |
| responde | muitas linhas de uma vez, em segundos | uma linha, em milissegundos |
| guarda | todo valor, com o dia em que era verdade | o valor mais novo por membro |

**Uma feature store não calcula atributos.** O cálculo continua sendo o `features.py`; o
armazenamento decide quando ele roda, guarda o que ele produziu e garante que ninguém o leia do dia
errado. O resto desta lição constrói uma pequena o bastante para ser lida inteira.
