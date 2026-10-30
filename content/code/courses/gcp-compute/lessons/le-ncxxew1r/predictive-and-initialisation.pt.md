---
title: Previsão, inicialização e redução devagar
version: 1
---

Uma agenda sabe o que uma pessoa escreveu. **O autoscaling preditivo aprende o padrão sozinho, pelo
histórico do próprio grupo, e liga máquinas antes de uma subida que ele já viu.** É o último dos três
jeitos de escalar, e só funciona bem junto com duas configurações que todo autoscaler deveria acertar,
preveja ele ou não.

## O período de inicialização

Entre uma máquina ligar e servir direito há um intervalo: o boot, o serviço iniciando, os caches
esquentando. Nesse intervalo a CPU dela engana, alta pelo trabalho de inicialização ou baixa porque
ainda não chega tráfego. **O período de inicialização diz ao autoscaler por quanto tempo ignorar os
números de uma máquina nova.** No Terraform ele ainda se chama `cooldown_period`, o nome antigo da
configuração, e a ajuda do gcloud diz para que serve:

```
ana@laptop:~/gcp/autoscale$ gcloud compute instance-groups managed set-autoscaling --help | sed -n '/^     --cool-down-period/,/^$/p'
     --cool-down-period=COOL_DOWN_PERIOD
        The number of seconds that your application takes to initialize on a VM
        instance. This is referred to as the initialization period
        (https://cloud.google.com/compute/docs/autoscaler#cool_down_period).
        Specifying an accurate initialization period improves autoscaler
        decisions. For example, when scaling out, the autoscaler ignores data
        from VMs that are still initializing because those VMs might not yet
        represent normal usage of your application. The default initialization
        period is 60 seconds. See $ gcloud topic datetimes for information on
        duration formats. Initialization periods might vary because of numerous
        factors. We recommend that you test how long your application may take
        to initialize. To do this, create a VM and time your application's
        startup process.
```

Curto demais, e o autoscaler lê a CPU de inicialização de uma máquina subindo como carga e acrescenta
máquinas sem motivo. Longo demais, e o escalonamento preditivo liga máquinas mais tarde do que
deveria, porque ele planeja de trás para a frente a partir de quanto tempo uma máquina leva. O número
certo é a mesma medida do atraso inicial da lição 4: da criação até a primeira resposta saudável.

## Previsão

A previsão é uma linha na política, e vale para o sinal de CPU:

```hcl
# autoscale/main.tf, prediction
    cpu_utilization {
      target            = 0.6
      predictive_method = "OPTIMIZE_AVAILABILITY"
    }
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E 'predictive_method|^              \+ target'
              + predictive_method = "OPTIMIZE_AVAILABILITY"
              + target            = 0.6
```

Ela precisa de histórico para aprender: a documentação do Google pede pelo menos três dias do grupo
rodando com autoscaling por CPU antes de as previsões começarem, e ela usa várias semanas quando as
tem. Ela é para **carga que se repete**: uma subida diária, um formato semanal. Para um grupo de carga
aleatória ela não prevê nada útil, e para um grupo novo ainda não tem do que aprender.

## Reduzindo devagar

Crescer tarde custa caro aos usuários; encolher cedo também, porque a carga que acabou de cair muitas
vezes volta logo. Dois mecanismos freiam a descida:

- o **período de estabilização**: antes de remover máquinas, o autoscaler olha as recomendações dos
  últimos dez minutos e usa a maior delas, então uma queda precisa durar para o grupo segui-la;
- os **controles de redução**, que limitam quantas máquinas podem sair numa janela de tempo.

```hcl
# autoscale/main.tf, scale-in control
    scale_in_control {
      time_window_sec = 600

      max_scaled_in_replicas {
        fixed = 2
      }
    }
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E 'scale_in_control|time_window_sec|fixed|^Plan'
          + scale_in_control {
              + time_window_sec = 600
                  + fixed = 2
Plan: 3 to add, 0 to change, 0 to destroy.
```

Leia como: **em quaisquer dez minutos, remova no máximo duas máquinas.** Um grupo que chegou a doze
leva então pelo menos meia hora para voltar a seis, e se a carga voltar nessa meia hora as máquinas
ainda estão lá.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico de barras do tamanho do grupo ao longo do tempo depois que a carga cai no minuto 0. A carga precisa de seis máquinas dali em diante, desenhada como uma linha tracejada. O grupo tem 12 máquinas no minuto 0, 10 no minuto 10, 8 no minuto 20 e 6 no minuto 30, porque o controle de redução remove no máximo duas máquinas a cada dez minutos.\"><defs><marker id=\"l5s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M70 250 L680 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"60\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><rect x=\"100\" y=\"70\" width=\"70\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"135\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minuto 0</text><rect x=\"215\" y=\"100\" width=\"70\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"250\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minuto 10</text><rect x=\"330\" y=\"130\" width=\"70\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"365\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minuto 20</text><rect x=\"445\" y=\"160\" width=\"70\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"480\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minuto 30</text><rect x=\"560\" y=\"160\" width=\"70\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"595\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minuto 40</text><path d=\"M80 160 L98 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M172 160 L213 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M287 160 L328 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M402 160 L443 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M517 160 L558 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M632 160 L680 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"676\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tracejado: o que a carga pede</text></svg>", "caption": "Com no máximo duas máquinas removidas a cada dez minutos, um grupo que chegou a 12 leva meia hora para voltar às 6 que a carga pede."}
```

Nada disso pode ser assistido neste laboratório: não há grupo, nem carga, nem dez minutos de
histórico para olhar. O que o laboratório mostra é a política como o Compute Engine a receberia, e a
conta da seção 02 que o autoscaler aplicaria a ela.
