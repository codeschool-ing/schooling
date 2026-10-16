---
title: Registros, escritos como um lote de mudanças
version: 1
---

**O Route 53 não tem comando que acrescente um registro.** Toda mudança numa zona é um **lote de
mudanças** (*change batch*): uma lista de ações, `CREATE`, `UPSERT` ou `DELETE`, cada uma sobre um
conjunto de registros, enviada numa única requisição que é aplicada inteira ou não é aplicada. A
imagem errada é uma tabela que se edita linha a linha. Um lote está mais perto de uma transação, e é
isso que torna seguro mudar um nome de um endereço para outro sem um instante em que ele não aponta
para nenhum dos dois.

## Os primeiros registros da loja

Um **conjunto de registros** (*record set*) é um nome, um tipo e os valores que respondem por eles:
`mail.shop.example.com`, tipo `A`, valor `203.0.113.25`. O lote abaixo escreve os cinco tipos de que
a maioria das zonas é feita. Salve-o como `~/aws/records.json`:

```json
{
  "Comment": "the shop's first records",
  "Changes": [
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "mail.shop.example.com", "Type": "A", "TTL": 3600,
      "ResourceRecords": [{"Value": "203.0.113.25"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "mail.shop.example.com", "Type": "AAAA", "TTL": 3600,
      "ResourceRecords": [{"Value": "2001:db8::25"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "shop.example.com", "Type": "MX", "TTL": 3600,
      "ResourceRecords": [{"Value": "10 mail.shop.example.com"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "shop.example.com", "Type": "TXT", "TTL": 3600,
      "ResourceRecords": [{"Value": "\"v=spf1 mx -all\""}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "www.shop.example.com", "Type": "CNAME", "TTL": 300,
      "ResourceRecords": [{"Value": "shop.example.com"}]}}
  ]
}
```

| tipo | responde com | aqui |
|---|---|---|
| `A` | um endereço IPv4 | o servidor de e-mail, num endereço da faixa de documentação |
| `AAAA` | um endereço IPv6 | o mesmo servidor, num endereço de `2001:db8::/32`, a faixa de documentação do IPv6 |
| `MX` | um servidor de e-mail do domínio, com uma preferência | números menores são tentados primeiro |
| `TXT` | texto livre | uma política SPF: só o MX do próprio domínio pode enviar o e-mail dele |
| `CNAME` | outro nome, a ser consultado no lugar | `www` é o que for o domínio sem prefixo |

Um valor `TXT` carrega as próprias aspas duplas dentro da string JSON, e é por isso que elas estão
escapadas: é assim que o Route 53 quer registros de texto escritos. Envie o lote:

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://records.json
{
    "ChangeInfo": {
        "Id": "/change/C2682N5HXP0BZ4",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:25.839195+00:00"
    }
}
```

## Se uma mudança já chegou

**`ChangeInfo` é um recibo, e o `Id` dele é como você pergunta pela mudança depois.** Na AWS, uma
mudança nova responde `PENDING` e vira `INSYNC` quando todo servidor de nomes do Route 53 a tem, o
que a AWS documenta como acontecendo em geral em até 60 segundos. Um script de implantação espera
por isso com `aws route53 wait resource-record-sets-changed --id …` antes de avisar alguém que o nome
mudou. O seu id de mudança será diferente do de baixo.

```
ana@laptop:~/aws$ aws route53 get-change --id /change/C2682N5HXP0BZ4
{
    "ChangeInfo": {
        "Id": "C2682N5HXP0BZ4",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:26.505955+00:00"
    }
}
ana@laptop:~/aws$ aws route53 get-change --id /change/NOSUCHCHANGE
{
    "ChangeInfo": {
        "Id": "NOSUCHCHANGE",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:27.013432+00:00"
    }
}
```

O moto respondeu `INSYNC` na hora, e o segundo comando mostra o pouco que isso significa: **o moto
responde `INSYNC` para um id de mudança que nunca existiu**. Use o `get-change` no moto para aprender
o formato da resposta, nunca como prova de que algo foi aplicado. A prova é a própria zona:

```
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[].[Name,Type,TTL,join(' ', ResourceRecords[].Value)]" --output text
shop.example.com.	MX	3600	10 mail.shop.example.com
shop.example.com.	NS	172800	ns-2048.awsdns-64.com ns-2049.awsdns-65.net ns-2050.awsdns-66.org ns-2051.awsdns-67.co.uk
shop.example.com.	SOA	900	{'Value': 'ns-2048.awsdns-64.com. hostmaster.example.com. 1 7200 900 1209600 86400'}
shop.example.com.	TXT	3600	"v=spf1 mx -all"
mail.shop.example.com.	A	3600	203.0.113.25
mail.shop.example.com.	AAAA	3600	2001:db8::25
www.shop.example.com.	CNAME	300	shop.example.com
```

Enviar o mesmo arquivo de novo mostra que o lote é **uma unidade só**. A primeira ação já falha,
então nenhuma das cinco é aplicada duas vezes, e o erro nomeia o registro que o parou:

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://records.json

aws: [ERROR]: An error occurred (InvalidChangeBatch) when calling the ChangeResourceRecordSets operation: Tried to create resource record set [name='mail.shop.example.com.', type='A'] but it already exists
```

`UPSERT` é a ação que não se importa se o registro existe: ela o cria ou o substitui. É o que um
script usa quando roda todo dia; `CREATE` é o que você usa quando um registro já existente seria uma
surpresa que vale parar para olhar.

## O ápice, e por que um CNAME não pode ficar lá

O nome da própria loja, `shop.example.com` sem nada na frente, é o **ápice da zona** (*zone apex*), e
ele deveria levar ao balanceador de carga. Um balanceador não tem endereço fixo, só um nome que a AWS
dá a ele, então o registro óbvio é um `CNAME`. **O padrão do DNS proíbe isso**: um nome que tem um
`CNAME` não pode ter nenhum outro registro, e o ápice sempre tem pelo menos dois, o NS e o SOA, além
do MX e do TXT que o lote acabou de escrever. Aqui está o moto aceitando mesmo assim:

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch '{"Changes":[{"Action":"CREATE","ResourceRecordSet":{"Name":"shop.example.com","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"shop-web-1.sa-east-1.elb.amazonaws.com"}]}}]}'
{
    "ChangeInfo": {
        "Id": "/change/C2682N5HXP0BZ4",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:29.095461+00:00"
    }
}
```

**A AWS recusa esse lote com `InvalidChangeBatch`; o moto 5.2.3 guardou o registro.** É o caso mais
claro desta lição do moto verificando menos que a AWS, e a resposta é a mesma de sempre: apagar o
que o moto nunca deveria ter aceitado.

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"shop.example.com","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"shop-web-1.sa-east-1.elb.amazonaws.com"}]}}]}' --query ChangeInfo.Status --output text
INSYNC
```

**Um registro de alias é a resposta do Route 53.** É um registro `A` ou `AAAA` cujo valor não é um
endereço, e sim um ponteiro para um recurso da AWS: um balanceador de carga, uma distribuição do
CloudFront, um site do S3, outro registro da mesma zona. O Route 53 consulta o alvo ele mesmo e
responde com **os endereços atuais dele**, então, para o resolvedor que pergunta, é um registro `A`
comum, e um registro `A` comum é permitido no ápice. O ponteiro precisa do nome do alvo e da zona
hospedada em que a AWS o guarda, e o balanceador informa os dois:

```
ana@laptop:~/aws$ aws elbv2 describe-load-balancers --names shop-web --query "LoadBalancers[0].[DNSName,CanonicalHostedZoneId]" --output text
shop-web-1.sa-east-1.elb.amazonaws.com	Z2P70J7EXAMPLE
```

`Z2P70J7EXAMPLE` é o marcador do moto; a AWS publica um id real por região e por tipo de
balanceador, e o `describe-load-balancers` imprime o certo. Salve o alias como `~/aws/apex.json`:

```json
{
  "Changes": [
    {"Action": "UPSERT", "ResourceRecordSet": {
      "Name": "shop.example.com", "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z2P70J7EXAMPLE",
        "DNSName": "shop-web-1.sa-east-1.elb.amazonaws.com",
        "EvaluateTargetHealth": true}}}
  ]
}
```

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://apex.json --query ChangeInfo.Status --output text
INSYNC
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[?Name=='shop.example.com.'].[Type,TTL,AliasTarget.DNSName]" --output text
A	None	shop-web-1.sa-east-1.elb.amazonaws.com
MX	3600	None
NS	172800	None
SOA	900	None
TXT	3600	None
```

**Um alias não tem TTL próprio**, e é por isso que a listagem imprimiu `None` na coluna de TTL dele:
a resposta leva o do alvo. `EvaluateTargetHealth` faz o Route 53 contar o alias como não saudável
quando o balanceador não tem alvos saudáveis, o que importa quando existe outro registro para onde
cair, como a próxima seção constrói. E uma consulta que o Route 53 responde a partir de um alias para
um recurso da AWS é **gratuita**, enquanto a mesma resposta a partir de um `CNAME` é cobrada; a
última seção lê essa linha da lista de preços.

## TTL, e o que a "propagação" é de verdade

**Um TTL é uma promessa a todo resolvedor que guarda a resposta em cache**: guarde isto por 3.600
segundos e não pergunte de novo. É o único número de um registro que decide com que rapidez uma
mudança é vista.

A imagem errada comum é que uma mudança de DNS "se propaga" pela internet ao longo de um ou dois
dias, devagar, como uma notícia se espalha. **Nada é empurrado para lugar nenhum.** Em cerca de um
minuto todo servidor de nomes do Route 53 tem a resposta nova. O que leva tempo são **os caches que
já guardam a antiga**: um resolvedor que perguntou cinco minutos antes da mudança fica com a cópia
até acabar o TTL que recebeu, e um TTL de 86.400 quer dizer um dia. Então a demora é escolhida de
antemão, por quem escreveu o TTL.

O hábito de trabalho sai daí. Um dia antes de mudar um nome, baixe o TTL dele para 60 segundos;
espere um TTL antigo para que todo cache tenha o curto; faça a mudança; suba o TTL de novo quando o
endereço novo tiver se provado. Um TTL baixo custa consultas, porque os resolvedores perguntam mais
vezes, e consultas são o que o Route 53 cobra.

A delegação é a exceção, e é lenta pelo mesmo motivo. Os registros NS do registro de `.com` levam um
TTL de dois dias, definido pelo registro e não por você, então trocar os servidores de nomes no
registrador é a única mudança de DNS que leva mesmo esse tempo todo.
