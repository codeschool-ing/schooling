---
title: O App Runner, ensinado pela documentação
version: 1
---

**Nada nesta seção foi executado.** O moto não tem App Runner, e a AWS não o oferece em São Paulo,
então este curso não consegue nem imitá-lo nem dar o preço dele em `sa-east-1`. O que vem a seguir
é o App Runner como a própria documentação da AWS o descreve, os preços que ele tem em `us-east-1`
e um comando que mostra o que o moto faz quando alguém pede:

```
ana@laptop:~/aws$ aws apprunner list-services --region us-east-1

aws: [ERROR]: An error occurred (500) when calling the ListServices operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

Um 500 do moto quer dizer que o serviço não está implementado. Não é um erro da AWS, e a AWS nunca
mandaria uma página HTML para a linha de comando.

## A situação do serviço, com data

**A AWS fechou o App Runner para novos clientes em 30 de abril de 2026.** As notas de versão
avisaram a data com antecedência, e o guia do desenvolvedor tem uma página chamada *AWS App Runner
availability change*. Em 16 de outubro de 2026, essa página dizia três coisas: o serviço não está
mais aberto a novos clientes, os clientes atuais podem continuar a usá-lo normalmente, e o caminho
recomendado para migrar é o Amazon ECS Express Mode. Esta aula não afirma nada além dessas frases: nem sobre
novos recursos, nem sobre o que acontece depois com os serviços que já existem. Se você estiver
lendo isto depois dessa data, confira a mesma página antes de confiar numa palavra deste parágrafo.

Então a leitura prática é curta. **Uma conta que nunca usou o App Runner não consegue começar
agora**, e a sua, se você abrir uma para este curso, é uma conta assim. O motivo para aprender
mesmo assim é que muitas empresas rodam serviços nele, e o modelo que ele usa é o exemplo mais
claro que a AWS tem de uma plataforma que recebe um contêiner e devolve um endereço. O Elastic
Beanstalk, na próxima seção, é o exemplo mais antigo, e ainda aberto, da mesma promessa.

## Entra a origem, sai um endereço

A imagem errada é a de que o App Runner é um Fargate menor. O Fargate, da aula 9, roda uma task que
você descreveu, dentro de uma rede e atrás de um load balancer que você construiu. **O App Runner
pede menos e decide mais.** Você entrega uma de duas origens, e o modelo da API que a própria linha
de comando carrega lista as duas:

```
ana@laptop:~/aws$ aws apprunner create-service --generate-cli-skeleton | jq '{ServiceName, SourceConfiguration: (.SourceConfiguration | keys), InstanceConfiguration: (.InstanceConfiguration | del(.InstanceRoleArn))}'
{
  "ServiceName": "",
  "SourceConfiguration": [
    "AuthenticationConfiguration",
    "AutoDeploymentsEnabled",
    "CodeRepository",
    "ImageRepository"
  ],
  "InstanceConfiguration": {
    "Cpu": "",
    "Memory": ""
  }
}
```

O esqueleto é impresso pela linha de comando no seu laptop, a partir da descrição da API que vem
com ela, e não chega a ninguém. `ImageRepository` é uma imagem no ECR, o registro da aula 10.
`CodeRepository` é um repositório Git, que o próprio App Runner transforma em imagem, com um
runtime gerenciado para Python, Node.js, Java e várias outras linguagens. `AutoDeploymentsEnabled`
faz de cada imagem nova ou de cada commit novo uma implantação, sem nenhum pipeline seu no meio.

O que volta é um endereço HTTPS em `awsapprunner.com`. Não há load balancer para criar, nem target
group, nem security group na frente do serviço, nem sub-rede para escolher. O App Runner é dono de
tudo isso, e esse é o propósito dele e também o primeiro limite que você encontra: por padrão o
serviço alcança a internet e nada mais, e alcançar um banco de dados privado exige um *VPC
connector*, um recurso à parte.

## Como ele escala, e o que é cobrado

A instância sai de um cardápio curto. A documentação da API dá de 0,25 a 4 vCPU e de 0,5 a 12 GB de
memória, com **1 vCPU e 2 GB como padrão**. A escala é por requisições simultâneas, e não por CPU,
definida numa *auto scaling configuration* com três números cujos padrões a mesma documentação
informa:

| configuração | padrão | o que decide |
| --- | --- | --- |
| `MaxConcurrency` | 100 | requisições que uma instância atende ao mesmo tempo antes de o App Runner somar outra |
| `MinSize` | 1 | instâncias mantidas provisionadas o tempo todo |
| `MaxSize` | 25 | o máximo de instâncias que chegam a atender tráfego |

**Uma instância provisionada não é o mesmo que uma instância ativa**, e a conta é construída sobre
essa diferença. O App Runner mantém pelo menos `MinSize` instâncias provisionadas, com o seu código
carregado e pronto, e as ativa quando as requisições chegam. Você paga a memória de toda instância
provisionada e o processador só das ativas. A documentação acrescenta que, durante uma implantação,
o App Runner dobra temporariamente as instâncias provisionadas, para que o código antigo e o novo
rodem lado a lado.

```
ana@laptop:~/aws$ python3 prices.py containers | tail -n 3
App Runner, us-east-1 (not offered in sa-east-1)
  vCPU, while serving                              0.064  per hour
  memory, provisioned or serving                   0.007  per GB-hour
```

Essas são as duas linhas que a tabela da aula 1 imprime, como publicadas em 16 de outubro de 2026.
O arquivo por trás delas tem mais três, e vale lê-las uma vez, direto do cache:

```
ana@laptop:~/aws$ jq -r '.terms.OnDemand[][].priceDimensions[] | "\(.pricePerUnit.USD)\t\(.unit)\t\(.description)"' ~/.cache/aws-prices/AWSAppRunner-*.json | sort
0.0050000000	Mins	AWS App Runner - Build-mins- US East (N. Virginia)
0.0070000000	hours	AWS App Runner - GB-hours - US East (N. Virginia)
0.0070000000	hours	AWS App Runner - Provisioned - GB-hours - US East (N. Virginia)
0.0640000000	vCPU-hour	AWS App Runner - vCPU - US East (N. Virginia)
1.0000000000	pipelines	AWS App Runner - AutomaticDeployment - US East (N. Virginia)
```

As duas linhas de memória, provisionada e atendendo, têm o mesmo 0,007, e é por isso que a tabela as
imprime como uma só. Um build a partir do código custa 0,005 USD por minuto de build. A
implantação automática custa 1 USD por *pipeline*, a unidade do próprio arquivo, que a página de
preços da AWS cobra por mês para cada serviço que a tem ligada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um dia de um serviço do App Runner com a instância padrão de 1 vCPU e 2 GB, em três linhas sobre um eixo de 24 horas. Linha um: uma instância provisionada, cuja memória é cobrada em todas as horas do dia, com ou sem visitas. Linha dois: a mesma instância ativa das 08:00 às 18:00, quando a vCPU também é cobrada. Linha três: o serviço pausado das 19:00 às 07:00, quando nada é cobrado, e cobrado como acima no intervalo.\"><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">instância provisionada</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memória: 2 GB × 0,007 USD por hora</text><rect x=\"190.0\" y=\"40\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">instância ativa</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">vCPU: 1 × 0,064 USD por hora</text><rect x=\"190.0\" y=\"110\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pausada à noite</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">PauseService das 19:00 às 07:00</text><rect x=\"190.0\" y=\"180\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"190.0\" y=\"40\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"436.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">memória cobrada toda hora, com ou sem visitas</text><rect x=\"354.0\" y=\"110\" width=\"205.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"456.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vCPU cobrada enquanto atende</text><rect x=\"333.5\" y=\"180\" width=\"246.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">memória e vCPU como acima</text><text x=\"261.75\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada cobrado</text><text x=\"630.75\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada cobrado</text><path d=\"M190.0 228 L190.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"190.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M313.0 228 L313.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"313.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M436.0 228 L436.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"436.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M559.0 228 L559.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"559.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M682.0 228 L682.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"682.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><path d=\"M190.0 228 L682.0 228\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "Dois medidores numa instância. A memória corre sempre que a instância está provisionada; o processador, só enquanto ela atende. Só uma pausa para os dois."}
```

Ponha números na instância padrão, 1 vCPU e 2 GB, num mês de 730 horas:

- provisionada e ociosa o mês todo: 2 GB × 0,007 × 730 = **10,22 USD**, só memória;
- ativa o mês todo: (0,064 + 2 × 0,007) × 730 = 0,078 × 730 = **56,94 USD**;
- ativa 240 horas e ociosa nas outras 490: 240 × 0,078 + 490 × 0,014 = 18,72 + 6,86 = **25,58 USD**.

**Ela nunca escala até zero sozinha.** `MinSize` não pode ficar abaixo de um, o que o próprio modelo
da API impõe, então um serviço que ninguém visita continua pagando a memória. O único jeito de parar
o medidor é `PauseService`, que segundo a documentação reduz a capacidade de computação a zero e
perde o estado, inclusive o armazenamento efêmero; um serviço pausado não responde a ninguém até
ser retomado. É um ato manual, o que torna o App Runner barato para um serviço movimentado no
horário comercial e pausado à noite só se alguém, ou um agendamento, fizer a pausa.
