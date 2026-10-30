---
title: Três jeitos de pagar por elas
version: 1
---

**Unidades de requisição são consumidas por operação e pagas por segundo de capacidade, a menos que
você escolha pagar por unidade.** Essa é toda a diferença entre os três jeitos em que o Cosmos DB as
vende, e a escolha tem mais a ver com o formato da carga que com o tamanho. Esta seção é ensinada a
partir da documentação da Microsoft; o emulador, como mostra o fim dela, aceita toda opção e não impõe
nenhuma.

| | você define | você paga por | quando serve |
|---|---|---|---|
| vazão manual | um número de RU/s, a partir de 400, em passos de 100 | esse número, toda hora em que ele existe | uma carga ocupada a maior parte do dia |
| autoescala | um máximo, a partir de 1.000 RU/s | em cada hora, o maior RU/s a que ela chegou, a 1,5 vez o preço manual | uma carga com picos e horas calmas |
| serverless | nada | as unidades de requisição consumidas, por milhão | uma carga parada a maior parte do tempo |

O armazenamento é cobrado à parte nos três, por gigabyte por mês.

## Vazão manual

**Você reserva um número de unidades de requisição por segundo, e cada segundo ganha esse tanto para
gastar.** Um contêiner com 1.000 RU/s pode fazer mil leituras pontuais de 1 KB por segundo, o dia
todo, e paga o mesmo fazendo ou não. A vazão pode ser definida num contêiner, ou num banco de dados e
dividida entre os contêineres dele, o que serve para muitos contêineres pequenos cujos picos não
coincidem. O número pode ser mudado a qualquer hora; o que ele não faz é mudar sozinho.

## Autoescala

**Você escolhe um teto, Tmax, e o Cosmos DB se move entre um décimo dele e ele inteiro, na hora,
conforme a carga pede.** Não há aquecimento nem atraso de minutos para reagir: um contêiner com máximo
de autoescala de 4.000 RU/s fica em 400 de madrugada e serve 4.000 no segundo em que a promoção
começa. Cada hora é cobrada pelo nível mais alto a que chegou naquela hora, nunca abaixo do décimo. A
documentação põe o preço de uma RU/s de autoescala em 1,5 vez o de uma manual, para uma conta que
escreve numa região. Esse fator define o ponto de equilíbrio: **a autoescala sai mais barata que o
manual sempre que as horas, em média, são cobradas a menos de dois terços do máximo.** Uma carga que
fica perto do pico o dia todo é o único caso em que o manual ganha.

## Serverless

**Nada é reservado, e cada unidade de requisição é cobrada quando consumida.** Um contêiner que não
faz nada custa só o armazenamento. A documentação limita o serverless a contas numa única região, e a
escolha é feita quando a conta é criada, não por contêiner. A fraqueza dele é o espelho da do manual:
uma unidade consumida em serverless custa muito mais que a mesma unidade reservada e usada, então um
contêiner ocupado paga um prêmio em cada requisição. A próxima seção põe números em onde cada um deixa
de ser o mais barato.

## O nível gratuito

Uma conta por assinatura pode ser criada com o nível gratuito, que a documentação descreve como as
primeiras 1.000 RU/s e 25 GB de armazenamento sem custo, pela vida da conta. Dá para uma conta de
desenvolvimento e para produções pequenas, e como toda franquia gratuita não é um plano para um
negócio.

## O que o emulador faz com tudo isso

Salve como `modes.py` e rode:

`modes.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey, ThroughputProperties

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).create_database_if_not_exists("quitanda")

asked = {
    "manual-1000": 1000,
    "autoscale-4000": ThroughputProperties(auto_scale_max_throughput=4000),
    "manual-100": 100,
}
made = {name: db.create_container_if_not_exists(name, PartitionKey("/id"), offer_throughput=throughput)
        for name, throughput in asked.items()}

for name, container in made.items():
    given = container.get_throughput()
    print(f"{name:15} reports {given.offer_throughput} RU/s, autoscale maximum "
          f"{given.auto_scale_max_throughput}; offer for {given.properties['offerResourceId']}, "
          f"container is {container.read()['_rid']}")
```

```
ana@laptop:~/azure$ python modes.py
manual-1000     reports 100 RU/s, autoscale maximum None; offer for MDAwNA==, container is MDAwMg==
autoscale-4000  reports 100 RU/s, autoscale maximum None; offer for MDAwNA==, container is MDAwMw==
manual-100      reports 100 RU/s, autoscale maximum None; offer for MDAwNA==, container is MDAwNA==
```

**Três contêineres pediram três coisas diferentes, e os três informam 100 RU/s e nenhum máximo de
autoescala.** As duas últimas colunas dizem por quê: toda resposta é a oferta que pertence a
`MDAwNA==`, o último contêiner criado, seja qual for o contêiner que perguntou. Duas das três respostas
descrevem outro contêiner, e a terceira descreve um pedido que o Azure teria recusado, já que 100 está
abaixo do mínimo manual de 400. **No emulador, a vazão é um campo que ele guarda e devolve, não um
orçamento que alguma coisa gasta**, e nem sempre o campo do contêiner certo. Com quanto um contêiner
está provisionado no Azure se lê na declaração dele e na conta, nunca aqui.
