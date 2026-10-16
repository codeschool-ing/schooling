---
title: Zonas, health checks e a substituição
version: 1
---

O grupo da seção anterior recebeu três subnets em três zonas. **Na AWS isso é uma instrução para
espalhar**: o grupo lança suas instâncias igualmente pelas zonas que pode usar, e trabalha para
mantê-las iguais. É aqui que o moto pôs as três instâncias que mantém agora:

```
ana@laptop:~/aws$ aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=web Name=instance-state-name,Values=running --query "Reservations[].Instances[].[InstanceId,Placement.AvailabilityZone,SubnetId]" --output table
-------------------------------------------------------------------
|                        DescribeInstances                        |
+----------------------+-------------+----------------------------+
|  i-2992055efed5159c1 |  sa-east-1a |  subnet-a320d80c3247aca2b  |
|  i-8e6c6519b05e2cbc1 |  sa-east-1a |  subnet-a320d80c3247aca2b  |
|  i-d44b8eadb87097a01 |  sa-east-1a |  subnet-a320d80c3247aca2b  |
+----------------------+-------------+----------------------------+
```

As três estão em `sa-east-1a`, na primeira subnet da lista. **Essa colocação é do moto, não da
AWS.** O moto 5.2.3 lança toda instância de um grupo na primeira subnet, quantas forem dadas. Na AWS
o mesmo grupo teria uma instância em cada uma de `sa-east-1a`, `sa-east-1b` e `sa-east-1c`, e com
seis teria duas em cada. Nada mais nesta lição depende da zona, então o resto do laboratório
continua fiel; a aritmética abaixo é a da AWS.

## O que o equilíbrio compra, e quando ele move instâncias

O motivo de espalhar é que uma zona pode falhar sozinha. A lição 1 de `aws-foundations` diz o que é
uma zona. Para um grupo, significa que, quando uma zona tem problemas, as instâncias dela param de
passar nos health checks e o grupo as substitui, nas zonas que ainda funcionam. Um grupo de seis em três zonas que perde uma zona é um grupo de quatro por alguns
minutos, e de seis outra vez quando as substitutas estiverem atendendo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três painéis de um grupo de seis em três zonas. Antes: duas instâncias em cada uma de sa-east-1a, 1b e 1c. Zona b com falha: suas instâncias são substituídas nas outras duas zonas, três em 1a e três em 1c. Zona b de volta: o AZRebalance lança em 1b e depois termina nas outras, de novo duas em cada.\"><defs><marker id=\"az-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">antes</text><rect x=\"16\" y=\"40\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"28\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"92\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"16\" y=\"132\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"28\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"92\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"16\" y=\"224\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"28\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"92\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><path d=\"M228 178 L248 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#az-ah)\"></path><text x=\"356\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">zona b com falha</text><rect x=\"252\" y=\"40\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"264\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"292\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"328\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"356\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"392\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"252\" y=\"132\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"262\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sa-east-1b</text><text x=\"356\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">com falha</text><rect x=\"252\" y=\"224\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"264\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"292\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"328\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"356\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"392\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><path d=\"M464 178 L484 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#az-ah)\"></path><text x=\"592\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">zona b de volta, rebalanceado</text><rect x=\"488\" y=\"40\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"500\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"564\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"488\" y=\"132\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"500\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"564\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"488\" y=\"224\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"500\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><rect x=\"564\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodando</text><text x=\"360\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as substitutas vão para onde o grupo consegue lançar; o rebalanceamento lança antes de terminar</text></svg>", "caption": "Um grupo de seis em três zonas, na AWS. O grupo mantém a contagem, não os lugares: perder uma zona leva a parte dela para as zonas que funcionam, e o AZRebalance a traz de volta depois sem deixar a contagem cair. O moto, como mostra a transcrição acima, poria as seis em sa-east-1a."}
```

Quando a zona se recupera, o grupo está desequilibrado: três, nenhuma, três. Um processo chamado
**`AZRebalance`** corrige isso, e corrige na ordem que mantém a capacidade. **Ele lança na zona vazia
primeiro e termina nas cheias depois.** Para abrir espaço, a AWS deixa o grupo passar do máximo
durante um rebalanceamento, em 10% dele ou em uma instância, o que for maior. O mesmo processo move
instâncias quando você acrescenta uma subnet ao grupo, ou quando uma zona não tinha capacidade para o
tipo de instância no lançamento.

## Dois jeitos de perguntar se uma instância está saudável

O grupo pergunta sobre cada instância, periodicamente, e tem duas fontes de respostas.

- **`EC2`** é o padrão: os status checks da instância. Eles perguntam se o hardware por baixo dela e
  o sistema operacional nela estão funcionando, e pegam um host com falha ou um kernel que parou. Não
  pegam um servidor web que caiu numa máquina que, fora isso, está bem.
- **`ELB`** acrescenta o health check do load balancer. O target group pede um caminho como
  `/health` a cada instância, e uma instância que para de responder é marcada como doente. Esse é o
  check que vê o que um usuário vê, e um grupo atrás de um load balancer deve usá-lo; a lição 22 de
  `aws-foundations` constrói o load balancer e o target group.

As duas fontes contam: com `ELB` configurado, uma instância que falha em qualquer uma está doente. O
grupo da Ana tem o padrão:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[HealthCheckType,HealthCheckGracePeriod]" --output text
EC2	300
```

O segundo número é o **período de carência do health check**: quantos segundos depois de entrar em
serviço o grupo ignora os health checks de uma instância. Uma instância nova passa os primeiros
minutos subindo e rodando o user data, e falha em todo check enquanto isso. **Uma carência mais curta
que o boot é um grupo que mata cada instância nova antes de ela ficar pronta, e lança outra, para
sempre.** O moto mostra 300 segundos porque o padrão dele é 300. O padrão da API da AWS é 0 quando a
chamada não informa, e o console preenche 300, então um grupo criado por um script sem esse valor
começa sem carência nenhuma. A lição 5 apresenta uma segunda configuração com um propósito parecido,
o default instance warmup, e diz em que as duas diferem.

## Uma instância doente é substituída, não consertada

**Quando uma instância é considerada doente, o grupo a termina e lança outra a partir do template.**
Ninguém entra nela para consertar, porque não há nada nela que valha o conserto: o que ela guardava
de importante devia morar em outro lugar. O `set-instance-health` permite que uma pessoa, ou um
script de monitoramento, declare uma instância doente, e é isto que o moto faz com isso:

```
ana@laptop:~/aws$ aws autoscaling set-instance-health --instance-id i-8e6c6519b05e2cbc1 --health-status Unhealthy
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,HealthStatus]" --output text
i-8e6c6519b05e2cbc1	Unhealthy
i-2992055efed5159c1	Healthy
i-d44b8eadb87097a01	Healthy
```

O moto anota a palavra e não faz mais nada. **Na AWS essa instância teria sumido em mais ou menos um
minuto, e uma nova estaria sendo lançada no lugar.** A substituição em si é algo que o moto faz, pela
chamada que termina uma instância e mantém a contagem:

```
ana@laptop:~/aws$ aws autoscaling terminate-instance-in-auto-scaling-group --instance-id i-8e6c6519b05e2cbc1 --no-should-decrement-desired-capacity --query 'Activity.[StatusCode,Cause]' --output text
InProgress	At 2026-10-16 16:26:01.573069, instance i-8e6c6519b05e2cbc1 was taken out of service in response to a user request.
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,HealthStatus]" --output text
i-2992055efed5159c1	Healthy
i-d44b8eadb87097a01	Healthy
i-e87c31b75179ed4be	Healthy
```

O `--no-should-decrement-desired-capacity` é a parte que importa: ele termina a instância e deixa a
capacidade desejada em três, então o grupo lança uma substituta na hora, e um id novo toma o lugar
do antigo no fim da lista. Com `--should-decrement-desired-capacity` a contagem cairia para dois, e
nada a substituiria.

## Quando a substituição é o problema

Um grupo que não para de substituir instâncias às vezes está fazendo exatamente o que mandaram, sobre
a coisa errada. Uma aplicação que cai ao subir, um caminho de health check que não existe, uma
carência mais curta que o boot: cada um produz um ciclo de lançamentos e términos, e cada lançamento
é cobrado por pelo menos um minuto. Para a hora em que alguém precisa olhar uma instância nesse
estado, o `suspend-processes` para partes nomeadas do ciclo (`HealthCheck`, `ReplaceUnhealthy`,
`Launch`, `Terminate`, `AZRebalance`), e o `resume-processes` as liga de novo. **Suspender a
substituição serve para investigar, nunca para operar**, porque um grupo suspenso deixa de cumprir a
promessa dele.
