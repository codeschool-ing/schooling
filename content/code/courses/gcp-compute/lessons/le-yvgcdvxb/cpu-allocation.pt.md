---
title: Alocação de CPU, e os dois jeitos de ser cobrado
version: 1
---

O Cloud Run dá duas respostas à pergunta de quando uma instância tem CPU. **Por padrão a CPU só é
alocada enquanto uma requisição está sendo processada, e a instância só é cobrada por esse tempo.**
A alternativa é uma CPU durante a vida inteira da instância, cobrada pela vida inteira, a uma taxa
menor. Escolher entre as duas é conta, e a tabela de preços tem os números.

## Cobrança por requisição

No padrão, uma instância que não está atendendo uma requisição é **estrangulada para quase nenhuma
CPU**. Ela continua existindo, guarda a memória e as conexões abertas, e responde a próxima
requisição na hora, mas entre requisições não consegue fazer nada útil. Você paga o tempo do
começo da primeira requisição até o fim da última em andamento, arredondado para cima em 100
milissegundos, mais um preço por requisição.

É isso que faz falhar o trabalho em segundo plano do aviso da lição 10. Um serviço que responde e
continua trabalhando para mandar um e-mail ou escrever um relatório está fazendo esse trabalho com
uma CPU que o Cloud Run acabou de tirar. Ele pode terminar minutos depois, ou quando a próxima
requisição chegar, ou nunca se a instância for desligada antes. **Trabalho depois da resposta
pertence a um job ou a uma fila**, o Cloud Tasks da lição 20, não ao rabo de uma requisição.

## Cobrança por instância

Com `cpu_idle = false`, chamado de "CPU sempre alocada" no gcloud, a instância tem CPU durante a
vida inteira e é cobrada pela vida inteira, ociosa ou não, sem preço por requisição. Trabalho em
segundo plano então roda normalmente. As taxas são menores por segundo, porque o Google está
vendendo um tempo que ele consegue planejar:

```
ana@laptop:~/gcp$ python3 prices.py serverless | head -12
Google Cloud public prices, us-central1, USD, 30 October 2026

Cloud Run, request-based billing (cloud.google.com/run/pricing)
  vCPU, while a request is being served             0.000024  per vCPU-second
  memory, while a request is being served          0.0000025  per GiB-second
  vCPU, an idle minimum instance                   0.0000025  per vCPU-second
  requests                                               0.4  per million
  free each month: vCPU                               180000  vCPU-seconds
  free each month: memory                             360000  GiB-seconds
  free each month: requests                          2000000  requests

Cloud Run, instance-based billing, and jobs
```

## Qual custa menos

A diferença é só a parte da vida da instância passada atendendo. Este programa calcula as duas para
uma instância de 1 vCPU e 512 MiB, aos preços da tabela. Salve como `~/gcp/runcost.py`:

```python
# runcost.py
"""What one Cloud Run instance of 1 vCPU and 0.5 GiB costs in a month,
billed by request or by instance, for the share of the month it is busy.
Prices from prices.py, lesson 1; requests and the free tier left out."""
import sys

VCPU, GIB = 1, 0.5
SECONDS = 730 * 3600                     # the month of the price sheet
busy = float(sys.argv[1])                # 0.25: serving a quarter of the time

by_request = busy * SECONDS * (VCPU * 0.000024 + GIB * 0.0000025)
by_instance = SECONDS * (VCPU * 0.000018 + GIB * 0.000002)
idle_minimum = (1 - busy) * SECONDS * (VCPU * 0.0000025 + GIB * 0.0000025)
print(f'busy {busy:4.0%}: by request {by_request:6.2f} USD, '
      f'plus {idle_minimum:5.2f} kept as a minimum instance; '
      f'by instance {by_instance:6.2f} USD')
```

E rode para uma instância ocupada de 5% do mês até ocupada o tempo todo:

```
ana@laptop:~/gcp$ for b in 0.05 0.25 0.50 0.75 1.00; do python3 runcost.py $b; done
busy   5%: by request   3.32 USD, plus  9.36 kept as a minimum instance; by instance  49.93 USD
busy  25%: by request  16.59 USD, plus  7.39 kept as a minimum instance; by instance  49.93 USD
busy  50%: by request  33.18 USD, plus  4.93 kept as a minimum instance; by instance  49.93 USD
busy  75%: by request  49.77 USD, plus  2.46 kept as a minimum instance; by instance  49.93 USD
busy 100%: by request  66.36 USD, plus  0.00 kept as a minimum instance; by instance  49.93 USD
```

**A cobrança por instância custa o mesmo faça a instância o que fizer**, 49,93 dólares por mês
neste tamanho. A cobrança por requisição cresce com o trabalho: 3,32 com 5% de ocupação, 33,18 com
metade. Elas se cruzam entre a metade e os três quartos; com 75% de ocupação a cobrança por
requisição dá 49,77 e com 100% dá 66,36, um terço mais cara. A coluna do meio é o assunto da seção
05: quanto custa manter a instância como mínimo quente, além da cobrança por requisição, nas horas
em que ela está ociosa.

Então **um serviço ocupado a maior parte do tempo sai mais barato com a CPU sempre alocada**, e um
ocupado de vez em quando sai mais barato com o padrão. Duas coisas que o programa deixa de fora
mexem um pouco na linha: o preço por requisição, 0,40 dólar por milhão, que só a cobrança por
requisição paga; e o nível gratuito mensal da tabela, que dá à cobrança por instância mais
vCPU-segundos que à cobrança por requisição, e dentro do qual um serviço pequeno pode viver inteiro.
