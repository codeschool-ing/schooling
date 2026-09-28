---
title: Quantas regiões, contadas a partir de dados publicados
version: 1
---

"Quantas regiões a AWS tem?" tem uma resposta numa página de marketing, e ela muda toda vez que uma
região abre. Esta seção conta de outro jeito, a partir de um arquivo que a AWS publica com outro
propósito, porque contar ensina a ler esse arquivo, e é um arquivo que você vai encontrar de novo.

**O `ip-ranges.json` lista todo bloco de endereços IP que a AWS usa em público**, com a região e o
serviço a que cada bloco pertence. Ele existe para firewalls. O firewall do escritório talvez só possa
deixar sair tráfego para o S3 em São Paulo, ou o seu servidor talvez só aceite conexões da rede de
distribuição de conteúdo da AWS. As duas regras tiram os endereços deste arquivo, e as pessoas o
baixam periodicamente para manter essas regras em dia. Ele não precisa de conta:

```
ana@laptop:~/cloud$ curl -s https://ip-ranges.amazonaws.com/ip-ranges.json -o ip-ranges.json
ana@laptop:~/cloud$ jq '.prefixes[0]' ip-ranges.json
{
  "ip_prefix": "3.4.12.4/32",
  "region": "eu-west-1",
  "service": "AMAZON",
  "network_border_group": "eu-west-1"
}
ana@laptop:~/cloud$ jq -r '.createDate, (.prefixes | length), (.ipv6_prefixes | length)' ip-ranges.json
2026-09-28-15-57-04
10532
6901
ana@laptop:~/cloud$ jq '[.prefixes[].region] | unique | length' ip-ranges.json
43
ana@laptop:~/cloud$ jq -r '[.prefixes[].region] | unique | .[] | select(startswith("sa-"))' ip-ranges.json
sa-east-1
sa-west-1
```

Cada entrada é um bloco de endereços com três rótulos. Esta cópia foi criada em 28 de setembro de
2026, segundo o seu próprio `createDate`, e tem 10532 blocos IPv4 e 6901 blocos IPv6. **Os blocos
IPv4 trazem 43 valores diferentes em `region`.** Dois começam com `sa-`, que é a América do Sul:
`sa-east-1` é São Paulo, e `sa-west-1` é a primeira surpresa.

43 não é o número de regiões, e o motivo está nos próprios valores. Três tipos não entram na conta:

```
ana@laptop:~/cloud$ jq -r '.prefixes[] | select(.region == "GLOBAL") | .service' ip-ranges.json | sort | uniq -c
    220 AMAZON
      1 AMAZON_CONNECT
      1 CHIME_MEETINGS
    118 CLOUDFRONT
     44 CLOUDFRONT_ORIGIN_FACING
     24 EC2
     45 GLOBALACCELERATOR
      1 IVS_LOW_LATENCY
      9 IVS_REALTIME
      8 ROUTE53
      1 ROUTE53_HEALTHCHECKS
     20 S3
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v37 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ jq -r '.partitions[] | select(.id != "aws") | .id as $p | .regions | to_entries[] | select(.key | test("global") | not) | "\($p)  \(.key)  \(.value.description)"' partitions.json | grep -v iso
aws-cn  cn-north-1  China (Beijing)
aws-cn  cn-northwest-1  China (Ningxia)
aws-eusc  eusc-de-east-1  AWS European Sovereign Cloud (Germany)
aws-us-gov  us-gov-east-1  AWS GovCloud (US-East)
aws-us-gov  us-gov-west-1  AWS GovCloud (US-West)
ana@laptop:~/cloud$ jq -rn --slurpfile a ip-ranges.json --slurpfile p partitions.json '([$a[0].prefixes[].region] | unique) - [$p[0].partitions[].regions | keys[]] | .[]'
GLOBAL
me-west-1
sa-west-1
us-south-1
```

**`GLOBAL` não é uma região.** Ele marca endereços que não pertencem a nenhuma região em particular, e
os serviços sob ele dizem por quê: `CLOUDFRONT` é a rede de distribuição de conteúdo da AWS,
`GLOBALACCELERATOR` é o seu ponto de entrada global e `ROUTE53` é o seu DNS. Eles respondem de muitos
lugares ao mesmo tempo, que é o assunto da seção sobre a borda.

**Cinco valores são regiões em partições separadas.** O `partitions.json` vem dentro do AWS CLI; é a
lista de regiões que este CLI conhece, agrupadas em partições, que são cópias separadas da AWS, com
contas próprias. A partição comum é a `aws`. China, AWS GovCloud e a European Sovereign Cloud são
partições à parte, e uma conta comum não consegue criar nada nelas. O `grep -v iso` remove mais
partições, que não têm nenhum endereço no `ip-ranges.json`.

**Três valores estão no arquivo de endereços e não na lista deste CLI**: `me-west-1`, `sa-west-1` e
`us-south-1`. Nenhum dos dois arquivos diz o que eles são. Eles têm espaço de endereços, então há algo
da AWS lá; são desconhecidos para o CLI 2.37.4, então ele não consegue endereçá-los. O último comando
mostra como a `sa-west-1` é magra: 27 + 2 + 7 + 1 + 2 = 39 blocos. Lê-la como uma região em
construção é um palpite, e esta aula a deixa como palpite.

A conta, então: 43 valores, menos o `GLOBAL`, são 42 nomes; menos os 5 de outras partições, 37; menos
os 3 que o CLI não conhece, **34 regiões comuns em que os dois arquivos concordam**. É uma
aproximação razoável de "regiões que uma conta comum pode usar hoje". Não é uma lista oficial: a AWS
pode abrir uma região antes de ela ter endereços públicos neste arquivo, e uma região pode ter
endereços aqui antes de aceitar clientes, como os três acima sugerem. Quando o número importa, a fonte
é a tabela de regiões do próprio provedor, e a chamada que lista as regiões habilitadas numa conta é
assunto do `aws-foundations`.
