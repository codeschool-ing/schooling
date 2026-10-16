---
title: Onde ficam os sistemas reais, e por que a resposta honesta é uma configuração
version: 1
---

**Pouquíssimos sistemas reais são CP ou AP por inteiro: a maioria faz a escolha por operação, e
muitos deixam quem chama fazê-la a cada requisição.** Então um rótulo como "o Cassandra é AP" é uma
afirmação sobre um padrão. A figura abaixo posiciona sete sistemas com essa ressalva desenhada, e a
tabela depois dela diz o que cada um faz quando um enlace é cortado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Um triângulo com P no alto, C embaixo à esquerda e A embaixo à direita. Junto à aresta CP: etcd, ZooKeeper, Spanner, PostgreSQL com um primário, e Kafka com acks=all, tracejado. Junto à aresta AP: Cassandra e as leituras padrão do DynamoDB, ambos tracejados. Sob a aresta de C e A: PostgreSQL numa máquina só, sem rede para cortar.\" data-fig=\"real-systems\"><defs><marker id=\"real-systems-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><polygon points=\"360,44 250,254 470,254\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></polygon><circle cx=\"360\" cy=\"44\" r=\"15\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">P</text><circle cx=\"250\" cy=\"254\" r=\"15\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"250\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">C</text><circle cx=\"470\" cy=\"254\" r=\"15\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"470\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">A</text><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partições acontecem: P não é opcional</text><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">CP: o lado minoritário recusa</text><rect x=\"20\" y=\"58\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"20\" y=\"94\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ZooKeeper</text><rect x=\"20\" y=\"130\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanner</text><rect x=\"20\" y=\"166\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL, um primário</text><rect x=\"20\" y=\"202\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Kafka, acks=all</text><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">AP: todo lado responde</text><rect x=\"520\" y=\"58\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Cassandra</text><rect x=\"520\" y=\"94\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">DynamoDB, leitura padrão</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">C e A sem P: só sem rede para cortar</text><rect x=\"270\" y=\"300\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL, uma máquina</text><rect x=\"520\" y=\"300\" width=\"26\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"554\" y=\"308\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">muda com a configuração</text></svg>", "caption": "Onde sete sistemas ficam, por padrão. As caixas tracejadas mudam com a configuração, e a aresta de C e A só tem sistemas sem rede para cortar.", "same": ["A", "C", "Cassandra", "Kafka, acks=all", "P", "Spanner", "ZooKeeper", "etcd"]}
```

A figura mantém o triângulo de propósito, para mostrar o que há de errado nele. A aresta de baixo, C
e A sem P, é onde um sistema fica só quando não tem rede para ser cortada. **Um banco PostgreSQL numa
máquina só fica ali, e todo programa do seu notebook também.** No momento em que uma segunda máquina
guarda uma cópia, o sistema passa para uma das outras duas arestas. As caixas tracejadas são as que
mudam de aresta conforme a configuração.

## Sete sistemas, uma pergunta para cada

| sistema | o que faz quando um enlace é cortado | a ressalva |
|---|---|---|
| **etcd** e **ZooKeeper** | o lado com maioria continua aceitando escritas; o outro lado as recusa | o ZooKeeper pode responder uma leitura a partir de uma réplica atrasada, a menos que o cliente peça que ela se atualize antes; o etcd oferece uma leitura mais barata que pode vir velha, se for pedida |
| **Spanner** | CP: consenso dentro de cada grupo de cópias, e a rede própria do Google construída para que partições sejam raras | Brewer, já no Google, argumentou em 2017 que ele é CP na teoria e tão raramente indisponível que os usuários podem tratá-lo como as duas coisas |
| **PostgreSQL** com um primário e réplicas | só o primário aceita escritas; uma réplica isolada dele continua respondendo leituras, com dados que podem estar velhos | com replicação síncrona, o primário espera um standby confirmar cada commit, e espera indefinidamente se esse standby estiver inalcançável |
| **Cassandra** | responde dos dois lados por padrão, e resolve os conflitos pelo horário depois | leituras e escritas em `QUORUM` fazem o lado minoritário recusar |
| **DynamoDB** | as leituras padrão podem devolver um valor que não é o mais recente | uma leitura fortemente consistente é uma opção na requisição |
| **Kafka** | cada partição de um tópico tem um líder; com `acks=all`, uma escrita é recusada quando há poucas cópias em sincronia | as configurações `min.insync.replicas` e `unclean.leader.election.enable` decidem se ele prefere recusar ou perder mensagens |

O Kafka é o que a maioria das plataformas de dados encontra primeiro, e as suas duas configurações
são a escolha do CAP por extenso. Com a eleição de líder "suja" desligada, que é o padrão, uma
partição cujas cópias em sincronia sumiram todas espera uma delas voltar em vez de promover uma
cópia atrasada. **Esperar é o C; promover a cópia atrasada é o A, pago com mensagens perdidas.** Um
aviso sobre o vocabulário: uma *partição* do Kafka é uma fatia de um tópico, o particionamento da
aula 9, e não tem nada a ver com uma partição de rede. `streaming` trata das duas configurações num
cluster de verdade.

## Mais um, porque mudou

O armazenamento de objetos é onde uma plataforma de dados guarda a maior parte dos seus arquivos. O
Amazon S3 foi eventualmente consistente para sobrescritas e exclusões durante a maior parte da sua
vida: um arquivo substituído há um instante podia ser lido de volta na versão antiga. **Desde
dezembro de 2020 ele dá consistência forte de leitura após escrita** em toda requisição. Os
pipelines escritos para o comportamento antigo carregavam contornos, como uma tabela à parte
registrando quais arquivos já tinham sido escritos, que agora são peso morto.

É a última razão para tratar qualquer posição nesta página como uma leitura feita numa data. A
documentação de um sistema diz o que ele promete hoje; confira lá, para a operação de que você vai
depender, antes de confiar num rótulo vindo de qualquer outro lugar, esta página incluída.
