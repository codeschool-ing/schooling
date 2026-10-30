---
title: Réplicas de leitura, as cópias que andam atrás
version: 1
---

**Uma réplica de leitura é uma instância separada que reaplica as mudanças do primário depois que elas
são confirmadas.** Ela tem endereço próprio, responde consultas, e está sempre um pouco atrás: o
primário confirma, responde à aplicação, e só então manda a mudança para a réplica, que a aplica quando
ela chega. Esse intervalo é o **atraso de replicação**, e é a única propriedade de uma réplica em volta
da qual todo uso dela precisa ser projetado.

**A ideia errada é que uma réplica é um backup, ou um standby.** Não é nenhum dos dois. Um `DELETE` sem
`WHERE` no primário é reaplicado na réplica um instante depois, fielmente, então a réplica não protege
nada contra um engano; a seção depois da próxima mostra ela fazendo exatamente isso. E como a
replicação é assíncrona, uma réplica pode estar sem as últimas transações quando o primário morre,
então promovê-la é decidir aceitar essa perda. O standby regional da seção anterior, síncrono no disco,
não perde nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma escrita no tempo, em quatro faixas: a aplicação, o primário na zona a, o disco do standby na zona b, e uma réplica de leitura. A aplicação manda COMMIT; o primário escreve no disco do standby, que confirma que está no disco, e só então o primário responde OK. Depois do OK, o primário manda a mudança para a réplica de leitura, que a aplica mais tarde. O intervalo entre o OK e a réplica aplicar a mudança é o atraso de replicação.\" data-fig=\"l07-sync\"><defs><marker id=\"arr-l07-sync\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"arra-l07-sync\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">aplicação</text><line x1=\"190\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">primário, zona a</text><line x1=\"190\" y1=\"110\" x2=\"700\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">disco do standby, zona b</text><line x1=\"190\" y1=\"170\" x2=\"700\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">réplica de leitura</text><line x1=\"190\" y1=\"230\" x2=\"700\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"220\" y1=\"50\" x2=\"268\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"232\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"280\" y1=\"112\" x2=\"328\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"312\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escrita</text><line x1=\"340\" y1=\"168\" x2=\"388\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"372\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no disco</text><line x1=\"400\" y1=\"108\" x2=\"448\" y2=\"52\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"430\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OK</text><line x1=\"470\" y1=\"112\" x2=\"598\" y2=\"228\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#arra-l07-sync)\" stroke-dasharray=\"5 3\"></line><text x=\"546\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">enviada depois do OK</text><circle cx=\"610\" cy=\"230\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"620\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aplicada</text><line x1=\"448\" y1=\"262\" x2=\"610\" y2=\"262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"448\" y1=\"256\" x2=\"448\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"610\" y1=\"256\" x2=\"610\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"529\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">atraso de replicação</text><text x=\"190\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo, da esquerda para a direita</text></svg>", "caption": "O disco do standby é escrito antes de o commit voltar; a réplica só fica sabendo da escrita depois. Essa ordem é o motivo de um não perder nada e a outra andar atrasada."}
```

## Para que serve uma réplica

**Leituras que aguentam estar um instante velhas.** Os analistas da Quitanda rodam a cada hora um
relatório que lê os últimos trinta dias de pedidos e os agrupa por bairro. No primário, esse relatório
disputa com o checkout a mesma CPU e o mesmo cache. Numa réplica, ele não disputa com nada que recebe
dinheiro, e se ler pedidos com um segundo de atraso, ninguém sai prejudicado.

**Não para leituras que precisam ver as próprias escritas.** Um cliente que faz um pedido e é mandado
para uma página que o lê de volta de uma réplica pode ouvir que o pedido não existe, porque a réplica
ainda não o reaplicou. Tudo que lê o que o mesmo usuário acabou de escrever lê do primário.

## Como o Cloud SQL monta uma

**Uma réplica é criada com o mesmo comando de uma instância, mais o nome do primário dela**, e o Cloud
SQL faz o resto: tira uma cópia dos dados do primário, inicia o motor nela, e a liga ao primário com a
replicação do próprio motor, que no PostgreSQL é a replicação em streaming do write-ahead log. Escrito
por inteiro, e **não executado**:

```sh
gcloud sql instances create quitanda-orders-reports \
  --master-instance-name=quitanda-orders \
  --region=southamerica-east1 --cpu=2 --memory=8GiB
```

Quatro coisas sobre ela vêm da documentação do Google sobre replicação:

- **o primário precisa ter backups automáticos ligados**, que o comando da aula 6 deixou no padrão;
- **uma réplica é cobrada como uma instância própria**: a página de preços diz que réplicas de leitura
  são cobradas pela mesma tarifa de instâncias independentes, então uma réplica da instância da aula 6
  são mais 177,34 por mês;
- **uma réplica pode estar em outra região**, e é isso que protege contra a perda de uma região
  inteira. O fluxo de replicação então cruza regiões, e a página de preços do Cloud SQL manda a saída
  dele para os preços de rede da aula 5;
- **uma réplica pode ser promovida**: `gcloud sql instances promote-replica quitanda-orders-reports`
  para a replicação de vez e a torna uma instância independente que aceita escritas. Não há volta; uma
  réplica nova é uma cópia nova.

**Uma réplica em outra região só é um plano de recuperação de desastre depois que alguém decidiu
quando promovê-la.** Se São Paulo cair, a réplica em outra região tem tudo até o atraso dela e nada
depois. Promovê-la é a decisão de aceitar essa perda e de apontar a aplicação para um endereço novo, e
uma empresa que não escreveu essa decisão a toma sob pressão, que é a pior hora. A conta do fluxo é
curta: um banco que escreve 20 GiB de log por dia manda 600 GiB por mês através da fronteira da
região, e aos 0,14 o GiB da linha da América Latina da aula 5 isso é o 84,0 da linha da seção anterior.

**No notebook**, a próxima seção monta o mesmo arranjo com o próprio motor: um primário, uma réplica em
streaming feita de uma cópia dele, e um atraso que você pode observar e medir.
