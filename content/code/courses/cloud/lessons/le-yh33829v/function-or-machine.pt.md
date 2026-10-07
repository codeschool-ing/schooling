---
title: Uma função ou uma máquina
version: 2
---

A conta da seção anterior é pequena porque a carga é pequena. **O custo de uma função é proporcional
ao uso; o de uma máquina é proporcional ao tempo.** Com tráfego baixo ou em picos isso favorece a
função, que não custa nada entre um pico e outro, enquanto a máquina custa o mesmo às quatro da manhã
e ao meio-dia. Com tráfego alto e constante isso favorece a máquina, que atende requisição atrás de
requisição pelo mesmo preço por hora. Em algum ponto entre as duas as linhas se cruzam, e a tabela de
preços basta para achar onde.

## As duas linhas

Pegue a carga da seção anterior, 512 MB e 120 ms por requisição, e deixe o nível gratuito de fora: ele
é uma franquia por conta, não uma propriedade de nenhum dos dois projetos. Um milhão de requisições
custa 0,20 USD em requisições mais 1.000.000 × 0,5 × 0,120 × 0,0000166667 = 1,00 USD em duração,
então **1,20 USD por milhão de requisições.**

Do outro lado, máquinas da mesma tabela, `us-east-1`, sob demanda. Uma t3.medium custa 0,04160 USD por
hora, e a AWS conta um mês como 730 horas: 0,04160 × 730 = 30,37 USD. **Mas uma máquina não é o mesmo
serviço que uma função.** Ela não tem segunda cópia quando falha nem nada na frente para dividir a
carga; a aula 4 defendeu pelo menos duas atrás de um balanceador. Duas t3.medium e um Application
Load Balancer a 0,0225 USD por hora: (2 × 0,04160 + 0,0225) × 730 = 77,16 USD.

O cruzamento é cada custo mensal dividido pelo custo da função por milhão. Salvo como `crossover.py`:

```python
# us-east-1, from `python3 prices.py`: on demand, USD per hour.
T3_MEDIUM = 0.04160
ALB = 0.0225
HOURS = 730                   # a month, as AWS counts one

# One million requests at 512 MB and 120 ms, as in bill.py, no free tier.
per_million = 0.20 + 1_000_000 * (512 / 1024) * 0.120 * 0.0000166667

for label, month in [("one t3.medium", T3_MEDIUM * HOURS),
                     ("two t3.medium + ALB", (2 * T3_MEDIUM + ALB) * HOURS)]:
    crossover = month / per_million
    per_second = crossover * 1_000_000 / (HOURS * 3600)
    print(f"{label:<20} {month:7.2f} USD a month   "
          f"break-even {crossover:5.1f} million requests ({per_second:4.1f} a second)")
print(f"Lambda, per million  {per_million:7.2f} USD")
```

```
ana@laptop:~/cloud$ python3 crossover.py
one t3.medium          30.37 USD a month   break-even  25.3 million requests ( 9.6 a second)
two t3.medium + ALB    77.16 USD a month   break-even  64.3 million requests (24.5 a second)
Lambda, per million     1.20 USD
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um gráfico do custo mensal em dólares contra requisições por mês, de zero a 80 milhões. O custo da função é uma reta que sai do zero, 1,20 dólar por milhão de requisições. Uma t3.medium custa 30,37 dólares fixos por mês e as linhas se cruzam em 25,3 milhões de requisições. Duas t3.medium atrás de um balanceador custam 77,16 dólares fixos e as linhas se cruzam em 64,3 milhões.\"><defs><marker id=\"sl-cross-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 250.0 L680 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M80 195.0 L680 195.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><path d=\"M80 140.0 L680 140.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M80 85.0 L680 85.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">75</text><path d=\"M80 30.0 L680 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M80.0 250 L80.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M230.0 250 L230.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M380.0 250 L380.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><path d=\"M530.0 250 L530.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60</text><path d=\"M680.0 250 L680.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">80</text><text x=\"380.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requisições por mês, em milhões (512 MB, 120 ms cada)</text><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">USD por mês</text><path d=\"M80 183.2 L680 183.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"86\" y=\"173.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma t3.medium, sempre ligada</text><path d=\"M80 80.2 L680 80.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"86\" y=\"70.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">duas t3.medium e um balanceador</text><path d=\"M80 250.0 L680.0 38.8\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"350.0\" y=\"135.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Lambda: 1,20 por milhão</text><circle cx=\"269.8\" cy=\"183.2\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><path d=\"M269.8 188.2 L269.8 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"275.8\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25.3</text><circle cx=\"562.2\" cy=\"80.2\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><path d=\"M562.2 85.2 L562.2 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"568.2\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">64.3</text></svg>", "caption": "À esquerda de um cruzamento a função sai mais barata; à direita, a máquina. Cada número é uma linha da tabela de preços, us-east-1, sob demanda, sem nível gratuito."}
```

Lido como tráfego, 25,3 milhões de requisições por mês são 9,6 por segundo em média, o dia inteiro,
todo dia. **Abaixo disso a função ganha até de uma máquina sozinha; acima de 64,3 milhões, um par
bem montado ganha da função.** **A maioria das APIs pequenas, ferramentas internas e sistemas de
retaguarda fica bem à esquerda do primeiro cruzamento.** Uma API pública movimentada fica à direita
do segundo.

## O que o gráfico deixa de fora

Cada linha dele vem da tabela, e cada item abaixo moveria uma linha:

- Se uma t3.medium dá conta deste trabalho a 24,5 requisições por segundo é uma medição, não uma
  conta. Se não der, a linha da máquina sobe para máquinas maiores.
- A linha da função deixa de fora o API gateway, que cobra por requisição e, portanto, empurra os
  cruzamentos para a esquerda.
- A linha da máquina deixa de fora os discos e a cobrança do balanceador pelo tráfego que ele
  atende, que vem separada do preço por hora e não está na tabela. Também deixa de fora as horas que
  alguém passa aplicando patches e vigiando as máquinas: o custo de operação que o serverless tira,
  e que nenhuma tabela de preços lista.
- O preço reservado, assunto da aula 10, baixa a linha da máquina. O preço de 1 ano da tabela para
  uma t3.medium em `us-east-1` é 0,02610 USD por hora: 0,02610 × 730 = 19,05 USD por mês, e
  19,05 / 1,20 leva o primeiro cruzamento de 25,3 para 15,9 milhões.

**E uma média esconde o formato do tráfego.** Uma máquina precisa ser dimensionada para a hora mais
cheia, não para a média. Pense em duas cargas com o mesmo total no mês, uma constante e outra que
chega numa correria de duas horas toda noite. Elas custam o mesmo para a função e custam muito
diferente para a máquina, porque a da correria precisa de uma máquina maior, que fica ociosa nas
outras vinte e duas horas. **Tráfego em picos leva a sua posição real para a esquerda do gráfico, na
direção da função.**
