---
title: O que ela registra, e com que nomes
version: 1
---

Um checkout, e então os spans que o `orders` produziu para ele, com o tipo que cada um recebeu:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/56414d8c2542c07251f5be873161653b | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[] | select($t.processes[.processID].serviceName == "orders") | [.operationName, (.tags[] | select(.key == "span.kind") | .value)] | @tsv'
POST /orders	server
INSERT	client
POST	client
UPDATE	client
```

**Um span `SERVER` e três spans `CLIENT`.** O Flask abriu o span de servidor quando a requisição
chegou; o psycopg abriu um span de cliente por consulta; o `requests` abriu um para a chamada ao
payments. Essa é a forma que a instrumentação automática sempre dá: um span onde uma requisição
entra, e um span onde quer que o serviço chame outra coisa. Os tipos importam para um backend, que
emparelha um span `CLIENT` num serviço com o span `SERVER` que ele causou no seguinte e desenha a
seta entre os dois.

Cada span leva o que a sua biblioteca conseguia ver. O span do banco:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/56414d8c2542c07251f5be873161653b | jq -c '.data[0].spans[] | select(.operationName == "INSERT") | [.tags[] | select(.key | test("^(db|server|net)")) | {(.key): .value}] | add'
{"db.name":"shop","db.statement":"INSERT INTO orders (sku, qty, total_cents, status, traceparent) VALUES (%s, %s, %s, 'pending', %s) RETURNING id","db.system":"postgresql","db.user":"shop","net.peer.name":"postgres","net.peer.port":5432}
```

**A consulta é registrada com os marcadores e não com os valores**: `%s` onde iam o SKU e o total.
A instrumentação registra o comando que o psycopg recebeu, e o psycopg recebeu os valores
separados, que é também o que protege a consulta de injeção. Uma consulta montada colando valores
na string seria registrada com eles, números de cartão e tudo, o que é mais um motivo para nunca
montar uma assim. E a chamada ao payments:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/56414d8c2542c07251f5be873161653b | jq -c '.data[0].spans[] | select(.operationName == "POST") | [.tags[] | select(.key | test("^(http|url|server)")) | {(.key): .value}] | add'
{"http.method":"POST","http.status_code":200,"http.url":"http://payments:8082/charge"}
```

**Esses nomes não são os que a aula 2 usou.** A vitrine, instrumentada à mão, registrou
`http.request.method` e `http.response.status_code`; aqui é `http.method` e `http.url`, e o span
do banco diz `db.statement` e `net.peer.name`. São os nomes **antigos** das mesmas convenções
semânticas, que o OpenTelemetry depois renomeou e declarou estáveis. As bibliotecas de
instrumentação continuam emitindo os antigos por padrão para que os painéis que as pessoas já
construíram não quebrem da noite para o dia, e uma variável de ambiente,
`OTEL_SEMCONV_STABILITY_OPT_IN`, passa um serviço para os nomes novos um domínio de cada vez.

Então a loja, como está, mistura duas gerações de nomes, e uma consulta por `http.request.method`
acha a vitrine e não acha o orders. **Esse é o estado normal de um sistema real** durante uma
migração que leva anos, e vale conferir quais nomes um backend realmente guarda antes de escrever
um painel contra eles.
