---
title: Quem atualiza primeiro
version: 1
---

**Todo modo de compatibilidade é também uma instrução sobre a ordem em que os programas são
atualizados**, e essa instrução é a parte que as equipes esquecem. O registro confere os esquemas;
ele não consegue conferir se os consumidores foram reimplantados antes dos produtores, e um modo
seguido na ordem errada quebra um leitor tanto quanto modo nenhum.

| modo | quem atualiza primeiro | por quê |
|---|---|---|
| `BACKWARD` | os **consumidores** | um leitor novo lê dados antigos, então os leitores andam primeiro e os dados antigos nunca os surpreendem |
| `FORWARD` | os **produtores** | um leitor antigo lê dados novos, então quem escreve anda primeiro e os leitores antigos acompanham |
| `FULL` | qualquer um, em qualquer ordem | cada lado lê os dados do outro |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas implantações ao longo do tempo. Sob BACKWARD, os consumidores passam primeiro para a versão 2, então por um tempo leitores novos leem dados antigos da versão 1, o que um esquema compatível para trás permite; depois passam os produtores. Sob FORWARD, os produtores passam primeiro, então leitores antigos leem dados novos da versão 2, o que um esquema compatível para a frente permite; depois passam os consumidores.\" data-fig=\"l6-upgrade-order\"><defs><marker id=\"l6-upgrade-order-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">BACKWARD</text><text x=\"150\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidores</text><rect x=\"170\" y=\"40\" width=\"160\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"330\" y=\"40\" width=\"360\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"150\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">produtores</text><rect x=\"170\" y=\"70\" width=\"350\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"520\" y=\"70\" width=\"170\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"425.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">leitores novos, dados antigos</text><line x1=\"330\" y1=\"94\" x2=\"520\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">FORWARD</text><text x=\"150\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">produtores</text><rect x=\"170\" y=\"140\" width=\"160\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"330\" y=\"140\" width=\"360\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"150\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidores</text><rect x=\"170\" y=\"170\" width=\"350\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"520\" y=\"170\" width=\"170\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"425.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">leitores antigos, dados novos</text><line x1=\"330\" y1=\"194\" x2=\"520\" y2=\"194\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"170\" y1=\"222\" x2=\"690\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l6-upgrade-order-ah-8343)\"></line><text x=\"686\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "O modo decide qual lado pode rodar a versão nova enquanto o outro ainda roda a antiga.", "same": ["BACKWARD", "FORWARD", "v1", "v2"]}
```

A ideia errada é que `BACKWARD` deixa mudar o produtor à vontade porque o registro aprovou o
esquema. Aprove sob `BACKWARD` uma versão 2 que remove um campo, implante primeiro o produtor, e
todo consumidor ainda na versão 1 encontra mensagens sem um campo de que precisa. O registro fez a
parte dele; o deploy foi na ordem contrária.

## As duas direções, num tópico só

A versão 2 só acrescentou um campo com valor padrão, o que é permitido em todos os modos: é uma
mudança `FULL`, e qualquer lado pode andar primeiro. Mande cinco vendas escritas com ela, com outra
semente para que sejam vendas novas:

```
ubuntu@stream:~/work$ python avro_tills.py --schema sale-v2.avsc --count 5 --seed 2
sent 5 sales to sales-avro as Avro
ubuntu@stream:~/work$ python avro_read.py
schema ids: {1: 10, 2: 5}
fields read: sale, shop, book, qty, cents, at
caruaru          213.70
joao-pessoa      444.30
natal            824.10
olinda           109.80
recife           196.70
ubuntu@stream:~/work$ python avro_read.py sale-v2.avsc
schema ids: {1: 10, 2: 5}
fields read: sale, shop, book, qty, cents, at, till
caruaru          213.70
joao-pessoa      444.30
natal            824.10
olinda           109.80
recife           196.70
```

O tópico agora guarda vendas escritas com dois esquemas, dez com o id 1 e cinco com o id 2, e dois
leitores receberam as quinze. O `avro_read.py` sem argumento as lê como versão 1 e nunca vê `till`:
um **leitor antigo em dados novos**, a direção para a frente. Com `sale-v2.avsc` ele as lê como
versão 2 e recebe `till` em toda venda, `unknown` nas dez escritas antes de o campo existir: um
**leitor novo em dados antigos**, a direção para trás. Os mesmos bytes, os mesmos totais, e cada
leitor recebeu o formato que pediu.

**Um tópico do Kafka não é migrado quando o seu esquema muda.** As dez mensagens antigas continuam
escritas com a versão 1 e assim ficarão enquanto o tópico as guardar, e é por isso que os leitores
precisam lidar com todas as versões ainda presentes no tópico, não só com a mais nova. A retenção,
da lição 3, é o que decide até quando "todas as versões" vai para trás.

## O Avro não é a única escolha

O registro guarda outros dois tipos de esquema, com os mesmos subjects, ids e modos de
compatibilidade:

- JSON Schema mantém as mensagens em JSON, que pessoas e o `jq` conseguem ler, e acrescenta as
  checagens que faltam ao JSON. Paga isso em tamanho: os nomes dos campos continuam em cada
  mensagem.
- Protocol Buffers identifica os campos por **número** em vez de nome, então renomear é de
  graça e reaproveitar um número é o erro a evitar. É comum onde as mesmas mensagens também viajam
  por gRPC.

A escolha entre os três importa menos do que ter um. O caixa da primeira seção não falhou porque
JSON é um formato ruim; falhou porque nada se pôs entre um nome melhor inventado por um programador
e todos os leitores do tópico.
