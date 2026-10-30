---
title: "Gatilhos: um relógio, uma janela ou um arquivo"
version: 1
---

**Um gatilho decide quando um pipeline roda, e os três tipos discordam sobre o que quer dizer "a
noite do dia 29".** Um gatilho agendado dispara num horário do relógio. Um gatilho tumbling window
dispara uma vez para cada fatia de tempo desde uma data de início, e lembra quais fatias já rodaram.
Um gatilho de evento dispara quando um arquivo chega. Esta seção confere duas declarações com o
Terraform, offline, e ensina o comportamento a partir da documentação da Microsoft; nenhum gatilho
disparou.

## A tumbling window

**Um gatilho tumbling window corta o tempo em janelas encostadas umas nas outras, de tamanho fixo, e
roda o pipeline uma vez por janela, com o início e o fim da janela como valores que o pipeline pode
usar.** É o gatilho de uma carga noturna, porque cada execução tem um dia que é dela. Salve isto ao
lado do `main.tf`, em `~/azure/tf/factory`:

`triggers.tf`:

```hcl
resource "azurerm_data_factory_trigger_tumbling_window" "nightly" {
  name            = "tr_orders_nightly"
  data_factory_id = azurerm_data_factory.etl.id
  start_time      = "2026-10-01T06:00:00Z"
  frequency       = "Hour"
  interval        = 24
  delay           = "00:30:00"
  max_concurrency = 4

  retry {
    count    = 3
    interval = 600
  }

  pipeline {
    name = azurerm_data_factory_pipeline.nightly.name
    parameters = {
      day = "@formatDateTime(trigger().outputs.windowStartTime, 'yyyy-MM-dd')"
    }
  }
}
```

```
ana@laptop:~/azure/tf/factory$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/factory$ sed -i 's/= "Hour"/= "Day"/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/= "Day"/= "Hour"/' triggers.tf
Error: expected frequency to be one of ["Hour" "Minute" "Month"], got Day
ana@laptop:~/azure/tf/factory$ sed -i 's/"00:30:00"/"30m"/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/"30m"/"00:30:00"/' triggers.tf
Error: invalid value for delay (invalid timespan, must be of format hh:mm:ss)
ana@laptop:~/azure/tf/factory$ sed -i 's/max_concurrency = 4/max_concurrency = 60/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/max_concurrency = 60/max_concurrency = 4/' triggers.tf
Error: expected max_concurrency to be in the range (1 - 50), got 60
```

**Não existe `Day`: um dia são 24 horas**, e por isso a janela acima diz `Hour` e `24`. As quatro
configurações que importam, lidas contra a noite da Quitanda:

- **`start_time` é em UTC, e é o início da primeira janela.** `2026-10-01T06:00:00Z` são três da
  manhã em São Paulo, que não tem horário de verão desde 2019, então cada janela vai das três da manhã
  de um dia às três da manhã do seguinte.
- **`delay` espera depois que a janela fecha antes de rodar**, trinta minutos aqui, então a execução
  da janela que fecha às 03:00 começa às 03:30, depois que o export da loja teve tempo de chegar. O
  provider confere o formato, `hh:mm:ss`.
- **o pipeline recebe o início da janela como parâmetro**, formatado como data pela expressão em
  `parameters`. A execução que começa às 03:30 do dia 2 carrega `day = 2026-10-01`.
- **`retry` reexecuta uma janela que falhou**, três vezes, com dez minutos entre elas, antes de a
  janela ser marcada como falha. Uma janela falha continua falha e visível, e pode ser reexecutada à
  mão quando a causa for corrigida.

**Uma data de início no passado é um backfill.** Ativado ao meio-dia de 30 de outubro, este gatilho
deve ao pipeline toda janela que fechou desde 1º de outubro, 29 delas, e as roda, no máximo
`max_concurrency` de cada vez; o provider aceita de 1 a 50. É assim que um pipeline novo carrega o
histórico, e também como uma data de início descuidada roda um ano de cargas numa tarde. Um pipeline
rodado por uma tumbling window deve portanto ser seguro de rodar duas vezes para o mesmo dia: escrever
a partição do dia inteira, substituindo o que havia, para que uma nova tentativa ou uma reexecução
deixe o mesmo resultado. A lição 24 volta a essa propriedade e ao nome dela.

## O gatilho agendado

**Um gatilho agendado dispara num relógio e não sabe nada sobre para que servia cada execução.** Ele
pode iniciar vários pipelines e entende fusos horários, mas não guarda registro de quais noites foram
feitas: uma data de início no passado não é um backfill, e uma execução que falhou não é devida de
novo. Salvo ao lado dos outros como `schedule.tf`:

`schedule.tf`:

```hcl
resource "azurerm_data_factory_trigger_schedule" "nightly" {
  name            = "tr_orders_3am"
  data_factory_id = azurerm_data_factory.etl.id
  pipeline_name   = azurerm_data_factory_pipeline.nightly.name
  frequency       = "Day"
  interval        = 1
  time_zone       = "E. South America Standard Time"
  activated       = false

  schedule {
    hours   = [3]
    minutes = [0]
  }
}
```

```
ana@laptop:~/azure/tf/factory$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/factory$ terraform fmt -check && echo formatted
formatted
```

`terraform fmt -check` não imprime nada e dá certo quando todo arquivo está disposto do jeito que o
Terraform o disporia, que é a outra conferência que o pipeline de um time roda nesses arquivos antes
de alguém revisá-los.

**`Day` é aceito aqui, e o fuso horário é um nome do Windows**, `E. South America Standard Time`, que é
como o Azure chama o horário de Brasília, em vez de `America/Sao_Paulo`. O pipeline não recebe janela
nenhuma, então o `day` dele tem de ser calculado lá dentro, por exemplo como a data de ontem no
momento em que roda, e uma execução atrasada ou reexecutada na manhã seguinte calcula outro dia.
`activated = false` o mantém declarado e desligado: a Quitanda roda a tumbling window, e o agendado
aparece pela diferença.

## O gatilho de evento de armazenamento

**Um gatilho de evento roda o pipeline quando um blob é criado ou apagado**, com a pasta e o nome do
blob como parâmetros, pelo Event Grid, que precisa estar registrado na assinatura. É o gatilho certo
quando os arquivos chegam sem horário fixo, como um parceiro que sobe o arquivo quando o sistema dele
termina. A fraqueza dele é o espelho da força: um arquivo que nunca chega não inicia nada, e nenhuma
execução falha para avisar. Uma tumbling window que não encontra arquivo falha alto às 03:30, que é o
comportamento que uma carga noturna quer.
