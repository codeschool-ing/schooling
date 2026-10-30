---
title: "Regras de escala, e quanto custa o zero"
version: 1
---

O scale set da lição 4 somava máquinas quando a carga média de processador passava de uma linha, e
nunca ficava abaixo do mínimo de três. Um container app escala de outro jeito, em dois pontos.
**Ele conta o trabalho que chega, e não a carga que esse trabalho causa**: requisições por segundo,
conexões abertas, mensagens esperando numa fila. E **o mínimo dele pode ser zero**, então uma
revisão sem nada para fazer não roda réplica nenhuma e não custa nada. O preço do zero é pago pela
primeira requisição depois dele, que tem de esperar uma réplica iniciar. Esta seção lê as regras da
documentação da Microsoft, compila a da loja e mostra um erro que o compilador apanha e um que ele
deixa passar.

## Limites, por revisão

Uma *réplica* é uma cópia em execução de uma revisão, e o bloco de escala diz quantas pode haver:

```
ana@laptop:~/azure$ az containerapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(min-replicas|max-replicas|scale-rule-http-concurrency|scale-rule-type) ' | sed 's/ For more.*//'
 --max-replicas : The maximum number of replicas. 
 --min-replicas : The minimum number of replicas. 
 --scale-rule-http-concurrency --scale-rule-tcp-concurrency --srhc --srtc : The maximum number of concurrent requests before scale out. Only supported for http and tcp scale rules. 
 --scale-rule-type --srt : The type of the scale rule. Default: http.
```

A ajuda não dá padrão para os dois limites; a documentação dá. **`minReplicas` vale 0 por padrão e
`maxReplicas`, 10**, e qualquer um dos dois pode ir até 1.000. Os dois contam réplicas **por
revisão**, o que importa na seção 05: duas revisões dividindo o tráfego podem rodar até dez cada uma.
Os limites da loja, como o template os leva:

```
ana@laptop:~/azure$ jq '.resources[1].properties.template.scale' shop-app.json
{
  "minReplicas": 0,
  "maxReplicas": 10,
  "cooldownPeriod": 300,
  "pollingInterval": 30,
  "rules": [
    {
      "name": "http",
      "http": {
        "metadata": {
          "concurrentRequests": "50"
        }
      }
    }
  ]
}
```

`cooldownPeriod` e `pollingInterval` estão escritos com 300 e 30 segundos, que são os padrões
documentados. Deixá-los de fora não mudaria nada. Escrevê-los põe os dois números diante de quem ler
o arquivo depois.

## Três tipos de regra

**HTTP** conta requisições concorrentes, e a documentação define a conta com precisão: a cada 15
segundos, o número de requisições dos últimos 15 segundos dividido por 15. 1.500 requisições em um
quarto de minuto dão uma concorrência de 100. Quando ela passa do `concurrentRequests` da regra, 10
se você não disser outro, a revisão ganha uma réplica, e continua ganhando até `maxReplicas`. A
regra da loja diz 50. **TCP** é a mesma ideia com conexões abertas, para um app cujo ingress fala TCP
em vez de HTTP.

Regras **personalizadas** são qualquer um dos scalers do KEDA: uma fila do Storage, uma fila do
Service Bus, Event Hubs, Kafka, Redis, carga de processador ou de memória. O worker de pedidos da
loja, que a lição 20 constrói sobre o Service Bus, escalaria pela fila dele. No formato que a página
de escala da Microsoft dá para uma fila do Storage, lida pela identidade gerenciada do próprio app em
vez de uma chave, a regra é:

```bicep
rules: [
  {
    name: 'orders-queue'
    custom: {
      type: 'azure-queue'
      metadata: {
        accountName: 'shopordersp'
        queueName: 'orders'
        queueLength: '5'
      }
      identity: 'system'
    }
  }
]
```

Esse fragmento não faz parte do arquivo da loja e não foi compilado sozinho. Onde o scaler precisa
de um segredo, a lista `auth` da regra nomeia um dos segredos do app. A página da Microsoft
acrescenta uma condição: um app que escala por eventos que não sejam HTTP deve rodar no modo de
revisão *única*, que a seção 04 explica.

**Uma regra de carga de processador não chega a zero sozinha.** A própria documentação do KEDA diz
que os scalers de CPU e de memória só escalam até zero quando há outro scaler, de outro tipo,
definido ao lado. Uma réplica que não está rodando não tem carga de processador para medir, então
nada traria a primeira de volta.

Mais duas regras de combinação. Com várias regras, o app começa a escalar assim que qualquer uma
delas é atendida. Sem nenhuma, vale um padrão: HTTP, entre 0 e 10. **Um app sem ingress, sem regra
personalizada e com mínimo 0 escala até zero e não tem como voltar a iniciar**, porque a única regra
que ele tem conta requisições que não conseguem chegar. A documentação marca isso como importante, e
é o tipo de erro que nada acusa: o app está saudável, e ocioso para sempre.

## Como uma decisão é tomada

O KEDA não reage a cada requisição. A tabela de comportamento da documentação:

| comportamento | valor |
| --- | --- |
| intervalo de polling | 30 segundos, para fontes de eventos; não usado por regras HTTP e TCP |
| período de cool-down | 300 segundos, aplicado só quando a última réplica vai a zero |
| janela de estabilização ao escalar para cima | 0 segundos |
| janela de estabilização ao escalar para baixo | 300 segundos |
| passo ao escalar para cima | 1, depois 4, 8, 16, 32 e assim por diante, até o máximo |
| passo ao escalar para baixo | todas as réplicas que não são mais necessárias |
| réplicas desejadas | `ceil(currentMetricValue / targetMetricValue)` |

A documentação resolve um exemplo até o fim, e vale acompanhá-lo uma vez. Uma regra de fila pede uma
réplica a cada 5 mensagens, com máximo de 20, e chegam 50 mensagens: o número desejado é
`ceil(50/5)`, 10. O app não pula para 10. Cada passo é
`min(maxReplicaCount, desiredReplicas, max(4, 2*currentReplicaCount))`, então a partir de 1 réplica o
número seguinte é `min(20, 10, 4)`, 4; no polling seguinte, `min(20, 10, 8)`, 8; depois 10.
**Escalar para cima é rápido, e escalar para baixo espera**: cinco minutos de uma condição valendo
antes de réplicas saírem, e cinco minutos depois do último evento antes de sair a última.

Os limites são onde o compilador para de ajudar. O próprio exemplo em Bicep da Microsoft para uma
regra HTTP diz que ela escala para cinco réplicas e de volta a zero, e escreve `maxReplicas: 0` e
`minReplicas: 5`. A mesma troca no arquivo da loja:

```
ana@laptop:~/azure$ sed 's/minReplicas: 0/minReplicas: 5/; s/maxReplicas: 10/maxReplicas: 0/' shop-app.bicep > swap.bicep
ana@laptop:~/azure$ bicep build swap.bicep
ana@laptop:~/azure$ jq -c '.resources[1].properties.template.scale | {minReplicas, maxReplicas}' swap.json
{"minReplicas":5,"maxReplicas":0}
```

Nenhum aviso. Os dois são números inteiros, que é tudo o que o tipo pede, e o compilador não compara
uma propriedade com outra: o mesmo ponto cego que a lição 4 encontrou com um mínimo de autoscale
acima do máximo. Um valor de metadata é diferente, porque todo valor em `metadata` é tipado como
texto:

```
ana@laptop:~/azure$ sed "s/concurrentRequests: '50'/concurrentRequests: 50/" shop-app.bicep > number.bicep
ana@laptop:~/azure$ bicep build number.bicep
/home/ana/azure/number.bicep(68,37) : Warning BCP036: The property "concurrentRequests" expected a value of type "string" but the provided value is of type "50". [https://aka.ms/bicep/core-diagnostics#BCP036]
```

## Quanto custa o zero

**Uma revisão com zero réplicas não gera cobrança de uso**, segundo a página de cobrança da
Microsoft, e esse é o motivo inteiro do perfil Consumption para uma loja quieta da meia-noite às
sete. Uma revisão mantida com mínimo de 1 ou mais paga por essa réplica a noite toda. A tarifa cai
para uma tarifa *ociosa*, reduzida, enquanto a réplica não atende requisições, usa menos de 0,01 de
um núcleo e recebe menos de 1.000 bytes por segundo. A lição 21 põe números na diferença.

O outro lado é o **cold start**. A documentação o define como o tempo de baixar a imagem,
provisionar os recursos e iniciar a aplicação, e a primeira requisição depois do zero espera pelas
três coisas. O estado da revisão mostra isso: *Scale to 0* enquanto ociosa, *Activating* enquanto a
primeira réplica é provisionada. Parte do que é baixado é isto:

```
ana@laptop:~/azure$ docker image ls shop:1.0 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
shop:1.0  178MB
```

178 MB, quase tudo da base `python:3.12-slim`, já que o `app.py` tem alguns kilobytes. Uma imagem
pequena é a primeira das sugestões da Microsoft para um cold start mais curto. A segunda é um
registro na mesma região do ambiente, e é por isso que o registro da loja fica em `brazilsouth`. A
terceira é uma aplicação que abre a porta cedo, antes de qualquer inicialização lenta, e a quarta
são clientes que esperam uma primeira resposta lenta e tentam de novo. A última é acordar o app de
propósito, com uma requisição enviada por um job agendado um pouco antes do primeiro cliente. A
lição 16 mede um cold start no laptop, para o Functions, onde a mesma troca decide o plano.

Então a escolha da loja é entre uma primeira requisição da manhã que espera, sem custo durante a
noite, e um mínimo de 1 que nunca espera e é pago a cada hora. Nenhuma das duas está errada. Para uma
API de pedidos que os clientes alcançam por um app no celular, uma réplica ociosa é a resposta
comum; para a página interna de estoque que os três desenvolvedores abrem duas vezes por dia, zero
é.

## Quando o trabalho termina: jobs

Um app é algo que roda até mandarem parar, e reinicia quando cai. Um **job do Container Apps** roda,
termina e para, no mesmo ambiente dos apps, com a mesma rede e os mesmos logs. É a resposta do
Container Apps ao grupo com `OnFailure` da lição 7, e o próprio exemplo da Microsoft é um processo
que gera relatórios financeiros toda noite.

Um job é iniciado de um de três jeitos: *Manual*, sob pedido; *Schedule*, por uma expressão cron de
cinco campos; ou *Event*, pelos mesmos scalers do KEDA vistos acima, que iniciam uma execução por
lote de mensagens em vez de somar réplicas. Jobs não aceitam regras HTTP nem TCP e não têm ingress.
Cada execução tem um `replicaTimeout` em segundos e um `replicaRetryLimit`, o que dá ao relatório o
que faltava ao grupo da lição 7: um prazo, e um limite de quantas vezes ele é tentado de novo. Um
detalhe pega São Paulo. **Expressões cron de jobs agendados são avaliadas em UTC**, então o relatório
das 23:30 em São Paulo, três horas atrás, é `30 2 * * *`.
