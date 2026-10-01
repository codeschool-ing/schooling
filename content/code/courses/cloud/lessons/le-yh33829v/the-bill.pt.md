---
title: Lendo a conta antes de ela chegar
version: 1
---

Uma função é cobrada em dois medidores. **As requisições contam quantas vezes ela foi chamada; os
GB-segundos contam quanta memória ela segurou e por quanto tempo.** Um GB-segundo é um gigabyte de
memória configurada durante um segundo de execução: uma função configurada com 512 MB que roda por
120 ms gasta 0,5 × 0,120 = 0,06 GB-segundo por chamada. **A memória é a que você configurou, não a
que o código usou**, e o Lambda cobra a duração por milissegundo, arredondada para cima.

Estas são as linhas de Lambda da tabela de preços do curso, a lista pública de preços da AWS para
`sa-east-1` (São Paulo) e `us-east-1` (Norte da Virgínia), em dólares americanos, sem impostos, nas
versões de oferta que a tabela imprime no topo:

```
ana@laptop:~/cloud$ python3 prices.py lambda
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
```

Três coisas nela merecem uma segunda olhada. **As duas regiões cobram o mesmo pelo Lambda**, enquanto
as linhas de EC2 da mesma tabela deixam São Paulo mais cara. O preço de Arm é menor que o de x86, para
o mesmo código rodando nos processadores Arm da AWS, desde que ele e as bibliotecas dele rodem em Arm.
E o nível gratuito aparece na lista como duas franquias, um milhão de requisições e 400.000
GB-segundos por mês. A lista mostra só a franquia; as condições do nível gratuito estão nas páginas da
própria AWS, e este curso não as repete.

## Um mês, com a conta à vista

Uma função atende uma API: 3 milhões de requisições por mês, 512 MB de memória, duração cobrada média
de 120 ms, em x86.

- GB-segundos: 3.000.000 × 0,5 GB × 0,120 s = 180.000.
- Requisições: 3 milhões × 0,20 USD por milhão = 0,60 USD.
- Duração: 180.000 × 0,0000166667 = 3,00 USD, ou 3,000006 antes do arredondamento.
- Juntos: **3,60 USD por mês, antes do nível gratuito.**

Descontado o nível gratuito, 2 milhões de requisições são cobradas, o que dá 0,40 USD, e 180.000
GB-segundos ficam abaixo da franquia de 400.000, então a duração não custa nada: 0,40 USD por mês.

A mesma conta como programa, para os números poderem ser trocados e rodados de novo:

```schooling-example
{"language": "python", "file": "bill.py", "parts": [{"code": "# Lambda, x86, from `python3 prices.py lambda`: the same in both regions.\nPER_MILLION_REQUESTS = 0.20\nPER_GB_SECOND = 0.0000166667\nFREE_REQUESTS = 1_000_000\nFREE_GB_SECONDS = 400_000\n", "note": "Quatro linhas da tabela de preços, copiadas como estão. O preço por GB-segundo é o de x86; em Arm esta linha seria `0.0000133334`."}, {"code": "requests = 3_000_000          # a month\nmemory_gb = 512 / 1024        # 512 MB\nseconds = 0.120               # average billed duration\n", "note": "Os três fatos sobre a carga. A memória é a que você configurou, e 512 MB são metade dos 1.024 MB que contam como um gigabyte."}, {"code": "gb_seconds = requests * memory_gb * seconds\nreq_cost = requests / 1_000_000 * PER_MILLION_REQUESTS\ngbs_cost = gb_seconds * PER_GB_SECOND", "note": "**Os dois medidores do Lambda**, cada um vezes o seu preço. O API gateway, os logs e os dados enviados para fora são cobrados pelos seus próprios serviços e não entram aqui."}, {"code": "print(f\"GB-seconds          {gb_seconds:>12,.0f}\")\nprint(f\"requests            {req_cost:>12.2f} USD\")\nprint(f\"GB-seconds          {gbs_cost:>12.2f} USD\")\nprint(f\"total, no free tier {req_cost + gbs_cost:>12.2f} USD\")\n", "note": "Impresso com separador de milhar e duas casas decimais, e é aí que 3.000006 vira 3.00."}, {"code": "req_left = max(0, requests - FREE_REQUESTS)\ngbs_left = max(0, gb_seconds - FREE_GB_SECONDS)\nfree_total = req_left / 1_000_000 * PER_MILLION_REQUESTS + gbs_left * PER_GB_SECOND\nprint(f\"total, free tier    {free_total:>12.2f} USD\")", "note": "Cada franquia sai do seu próprio medidor, nunca abaixo de zero: as requisições depois do primeiro milhão são cobradas, e os 180.000 GB-segundos cabem inteiros nos 400.000."}], "output": "GB-seconds               180,000\nrequests                    0.60 USD\nGB-seconds                  3.00 USD\ntotal, no free tier         3.60 USD\ntotal, free tier            0.40 USD"}
```

**Esses são os medidores do Lambda e nada mais.** O API gateway na frente da função, os logs que ela
escreve e os dados que ela manda para a internet são cobrados pelos seus próprios serviços, e nenhum
deles está neste total. A aula 10 é sobre achar linhas assim antes de elas chegarem.

Os 3,60 mudam com a carga de um jeito que dá para ler nos medidores. O dobro de requisições é o
dobro da conta. O dobro de memória, ou o dobro de duração, dobra a parte da duração. E **uma função
que passa 100 ms dos seus 120 esperando um banco de dados é cobrada pela espera**, porque os
GB-segundos contam o tempo em que o ambiente ficou ocupado, não o tempo em que o processador
trabalhou. Numa máquina que você já paga por hora, uma consulta lenta custa latência; aqui ela custa
dinheiro também.
