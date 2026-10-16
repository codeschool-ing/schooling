---
title: Quando o número medido não cumpre a promessa
version: 1
---

O sentido de medir é descobrir, num dia tranquilo, que o esquema não cumpre a promessa. Aí só existem
dois movimentos honestos: mudar o esquema ou mudar a promessa. Fingir é o terceiro movimento, e o
incidente dá fim a ele.

## Alavancas do RPO

| alavanca | o que ela compra | o que ela custa |
|---|---|---|
| um `archive_timeout` menor | perda limitada a esse intervalo num servidor parado | segmentos vazios de 16 MB no arquivo |
| um receptor por streaming (`pg_receivewal`) | perda de uma fração de segundo | uma segunda máquina, um slot para vigiar |
| uma réplica (lição 11) | o mesmo, mais um servidor pronto para assumir | um segundo servidor, permanentemente |
| replicação síncrona (lição 12) | perda **zero** quando um servidor se perde | todo commit espera pela rede |

Nenhuma delas ajuda contra um `DELETE` equivocado. Para isso, o RPO é definido pela recuperação para
um ponto no tempo, que pode parar em qualquer momento, e por quanto tempo o arquivo é guardado.

## Alavancas do RTO

As duas fases da restauração apontam para alavancas diferentes:

- **Copiar os arquivos de volta** encolhe com armazenamento e rede mais rápidos, paralelismo
  (`process-max` no pgBackRest) e um servidor de restauração que já existe, em vez de um encomendado
  no dia.
- **Reaplicar o log** encolhe com **backups mais frequentes**, porque uma restauração parte do backup
  mais recente de qualquer tipo e reaplica só o que veio depois dele. O diferencial diário da lição 5
  não era só sobre armazenamento: ele limita a reaplicação a um dia de log em vez de uma semana.
- **Todo o resto** (perceber, decidir, achar a pessoa que tem a senha) encolhe com alertas que
  funcionam, um runbook (lição 24) e ensaio (lição 23). Em incidentes reais, esses minutos muitas
  vezes passam dos da restauração.

E quando todas as alavancas foram puxadas e a restauração ainda não cabe, o RTO está dizendo que
restaurar é a ferramenta errada para aquela falha. A resposta é um servidor que **já está restaurado
e é mantido em dia**, que é para onde o curso vai agora: as lições 11 a 21 constroem exatamente isso,
e a lição 9 antes leva os backups para um lugar de onde uma máquina perdida não consegue levá-los
junto.
