---
title: A conta de esperar contra manter
version: 1
---

A crença comum é que serverless é a opção barata e uma instância mantida rodando a cara. **Nenhuma
das duas é mais barata em geral.** Um medidor conta os segundos que o seu código roda, o outro
conta as horas que uma instância existe, e qual conta sai menor depende de quantos pedidos chegam.
Abaixo de um certo ritmo, pagar por execução ganha; acima dele, ganha a instância. Esta seção acha
esse ritmo para a API de pedidos da loja, e depois faz a pergunta que o ritmo não responde: quanto
valem as partidas a frio abaixo dele.

## Os dois medidores

A documentação descreve os medidores e deixa os preços na página de preços. O Flex Consumption, sob
demanda, cobra duas coisas: "a quantidade total de memória provisionada enquanto cada instância sob
demanda está executando funções ativamente (em GB-segundos), menos uma cota gratuita de GB-s por
mês", e "o número total de execuções, menos uma cota gratuita (número) de execuções por mês". **A
memória é o tamanho da instância, não o que o seu código usa**: uma instância de 2.048 MB é cobrada
como 2.048 MB enquanto trabalha. A documentação também fixa "o período mínimo de execução cobrável"
em 1.000 ms, arredondado para os 100 ms seguintes depois disso. Um pedido a `take_order` leva cerca
de um décimo de segundo, então quando os pedidos chegam um de cada vez, cada um é cobrado como um
segundo inteiro de uma instância de 2 GB; esta seção usa essa leitura.

As instâncias always ready do Flex são cobradas de outro jeito: uma base pela memória de toda
instância always ready, o tempo todo, mais a execução enquanto trabalham, mais as execuções, e **na
cobrança always ready não há cotas gratuitas**. O Premium cobra núcleos e memória de toda instância
alocada, pelo menos uma, sem cobrança por execução. O Dedicado cobra o plano. Esses três são o outro
medidor: o tempo em que uma instância existe, faça ela o que fizer.

## As taxas, e por que não são as do Azure

A máquina em que estas aulas foram gravadas não conseguia acessar as páginas de preços da
Microsoft. Então **toda taxa desta seção é ilustrativa, não o preço do Azure.** Duas delas são as
que o próprio artigo de custos da Microsoft supõe no exemplo resolvido, "uma taxa de execução sob
demanda de $0.000026 GB-s" e "uma taxa sob demanda de $0.40 por milhão de execuções", com a
instrução de sempre conferir a página de preços. A terceira, 150 USD por mês, é um número redondo
que representa uma instância rodando o mês inteiro, seja um EP1 do Premium, uma instância Dedicada
ou uma always ready do Flex. O tamanho das cotas gratuitas só está na página de preços, então o
programa as deixa em zero e mostra onde elas entram. A aula 21 mostra como pôr os preços reais.

Salve isto como `~/azure/plans.py`:

```schooling-example
{"language": "python", "file": "plans.py", "parts": [{"code": "# plans.py\n# A month of the shop's order API on demand, against one instance kept\n# running. ILLUSTRATIVE RATES, NOT AZURE'S PRICES.\nGB_SECOND = 0.000026      # USD per GB-second of an instance executing\nPER_MILLION = 0.40        # USD per million executions\nALWAYS_ON = 150.00        # USD a month for one instance that never stops\n\n", "note": "**As taxas são ilustrativas, não os preços do Azure.** As duas primeiras são as que o próprio artigo de custos da Microsoft supõe no exemplo resolvido, que ele manda conferir na página de preços; a terceira é um número redondo que representa uma instância rodando o mês inteiro, seja qual for o nome que o plano dá a ela."}, {"code": "MEMORY_GB = 2             # a 2,048 MB instance\nBILLED_S = 1.0            # each order billed as the 1,000 ms minimum\nGRANT_GBS = 0             # the monthly free grants: from the pricing page\nGRANT_EXECUTIONS = 0\nSECONDS = 730 * 3600      # a month of 730 hours\n\n", "note": "A API de pedidos da loja numa instância Flex de 2.048 MB, que o exemplo da Microsoft conta como 2 GB. Cada pedido é cobrado como um segundo, o mínimo documentado. As cotas gratuitas ficam em zero, porque o tamanho delas só está na página de preços; um mês tem 730 horas."}, {"code": "def on_demand(per_second):\n    requests = per_second * SECONDS\n    gbs = max(requests * MEMORY_GB * BILLED_S - GRANT_GBS, 0)\n    executions = max(requests - GRANT_EXECUTIONS, 0)\n    return gbs * GB_SECOND + executions / 1e6 * PER_MILLION\n\n\nfor rate in (0.01, 0.1, 0.5, 1, 2, 5):\n    print(f'{rate:5} req/s {rate * SECONDS:>11,.0f} a month   '\n          f'on demand {on_demand(rate):7.2f}   always on {ALWAYS_ON:.2f} USD')\n\n", "note": "A conta sob demanda para um ritmo constante de pedidos: GB-segundos menos a cota, à taxa por GB-segundo, mais execuções menos a cota, à taxa por milhão. Depois uma linha para cada um de seis ritmos, contra a instância que custa o mesmo em qualquer ritmo."}, {"code": "per_request = MEMORY_GB * BILLED_S * GB_SECOND + PER_MILLION / 1e6\nbreak_even = ALWAYS_ON / per_request / SECONDS\nprint(f'one request: {per_request:.7f} USD')\nprint(f'break-even: {break_even:.2f} requests a second, '\n      f'{break_even * SECONDS:,.0f} a month')\n", "note": "O preço de um pedido sob demanda, e o ritmo em que um mês de pedidos custa tanto quanto a instância: o preço da instância sempre ligada dividido pelo preço de um pedido, espalhado pelos segundos do mês."}]}
```

E rode:

```
ana@laptop:~/azure$ python3 plans.py
 0.01 req/s      26,280 a month   on demand    1.38   always on 150.00 USD
  0.1 req/s     262,800 a month   on demand   13.77   always on 150.00 USD
  0.5 req/s   1,314,000 a month   on demand   68.85   always on 150.00 USD
    1 req/s   2,628,000 a month   on demand  137.71   always on 150.00 USD
    2 req/s   5,256,000 a month   on demand  275.41   always on 150.00 USD
    5 req/s  13,140,000 a month   on demand  688.54   always on 150.00 USD
one request: 0.0000524 USD
break-even: 1.09 requests a second, 2,862,595 a month
```

**Com essas taxas as duas contas se cruzam em cerca de um pedido por segundo**, 1,09, o que dá
2.862.595 por mês. A um décimo disso, a conta sob demanda é 13,77 USD contra 150; a cinco por
segundo é 688,54. Cada pedido custa 0,0000524 USD, e quase tudo é o GB-segundo: a cobrança por
execução é 0,0000004 disso. É por isso que o tamanho da instância mexe muito mais na resposta do que
o número de pedidos. O mesmo pedido numa instância de 512 MB custa cerca de um quarto, e o ponto de
equilíbrio dela fica quase quatro vezes mais alto; ela também tem um quarto de núcleo, que a seção
anterior viu esticar uma partida no laptop.

A cota gratuita move a linha por um valor fixo. Uma cota de G GB-segundos paga G dividido por 2
pedidos aqui, já que cada um gasta 2 GB-s, então ela sobe o ponto de equilíbrio nesse número de
pedidos por mês e não muda nada acima dele.

## A concorrência muda a contagem de segundos

O programa supõe que cada pedido tem uma instância só para ele. O artigo de custos da Microsoft
resolve um exemplo que mostra o que acontece quando não têm: um app só com triggers HTTP, 40 pedidos
por segundo, 10 deles em andamento a qualquer momento, em instâncias de 2.048 MB sem nenhuma always
ready. Se o trabalho é limitado por CPU e cada pedido ganha uma instância própria, dez instâncias
ficam ativas o tempo todo, e o total da documentação é `$1.9296 USD` por hora. **Se o trabalho é
esperar entrada e saída, os dez cabem numa instância, e os mesmos pedidos custam `$0.245 USD` por
hora**, porque o medidor conta a memória das instâncias ativas, não o número de pedidos dentro delas.
As execuções, 0,0576 USD por hora, são as mesmas nos dois. Para a loja, cujo `take_order` faz pouco
além de entregar um pedido a uma fila, o custo real por pedido fica um pouco abaixo do que o
programa imprime, e o ponto de equilíbrio correspondentemente mais alto.

## O que o ponto de equilíbrio não diz

A API de pedidos da loja recebeu uns 400.000 pedidos no mês passado, cerca de 0,15 por segundo,
quase todos entre as oito da manhã e as onze da noite. Com essas taxas isso dá uns 21 USD sob
demanda contra 150 por uma instância. Então, só pelo dinheiro, sob demanda ganha, por um fator de
sete.

**Abaixo do ponto de equilíbrio, uma instância mantida pronta é comprada por latência, não por
economia.** De noite a API de pedidos fica ociosa por muitos minutos seguidos, e a documentação diz
que um app ocioso pode ser escalado a zero depois de alguns minutos. Então o primeiro cliente da
manhã encontra uma partida a frio, e o primeiro depois de cada trecho calmo também. Manter uma
instância pronta tira essas partidas, e com essas taxas custa uns 129 USD por mês a mais do que não
fazer isso. Se vale a pena pagar é uma pergunta sobre clientes, não sobre aritmética: quantos
pedidos por mês encontram uma partida a frio, e quantas dessas pessoas desistem.

O mesmo raciocínio, feito para `make_receipt` ou para a exportação financeira noturna, sai para o
outro lado quase na hora. Ninguém espera atrás de um trigger de fila, então uma partida a frio custa
alguns segundos que ninguém vê, e a instância mantida para ela não compraria nada. **Prontidão só
vale o preço onde alguém está esperando**, e os dois medidores deixam você pagar por ela exatamente
ali: uma instância always ready para o grupo `http`, e nenhuma para o resto.
