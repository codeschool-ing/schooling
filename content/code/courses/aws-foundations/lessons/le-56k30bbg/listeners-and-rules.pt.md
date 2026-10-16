---
title: Listeners, regras e grupos de alvos
version: 1
---

**Um balanceador não faz nada até ter um listener**, e um listener não faz nada até ter para onde
mandar. Três objetos formam o caminho, e a API os mantém separados de propósito. O **listener** é um
protocolo e uma porta que o balanceador aceita. As **regras** dele decidem, requisição a requisição,
qual **grupo de alvos** (*target group*) responde. Um grupo de alvos é um conjunto de máquinas,
endereços ou funções com uma verificação de saúde que todos compartilham. A imagem errada são
máquinas presas a um balanceador. Máquinas são presas a um grupo de alvos, e o mesmo grupo pode
estar atrás de vários listeners e várias regras ao mesmo tempo.

## Um grupo de alvos, e o que ele vigia

A aplicação web da loja escuta na porta 8080 de cada máquina e responde a `GET /health` quando está
bem. O grupo de alvos diz as duas coisas:

```
ana@laptop:~/aws$ aws elbv2 create-target-group --name shop-web-app --protocol HTTP --port 8080 --vpc-id $vpc --target-type instance --health-check-path /health --health-check-interval-seconds 15 --healthy-threshold-count 3 --matcher HttpCode=200 --query "TargetGroups[0].[TargetType,Protocol,Port,HealthCheckPath,HealthCheckIntervalSeconds,HealthyThresholdCount,UnhealthyThresholdCount]" --output text
instance	HTTP	8080	/health	15	3	2
```

**Um alvo fica saudável depois de três respostas boas seguidas e não saudável depois de duas
ruins**, com uma verificação a cada 15 segundos. O dois é o padrão, que o comando não mudou. Então
uma máquina que para de responder sai do rodízio uns 30 segundos depois, e uma que volta entra de
novo depois de 45. Esses três números são a troca entre reagir rápido e reagir a ruído.

**`--target-type` decide o que é um alvo, e não pode ser mudado depois.** `instance` registra
máquinas pelo id, e o tráfego vai para o endereço primário delas na porta do grupo. `ip` registra
endereços, e é assim que uma plataforma de contêineres, uma máquina numa VPC emparelhada ou uma no
datacenter da própria loja, pela VPN da lição 24, entra atrás de um ALB. `lambda` registra uma
função, e o ALB transforma cada requisição numa invocação. A lição 14 do `aws-compute` escreve uma.
Ponha os ids em variáveis e registre as duas máquinas:

```
ana@laptop:~/aws$ tg=$(aws elbv2 describe-target-groups --names shop-web-app --query "TargetGroups[0].TargetGroupArn" --output text)
```

```
ana@laptop:~/aws$ aws elbv2 register-targets --target-group-arn $tg --targets Id=$web1 Id=$web2
```

## O que o moto sabe sobre saúde

```
ana@laptop:~/aws$ aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]" --output text
i-93a432057e9443a25	8080	healthy
i-8eb1bd5fa0d8d0a62	8080	healthy
```

**As duas máquinas estão `healthy`, e ninguém perguntou a elas.** Nenhum programa escuta na 8080 de
nenhuma delas, porque no moto não há máquinas para rodar um, só registros de máquinas. Na AWS um
alvo novo começa `initial` enquanto as primeiras verificações rodam, e estes dois passariam a
`unhealthy` com o motivo `Target.FailedHealthChecks`. Mas o moto vai além do otimismo. Registre um id
de instância que não existe em lugar nenhum:

```
ana@laptop:~/aws$ aws elbv2 register-targets --target-group-arn $tg --targets Id=i-0000000000000dead
ana@laptop:~/aws$ aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]" --output text
i-93a432057e9443a25	8080	healthy
i-8eb1bd5fa0d8d0a62	8080	healthy
i-0000000000000dead	8080	healthy
```

**A AWS recusa isso com `InvalidTarget`; o moto o registrou e o chama de saudável.** O que o moto lê
é o estado da instância: uma máquina parada volta `unused` com o motivo `Target.InvalidState`, que é
também o que a AWS diz de uma. Tire o id morto de novo, para o grupo dizer só o que é verdade:

```
ana@laptop:~/aws$ aws elbv2 deregister-targets --target-group-arn $tg --targets Id=i-0000000000000dead
```

## Listeners, e um certificado

A loja responde em HTTPS, então o balanceador precisa de um **certificado** para `shop.example.com`.
O **AWS Certificate Manager (ACM)** emite certificados públicos sem custo, os renova sozinho e os
entrega a um balanceador sem que a chave privada saia da AWS. É isso que **terminação TLS** quer
dizer aqui: o ALB decifra e lê a requisição. Ele fala com os alvos pela VPC, em HTTP puro na 8080
como configurado acima, ou em TLS de novo se o grupo disser `HTTPS`.

```
ana@laptop:~/aws$ aws acm request-certificate --domain-name shop.example.com --subject-alternative-names www.shop.example.com --validation-method DNS --query CertificateArn --output text
arn:aws:acm:sa-east-1:123456789012:certificate/07485baf-cc49-4664-9db9-21b13587240b
```

```
ana@laptop:~/aws$ cert=$(aws acm list-certificates --query "CertificateSummaryList[0].CertificateArn" --output text)
ana@laptop:~/aws$ aws acm describe-certificate --certificate-arn $cert --query "Certificate.[DomainName,Status,Type]" --output text
shop.example.com	PENDING_VALIDATION	AMAZON_ISSUED
```

**`PENDING_VALIDATION` é onde um certificado novo espera a prova.** O ACM lhe dá um registro `CNAME`
para criar na zona, como a lição 21 cria registros, e emite o certificado quando consegue ver o
registro. Um balanceador só aceita um certificado que foi emitido. O moto nunca o emite, e deixa um
listener usá-lo mesmo assim. O listener também nomeia uma **política de segurança**, que decide as
versões de TLS e as cifras que ele aceita:

```
ana@laptop:~/aws$ lb=$(aws elbv2 describe-load-balancers --names shop-web --query "LoadBalancers[0].LoadBalancerArn" --output text)
```

```
ana@laptop:~/aws$ aws elbv2 describe-ssl-policies --names ELBSecurityPolicy-2016-08 ELBSecurityPolicy-TLS13-1-2-2021-06 --query "SslPolicies[].[Name,join(' ', SslProtocols)]" --output text
ELBSecurityPolicy-2016-08	TLSv1.2 TLSv1.1 TLSv1
ELBSecurityPolicy-TLS13-1-2-2021-06	TLSv1.3 TLSv1.2
```

**Nomeie a política você mesmo.** Se ela ficar de fora, o listener recebe uma padrão, e no moto essa
padrão é `ELBSecurityPolicy-2016-08`, que ainda aceita TLS 1.0 e 1.1. A política mais nova aceita só 1.2
e 1.3, que todo navegador dos clientes da loja fala. O listener na 443 manda tudo para o grupo de
alvos web a menos que uma regra diga outra coisa, e o ARN dele vai para uma variável para as regras:

```
ana@laptop:~/aws$ aws elbv2 create-listener --load-balancer-arn $lb --protocol HTTPS --port 443 --certificates CertificateArn=$cert --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 --default-actions Type=forward,TargetGroupArn=$tg --query "Listeners[0].[Protocol,Port,SslPolicy]" --output text
HTTPS	443	ELBSecurityPolicy-TLS13-1-2-2021-06
ana@laptop:~/aws$ https=$(aws elbv2 describe-listeners --load-balancer-arn $lb --query "Listeners[?Port==\`443\`].ListenerArn" --output text)
```

A porta 80 ganha então um listener próprio cujo único trabalho é mandar todo mundo para o HTTPS:

```
ana@laptop:~/aws$ aws elbv2 create-listener --load-balancer-arn $lb --protocol HTTP --port 80 --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,StatusCode=HTTP_301}" --query "Listeners[0].DefaultActions[0].[Type,RedirectConfig.StatusCode]" --output text
redirect	HTTP_301
```

## Regras: a camada 7 do nome

**Uma regra é uma condição e uma ação, com uma prioridade**. O listener tenta as regras do menor
número para cima, e a primeira que casar vence. A ação padrão responde ao que não casar com nenhuma.
As condições são o que só um ALB enxerga, porque só um ALB lê a requisição: o **host**, o **caminho**,
um **cabeçalho**, o método, uma query string, o endereço de quem chama. A API da loja roda em
máquinas separadas em endereços conhecidos, `10.20.0.50` e `10.20.1.50`. Então ela ganha um grupo de
alvos do tipo `ip`, os dois endereços e uma regra pelo caminho:

```
ana@laptop:~/aws$ aws elbv2 create-target-group --name shop-api --protocol HTTP --port 9000 --vpc-id $vpc --target-type ip --query "TargetGroups[0].TargetGroupArn" --output text
arn:aws:elasticloadbalancing:sa-east-1:123456789012:targetgroup/shop-api/ed52c3668157d2d1
```

```
ana@laptop:~/aws$ api=$(aws elbv2 describe-target-groups --names shop-api --query "TargetGroups[0].TargetGroupArn" --output text)
ana@laptop:~/aws$ aws elbv2 register-targets --target-group-arn $api --targets Id=10.20.0.50 Id=10.20.1.50
```

```
ana@laptop:~/aws$ aws elbv2 create-rule --listener-arn $https --priority 10 --conditions Field=path-pattern,Values='/api/*' --actions Type=forward,TargetGroupArn=$api --query "Rules[0].[Priority,Conditions[0].Field,Actions[0].Type]" --output text
10	path-pattern	forward
```

E uma regra que responde sozinha, sem alvo nenhum: o site da equipe ainda não está pronto, então o
host dele recebe uma recusa direto do balanceador.

```
ana@laptop:~/aws$ aws elbv2 create-rule --listener-arn $https --priority 20 --conditions Field=host-header,Values=admin.shop.example.com --actions "Type=fixed-response,FixedResponseConfig={StatusCode=403,ContentType=text/plain,MessageBody=staff only}" --query "Rules[0].[Priority,Conditions[0].Field,Actions[0].Type]" --output text
20	host-header	fixed-response
```

```
ana@laptop:~/aws$ aws elbv2 describe-rules --listener-arn $https --query "Rules[].[Priority,Conditions[0].Field,Conditions[0].Values[0],Actions[0].Type]" --output text
10	path-pattern	/api/*	forward
20	host-header	admin.shop.example.com	fixed-response
default	None	None	forward
```

Essa última regra roteia; ela não protege. **O host, o caminho e todo cabeçalho são o que quem chama
escolheu mandar**, então uma regra sobre eles decide para onde uma requisição vai e nunca quem pode
fazê-la. Quem pode é decidido pela autenticação por trás do balanceador, pelos grupos de segurança da
lição 18 e pelo AWS WAF, que a lição 23 cita.

## Sessões fixas

Por padrão cada requisição pode cair num alvo diferente. A **aderência** (*stickiness*) diz ao ALB
para manter quem chama no mesmo alvo por um tempo, por um cookie que ele mesmo define (`lb_cookie`)
ou um que a aplicação define (`app_cookie`):

```
ana@laptop:~/aws$ aws elbv2 modify-target-group-attributes --target-group-arn $tg --attributes Key=stickiness.enabled,Value=true Key=stickiness.type,Value=lb_cookie Key=stickiness.lb_cookie.duration_seconds,Value=3600 --query "Attributes[?starts_with(Key, 'stickiness')]" --output text
stickiness.enabled	true
stickiness.type	lb_cookie
stickiness.lb_cookie.duration_seconds	3600
```

**A aderência é um remendo para estado guardado numa máquina só**, como uma cesta mantida na memória
de um processo. Ela tem um custo: um alvo que segura muitos chamadores fixos não pode ser esvaziado
rápido, e a carga se espalha de forma desigual. A cesta da loja pertence a um banco de dados ou a um
cache que todo alvo consegue ler, e aí a aderência não tem mais nada para consertar.
