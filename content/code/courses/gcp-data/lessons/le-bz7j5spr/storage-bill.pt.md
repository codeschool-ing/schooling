---
title: A conta do armazenamento, e as duas escolhas que a definem
version: 1
---

**O BigQuery cobra armazenamento numa de quatro tarifas, e duas escolhas independentes escolhem a
tarifa.** A primeira não é sua: uma tabela ou partição que passa 90 dias sem ser modificada cai para a
tarifa de **longo prazo** sozinha, e volta para **ativo** no momento em que recebe uma escrita. A
segunda é sua, uma por dataset: se a conta conta os bytes **lógicos** da última seção ou os bytes
**físicos** que o BigQuery de fato guarda depois da compressão. Estas são as quatro tarifas de São
Paulo, de `cloud.google.com/bigquery/pricing`, lidas em 2026-10-30:

| southamerica-east1, USD por GiB-mês | ativo | longo prazo |
|---|---|---|
| bytes **lógicos** | 0,023 | 0,016 |
| bytes **físicos** | 0,07 | 0,035 |

**Os primeiros 10 GiB de armazenamento de cada mês são gratuitos**, diz a página, e os pedidos da
Quitanda pesam 0,092 GiB. Então a tabela que esta aula construiu não custa nada para guardar, e
continuaria não custando com três anos dos mesmos pedidos, o que dá cerca de 1,7 GiB a 0,092 a cada
sessenta dias. A conta dos pedidos é a das consultas. A conta do armazenamento começa a pesar com os
dados que são grandes por natureza, como o fluxo de cliques do aplicativo, que chega pelo Pub/Sub na
aula 19, e a conta abaixo é feita sobre 1 TiB redondo para as tarifas ficarem fáceis de comparar.

## Ativo e longo prazo

**Longo prazo é o mesmo armazenamento, por cerca de metade do preço.** A página é explícita de que
nada mais muda: "There is no difference in performance, durability, or availability between active
and long-term storage", ou seja, nem desempenho, nem durabilidade, nem disponibilidade. O que decide é
se o dado foi modificado nos últimos 90 dias seguidos, e a página lista o que conta como modificar:
uma carga ou consulta que escreve na tabela, uma cópia para dentro dela, um comando DML, um
`CREATE OR REPLACE TABLE`, linhas enviadas por streaming. Consultar a tabela não zera o relógio, e
exportá-la, criar uma view sobre ela ou copiá-la para outro lugar também não.

**Cada partição de uma tabela particionada conta separadamente**, e essa frase da página vale mais do
que qualquer outra coisa nesta seção. Uma tabela de pedidos particionada por dia, como a que a aula 15
constrói, recebe uma partição nova toda noite e nunca toca as do ano passado. Depois de três anos, as
últimas 90 partições estão ativas e as outras mil e poucas estão em longo prazo, cerca de nove bytes
em dez. **Os mesmos pedidos numa tabela sem partição ficam inteiramente ativos**, porque toda carga
noturna modifica a tabela, e com ela o relógio de 90 dias de cada linha.

## Lógico e físico

**A cobrança lógica conta o tamanho sem compressão; a física conta o que está de fato guardado, a
três vezes a tarifa.** A 0,023 contra 0,07, a cobrança física só é mais barata para dado que comprime
mais de 0,07 ÷ 0,023 = 3,04, e para dado em longo prazo mais de 0,035 ÷ 0,016 = 2,19. Os arquivos
Parquet da última seção deram 3,06. Ninguém consegue dizer a partir disso se o formato do próprio
BigQuery se sairia melhor ou pior, e essa é a posição honesta: a escolha depende de uma razão que este
laboratório não mede, e que o BigQuery informa para cada tabela na view
`INFORMATION_SCHEMA.TABLE_STORAGE`, que é onde a decisão é tomada num projeto real.

**A cobrança física também cobra time travel e fail-safe.** O **time travel** é o BigQuery guardando
as versões anteriores dos dados de uma tabela, para que uma consulta escrita `FOR SYSTEM_TIME AS OF`
um momento anterior leia a tabela como ela era, e para que uma tabela apagada por engano possa voltar.
A documentação do Google, "Data retention with time travel and fail-safe", dá a janela como sete dias
por padrão, configurável por dataset até dois. O **fail-safe** são mais sete dias depois disso, em que
o dado só pode ser recuperado pelo suporte do Google, não por você. A página de preços diz isso numa
frase: "There are no charges for time travel and failsafe storage for logical storage. Time travel and
failsafe storage charges apply for physical storage." Então uma tabela reescrita toda noite carrega,
na cobrança física, os bytes que ela substituiu por até catorze dias, e paga por eles na tarifa ativa.

## A conta, como programa

**Três números decidem a conta**: o tamanho lógico, a razão de compressão e a parte dos bytes que está
em longo prazo. Um quarto, os bytes físicos guardados para time travel e fail-safe, só vale para o
modelo físico. Salve isto como `~/gcp/storage.py`:

`storage.py`:

```python
import sys

PRICE = {  # USD per GiB-month, southamerica-east1, cloud.google.com/bigquery/pricing, read 2026-10-30
    'logical': {'active': 0.023, 'long-term': 0.016},
    'physical': {'active': 0.07, 'long-term': 0.035},
}

logical_gib, ratio, long_term = (float(a) for a in sys.argv[1:4])
kept_gib = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0


def month(model, gib, extra=0.0):
    rate = PRICE[model]
    return (gib * (1 - long_term) + extra) * rate['active'] + gib * long_term * rate['long-term']


physical_gib = logical_gib / ratio
print(f'logical  {logical_gib:9,.1f} GiB  {month("logical", logical_gib):8,.2f} USD a month')
print(f'physical {physical_gib:9,.1f} GiB  {month("physical", physical_gib, kept_gib):8,.2f} USD a month')
```

**Ele deixa de fora os 10 GiB gratuitos**, que são os mesmos poucos centavos em qualquer dos modelos,
e recebe a razão de compressão pronta, já que esse é o número que ninguém aqui consegue medir. Três
casos, para 1 TiB de bytes lógicos que comprimem três para um:

```
ana@laptop:~/gcp$ python3 storage.py 1024 3 0
logical    1,024.0 GiB     23.55 USD a month
physical     341.3 GiB     23.89 USD a month
ana@laptop:~/gcp$ python3 storage.py 1024 3 0.9
logical    1,024.0 GiB     17.10 USD a month
physical     341.3 GiB     13.14 USD a month
ana@laptop:~/gcp$ python3 storage.py 1024 3 0.9 20
logical    1,024.0 GiB     17.10 USD a month
physical     341.3 GiB     14.54 USD a month
```

**Tudo ativo, os dois modelos custam quase o mesmo**, 23,55 contra 23,89, porque três para um fica
logo abaixo dos 3,04 em que eles se cruzam. **Com nove décimos em longo prazo, o físico sai um quarto
mais barato**, 13,14 contra 17,10, porque a linha do longo prazo cruza em 2,19 e três está bem acima.
**Vinte GiB de dado substituído guardados para time travel e fail-safe** somam 20 × 0,07 = 1,40 à
conta física e nada à lógica. Uma tabela reescrita toda noite guardaria muito mais que isso, e poderia
fazer da cobrança física a mais cara das duas.

**O modelo é escolhido por dataset, e não à toa.** Num projeto real é um comando, mostrado aqui e não
rodado:

```sql
ALTER SCHEMA quitanda SET OPTIONS (storage_billing_model = 'PHYSICAL');
```

A documentação do Google sobre os modelos de cobrança de armazenamento diz que, depois que o modelo de
um dataset é trocado, ele não pode ser trocado de novo por 14 dias, então não é uma chave para virar
todo mês conforme os números mudam.

## A computação é a outra conta

**Nenhuma linha desta seção depende de quantas vezes a tabela é consultada.** Uma tabela lida mil vezes
por dia custa o mesmo para guardar que uma que ninguém lê, e uma tabela de armazenamento gratuito, como
a dos pedidos da Quitanda, ainda pode custar uma fortuna para consultar. Compare com a tarifa da classe
Standard do Cloud Storage na mesma região, 0,035 USD por GiB-mês em
`cloud.google.com/storage/pricing`, lida no mesmo dia: os arquivos no bucket custam mais por GiB que a
tarifa ativa lógica da tabela em que foram carregados, e menos que a física. A conta das consultas é o
segundo medidor, e é a próxima aula.
