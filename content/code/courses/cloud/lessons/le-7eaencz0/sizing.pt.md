---
title: "Dimensionamento: lendo a tabela e calculando um mês"
version: 1
---

Todo preço deste curso vem de uma tabela só, `prices.py`, que lê a lista pública de preços da AWS em
versões fixas das ofertas. É o preço de lista para Linux, em dólares americanos e sem impostos, para
`sa-east-1` (São Paulo) e `us-east-1` (Norte da Virgínia). Não é uma fatura, e nenhuma conta foi
envolvida. As primeiras dezessete linhas têm tudo de que esta seção precisa:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | sed -n 1,17p
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

EC2, Linux, on demand, USD per hour
  t3.micro    2 vCPU   1 GiB              0.01680      0.01040
  t4g.small   2 vCPU   2 GiB              0.02680      0.01680
  t3.medium   2 vCPU   4 GiB              0.06720      0.04160
  m7i.large   2 vCPU   8 GiB              0.16065      0.10080
  m7g.large   2 vCPU   8 GiB              0.13010      0.08160
  c7i.large   2 vCPU   4 GiB              0.13755      0.08925
  m7i.xlarge  4 vCPU  16 GiB              0.32130      0.20160
```

**Leia uma coluna de cada vez.** Misturar as duas regiões numa comparação é o jeito mais fácil de
chegar a uma conclusão errada a partir de números certos; `m7i.large` custa 0,10080 na Virgínia e
0,16065 em São Paulo, e por que as regiões diferem é assunto das aulas 9 e 10. Esta seção fica em
`sa-east-1`.

## Um degrau acima dobra tudo

`m7i.large` tem 2 vCPU e 8 GiB por 0,16065 USD por hora. `m7i.xlarge` tem 4 vCPU e 16 GiB por
0,32130. **Cada degrau de tamanho dobra o processador, a memória e o preço juntos**, e o padrão segue
família acima: `2xlarge`, depois `4xlarge`, cada um o dobro do anterior.

A consequência é que, dentro de uma família, o preço é linear no tamanho. Duas `m7i.large` custam
exatamente o que custa uma `m7i.xlarge`, então a escolha entre uma máquina grande e duas pequenas
nunca é sobre a tarifa por hora. É sobre o que acontece quando uma máquina falha, e sobre se o seu
programa consegue dividir o trabalho entre duas. A segunda metade desta aula é construída sobre essa
escolha.

## De um preço por hora a um mês

Um preço por hora não diz nada a quem aprova o orçamento. Multiplique pelas horas de um mês, e a
pergunta é qual mês: fevereiro tem 672 horas e um mês de 31 dias tem 744. **Use 730**, que são as
8.760 horas de um ano divididas por doze. É o mês médio, é o número que a própria calculadora de
preços da AWS usa, e faz com que uma estimativa para março e outra para fevereiro deem o mesmo
número, que é para isso que serve uma estimativa.

Aqui está a conta como programa, para que nada nela seja feito de cabeça:

```schooling-example
{"language": "python", "file": "estimate.py", "parts": [{"code": "HOURS_PER_MONTH = 8760 / 12        # 365 days x 24 hours, over 12 months\n\n", "note": "As horas de um mês médio: um ano de 8.760 horas dividido por doze. Fevereiro tem 672 e um mês de 31 dias, 744; com 730 toda estimativa mensal dá o mesmo número."}, {"code": "# sa-east-1, Linux, on demand, USD per hour, from prices.py\nper_hour = {\n    \"m7i.large\": 0.16065,\n    \"m7i.xlarge\": 0.32130,\n    \"m7g.large\": 0.13010,\n}\n\n", "note": "Três linhas da tabela, copiadas como estão. Com os números num lugar só, um preço novo é uma edição, e o comentário diz de onde veio cada número."}, {"code": "for name, price in per_hour.items():\n    month = price * HOURS_PER_MONTH\n    print(f\"{name:10}  {price:.5f} x {HOURS_PER_MONTH:.0f} h = {month:6.2f} USD\")\n", "note": "Preço por hora vezes horas. A f-string completa o nome até dez caracteres, imprime o preço com cinco casas, como a tabela, e o mês com duas."}], "output": "m7i.large   0.16065 x 730 h = 117.27 USD\nm7i.xlarge  0.32130 x 730 h = 234.55 USD\nm7g.large   0.13010 x 730 h =  94.97 USD\n"}
```

Então uma `m7i.large` rodando o mês inteiro em São Paulo custa 117,27 USD no preço de lista, antes do
disco, do tráfego de rede e dos impostos. A `xlarge` custa 234,55, o dobro, como a regra diz.

## Arm contra x86 no mesmo tamanho

`m7g.large` e `m7i.large` têm o mesmo tamanho no papel, 2 vCPU e 8 GiB. A Graviton custa 0,13010 por
hora e a Intel 0,16065: 0,03055 a menos, que são 19% do preço da Intel, e 22,30 USD por mês em 730
horas.

Essa economia é real com uma condição, que na prática são duas. O seu software precisa rodar em Arm,
o que a seção anterior tratou. E precisa rodar pelo menos tão rápido nele, o que ninguém consegue
dizer sem testar, porque duas vCPU são um núcleo na `m7i` e dois na `m7g`. Para alguns programas a
máquina Graviton é mais rápida e a economia passa de 19%; para outros ela é mais lenta, e a economia
some na necessidade de um tamanho maior.

## Dimensionar certo: medir, depois escolher

O erro comum é escolher no chute, e chutar alto "por via das dúvidas". Uma `m7i.xlarge` que passa o
mês em 10% de CPU faz o trabalho de uma `m7i.large` e custa 117,27 USD a mais por mês pelo privilégio.
Ninguém repara, porque nada está quebrado.

**Dimensione a partir de uma medição.** Rode o programa num tamanho que você possa pagar, com uma
carga realista, por tempo suficiente para ver a hora mais movimentada, e olhe dois números:

- memória é um limite rígido. Uma máquina que fica sem ela usa swap ou tem um processo encerrado,
  então o pico precisa caber com folga;
- processador é um limite flexível. Uma máquina com falta dele fica lenta em vez de quebrar, então a
  média importa tanto quanto o pico.

Depois escolha o menor tipo em que o pico cabe, e olhe de novo um mês depois, porque o programa e o
tráfego mudam. A família sai da proporção que você mediu: um serviço usando 6 GiB de memória e meio
núcleo está pedindo um `m`, e um usando dois núcleos inteiros e 1 GiB está pedindo um `c`. Coletar
esses números ao longo de semanas é o que o curso `observability` monta; aqui o ponto é só que o tipo
é escolhido depois dos números, nunca antes.
