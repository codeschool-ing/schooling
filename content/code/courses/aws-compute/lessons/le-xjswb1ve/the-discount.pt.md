---
title: O desconto, e o que o define
version: 1
---

A imagem comum do spot é um leilão: você dá um lance, os maiores lances ganham, e um lance melhor
mantém a sua instância. Isso era mais ou menos verdade até 2017 e não é como funciona hoje. **Uma
instância spot é capacidade sob demanda que ninguém está usando no momento, vendida mais barato, com
uma condição: a AWS a toma de volta quando precisa dela.** Não há lances. O preço de cada tipo de
instância em cada Availability Zone é definido pela AWS a partir da oferta e da procura de longo
prazo daquele pool, e muda aos poucos, ao longo de dias e não de minutos.

## Quanto mais barato

A AWS descreve o desconto como **até 90%** sobre o preço sob demanda. Esse número é um teto, não uma
cotação: o desconto real depende do tipo, da zona e da semana, e um tipo que todo mundo quer numa
zona movimentada tem muito menos desconto que um mais antigo que ninguém pede. Preços spot não estão
na tabela de preços da lição 1, que lê a lista sob demanda publicada pela AWS em 16 de outubro de
2026, e este curso não os inventa. Onde uma conta precisa de um, a lição diz que é uma suposição.

O moto tem um histórico de preços spot, e ele mostra por que um número do moto nunca é um preço:

```
ana@laptop:~/aws$ aws ec2 describe-spot-price-history --instance-types m7i.large --product-descriptions Linux/UNIX --query "SpotPriceHistory[].[AvailabilityZone,SpotPrice,Timestamp]" --output table
--------------------------------------------------------
|               DescribeSpotPriceHistory               |
+-------------+----------+-----------------------------+
|  sa-east-1a |  0.00001 |  2006-01-02T15:04:05+00:00  |
|  sa-east-1b |  0.00001 |  2006-01-02T15:04:05+00:00  |
|  sa-east-1c |  0.00001 |  2006-01-02T15:04:05+00:00  |
+-------------+----------+-----------------------------+
```

**Cada uma dessas linhas é um valor de enchimento.** Um centésimo de milésimo de dólar por hora, o
mesmo em todas as zonas, com uma data de 2006, o ano em que o EC2 abriu e três anos antes de o spot
existir. Na AWS o mesmo comando devolve uma linha por zona a cada mudança de preço, nos últimos 90
dias, e é o jeito honesto de ver quanto um pool custou recentemente. Mesmo assim ele mostra o
passado, que é a única coisa que um preço spot pode prometer.

## Pedindo uma

Uma instância spot é um lançamento comum com uma opção a mais. O `--instance-market-options` indica
o mercado e duas escolhas: se o pedido é `one-time` ou `persistent`, e o que acontece numa
interrupção.

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type m7i.large --instance-market-options '{"MarketType": "spot", "SpotOptions": {"SpotInstanceType": "one-time", "InstanceInterruptionBehavior": "terminate"}}' --query 'Instances[].[InstanceId,InstanceType,InstanceLifecycle]' --output text
i-25f3f8de6964698c7	m7i.large	spot
ana@laptop:~/aws$ aws ec2 describe-spot-instance-requests --query "length(SpotInstanceRequests)"
0
```

A instância é uma `m7i.large` como qualquer outra, e o `InstanceLifecycle` é o único campo que diz
que ela é spot; uma instância sob demanda não tem esse campo. **O zero é do moto, de novo.** Na AWS,
lançar spot pelo `run-instances` também cria um spot instance request por trás da instância, e o
`describe-spot-instance-requests` o lista com o estado; o moto registra a instância e nenhum pedido.

O comportamento na interrupção é uma decisão sobre o que a instância é:

- **`terminate`**, o padrão, a encerra. O volume raiz vai junto se o template disse isso, como o da
  lição 4 disse.
- **`stop`** mantém os volumes EBS e para a instância, e o pedido a liga de novo quando a capacidade
  volta. Ele exige um pedido `persistent`.
- **`hibernate`** grava a memória no volume raiz antes, para ela voltar de onde estava. Também exige
  um pedido persistente, um volume raiz criptografado com espaço para a memória, e uma imagem
  preparada para isso.

Existe também um **preço máximo**, `MaxPrice`, cujo padrão é o preço sob demanda. Defini-lo mais
baixo não deixa o spot mais barato, já que você paga o preço spot seja qual for o seu máximo; só
acrescenta um segundo motivo para ser interrompido, quando o preço spot passa dele.

## O que o desconto compra, nos números da tabela

A tabela tem o lado sob demanda: uma `m7i.large` em São Paulo custa 0,16065 USD por hora. Dez delas
por um mês de 730 horas custam 10 × 0,16065 × 730 = 1.172,745 USD sob demanda. O grupo da seção
sobre grupos mistos mantém quatro das dez sob demanda e seis em spot. **Suponha, só para a conta, um
desconto spot de 60%**, que é uma suposição e não um preço que alguém cotou. As quatro sob demanda
custam 4 × 0,16065 × 730 = 469,10, as seis spot 6 × 0,16065 × 0,4 × 730 = 281,46, e o mês fica em
750,56 em vez de 1.172,75: uns 36% a menos para o grupo, a partir de um desconto de 60% sobre 60%
dele.

Essa última frase é a forma a guardar. **A economia é o desconto vezes a fração do grupo em spot**, e
a fração em spot é limitada por quanto do grupo aguenta perder uma instância com dois minutos de
aviso. O resto desta lição é sobre fazer essa fração grande sem torná-la perigosa.
