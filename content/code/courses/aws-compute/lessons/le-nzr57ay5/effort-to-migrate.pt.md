---
title: O que a mudança custa, e nenhuma tabela de preços mostra
version: 1
---

A coluna mais barata da seção anterior é um preço para rodar a carga de trabalho depois que ela já
está lá. **Levá-la até lá é uma segunda conta, paga em tempo de engenharia**, e ela costuma ser maior
do que um ano da diferença. Um serviço que economiza 20 USD por mês indo para o Lambda e precisa de
seis semanas de retrabalho para chegar lá comprou a economia a um preço que ninguém assinaria por
escrito.

O que encarece uma mudança quase nunca é o código que responde a uma requisição. É o que o código
supõe, em silêncio, sobre o lugar onde roda.

## Cinco suposições que não viajam

**Um disco só dele.** Um programa numa instância grava uploads, caches e relatórios no sistema de
arquivos e os encontra lá no dia seguinte. O armazenamento de uma task de Fargate é efêmero, 20 GB
por padrão, e vai embora com a task (aula 9). O `/tmp` de uma função tem 512 MB, a menos que você
configure mais, até 10.240 MB segundo a própria documentação da API, e dura só enquanto durar um
ambiente de execução. Sair da instância quer dizer achar cada gravação e mandá-la antes para o S3,
o EFS ou um banco de dados.

**Memória que sobrevive a uma requisição.** Sessões guardadas no processo, um cache em memória, um
contador. Em duas instâncias atrás de um load balancer, isso já funciona pela metade; no Lambda,
cada requisição concorrente pode cair num ambiente diferente, e um ambiente pode sumir a qualquer
momento. Tudo isso precisa ir para um armazenamento compartilhado antes que o código possa mudar.

**Um processo que roda por muito tempo.** Uma função para no timeout, e a documentação da API para
`create-function` dá o limite: **900 segundos, quinze minutos**, com padrão de 3. Um relatório que
leva vinte minutos não roda no Lambda como está escrito; precisa ser cortado em pedaços, rodar numa
task de Fargate ou ser orquestrado pelo Step Functions (aula 20).

**Uma requisição que espera muito.** Atrás do API Gateway, a integração tem o próprio limite, e ele é
mais curto. A documentação que vem com a linha de comando diz que uma integração de HTTP API tem
timeout entre 50 e 30.000 milissegundos, **30 segundos no máximo**; uma REST API tem padrão de 29
segundos, que só pode ser aumentado para APIs regionais e privadas. Um endpoint que monta uma
exportação de 45 segundos de forma síncrona precisa virar um job: aceitar o pedido, colocá-lo numa
fila (aula 21) e deixar o cliente buscar o resultado.

**Uma conexão que fica aberta.** Um pool de 20 conexões de banco por instância são 40 para duas
instâncias. No Lambda, cada ambiente concorrente abre as suas, e na concorrência que a aula 16
calculou o banco de dados é a primeira coisa a cair.

## O moto aceita o que a AWS recusa

Nenhum desses limites pode ser aprendido com o moto, porque o moto não os aplica. Pedindo uma
função com timeout um segundo além do limite, ele a cria:

```
ana@laptop:~/aws$ aws lambda create-function --function-name report --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/report --zip-file fileb://app.zip --timeout 901 --query "[FunctionName, Timeout]"
[
    "report",
    901
]
```

`app.zip` guarda um `app.py` de duas linhas, um handler que devolve `{"ok": True}`, e nada mais.
Pedindo uma integração de HTTP API que espera dois minutos, o moto também registra:

```
ana@laptop:~/aws$ API=$(aws apigatewayv2 create-api --name shop --protocol-type HTTP --query ApiId --output text)
ana@laptop:~/aws$ aws apigatewayv2 create-integration --api-id "$API" --integration-type AWS_PROXY --integration-uri arn:aws:lambda:sa-east-1:123456789012:function:report --payload-format-version 2.0 --timeout-in-millis 120000 --query "[IntegrationType, TimeoutInMillis]"
[
    "AWS_PROXY",
    120000
]
```

**A AWS recusa as duas chamadas**, e nenhuma das recusas foi executada aqui, então esta aula não
cita texto de erro para elas. A lição a tirar é sobre conferir, não sobre o moto: um limite que você
só encontrou numa imitação é um limite que você não encontrou. Leia-o na documentação do serviço e,
na dúvida, no próprio modelo da API que a linha de comando carrega, que é de onde vêm os dois
números acima.

## Uma tabela de mudanças

As mesmas suposições dão um custo aproximado para cada mudança, antes de ler uma linha de código:

| mudança | o que costuma precisar mudar |
| --- | --- |
| EC2 → Fargate | construir uma imagem (curso `docker`); arquivos locais para o S3 ou o EFS; configuração para a task definition |
| EC2 → Lambda | tudo o que está acima, mais sessões e caches fora da memória, jobs longos divididos, conexões agrupadas fora da função |
| Fargate → Lambda | requisições longas transformadas em jobs; o processo servidor trocado por um handler, ou por um adaptador que o embrulhe |
| Lambda → Fargate | um processo servidor em volta dos handlers; regras de escala próprias; um load balancer na frente |
| App Runner → ECS | uma task definition, um service e um load balancer, a partir da mesma imagem |

**As mudanças em direção ao Lambda são as que mais custam**, porque uma função é a que menos supõe
sobre onde roda. As mudanças para fora dele são mais baratas do que parecem: um handler é uma função,
e embrulhá-lo num pequeno servidor web é trabalho de um dia, não de um trimestre. Vale conhecer essa
assimetria antes de escrever a primeira linha, e a aula 24 a transforma numa decisão.
