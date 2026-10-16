---
title: Controles, e quanto custa manter a landing zone
version: 1
---

**Um controle é uma regra que o Control Tower aplica a toda conta de uma OU, e há três tipos,
distinguidos por quando agem.** A imagem errada é que um controle bloqueia algo. Só um tipo bloqueia.
Os outros dois acham um problema, um depois do fato e outro antes de qualquer coisa ser construída, e
uma landing zone precisa dos três porque cada um deixa passar o que os outros pegam.

## Três tipos

| tipo | quando age | feito de | o que a loja vê |
|---|---|---|---|
| **preventivo** | antes de a requisição ser executada | SCPs, lição 4 | a requisição recusada |
| **detectivo** | depois de o recurso existir | regras do AWS Config | o recurso informado como fora de conformidade |
| **proativo** | antes de uma stack do CloudFormation criá-lo | hooks do CloudFormation | a stack recusada antes de construir |

**Um controle preventivo é a barreira da lição 4, escrita e anexada pelo Control Tower.** Ele recusa a
chamada, então o estado ruim nunca existe; o limite dele é que uma SCP só enxerga uma requisição, não
o estado da conta, então não consegue dizer "todo bucket tem de ser criptografado", só "esta chamada
não pode ser feita". A negação de regiões do Control Tower, que recusa toda região que a landing zone
não governa, é a `sa-east-1-only` da lição 4 como configuração.

**Um controle detectivo é uma regra do Config.** O Config registra cada recurso de uma conta e como
ele muda, e uma regra julga cada registro: um bucket legível pelo público, um usuário root sem MFA.
Ele **não desfaz nada**. Ele marca o recurso como "fora de conformidade" num painel na conta Audit, e
alguém age. É mais fraco que uma recusa e é o único tipo que enxerga um recurso criado antes de o
controle existir.

**Um controle proativo confere um template antes de ele rodar.** Quando uma stack é criada com o
CloudFormation, um hook lê os recursos que ela vai criar e recusa a stack se um deles quebra a regra.
Ele só vê o que passa pelo CloudFormation, e o curso `iac` é onde isso importa.

## Obrigatórios, fortemente recomendados, eletivos

Todo controle também traz a **orientação** da AWS, que diz quanta escolha existe:

- os controles **obrigatórios** estão ligados em toda landing zone e não podem ser desligados. Eles
  protegem a própria landing zone: a trilha, o bucket de logs, as roles e a configuração do Config
  que o Control Tower criou.
- os **fortemente recomendados** são o conselho da AWS para qualquer empresa: detectar um usuário root
  sem segundo fator é o tipo de regra deste grupo.
- os **eletivos** são para necessidades específicas, como uma carga de trabalho regulada, e são
  ligados OU por OU quando a empresa tem o motivo.

A loja começa com os obrigatórios, que chegam sozinhos, e liga os fortemente recomendados em
`Workloads` e `Sandbox` igualmente.

## Quanto custa manter a landing zone

**O Control Tower é de graça, e os serviços que ele liga não são.** Dois deles rodam em toda conta e
região que a landing zone governa, então são os que vale precificar. O Config primeiro:

```
ana@laptop:~/aws$ python3 price.py AWSConfig 20260911124534 sa-east-1 SAE1-ConfigurationItemRecorded SAE1-ConfigRuleEvaluations
AWSConfig 20260911124534, published 2026-09-11, USD
SAE1-ConfigurationItemRecorded
          0 to       Inf SAE1-ConfigurationItemRecorded 0.0030
SAE1-ConfigRuleEvaluations
          0 to   100,000 ConfigRuleEvaluations 0.0010
    100,000 to   500,000 ConfigRuleEvaluations 0.0008
    500,000 to       Inf ConfigRuleEvaluations 0.0005
```

Um **item de configuração** é um registro de um recurso num momento, gravado cada vez que um recurso
gravado muda, a 0,003 dólar cada; uma **avaliação de regra** é uma regra do Config julgando um
recurso, a 0,001 nas primeiras 100.000 do mês. As contagens dependem inteiramente de quanto muda.
Como ilustração, não como medição: uma conta cujas máquinas são trocadas com frequência suficiente
para gravar 20.000 itens de configuração num mês paga 60 dólares de gravação. Se dez controles
detectivos os avaliam 200.000 vezes, são 100,00 pelas primeiras 100.000 mais 80,00 pelas
seguintes, 180 dólares. **A conta mais movimentada paga mais**, e em geral é a produção.

Depois o CloudTrail:

```
ana@laptop:~/aws$ python3 price.py AWSCloudTrail 20260911124531 sa-east-1 SAE1-FreeEventsRecorded SAE1-PaidEventsRecorded SAE1-DataEventsRecorded
AWSCloudTrail 20260911124531, published 2026-09-11, USD
SAE1-FreeEventsRecorded
          0 to       Inf Events 0.0000
SAE1-PaidEventsRecorded
          0 to       Inf Events 0.0000
SAE1-DataEventsRecorded
          0 to       Inf Events 0.0000
ana@laptop:~/aws$ jq -r '.terms.OnDemand[][].priceDimensions[].description | select(test("paid event|data event recorded"))' ~/.cache/aws-prices/AWSCloudTrail-20260911124531-sa-east-1.json
0.000001 per data event recorded in South America(Sao Paulo) region
0.00002 per paid event recorded in South America(Sao Paulo) region
```

O `price.py` imprime quatro casas decimais e um evento custa menos que isso, então as duas últimas
linhas dele mostram `0.0000`; o arquivo da oferta que ele salvou traz os preços exatos, e o `jq` os
lê. **A primeira cópia dos eventos de gerenciamento de uma conta não custa nada**, e a trilha da
organização é essa cópia. Uma segunda trilha gravando os mesmos eventos, uma que uma equipe
acrescenta na própria conta, paga 0,00002 dólar por evento, 2 dólares a cada 100.000. Eventos de
dados, como cada leitura de um objeto num bucket, custam 0,000001 cada e ficam desligados até alguém
os ligar. O que os registros custam depois para guardar é armazenamento no S3 na `log-archive`, que
esta lição não precificou.

**Estes preços são das listas que a AWS publicou em 11 de setembro de 2026**, lidas pelo programa da
lição 1. Nada aqui foi cobrado, já que o moto não tem fatura: as contagens são ilustrações e a conta
é a do parágrafo.
