---
title: Gatling, de um zip
version: 1
---

O Gatling foi escrito em Scala, e os testes dele também eram escritos em Scala no começo, então por
anos "Gatling" e "uma DSL em Scala" queriam dizer a mesma coisa. **Hoje a mesma DSL existe em Java,
Kotlin, Scala e JavaScript**, e o pacote que você baixa vem preparado para Java. Os testes
continuam sendo código, como os do k6 na aula 5, então moram no repositório e passam por revisão; o
que muda é a linguagem, e a linguagem muitas vezes é o motivo de um time escolher a ferramenta. Um
time que escreve os seus serviços em Java ou Kotlin escreve os testes de carga na mesma linguagem,
com o mesmo editor e o mesmo build.

## Um zip

O Gatling é publicado no Maven Central como um pacote: um pequeno projeto Maven com um wrapper,
`mvnw`, e todas as bibliotecas de que precisa dentro. No shell da VM:

```sh
cd ~
curl -fsSLO https://repo.maven.apache.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/3.15.1/gatling-charts-highcharts-bundle-3.15.1-bundle.zip
unzip -q gatling-charts-highcharts-bundle-3.15.1-bundle.zip -d ~
```

A máquina das transcrições descompactou o mesmo arquivo do mesmo jeito quando foi montada. Ele
precisa do JDK da aula 1, porque o Gatling compila uma simulação antes de rodá-la. Por dentro, o
pacote é um projeto Maven comum:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ls; ls src/test/java/*
README.md
mvnw
mvnw.cmd
pom.xml
src
src/test/java/boxoffice:
BoxOfficeSimulation.java

src/test/java/example:
BasicSimulation.java
```

**`src/test/java/` é onde ficam as simulações.** O exemplo que vem no pacote, `BasicSimulation.java`,
manda as requisições para um host na internet, então falha numa máquina sem rede. A simulação abaixo
pergunta à bilheteria.

## Uma simulação da bilheteria

Crie a pasta do pacote dela e abra o arquivo:

```sh
cd ~/gatling-charts-highcharts-bundle-3.15.1
mkdir -p src/test/java/boxoffice && nano src/test/java/boxoffice/BoxOfficeSimulation.java
```

É a mesma jornada do script da aula 5, escrita no vocabulário do Gatling: olhar um espetáculo,
pensar, reservar um assento.

```schooling-example
{"language": "java", "file": "BoxOfficeSimulation.java", "parts": [{"code": "// gatling-charts-highcharts-bundle-3.15.1/src/test/java/boxoffice/BoxOfficeSimulation.java\npackage boxoffice;\n\nimport static io.gatling.javaapi.core.CoreDsl.*;\nimport static io.gatling.javaapi.http.HttpDsl.*;\n\nimport io.gatling.javaapi.core.*;\nimport io.gatling.javaapi.http.*;\nimport java.util.Iterator;\nimport java.util.Map;\nimport java.util.concurrent.ThreadLocalRandom;\nimport java.util.stream.Stream;\n", "note": "A primeira linha diz onde o arquivo fica: dentro do pacote, em `src/test/java/`, numa pasta de pacote chamada `boxoffice`. Os dois imports estáticos trazem a DSL Java do Gatling, o vocabulário de `scenario`, `exec`, `http` e o resto, e por isso o código abaixo se lê quase como uma descrição do teste."}, {"code": "public class BoxOfficeSimulation extends Simulation {\n\n  HttpProtocolBuilder protocol = http\n      .baseUrl(\"http://127.0.0.1:8000\")\n      .contentTypeHeader(\"application/json\");\n", "note": "Uma simulação é uma classe que estende `Simulation`. O protocolo é definido uma vez para todas as requisições: o endereço base e o cabeçalho que diz que os corpos são JSON."}, {"code": "  Iterator<Map<String, Object>> orders = Stream.generate(() -> Map.<String, Object>of(\n      \"show\", 981 + ThreadLocalRandom.current().nextInt(20),\n      \"seat\", 1 + ThreadLocalRandom.current().nextInt(300))).iterator();\n", "note": "Um feeder entrega a cada usuário virtual um registro de valores. Este nunca acaba: cada registro é um espetáculo sorteado entre os vinte à venda, de 981 a 1000, e um assento de 1 a 300. Um arquivo CSV de valores reais é o outro feeder comum, `csv(\"orders.csv\").random()`."}, {"code": "  ScenarioBuilder visitor = scenario(\"visitor\")\n      .feed(orders)\n      .exec(http(\"show\").get(\"/shows/#{show}\")\n          .check(status().in(200), jmesPath(\"left\").ofInt().exists()))\n      .pause(1, 3)\n      .exec(http(\"booking\").post(\"/bookings\")\n          .body(StringBody(\"{\\\"show_id\\\": #{show}, \\\"seat\\\": #{seat}, \\\"customer\\\": \\\"gatling\\\"}\"))\n          .check(status().in(201, 409)));\n", "note": "O cenário é a jornada de um visitante, como uma corrente. `#{show}` é trocado pelo valor que o feeder deu a esse usuário. O primeiro check aceita só um 200 e o segundo pede um campo `left` com um número; a pausa entre as duas requisições é o tempo de reflexão, de um a três segundos. A reserva aceita 201 e 409, então um assento já ocupado é a bilheteria respondendo certo e não conta como KO."}, {"code": "  {\n    setUp(visitor.injectOpen(\n            rampUsersPerSec(1).to(3).during(5),\n            constantUsersPerSec(3).during(15)))\n        .protocols(protocol)\n        .assertions(\n            details(\"show\").responseTime().percentile(95.0).lt(Integer.getInteger(\"p95\", 200)),\n            global().failedRequests().percent().lt(1.0));\n  }\n}", "note": "O perfil de injeção é um modelo aberto: `rampUsersPerSec` começa novos usuários a uma taxa que sobe de 1 para 3 por segundo em 5 segundos, e `constantUsersPerSec` mantém 3 por segundo por mais 15. Um usuário do Gatling roda o cenário uma vez e vai embora. As asserções são o requisito da aula 1 para `GET /shows/{id}` e uma taxa de erro abaixo de 1%; uma asserção ultrapassada reprova o build do Maven. `Integer.getInteger` lê `-Dp95=` da linha de comando, com 200 quando não é dado."}]}
```

**Um usuário do Gatling é um visitante que chega, faz a jornada uma vez e vai embora.** Essa é a
diferença para um usuário virtual do k6, que repete enquanto o cenário durar. Então
`constantUsersPerSec(3)` são três chegadas por segundo, faça a bilheteria o que fizer com elas: um
modelo aberto, o mesmo do executor por taxa de chegada da aula 5. `injectClosed` é a outra família,
com `constantConcurrentUsers(10)` mantendo dez usuários dentro do sistema ao mesmo tempo, um novo
começando a cada um que sai. As duas famílias não se misturam num mesmo perfil de injeção, porque
respondem a perguntas diferentes.
