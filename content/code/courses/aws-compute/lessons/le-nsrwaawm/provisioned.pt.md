---
title: "Concorrência provisionada: ambientes mantidos prontos, e cobrados enquanto esperam"
version: 1
---

**A concorrência provisionada é um número de ambientes de execução que o Lambda inicia com
antecedência e mantém inicializados**, com o seu código carregado e o código de fora do handler já
executado. Uma requisição que cai num deles pula a inicialização que a lição 17 mede, o cold start.
Ela não é um teto, nem uma garantia no sentido da seção anterior: as requisições além do número
provisionado continuam sendo atendidas, por ambientes comuns iniciados sob demanda, com um cold
start cada. E, ao contrário de uma reserva, **ela é cobrada por cada segundo em que está
configurada**, chegue uma requisição ou nenhuma.

## Uma versão ou um alias, nunca `$LATEST`

A concorrência provisionada é configurada sobre um código fixo, porque o que o Lambda mantém pronto
é aquele código já inicializado. `$LATEST` é a cópia editável da função e pode mudar por baixo
dela, então a AWS a recusa ali. A configuração vai numa **versão**, que é um retrato imutável do
código e das configurações, ou num **alias**, um nome que aponta para uma versão e pode ser movido.
O alias é a escolha comum: um deploy move `live` da versão 3 para a versão 4, e os ambientes
provisionados são preparados para a versão 4 como parte da mudança.

O moto faz versões e aliases, então os dois primeiros passos rodam contra ele:

```
ana@laptop:~/aws$ aws lambda publish-version --function-name orders --query "{Version: Version, Arn: FunctionArn}"
{
    "Version": "1",
    "Arn": "arn:aws:lambda:sa-east-1:123456789012:function:orders:1"
}
ana@laptop:~/aws$ aws lambda create-alias --function-name orders --name live --function-version 1 --query "{Alias: Name, Version: FunctionVersion}"
{
    "Alias": "live",
    "Version": "1"
}
```

O terceiro passo é a configuração em si, dez ambientes mantidos prontos atrás de `live`. O moto
5.2.3 não a implementou, e responde com a mesma página HTML que o `get-account-settings` deu:

```
ana@laptop:~/aws$ aws lambda put-provisioned-concurrency-config --function-name orders --qualifier live --provisioned-concurrent-executions 10

aws: [ERROR]: An error occurred (404) when calling the PutProvisionedConcurrencyConfig operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

Na AWS a chamada devolve o status `IN_PROGRESS` enquanto o Lambda inicia os dez ambientes e roda a
inicialização deles, e `READY` quando estão atendendo, o que leva minutos e não segundos. Nada neste
parágrafo foi executado. Mais dois fatos da documentação da AWS dão forma ao uso. Os dez saem do
pool da segunda seção desta lição, da reserva da própria função se ela tiver uma, e da parte sem
reserva se não tiver. E o número pode seguir um horário ou um alvo pelo Application Auto Scaling:
vinte ambientes a partir das oito da manhã e dois de madrugada, que é como uma equipe paga pela
prontidão só nas horas em que alguém está esperando.

## A conta, pela tabela

Três linhas da tabela de preços decidem. São os preços de 16 de outubro de 2026 para x86 em
sa-east-1:

```
ana@laptop:~/aws$ python3 prices.py lambda
AWS public price list, sa-east-1, USD, excluding tax

Lambda
  requests                                           0.2  per million
  duration, x86                             0.0000166667  per GB-second
  duration, Arm                             0.0000133334  per GB-second
  provisioned concurrency, x86              0.0000066372  per GB-second
  duration on provisioned, x86              0.0000154867  per GB-second
```

Sob demanda, uma função paga pela **duração**: 0,0000166667 USD por gigabyte-segundo que ela de fato
roda. O provisionado divide isso em dois. A **concorrência provisionada** custa 0,0000066372 USD por
gigabyte-segundo em que um ambiente fica pronto, ocupado ou parado; a **duração no provisionado**
custa 0,0000154867 USD por gigabyte-segundo rodando num deles, um pouco menos que sob demanda. As
requisições custam 0,2 USD por milhão nos dois casos, então saem da comparação.

O programa abaixo compara um mês dos dois para dez ambientes de 1 GB, em quatro níveis de uso.
Salve-o como `~/aws/provisioned.py`:

```schooling-example
{"language": "python", "file": "provisioned.py", "parts": [{"code": "# A month of one function in sa-east-1: on demand against provisioned\n# concurrency. Prices from prices.py, 16 October 2026, x86, USD.\nON_DEMAND = 0.0000166667        # per GB-second of running\nPROVISIONED = 0.0000066372      # per GB-second an environment is kept ready\nON_PROVISIONED = 0.0000154867   # per GB-second of running on one of them\n\n", "note": "Os três preços, copiados da tabela. As requisições ficam de fora porque custam o mesmo dos dois lados."}, {"code": "MEMORY_GB = 1.0\nENVIRONMENTS = 10\nSECONDS = 730 * 3600            # a month of 730 hours\n\n", "note": "A função: dez ambientes de 1 GB, por um mês de 730 horas, que são 2.628.000 segundos."}, {"code": "kept = ENVIRONMENTS * MEMORY_GB * SECONDS * PROVISIONED\n\nfor busy in (0.25, 0.50, 0.75, 1.00):\n    used = ENVIRONMENTS * MEMORY_GB * SECONDS * busy      # GB-seconds of running\n    on_demand = used * ON_DEMAND\n    provisioned = kept + used * ON_PROVISIONED\n    print(f'{busy:4.0%} busy   on demand {on_demand:7.2f}   provisioned {provisioned:7.2f} USD')\n\n", "note": "`kept` é o preço da prontidão, o mesmo aconteça o que acontecer. Depois cada nível de uso: `busy` é a fração do mês que os dez ambientes passam rodando requisições, e as duas contas são calculadas para o mesmo trabalho."}, {"code": "break_even = PROVISIONED / (ON_DEMAND - ON_PROVISIONED)\nprint(f'break-even: the environments would have to be {break_even:.0%} busy')\n", "note": "Onde as duas linhas se cruzariam. O provisionado economiza 0,0000011800 USD por GB-segundo rodando e custa 0,0000066372 por GB-segundo mantido pronto, então só se paga se os segundos rodando superarem os segundos mantidos prontos nessa proporção."}]}
```

Rode:

```
ana@laptop:~/aws$ python3 provisioned.py
 25% busy   on demand  109.50   provisioned  276.17 USD
 50% busy   on demand  219.00   provisioned  377.92 USD
 75% busy   on demand  328.50   provisioned  479.67 USD
100% busy   on demand  438.00   provisioned  581.42 USD
break-even: the environments would have to be 562% busy
```

**Com estes preços, nesta região, a concorrência provisionada nunca custa menos que sob demanda.** O
ponto de equilíbrio exigiria os ambientes ocupados 562% do tempo, cinco meses e meio de trabalho
num mês, o que nenhum mês permite. Mesmo com 100% de uso ela custa 581,42 USD contra 438,00, e só a
parte `kept` é 174,43 USD por mês por dez gigabytes parados. Textos sobre concorrência provisionada
costumam citar um nível de uso acima do qual ela vira a opção mais barata. Esse ponto é conta feita
com os preços de uma região, e a tabela de São Paulo não tem um: aqui o desconto no tempo rodando é
pequeno demais para pagar a cobrança pela espera.

Então em sa-east-1 a concorrência provisionada é **comprada por latência e nunca por economia**, e a
pergunta a fazer é quanto um cold start custa a quem o encontra. Para uma API em que um usuário
espera num botão de checkout, dez ambientes mantidos prontos podem valer muitas vezes os seus 174 USD
por mês. Para um consumidor de fila que ninguém observa, é dinheiro gasto num atraso que ninguém vê. O
outro desconto do Lambda, um Compute Savings Plan, não está na tabela; a lição 22 de
`aws-operations` é onde ele é pesado.

A lição 17 mede o que um cold start realmente é, e volta à concorrência provisionada como uma das
formas de removê-lo, ao lado de outras mais baratas que devem ser tentadas primeiro.
