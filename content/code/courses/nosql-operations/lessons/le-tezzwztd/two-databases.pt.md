---
title: O preço de dois bancos
version: 1
---

A resposta mais comum da seção anterior foi "Redis ao lado do Postgres". É uma boa resposta, e **não
sai de graça**: o segundo banco é um segundo sistema para operar, e no momento em que uma operação de
negócio grava nos dois, passa a existir um tipo novo de falha que nenhum dos dois bancos enxerga.

## O que dois custam antes de qualquer coisa quebrar

- **Dois backups, e dois testes de restauração.** O dump e o snapshot da aula 11 para um, o RDB e o
  AOF da aula 13 para o outro, cada um restaurado num calendário. Restaurar um sem o outro dá uma loja
  cujos pedidos e contadores descrevem momentos diferentes.
- **Dois conjuntos de habilidades de plantão.** Quem é acionado às três da manhã precisa ler os sinais
  da aula 20 dos dois, e o vocabulário de falhas de cada um é próprio.
- **Dois upgrades, dois patches de segurança, dois lugares para o acesso estar errado**, e num
  serviço gerenciado duas faturas (aula 21).

Nada disso é motivo para recusar um segundo banco. É o preço a escrever ao lado do motivo para
acrescentá-lo.

## A escrita dupla

A loja vende um monitor. O pedido vai para o Postgres, e o estoque mostrado na página do produto fica
em cache no Redis para que a página não consulte o Postgres a cada visualização. O código óbvio
grava nos dois:

1. `COMMIT` do pedido e do novo estoque no Postgres;
2. `SET` do novo estoque no Redis.

**Entre os dois há uma brecha, e qualquer coisa pode acontecer nela.** O processo é morto por um
deploy; a rede até o Redis cai por um segundo; o Redis está em failover (aula 15). O Postgres
confirmou, o Redis não ficou sabendo, e a página continua mostrando um monitor que não existe mais.
Fazer na ordem inversa só muda qual lado fica errado. Uma repetição também não fecha a brecha: o
processo que repetiria é o que morreu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Duas linhas do tempo da mesma venda. À esquerda, a escrita dupla: a aplicação confirma o pedido no Postgres, depois a escrita no Redis falha, e o Redis continua mostrando o estoque antigo. À direita, o outbox: a aplicação confirma o pedido e uma linha de outbox numa única transação do Postgres; um relay lê a linha do outbox, grava o estoque no Redis e só então marca a linha como feita.\"><defs><marker id=\"l22ob-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22ob-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22ob-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"160\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">escrita dupla</text><text x=\"50\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aplicação</text><line x1=\"50\" y1=\"50\" x2=\"50\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"160\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Postgres</text><line x1=\"160\" y1=\"50\" x2=\"160\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"270\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"270\" y1=\"50\" x2=\"270\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"50\" y1=\"70\" x2=\"158\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"104\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pedido + estoque</text><line x1=\"160\" y1=\"95\" x2=\"52\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"104\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">COMMIT ok</text><line x1=\"50\" y1=\"140\" x2=\"230\" y2=\"155\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-amber)\" stroke-dasharray=\"4 3\"></line><text x=\"140\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SET estoque: falha</text><text x=\"242\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--amber)\">×</text><text x=\"160\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o Redis ainda mostra 1 monitor</text><text x=\"520\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">outbox transacional</text><text x=\"380\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aplicação</text><line x1=\"380\" y1=\"50\" x2=\"380\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"480\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Postgres</text><line x1=\"480\" y1=\"50\" x2=\"480\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"580\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">relay</text><line x1=\"580\" y1=\"50\" x2=\"580\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"670\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"670\" y1=\"50\" x2=\"670\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"380\" y1=\"70\" x2=\"478\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"430\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pedido + linha de outbox</text><line x1=\"480\" y1=\"95\" x2=\"382\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"430\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um só COMMIT</text><line x1=\"580\" y1=\"140\" x2=\"482\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-paper-dim)\"></line><text x=\"530\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê o outbox</text><line x1=\"580\" y1=\"180\" x2=\"668\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"624\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SET estoque = 0</text><line x1=\"580\" y1=\"255\" x2=\"482\" y2=\"265\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-paper-dim)\"></line><text x=\"530\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">marca feito</text><text x=\"575\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">se o relay morrer aqui, ele repete o SET</text><line x1=\"500\" y1=\"205\" x2=\"660\" y2=\"205\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "A escrita dupla deixa uma brecha que nenhuma repetição fecha, porque o processo que repetiria é o que falhou. O outbox põe a segunda escrita dentro da primeira transação, e um relay a entrega pelo menos uma vez.", "same": ["relay", "COMMIT ok", "Postgres", "Redis"]}
```

## O outbox transacional

A correção é tornar a segunda escrita **parte da primeira transação**, no único banco que tem
transações. Ao lado do pedido, no mesmo `COMMIT`, a aplicação insere uma linha numa tabela `outbox`
dizendo o que precisa acontecer em outro lugar: "ponha o estoque do MN-330 em 0". Ou as duas linhas
existem, ou nenhuma existe; não há brecha.

Um processo separado, o **relay**, lê o outbox em ordem, aplica cada entrada no Redis e só então a
marca como feita. Se o relay morre depois do `SET` e antes de marcar, a entrada é aplicada de novo
quando ele volta, então **a entrega é pelo menos uma vez**. As entradas são escritas de modo que
aplicar uma duas vezes não faz mal: "ponha o estoque em 0" duas vezes ainda dá 0, enquanto
"decremente o estoque" duas vezes dá errado. A aula 4 chamou isso de manter as cópias honestas; o
outbox é o mecanismo que faz isso entre dois bancos.

O relay é a fila da seção anterior: `SELECT ... FOR UPDATE SKIP LOCKED` deixa vários relays dividirem
o outbox sem pegar a mesma entrada. **Esta aula não constrói o relay**; as peças de que ele é feito,
a transação, a leitura com trava e o `SET` do Redis, foram rodadas uma a uma neste curso, e
montá-las é código de aplicação, na linguagem em que a loja for escrita.

O outro caminho lê o próprio log de alterações do banco em vez de uma tabela de outbox, a captura de
dados de alteração, que a aula 14 de `streaming` ensina com o Debezium. Os dois se apoiam na mesma
ideia: **o banco que confirma é o único autorizado a decidir que algo aconteceu**, e todo o resto o
segue.
