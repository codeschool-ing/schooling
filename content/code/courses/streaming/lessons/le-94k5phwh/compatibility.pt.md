---
title: Compatibilidade, e o registro dizendo não
version: 1
---

**Um modo de compatibilidade é uma regra que o registro aplica a cada versão nova de um subject
antes de aceitá-la: o esquema novo e o antigo conseguem ler os dados um do outro, e em que
direção?** Ela é conferida uma vez, quando a versão é oferecida, e nunca mais. Esse é o ponto: a
discussão sobre se uma mudança quebra um leitor acontece no registro, num lugar só, e não em cada
consumidor na manhã seguinte a um deploy.

Os modos levam o nome da direção que protegem:

| modo | o esquema novo precisa conseguir… | o que ele permite |
|---|---|---|
| `BACKWARD` | ler dados escritos com a versão anterior | acrescentar um campo **com valor padrão**; remover um campo |
| `FORWARD` | ser lido por um leitor ainda na versão anterior | acrescentar um campo; remover um campo **que tinha valor padrão** |
| `FULL` | as duas coisas | acrescentar ou remover só campos com valor padrão |
| `NONE` | nada é conferido | qualquer coisa |

Cada um tem uma variante `_TRANSITIVE`, que confere a versão nova contra **todas** as anteriores em
vez de só a última. A diferença aparece em três passos: remover um campo na versão 2 e devolvê-lo
com outro tipo na versão 3 passa em duas checagens contra a versão anterior, e deixa a versão 3
incapaz de ler a versão 1.

## O padrão não é o mesmo em todo lugar

O registro da Confluent começa todo subject em `BACKWARD`. A API compatível com a Confluent do
Apicurio não, como mostra o primeiro comando; o segundo define o modo para o subject desta lição:

```
ubuntu@stream:~/work$ curl -s localhost:8080/apis/ccompat/v7/config; echo
{"compatibilityLevel":"NONE"}
ubuntu@stream:~/work$ curl -s -X PUT -H 'Content-Type: application/vnd.schemaregistry.v1+json' --data '{"compatibility": "BACKWARD"}' localhost:8080/apis/ccompat/v7/config/sales-avro-value; echo
{"compatibility":"BACKWARD","normalize":false}
```

**`NONE` quer dizer que o registro que você iniciou nesta lição aceita qualquer mudança** até
alguém dizer o contrário, e é por isso que a primeira coisa a fazer com um subject novo é definir o
seu modo. O `PUT` acima definiu `BACKWARD` só para `sales-avro-value`; sem o nome do subject no fim
do endereço, ele teria mudado o padrão de todos os subjects.

## Uma mudança que ele aceita

Os caixas passarão a informar que caixa registrou cada venda. O `jq` escreve uma versão 2 do
esquema com um campo `till` e um valor padrão, para as vendas escritas antes de o campo existir.
Depois o produtor tenta enviar com ela, e a versão é oferecida ao registro:

```
ubuntu@stream:~/work$ jq '.fields += [{"name": "till", "type": "string", "default": "unknown"}]' sale.avsc > sale-v2.avsc
ubuntu@stream:~/work$ python avro_tills.py --schema sale-v2.avsc --count 1 2>&1 | tail -1
confluent_kafka.schema_registry.error.SchemaRegistryError: The given schema does not match any schema under the subject sales-avro-value (HTTP status code 404, SR code 40403)
ubuntu@stream:~/work$ ./register.sh sales-avro-value sale-v2.avsc
{"id":2}
```

O produtor ainda não quis enviar com a versão 2: com `auto.register.schemas` desligado, um esquema
que o registro não tem é um 404, e a venda nunca é escrita. Registrá-lo é um passo separado e
deliberado, e o registro o conferiu contra a versão 1 sob `BACKWARD` antes de lhe dar o id 2. Um
campo novo com valor padrão passa, porque um leitor na versão 2 consegue preencher `till` com
`unknown` em toda venda escrita antes de o campo existir.

## Uma mudança que ele recusa

Agora a renomeação da primeira seção desta lição, de `cents` para `amount`, como esquema:

```
ubuntu@stream:~/work$ jq '.fields[4].name = "amount"' sale.avsc > sale-renamed.avsc
ubuntu@stream:~/work$ ./register.sh sales-avro-value sale-renamed.avsc
{"message":"io.apicurio.registry.rules.violation.RuleViolationException: Incompatible artifact: sales-avro-value [AVRO], num of incompatible diffs: {1}, list of diff types: [amount at /fields/4]","error_code":409}
ubuntu@stream:~/work$ curl -s localhost:8080/apis/ccompat/v7/subjects/sales-avro-value/versions; echo
[1,2]
```

**409, Conflict**, e o subject continua só com as versões 1 e 2. A mensagem nomeia o campo em que a
checagem parou, `amount`, na posição 4 da lista de campos.

Para o Avro, uma renomeação são duas mudanças: `cents` removido e `amount` acrescentado. Remover é
permitido sob `BACKWARD`; acrescentar um campo **sem valor padrão** não é, porque um leitor no
esquema novo não consegue preencher `amount` a partir de uma venda escrita antes de ele existir. O
registro disse isso antes de uma única mensagem ser escrita, e essa é a diferença entre esta
execução e a segunda-feira do começo da lição.

Se um campo realmente precisa ser renomeado, há dois jeitos honestos. Um é o alias da seção sobre
Avro, com um valor padrão no nome novo, o que é uma mudança nos **dois** esquemas e uma ordem de
atualização, como explica a próxima seção. O outro é um campo novo ao lado do antigo, escrito pelos
produtores por um tempo e lido pelos consumidores quando estiverem prontos, com o antigo removido
só quando ninguém mais o lê. Mais lento, e nunca quebra ninguém.
