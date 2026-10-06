---
title: Dentro do cluster ou ao lado dele
version: 1
---

Tudo acima funcionou, e ainda é uma parte pequena de operar um banco. **Replicação, failover,
recuperação para um ponto no tempo, atualizações entre versões principais, ajuste e monitoramento** são
o resto, e um StatefulSet não faz nada disso. Há três jeitos de consegui-los.

| | banco gerenciado (RDS, Cloud SQL, Azure Database) | operator no cluster (CloudNativePG, por exemplo) | StatefulSet à mão |
|---|---|---|---|
| quem cuida de failover e backups | o provedor | o operator, configurado por você | você |
| onde os dados vivem | no serviço do provedor, ao lado do cluster | em volumes no cluster | em volumes no cluster |
| custo | um acréscimo sobre as máquinas | as máquinas, e o seu tempo | as máquinas, e mais do seu tempo |
| vai junto com o cluster | não | sim | sim |
| serve para | a maioria das equipes numa nuvem | equipes que querem uma plataforma igual em todo lugar | laboratórios, testes, ferramentas internas pequenas |

**Para a maioria das equipes rodando numa nuvem, o banco fica fora do cluster**, no serviço gerenciado
do provedor: backups, réplicas e failover vêm como configurações, e as aplicações do cluster o alcançam
por um endereço comum, muitas vezes embrulhado num Service do tipo `ExternalName` para que os pods usem
um nome que não muda. O cluster pode então ser refeito a partir dos manifestos a qualquer momento,
porque nada nele é insubstituível.

Um operator, assunto da lição 44, é o argumento forte para ficar dentro: um programa que roda no
cluster e sabe operar um banco em particular, transformando "três réplicas com backups diários neste
bucket" em StatefulSets, Services, Jobs e decisões de failover. Ele serve a equipes que rodam em
hardware próprio, ou em várias nuvens, e querem um jeito só de fazer isso.

O StatefulSet à mão desta lição é a escolha certa exatamente para o que ele foi usado: aprender,
testar, e dados de que ninguém sentiria falta. Seja o que for que rode o banco, as perguntas da seção
anterior não mudam. **Um backup que nunca foi restaurado é uma esperança, não um backup.**
