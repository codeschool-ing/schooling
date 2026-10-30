---
title: Escalando por agenda
version: 1
---

Alguma carga não é surpresa. O tráfego da loja sobe todo dia útil às nove, e a promoção da Black
Friday começa à meia-noite de uma data conhecida. **Uma agenda conta ao autoscaler sobre a carga antes
de ela chegar, então as máquinas já estão de pé quando ela chega**, em vez de serem ligadas pelo
primeiro minuto lento dela.

## Uma agenda define um piso, não um tamanho

A primeira coisa a entender: **uma agenda de escalonamento sobe o mínimo durante uma janela de tempo;
ela não define o tamanho.** Durante a janela o grupo tem pelo menos aquele número de máquinas, e a
regra de CPU ainda pode acrescentar mais por cima. Fora da janela a agenda não tem efeito nenhum.
Então uma agenda nunca deixa o grupo menor do que a carga precisa, e é isso que torna seguro
acrescentá-la.

Acrescente duas agendas ao autoscaler web da seção 02, dentro do `autoscaling_policy` dele:

```hcl
# autoscale/main.tf, schedules
    scaling_schedules {
      name                  = "weekday-mornings"
      min_required_replicas = 6
      schedule              = "0 8 * * MON-FRI"
      time_zone             = "America/Sao_Paulo"
      duration_sec          = 36000
    }

    scaling_schedules {
      name                  = "black-friday"
      min_required_replicas = 10
      schedule              = "0 0 27 11 *"
      time_zone             = "America/Sao_Paulo"
      duration_sec          = 86400
    }
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E 'scaling_schedules|min_required_replicas|schedule +=|time_zone|duration_sec'
          + scaling_schedules {
              + duration_sec          = 36000
              + min_required_replicas = 6
              + schedule              = "0 8 * * MON-FRI"
              + time_zone             = "America/Sao_Paulo"
          + scaling_schedules {
              + duration_sec          = 86400
              + min_required_replicas = 10
              + schedule              = "0 0 27 11 *"
              + time_zone             = "America/Sao_Paulo"
```

A primeira se lê: a partir das oito da manhã, de segunda a sexta, no horário de São Paulo, por dez
horas, manter pelo menos seis máquinas. Ela começa uma hora antes da subida de propósito, porque uma
máquina nova precisa de tempo para subir e passar na verificação de saúde, que a lição 4 mediu com o
atraso inicial. A segunda mantém dez máquinas o dia 27 de novembro inteiro.

**`schedule` é uma expressão cron e `time_zone` decide como ela é lida.** Ao contrário do agendamento
de snapshots da lição 3, que é em UTC, este recebe um fuso pelo nome, e escrevê-lo é o que mantém as
oito da manhã nas oito quando os relógios de algum outro país mudam. Uma linha cron que nomeia o dia 27
de novembro dispara nessa data todo ano, o que serve para uma promoção de data fixa e não serve para
uma que muda; uma agenda assim é apagada depois do evento.

## O que uma agenda custa

A agenda da manhã sobe o piso de três máquinas para seis, então no máximo três `e2-standard-2` extras
rodam dez horas em cada dia útil. Um mês com 22 dias úteis são 660 horas-máquina, cerca de **44,23
dólares** aos 0,06701142 por hora da tabela, e menos sempre que a regra de CPU já teria acrescentado
essas máquinas de qualquer jeito.
