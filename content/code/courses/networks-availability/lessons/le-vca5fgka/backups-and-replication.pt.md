---
title: Backups, replicação, e o que cada um salva
version: 1
---

O RPO de um sistema é definido por uma coisa: como os dados são copiados para outro lugar, e com que
frequência. Há duas famílias de cópia, e o erro comum é achar que a moderna substitui a antiga. **Uma
réplica copia os erros tão fielmente quanto copia os dados.** Um `DELETE` sem o `WHERE` chega a todas as
réplicas momentos depois de chegar ao primário, e só uma cópia feita antes dele traz as linhas de volta.

## Backups

Um backup é uma cópia dos dados como eles estavam num momento. O RPO dele é o intervalo entre backups: com
um por noite, uma falha logo antes do próximo perde quase um dia de gravações. O RTO é o tempo de achar a
cópia certa, restaurá-la e conferi-la, que cresce com o tamanho dos dados e se mede em horas para qualquer
coisa grande.

Aquilo contra o que um backup protege é exatamente o que a replicação não cobre: exclusão, corrupção, uma
versão ruim que reescreveu uma coluna, um ransomware que criptografou o primário e tudo o que estava ligado
a ele. A regra usual é a **3-2-1**: três cópias dos dados, em dois tipos diferentes de armazenamento, uma
delas fora do local. Muitas equipes acrescentam que uma cópia fique offline ou imutável, já que tudo o que
um atacante alcança a partir do primário, um atacante também consegue criptografar.

**Um backup que nunca foi restaurado não é um backup; é uma esperança.** Restaurar um com regularidade é o
único jeito de saber que funciona, e o único jeito de saber o RTO, porque o tempo real de restauração é o
medido, não o estimado.

## Replicação

Uma réplica é uma segunda cópia mantida atualizada o tempo todo. O quanto ela acompanha de perto é a
escolha que define o RPO:

- Na replicação **síncrona**, o primário só confirma uma gravação para a aplicação depois que a réplica também a tem.
  Nada confirmado se perde jamais, um RPO de zero. Toda gravação paga uma ida e volta até a réplica, então
  a distância custa: a luz na fibra percorre cerca de 200 km por milissegundo, e uma réplica a 1000 km
  acrescenta uns 10 ms a cada gravação.
- Na replicação **assíncrona**, o primário confirma na hora e manda a mudança depois. As gravações são rápidas, e o RPO é
  o quanto a réplica estava atrasada no momento da falha, o **atraso de replicação** (replication lag): em
  geral segundos, e muito mais quando o primário está ocupado, que é quando as falhas costumam acontecer.

| cópia | RPO | RTO | protege contra |
|---|---|---|---|
| backup noturno | até 24 horas | horas | perda de hardware, perda do local se guardado fora, exclusão, corrupção, ransomware se offline |
| réplica assíncrona | o atraso, segundos ou mais | minutos | perda de hardware, perda do local se estiver longe o bastante |
| réplica síncrona | zero | de segundos a minutos | perda de hardware, perda do local dentro da distância que ela tolera |

Promover uma réplica quando o primário falha traz de volta o problema mais difícil da aula 14. Se o
primário antigo não morreu, só ficou isolado, e continua aceitando gravações enquanto a réplica é promovida,
há dois primários e **duas cópias da verdade se afastando**: split brain, com dados. É aí que o quórum e o
fencing da aula 14 deixam de ser teoria. Um cluster de banco de dados que faz failover automático precisa
de um terceiro voto para decidir quem pode ser primário, e de um jeito de garantir que o antigo parou.

Então um projeto sério usa as duas famílias: replicação para o RTO das falhas que são de hardware e de
lugar, backups para o RPO das que são de erro, e um teste de restauração para provar os números escritos no
plano.
