---
title: O histórico de eventos, e uma trilha própria
version: 1
---

Toda requisição a uma API da AWS, vinda do console, da linha de comando, de um SDK ou de outro serviço
da AWS, é um **evento**, e o CloudTrail o registra: quem pediu, de onde, o quê, e qual foi a resposta. É o
registro que a linha do tempo da lição 13 teria querido, e o que responde à pergunta que todo incidente
faz mais cedo ou mais tarde: **quem fez isto?**

O CloudTrail guarda duas coisas fáceis de confundir:

| | histórico de eventos | uma trilha |
|---|---|---|
| o que guarda | eventos de gerenciamento, os últimos 90 dias | o que os seletores dela escolherem, pelo tempo que o bucket guardar |
| onde | dentro do CloudTrail, pesquisável por um atributo de cada vez | arquivos num bucket S3, e opcionalmente num grupo do CloudWatch Logs |
| configuração | nenhuma; sempre ligado | criada pela equipe |
| custo | nada | a primeira cópia dos eventos de gerenciamento grátis; eventos de dados e outras cópias cobrados |

**O histórico de eventos não é um log de auditoria**: noventa dias é menos que a maioria das perguntas que
as pessoas fazem, e ninguém o controla. Uma trilha é o log de auditoria. Ela escreve um arquivo a cada
poucos minutos num bucket, e o ciclo de vida e o object lock do bucket decidem quanto tempo a evidência
vive.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Uma requisição de API, do console, da linha de comando ou de um SDK, vira um evento do CloudTrail. O evento vai para quatro lugares: o histórico de eventos, guardado 90 dias e pesquisado por um atributo; uma trilha para o S3, como arquivos com digests por hora; uma trilha para o CloudWatch Logs, onde um filtro de métrica alimenta um alarme; e o EventBridge, onde uma regra casa o evento pelo nome. Os dois primeiros são lidos depois do fato; os dois últimos agem enquanto acontece.\"><defs><marker id=\"trl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"120\" width=\"130\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma requisição</text><text x=\"85.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">console, CLI, SDK</text><path d=\"M152 144 L198 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"200\" y=\"112\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"135.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CloudTrail</text><text x=\"260.0\" y=\"152.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um evento</text><rect x=\"400\" y=\"20\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"500.0\" y=\"36.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">histórico de eventos</text><text x=\"500.0\" y=\"51.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90 dias, um atributo</text><path d=\"M322 144 L398 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"400\" y=\"88\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"104.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">trilha para o S3</text><text x=\"500.0\" y=\"119.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquivos e digests por hora</text><path d=\"M322 144 L398 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"400\" y=\"156\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">trilha para o CloudWatch Logs</text><text x=\"500.0\" y=\"187.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">filtro de métrica, depois alarme</text><path d=\"M322 144 L398 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"400\" y=\"224\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"240.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EventBridge</text><text x=\"500.0\" y=\"255.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma regra por nome de evento</text><path d=\"M322 144 L398 248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><text x=\"660\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois</text><text x=\"660\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do fato</text><text x=\"660\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">enquanto</text><text x=\"660\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">acontece</text></svg>", "caption": "Um evento, quatro destinos. O log de auditoria é a trilha; os alarmes são os dois últimos.", "same": ["CloudTrail", "EventBridge", "console, CLI, SDK"]}
```

## Criando a da loja

Trabalhe em `~/aws/trail` (`mkdir -p ~/aws/trail && cd ~/aws/trail`). Um bucket, e uma trilha que cobre
todas as regiões e valida seus arquivos:

```
ana@laptop:~/aws/trail$ aws s3 mb s3://shop-trail-123456789012
make_bucket: shop-trail-123456789012
ana@laptop:~/aws/trail$ aws cloudtrail create-trail --name shop --s3-bucket-name shop-trail-123456789012 --is-multi-region-trail --enable-log-file-validation --query '[TrailARN,IsMultiRegionTrail,LogFileValidationEnabled]' --output text
arn:aws:cloudtrail:sa-east-1:123456789012:trail/shop	True	True
ana@laptop:~/aws/trail$ aws cloudtrail start-logging --name shop
ana@laptop:~/aws/trail$ aws cloudtrail get-trail-status --name shop --query '[IsLogging,LatestDeliveryTime]' --output text
True	2026-10-16T19:49:02-03:00
ana@laptop:~/aws/trail$ aws s3 ls s3://shop-trail-123456789012 --recursive | wc -l
0
```

**Multirregião** importa porque uma credencial em mãos erradas é usada numa região que ninguém vigia; uma
trilha só de São Paulo não registra nada das instâncias iniciadas em outra região. A **validação de
arquivos de log** faz o CloudTrail escrever, a cada hora, um arquivo de digest assinado com o hash de cada
arquivo de log que entregou, para que `validate-logs` possa provar depois que nenhum arquivo foi mudado ou
removido: evidência que não pode ser conferida é opinião.

As duas últimas linhas são o moto sendo confiante: o status informa uma entrega um segundo atrás, e o
bucket não tem nada. Na AWS a trilha também precisa de uma **política de bucket** que deixe
`cloudtrail.amazonaws.com` escrever nele, que o console acrescenta e a linha de comando não; sem ela,
`create-trail` é recusado. O moto não confere política de bucket nenhuma.

## Eventos de gerenciamento e de dados

**Eventos de gerenciamento** são mudanças e leituras de recursos: criar um bucket, mudar um security group,
agendar a exclusão de uma chave. **Eventos de dados** são operações dentro de um recurso: ler um objeto no
S3, invocar uma função Lambda. Há muito mais deles, não são registrados a menos que uma trilha os
selecione, e são cobrados. A escolha comum é selecioná-los só onde a pergunta *quem leu isto?* importa,
aqui o bucket dos arquivos de pedidos:

```
ana@laptop:~/aws/trail$ aws cloudtrail put-event-selectors --trail-name shop --advanced-event-selectors '[{"Name":"management","FieldSelectors":[{"Field":"eventCategory","Equals":["Management"]}]},{"Name":"orders objects","FieldSelectors":[{"Field":"eventCategory","Equals":["Data"]},{"Field":"resources.type","Equals":["AWS::S3::Object"]},{"Field":"resources.ARN","StartsWith":["arn:aws:s3:::shop-orders/"]}]}]' --query 'AdvancedEventSelectors[].Name' --output text
management	orders objects
```

O primeiro seletor mantém os eventos de gerenciamento; o segundo acrescenta eventos de objeto de um bucket,
e só desse bucket.
