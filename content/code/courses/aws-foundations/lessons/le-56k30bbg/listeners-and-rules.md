---
title: Listeners, rules and target groups
version: 1
---

**A load balancer does nothing until it has a listener**, and a listener does nothing until it has
somewhere to send. Three objects make the path, and the API keeps them apart on purpose. The **listener**
is a protocol and a port the load balancer accepts. Its **rules** decide, request by request, which **target
group** answers. A target group is a set of machines, addresses or functions with one health check
that they all share. The wrong picture is machines attached to a load balancer. Machines are
attached to a target group, and the same group can sit behind several listeners and several rules at
once.

## A target group, and what it watches

The shop's web application listens on port 8080 on each machine and answers `GET /health` when it is
well. The target group says both:

```
ana@laptop:~/aws$ aws elbv2 create-target-group --name shop-web-app --protocol HTTP --port 8080 --vpc-id $vpc --target-type instance --health-check-path /health --health-check-interval-seconds 15 --healthy-threshold-count 3 --matcher HttpCode=200 --query "TargetGroups[0].[TargetType,Protocol,Port,HealthCheckPath,HealthCheckIntervalSeconds,HealthyThresholdCount,UnhealthyThresholdCount]" --output text
instance	HTTP	8080	/health	15	3	2
```

**A target is healthy after three good answers in a row and unhealthy after two bad ones**, with a
check every 15 seconds. The two is the default, which the command did not change. So a machine that
stops answering is out of rotation about 30 seconds later, and one that comes back is in again after 45.
Those three numbers are the trade between reacting fast and reacting to noise.

**`--target-type` decides what a target is, and it cannot be changed later.** `instance` registers
machines by id, and traffic goes to their primary address on the group's port. `ip` registers
addresses, which is how a container platform, a machine in a peered VPC or one in the shop's own
datacentre over lesson 24's VPN gets behind an ALB. `lambda` registers a function, and the ALB turns
each request into an invocation. Lesson 14 of `aws-compute` writes one. Put the ids into variables
and register the two machines:

```
ana@laptop:~/aws$ tg=$(aws elbv2 describe-target-groups --names shop-web-app --query "TargetGroups[0].TargetGroupArn" --output text)
```

```
ana@laptop:~/aws$ aws elbv2 register-targets --target-group-arn $tg --targets Id=$web1 Id=$web2
```

## What moto knows about health

```
ana@laptop:~/aws$ aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]" --output text
i-93a432057e9443a25	8080	healthy
i-8eb1bd5fa0d8d0a62	8080	healthy
```

**Both machines are `healthy`, and nothing asked them.** No program listens on 8080 on either of
them, because in moto there are no machines to run one, only records of machines. Against AWS a new
target starts `initial` while its first checks run, and these two would turn `unhealthy` with the
reason `Target.FailedHealthChecks`. moto goes further than optimism, though. Register an instance id
that does not exist anywhere:

```
ana@laptop:~/aws$ aws elbv2 register-targets --target-group-arn $tg --targets Id=i-0000000000000dead
ana@laptop:~/aws$ aws elbv2 describe-target-health --target-group-arn $tg --query "TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]" --output text
i-93a432057e9443a25	8080	healthy
i-8eb1bd5fa0d8d0a62	8080	healthy
i-0000000000000dead	8080	healthy
```

**AWS refuses that with `InvalidTarget`; moto registered it and calls it healthy.** What moto does
read is the instance's state: a stopped machine comes back `unused` with the reason
`Target.InvalidState`, which is also what AWS says of one. Take the dead id out again, so the group
says only what is true:

```
ana@laptop:~/aws$ aws elbv2 deregister-targets --target-group-arn $tg --targets Id=i-0000000000000dead
```

## Listeners, and a certificate

The shop answers on HTTPS, so the load balancer needs a **certificate** for `shop.example.com`. **AWS
Certificate Manager (ACM)** issues public ones at no charge, renews them by itself, and hands them
to a load balancer without the private key ever leaving AWS. That is what **TLS termination** means
here: the ALB decrypts and reads the request. It talks to the targets over the VPC, in plain HTTP on
8080 as configured above, or in TLS again if the group says `HTTPS`.

```
ana@laptop:~/aws$ aws acm request-certificate --domain-name shop.example.com --subject-alternative-names www.shop.example.com --validation-method DNS --query CertificateArn --output text
arn:aws:acm:sa-east-1:123456789012:certificate/07485baf-cc49-4664-9db9-21b13587240b
```

```
ana@laptop:~/aws$ cert=$(aws acm list-certificates --query "CertificateSummaryList[0].CertificateArn" --output text)
ana@laptop:~/aws$ aws acm describe-certificate --certificate-arn $cert --query "Certificate.[DomainName,Status,Type]" --output text
shop.example.com	PENDING_VALIDATION	AMAZON_ISSUED
```

**`PENDING_VALIDATION` is where a new certificate waits for proof.** ACM gives you a `CNAME` record
to create in the zone, as lesson 21 creates records, and issues the certificate once it can see the
record. A load balancer accepts only a certificate that has been issued. moto never issues it, and
lets a listener use it anyway. The listener also names a **security policy**, which decides the TLS
versions and ciphers it accepts:

```
ana@laptop:~/aws$ lb=$(aws elbv2 describe-load-balancers --names shop-web --query "LoadBalancers[0].LoadBalancerArn" --output text)
```

```
ana@laptop:~/aws$ aws elbv2 describe-ssl-policies --names ELBSecurityPolicy-2016-08 ELBSecurityPolicy-TLS13-1-2-2021-06 --query "SslPolicies[].[Name,join(' ', SslProtocols)]" --output text
ELBSecurityPolicy-2016-08	TLSv1.2 TLSv1.1 TLSv1
ELBSecurityPolicy-TLS13-1-2-2021-06	TLSv1.3 TLSv1.2
```

**Name the policy yourself.** Left out, the listener gets a default, and in moto that default is
`ELBSecurityPolicy-2016-08`, which still accepts TLS 1.0 and 1.1. The newer policy accepts only 1.2
and 1.3, which every browser the shop's customers use speaks. The listener on 443 sends everything
to the web target group unless a rule says otherwise, and its ARN goes into a variable for the
rules:

```
ana@laptop:~/aws$ aws elbv2 create-listener --load-balancer-arn $lb --protocol HTTPS --port 443 --certificates CertificateArn=$cert --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 --default-actions Type=forward,TargetGroupArn=$tg --query "Listeners[0].[Protocol,Port,SslPolicy]" --output text
HTTPS	443	ELBSecurityPolicy-TLS13-1-2-2021-06
ana@laptop:~/aws$ https=$(aws elbv2 describe-listeners --load-balancer-arn $lb --query "Listeners[?Port==\`443\`].ListenerArn" --output text)
```

Port 80 then gets a listener of its own whose only job is to send everybody to HTTPS:

```
ana@laptop:~/aws$ aws elbv2 create-listener --load-balancer-arn $lb --protocol HTTP --port 80 --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,StatusCode=HTTP_301}" --query "Listeners[0].DefaultActions[0].[Type,RedirectConfig.StatusCode]" --output text
redirect	HTTP_301
```

## Rules: the layer 7 in the name

**A rule is a condition and an action, with a priority**. The listener tries its rules from the
lowest number up, and the first match wins. The default action answers whatever matches none. The
conditions are what only an ALB can see, because only an ALB reads the request: the **host**, the **path**,
a **header**, the method, a query string, the caller's address. The shop's API runs on separate
machines at known addresses, `10.20.0.50` and `10.20.1.50`. So it gets a target group of type `ip`,
the two addresses, and a rule on the path:

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

And a rule that answers by itself, without any target: the staff site is not built yet, so its host
gets a refusal straight from the load balancer.

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

That last rule routes; it does not protect. **The host, the path and every header are whatever the
caller chose to send**, so a rule on them decides where a request goes and never who may make it.
Who may is decided by authentication behind the load balancer, by lesson 18's security groups, and
by AWS WAF, which lesson 23 names.

## Sticky sessions

By default each request may land on a different target. **Stickiness** tells the ALB to keep a
caller on the same target for a while, by a cookie it sets itself (`lb_cookie`) or one the
application sets (`app_cookie`):

```
ana@laptop:~/aws$ aws elbv2 modify-target-group-attributes --target-group-arn $tg --attributes Key=stickiness.enabled,Value=true Key=stickiness.type,Value=lb_cookie Key=stickiness.lb_cookie.duration_seconds,Value=3600 --query "Attributes[?starts_with(Key, 'stickiness')]" --output text
stickiness.enabled	true
stickiness.type	lb_cookie
stickiness.lb_cookie.duration_seconds	3600
```

**Stickiness is a patch for state kept on one machine**, such as a basket held in a process's
memory. It has a cost: a target that holds many sticky callers cannot be drained quickly, and the
load spreads unevenly. The shop's basket belongs in a database or a cache that every target can
read, and then stickiness has nothing left to fix.
