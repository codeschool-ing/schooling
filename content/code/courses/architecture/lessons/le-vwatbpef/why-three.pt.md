---
title: Por que clusters vêm de três em três
version: 1
---

A aula 6 disse que um Kafka em produção roda três nós pelo menos, e os servidores do etcd, do ZooKeeper e
do Consul são instalados em grupos de três e de cinco, nunca de dois ou de quatro. O motivo é o problema
do failover de duas seções atrás, dito com precisão.

Quando o líder para de responder, os outros têm de decidir se elegem um novo. Eles não conseguem
distinguir um líder que caiu de um líder rodando perfeitamente do outro lado de um cabo rompido, o que a
aula 8 mostrou ser a definição de uma partição. Se elegerem um líder novo e o antigo estiver vivo, há
dois, e os dois aceitam escritas. **A saída é exigir maioria**: um grupo só pode eleger um líder, e um
líder só pode aceitar escritas, enquanto alcança mais da metade dos nós. Dois grupos não podem ter, os
dois, mais da metade, então nunca pode haver dois líderes ao mesmo tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três nós divididos por uma partição de rede num grupo de dois e num grupo de um. O grupo de dois é maioria, dois de três, e mantém um líder e continua aceitando escritas. O nó sozinho é minoria e recusa escritas. Com só dois nós, uma divisão deixa um de cada lado, e nenhum consegue saber se o outro falhou ou está isolado.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"300\" height=\"150\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><circle cx=\"110\" cy=\"110\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"110\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nó 1</text><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">líder</text><circle cx=\"250\" cy=\"110\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"250\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nó 2</text><path d=\"M146 110 L214 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">2 de 3: maioria, continua escrevendo</text><text x=\"400\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">partição</text><path d=\"M400 84 L400 180\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><rect x=\"470\" y=\"40\" width=\"220\" height=\"150\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><circle cx=\"580\" cy=\"110\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"580\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nó 3</text><text x=\"580\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1 de 3: recusa escritas</text></svg>", "caption": "A maioria de três é dois, então um nó pode falhar ou ficar isolado e o resto continua. Dois nós não têm maioria de sobra: um sozinho nunca é mais da metade."}
```

Agora conte. Com **dois nós**, a maioria é dois: no momento em que qualquer um fica inalcançável, nenhum
lado tem maioria, e nada pode ser escrito. Dois nós são menos disponíveis que um, e em troca dão uma
cópia dos dados. Com **três**, a maioria é dois, então um nó pode falhar e os outros dois continuam. Com
**quatro**, a maioria é três, então ainda só um pode falhar: o quarto nó acrescentou custo e nenhuma
tolerância. Com **cinco**, a maioria é três, e dois podem falhar.

| nós | maioria | falhas toleradas |
| --- | --- | --- |
| 1 | 1 | 0 |
| 2 | 2 | 0 |
| 3 | 2 | 1 |
| 4 | 3 | 1 |
| 5 | 3 | 2 |
| 7 | 4 | 3 |

A regra é **2f + 1 nós para sobreviver a f falhas**, e é por isso que os números são ímpares. Três é o
menor cluster que sobrevive à perda de um nó; cinco é comum onde um nó pode estar em manutenção quando
outro falha. Além disso, cada escrita espera mais máquinas responderem, e clusters raramente passam de
sete votantes.

É a regra sobre a qual são construídos o **Raft** e o **Paxos**, os protocolos de consenso por baixo do
etcd, do Consul, do ZooKeeper (cujo protocolo, o Zab, é um parente próximo), e dos próprios
controladores do Kafka desde o KRaft. Um banco de líder único como o PostgreSQL não inclui um: o failover
dele é decidido por uma ferramenta ao lado, como o Patroni, que por sua vez guarda a decisão num desses
armazenamentos de consenso. A aula 19 usa um para outra finalidade.
