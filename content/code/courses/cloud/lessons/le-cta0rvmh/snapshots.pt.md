---
title: "Snapshots: um instante, guardado em outro lugar"
version: 1
---

Um snapshot é **uma cópia de um volume como ele estava num instante**, feita enquanto o volume
continua em uso. É assim que se faz backup de um volume, que se copia um volume para outra zona e
que se criam volumes novos a partir de um estado conhecido.

Três fatos sobre como os snapshots são guardados decidem quanto custam e do que protegem.

**O primeiro snapshot copia cada bloco que já foi gravado; cada um depois copia só o que mudou
desde o anterior.** Um volume de 200 GB com 60 GB de dados dá um primeiro snapshot de uns 60 GB. Se
2 GB mudam no dia seguinte, o segundo snapshot acrescenta uns 2 GB. Cada um ainda restaura o volume
inteiro, porque aponta para os blocos que os anteriores já guardam, e apagar um snapshot antigo
preserva os blocos de que um posterior ainda precisa.

**Os snapshots ficam no armazenamento de objetos do provedor, não na zona do volume.** É isso que os
faz sobreviver à perda de uma zona, e que permite recriar o volume em qualquer zona da mesma região.
Eles não aparecem como objetos em nenhum bucket seu; o provedor usa o próprio repositório de objetos
por baixo e entrega a você um id de snapshot.

**Restaurar não rebobina o volume; cria um volume novo.** Você cria um volume a partir do snapshot,
na zona que escolher, e o anexa a uma instância. O volume antigo fica intacto, que muitas vezes é o
que se quer quando a pergunta é como um arquivo estava na terça-feira.

O armazenamento de snapshots é cobrado por GB-mês sobre o que os snapshots guardam, não sobre o
tamanho do volume. A linha `snapshot` da captura da seção anterior é 0.0680 em `sa-east-1`. Um mês de
snapshots diários daquele volume de 200 GB, com 60 GB de dados e 2 GB mudando por dia, guarda a
primeira cópia inteira mais 29 incrementos:

- 60 + 29 × 2 = 118 GB de dados em snapshot
- 118 × 0.0680 = 8.02 USD no mês, ao lado dos 30.40 do próprio volume

## Snapshot não é política de backup

Um agendamento de snapshots é um bom começo, mas tem duas lacunas.

**Os snapshots moram na mesma conta e na mesma região do volume.** Quem pode apagar o volume em geral
pode apagar os snapshots também, seja o script de limpeza de um colega, um atacante com credenciais
roubadas ou você numa tarde ruim. Uma região que cai tira os dois do alcance ao mesmo tempo.

E um snapshot de um banco de dados em funcionamento só é tão consistente quanto o disco estava
naquele instante. Ele é **consistente como após uma queda**, o estado de um servidor depois que
alguém puxa o cabo da tomada. Um banco com log de escrita antecipada se recupera disso, na maioria
das vezes, o que não é o mesmo que um backup feito pelo próprio banco e que alguém já restaurou para
provar que funciona.

Uma política de backup diz por quanto tempo as cópias ficam, onde mora uma cópia que a conta de
produção não consegue apagar e quando alguém restaurou uma pela última vez. Copiar snapshots para
outra conta ou região é um recurso que todo provedor oferece, e uma decisão que ninguém toma por
você. Quem pode apagar o quê é assunto da aula 7, e o `cloud-security` vai além.
