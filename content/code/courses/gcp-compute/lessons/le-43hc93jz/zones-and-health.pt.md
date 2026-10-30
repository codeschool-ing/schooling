---
title: Zonas, verificações de saúde e autohealing
version: 1
---

Um grupo que só contasse máquinas manteria três máquinas rodando que respondem todas com erro. **O
autohealing acrescenta um segundo teste: o grupo faz uma pergunta pela rede a cada máquina, e uma
máquina que falha vezes suficientes é apagada e refeita a partir do template.** Uma máquina ligada e
quebrada é o tipo mais comum de quebrada, e é isso que a encontra.

## A pergunta que uma verificação de saúde faz

Uma verificação de saúde é um recurso próprio: o que perguntar, com que frequência e quantas
respostas decidem. Acrescente-a ao `group/main.tf`:

```hcl
# group/main.tf, health
resource "google_compute_health_check" "web" {
  name                = "web-health"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }
}
```

Leia como uma regra: **a cada 10 segundos, peça `/healthz` na porta 8080 e espere 5 por uma resposta;
três falhas seguidas deixam uma máquina doente, dois sucessos a deixam saudável de novo.** Então uma
máquina que para de responder é notada em cerca de 30 segundos, e uma única resposta lenta não basta
para condená-la. O caminho é a aplicação que fornece, e o que ele verifica importa: um `/healthz` que
sempre responde `200` porque o servidor web está de pé não diz nada sobre o banco atrás dele estar
acessível.

## Ligando ao grupo

O grupo usa a verificação por um bloco `auto_healing_policies`. Acrescente-o dentro do recurso do
grupo, depois de `named_port`:

```hcl
# group/main.tf, inside the group
  auto_healing_policies {
    health_check      = google_compute_health_check.web.id
    initial_delay_sec = 120
  }
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^  #|initial_delay_sec|request_path|unhealthy_threshold|^Plan'
  # google_compute_health_check.web will be created
      + unhealthy_threshold = 3
          + request_path = "/healthz"
  # google_compute_instance_template.web will be created
  # google_compute_region_instance_group_manager.web will be created
          + initial_delay_sec = 120
Plan: 3 to add, 0 to change, 0 to destroy.
```

**`initial_delay_sec` é o número mais importante do bloco.** Uma máquina nova precisa de tempo para
subir, iniciar o serviço e esquentar, e durante esse tempo ela falha em toda verificação. Sem um
atraso, o grupo veria uma máquina nova falhar, a apagaria, faria outra, veria essa falhar, e daria
voltas para sempre sem nenhuma máquina terminar o boot. 120 segundos é um palpite a trocar por uma
medida: cronometre quanto tempo uma máquina leva da criação até a primeira resposta saudável, e some
uma margem.

As verificações de saúde vêm de endereços de sondagem do próprio Google, e o firewall precisa
deixá-las entrar, senão toda máquina falha na verificação e o grupo recria todas num laço. Essas
faixas e a regra que as libera pertencem à lição 16 do `gcp-foundations`, sobre regras de firewall.

## Como um grupo regional distribui máquinas

O grupo da seção 03 nomeou três zonas e pediu três máquinas, então põe uma em cada. Com
`target_size = 4` a quarta vai para uma das zonas e a distribuição fica dois, um, um; o grupo mantém
a diferença entre zonas em no máximo uma máquina. Se uma zona cai, o grupo cria substitutas nas zonas
que sobraram, e quando a zona volta ele move máquinas de volta para equilibrar, **o que significa
apagar algumas e criar outras**. Esse movimento é controlado pela política de atualização da seção
05, e é mais um motivo para as máquinas não terem estado.
