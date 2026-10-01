---
title: "Security groups: um filtro com estado em cada máquina"
version: 1
---

Uma rota decide para onde um pacote pode ir. Um filtro decide se ele passa quando chega lá, e o filtro
que você mais vai usar é o **security group**: um firewall preso à interface de rede de uma instância.
O provedor o aplica fora da máquina, então nada que rode na instância consegue desligá-lo.

Três propriedades o definem, e cada uma é um erro que alguém comete uma vez.

**Ele só permite.** Um security group é uma lista de regras de permissão; não existe regra de negação
para escrever. O que nenhuma regra permite é descartado. Um grupo novo na AWS não tem regra de entrada,
então nada entra, e tem uma regra de saída que permite tudo.

**Ele tem estado.** O provedor acompanha as conexões. Quando uma regra deixa entrar um pedido na porta
443, a resposta sai sem nenhuma regra de saída dizendo isso, e quando a instância abre uma conexão para
fora, a resposta volta sem regra de entrada. Você escreve regras para quem pode **começar** uma
conversa, e o resto vem junto.

**Uma origem pode ser outro security group.** Em vez de uma faixa de endereços, uma regra pode nomear
um grupo, e então admite tráfego de qualquer interface que carregue aquele grupo. É a propriedade que
faz os layouts desta aula funcionarem, porque na nuvem endereços não ficam parados: o grupo de
autoscaling da aula 4 substitui uma instância e a nova tem outro endereço privado. Um banco que aceita
a porta 5432 só do grupo da aplicação continua admitindo todo servidor de aplicação, o de hoje e o de
amanhã, e mais nada na VPC.

## As regras de um grupo, escritas

Na AWS, regras de entrada são acrescentadas com `aws ec2 authorize-security-group-ingress`, que as
recebe como JSON em `--ip-permissions`. A CLI imprime a forma de uma permissão sem falar com a AWS:

```
ana@laptop:~/cloud$ aws ec2 authorize-security-group-ingress --generate-cli-skeleton | jq '.IpPermissions[0] | keys'
[
  "FromPort",
  "IpProtocol",
  "IpRanges",
  "Ipv6Ranges",
  "PrefixListIds",
  "ToPort",
  "UserIdGroupPairs"
]
```

Aqui estão duas regras para o grupo dos servidores de aplicação, nessa forma. Foram escritas para esta
aula e não aplicadas em lugar nenhum; os ids de grupo são marcadores no formato que a própria
documentação da AWS usa.

```schooling-example
{"language": "json", "file": "app-ingress.json", "parts": [{"code": "[\n  {\n    \"IpProtocol\": \"tcp\",\n    \"FromPort\": 8080,\n    \"ToPort\": 8080,", "note": "O arquivo é uma lista de permissões, e esta é a primeira. Um protocolo e uma faixa de portas, de `FromPort` a `ToPort`: uma porta só é uma faixa de uma. A aplicação escuta na 8080 no layout desta aula, e só o balanceador de carga fala com ela ali."}, {"code": "    \"UserIdGroupPairs\": [\n      {\n        \"GroupId\": \"sg-0123456789abcdef0\",\n        \"Description\": \"from the load balancer's group\"\n      }\n    ]\n  },", "note": "**A origem é um grupo, não um endereço.** Qualquer interface de rede que carregue o grupo do balanceador pode abrir uma conexão na 8080. Quando os nós do balanceador mudam de endereço, o que é assunto do provedor, esta regra não muda. `Description` é para a próxima pessoa que ler o grupo."}, {"code": "  {\n    \"IpProtocol\": \"tcp\",\n    \"FromPort\": 22,\n    \"ToPort\": 22,", "note": "A segunda permissão, SSH na 22. Tem a mesma forma da primeira; só a origem é de outro tipo."}, {"code": "    \"IpRanges\": [\n      {\n        \"CidrIp\": \"203.0.113.0/24\",\n        \"Description\": \"SSH from the office\"\n      }\n    ]\n  }\n]", "note": "Uma faixa de endereços como origem, escrita em CIDR. `203.0.113.0/24` é um bloco reservado para documentação, no lugar dos endereços públicos do escritório. A mesma regra com `0.0.0.0/0` ofereceria SSH a todo endereço da internet."}]}
```

Gravado num arquivo, seria entregue como
`aws ec2 authorize-security-group-ingress --group-id <the app's group> --ip-permissions file://app-ingress.json`.
Não foi rodado aqui: não há conta neste curso, e a resposta da AWS não aparece aqui.

## O que as regras não dizem, e o que isso significa

Não há regra de saída naquele arquivo, e nenhuma é necessária para as respostas. Também não há regra
para o banco: o grupo do próprio banco carrega uma permissão, TCP 5432 com o grupo da aplicação como
origem, e isso é a resposta inteira para "quem pode alcançar o banco".

**Uma interface pode carregar mais de um grupo**, até um limite, e as regras se somam: um pacote entra
se qualquer regra de qualquer grupo preso a ela permitir. Isso torna os grupos combináveis, um para
"alcançável pelo balanceador de carga", outro para "alcançável pelo monitoramento", e significa que
tirar uma regra de um grupo não fecha uma porta que outro grupo abre.

Como um pacote descartado simplesmente não é entregue, um security group nunca responde. Uma conexão
que ele bloqueia não recebe "connection refused"; não recebe nada, e o cliente espera até desistir. A
última seção desta aula transforma esse silêncio num diagnóstico.
