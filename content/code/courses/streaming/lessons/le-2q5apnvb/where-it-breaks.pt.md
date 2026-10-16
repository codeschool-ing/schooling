---
title: Os dois lugares onde uma mensagem se perde ou se duplica
version: 1
---

**Uma mensagem que vai de um caixa até um banco de dados atravessa dois vãos, e cada vão é um
momento em que um lado já fez a sua parte e o outro ainda não sabe.** Toda garantia de entrega é
uma decisão sobre o que fazer nesses dois momentos, e mais nada. A rede, os discos e o próprio
Kafka podem ser perfeitos; os vãos continuam lá, porque são feitos de dois programas que não
dividem a mesma memória.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma venda vai do produtor do caixa para o Kafka e do Kafka para um consumidor que grava num banco. Duas lacunas estão marcadas. A primeira fica entre o líder gravar a venda e o produtor receber a confirmação: se a confirmação se perde, uma nova tentativa pode gravar a venda duas vezes. A segunda fica entre o consumidor processar a venda e confirmar o offset: conforme o que vem primeiro, uma queda perde a venda ou a processa de novo.\" data-fig=\"l7-gaps\"><defs><marker id=\"l7-gaps-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l7-gaps-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">caixa · produtor</text><rect x=\"250\" y=\"30\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Kafka</text><rect x=\"470\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">consumidor</text><rect x=\"600\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">banco de dados</text><line x1=\"130\" y1=\"42\" x2=\"248\" y2=\"42\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l7-gaps-ah-726)\"></line><text x=\"189\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1  grava</text><line x1=\"248\" y1=\"60\" x2=\"132\" y2=\"60\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l7-gaps-ah-0)\"></line><text x=\"189\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2  confirma</text><line x1=\"390\" y1=\"50\" x2=\"468\" y2=\"50\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l7-gaps-ah-726)\"></line><line x1=\"580\" y1=\"42\" x2=\"598\" y2=\"42\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l7-gaps-ah-726)\"></line><text x=\"625\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3  processa</text><path d=\"M 525 72 Q 460 120 392 72\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l7-gaps-ah-0)\"></path><text x=\"460\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4  confirma o offset</text><rect x=\"110\" y=\"140\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"200\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">lacuna 1: confirmação perdida</text><text x=\"200\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nova tentativa → gravada duas vezes</text><rect x=\"440\" y=\"140\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">lacuna 2: queda entre 3 e 4</text><text x=\"550\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">perdida, ou processada de novo</text><line x1=\"189\" y1=\"86\" x2=\"189\" y2=\"138\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><line x1=\"550\" y1=\"124\" x2=\"550\" y2=\"138\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "Dois programas que não compartilham memória, ligados duas vezes: toda garantia é uma escolha sobre essas duas lacunas.", "same": ["Kafka"]}
```

## Vão um: o produtor e a confirmação

O produtor manda uma venda; o líder a grava e responde; a resposta se perde, porque uma conexão
caiu ou o líder foi trocado antes de responder. Do lado do produtor, a venda está num de dois
estados e ele não tem como saber qual: **gravada e não confirmada, ou nunca gravada**. Ele tem duas
escolhas:

- mandar de novo, e se ela tinha sido gravada, o tópico agora a tem duas vezes;
- desistir, e se ela não tinha sido gravada, ela sumiu.

Um cliente com novas tentativas ligadas, que é o padrão do cliente Python, escolhe a primeira. A
lição 5 viu um produtor atravessar a morte de um líder assim: o `acks.py` não perdeu nada e,
daquela vez, não gravou nada duas vezes. Nada no cliente prometia a segunda parte. A cura para este
vão é do Kafka, e é o produtor idempotente, duas seções adiante. Uma confirmação perdida não é
provocada nesta lição: isso exige uma rede que derrube uma resposta e não a gravação antes dela, o
que este laboratório não consegue encenar.

## Vão dois: o consumidor e o commit

Um consumidor lê uma venda, faz algo com ela e diz ao Kafka até onde chegou **fazendo commit de um
offset**, a posição da próxima mensagem que ele quer. A lição 4 apresentou o commit; aqui está o
que ele significa. O offset confirmado é a única coisa que sobrevive ao consumidor: reinicie-o, ou
ponha outro membro do grupo no lugar dele, e a leitura continua dali.

Então a ordem de dois passos decide o resultado de uma queda entre eles:

| ordem | uma queda entre os dois passos | a garantia |
|---|---|---|
| commit, depois processar | as vendas depois do commit nunca são processadas | **no máximo uma vez** |
| processar, depois commit | as vendas processadas são lidas de novo depois do reinício | **pelo menos uma vez** |

Nenhuma das ordens é um defeito. **Cada uma escolhe qual falha prefere**, e as duas próximas seções
derrubam um consumidor de cada jeito e contam o resultado.

## E do que "exatamente uma vez" precisaria

Exatamente uma vez é o desejo de que uma queda em qualquer dos vãos não mude nada. Isso exige que
os dois passos de cada vão virem um passo só, que acontece ou não acontece: a gravação e a
confirmação, o processamento e o commit. Dentro do Kafka, onde processar é escrever em outro tópico
e o commit é escrever em `__consumer_offsets`, os dois passos são escritas no Kafka e podem dividir
uma transação. Fora do Kafka, onde processar é uma linha num banco ou um e-mail, não podem, e essa
borda é a última seção desta lição e a lição 8 inteira.

O que nada disso cobre é uma queda que perde os próprios dados. Isso foi a lição 5: uma venda
confirmada com `acks=all` em três réplicas não se perde numa queda, e os vãos daqui partem desse
pressuposto.
