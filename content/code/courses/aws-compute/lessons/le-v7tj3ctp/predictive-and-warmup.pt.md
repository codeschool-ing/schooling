---
title: Escala preditiva, e os minutos de que uma instância precisa
version: 1
---

Um agendamento é uma previsão escrita por uma pessoa. **A escala preditiva é uma previsão escrita
pela AWS**: ela lê o histórico de carga do próprio grupo, acha nele o padrão diário e semanal, e
lança instâncias antes da subida que espera. É um agendamento que se reescreve sozinho, e ajuda
exatamente na medida em que a carga se repete.

## O que a AWS documenta sobre ela

Nada da parte preditiva desta seção foi executado, porque o moto não tem nem o histórico nem a
previsão. Segundo a documentação da AWS:

- uma política preditiva precisa de pelo menos 24 horas de histórico de métricas antes de prever
  qualquer coisa, e lê até 14 dias dele;
- ela prevê as próximas 48 horas, hora a hora, e faz uma previsão nova a cada 6 horas;
- no modo `ForecastOnly` ela prevê e não faz mais nada, que é como descobrir se a previsão presta
  antes de deixá-la agir; no `ForecastAndScale` ela sobe a capacidade mínima do grupo antes de cada
  hora prevista;
- `SchedulingBufferTime` diz quantos segundos antes lançar, que é o tempo de boot que ela está
  comprando;
- ela não reduz sozinha. Ela trabalha ao lado de uma política de target tracking: a previsão sobe o
  piso antes da subida, e a política dinâmica cuida do que a previsão errou.

No laboratório a política pode ser criada, no modo para começar, e a previsão dela não pode ser
lida:

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name forecast --policy-type PredictiveScaling --predictive-scaling-configuration '{"MetricSpecifications": [{"TargetValue": 50, "PredefinedMetricPairSpecification": {"PredefinedMetricType": "ASGCPUUtilization"}}], "Mode": "ForecastOnly"}'
ana@laptop:~/aws$ aws autoscaling get-predictive-scaling-forecast --auto-scaling-group-name web --policy-name forecast --start-time 2026-10-19T00:00:00Z --end-time 2026-10-20T00:00:00Z

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

O `put-scaling-policy` fica em silêncio como antes, e o `get-predictive-scaling-forecast` é mais uma
chamada que o moto não implementa. **Na AWS essa chamada devolve a carga prevista e a capacidade
prevista**, hora a hora para o período pedido, e é ela que se olha durante uma semana em
`ForecastOnly`, contra o que de fato aconteceu, antes de trocar o modo.

Uma carga cheia de picos mas sem período não ganha nada com ela. Uma previsão é um padrão projetado
para a frente, e um lançamento anunciado numa rede social num horário que ninguém escolheu não está
em padrão nenhum.

## Os minutos de que uma instância precisa

Todas as políticas acima contam instâncias, e uma instância nova não é útil no momento em que passa
a existir. Ela sobe, roda o user data, inicia a aplicação e enche os caches, e durante esse tempo as
métricas dela enganam: a CPU pode ficar em 100% enquanto ela inicia, ou perto de zero porque nada é
enviado a ela ainda. Contada na média do grupo, de um jeito ou de outro, ela distorce justamente o
número pelo qual a política se guia.

**O default instance warmup é o tempo, depois de uma instância entrar em serviço, durante o qual as
métricas dela ficam fora do agregado do grupo.** Políticas de passos e de target tracking o usam para
não aumentar de novo por uma subida que as instâncias aquecendo estão prestes a absorver, e um
instance refresh (lição 4) o usa como warmup entre lotes quando nenhum é informado. A AWS recomenda
defini-lo em todo grupo, com o tempo que a aplicação realmente leva para ficar pronta.

Ele não é a mesma coisa que duas configurações com que é fácil confundi-lo:

| configuração | o que ela decide |
| --- | --- |
| período de carência do health check | quanto tempo até um health check com falha contar contra uma instância nova |
| default instance warmup | quanto tempo até as métricas de uma instância nova contarem na média do grupo |
| cooldown | quanto tempo uma política simples espera antes de agir de novo |

O grupo desta lição foi criado com um warmup de 180 segundos. Isto é o que o moto guardou:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].{grace: HealthCheckGracePeriod, warmup: DefaultInstanceWarmup, cooldown: DefaultCooldown}"
[
    {
        "grace": 300,
        "warmup": null,
        "cooldown": 300
    }
]
```

**`null` é o moto descartando a configuração.** Ele aceitou `--default-instance-warmup 180` sem erro
e não guardou nada; na AWS a mesma descrição mostra `DefaultInstanceWarmup` como 180. A carência e o
cooldown são os padrões do moto, 300 cada um, que a lição 4 já comparou com os da AWS.

## Encurtar os minutos em vez de esperar por eles

O warmup diz às políticas para ter paciência. A outra direção é precisar de menos paciência. Uma
imagem pronta (lição 2) sobe preparada em vez de instalar no boot (lição 7), e um **warm pool** mantém
algumas instâncias já lançadas e depois paradas, para que um aumento ligue uma em segundos em vez de
subir uma nova do zero. Uma instância parada no pool custa os volumes EBS e não as horas. Warm pools
não foram exercitados aqui; a lição 6 apresenta o outro jeito de conseguir capacidade barata, que é
aceitar que a AWS pode tomá-la de volta.
