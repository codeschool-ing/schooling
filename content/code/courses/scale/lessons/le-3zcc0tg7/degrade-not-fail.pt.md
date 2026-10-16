---
title: Menos, em vez de nada
version: 1
---

A bilheteria depende de seis outras coisas: o primário, a réplica, o Redis, o payments, o Collector
e o nginx. Cada uma vai ficar indisponível em algum momento, e com a bilheteria da aula 10 perder
algumas delas ainda quer dizer perder tudo: uma réplica que para faz toda leitura virar `500`, e um
primário que para derruba as leituras junto com as vendas. **Degradação graciosa** (*graceful
degradation*) é a prática de decidir, para cada dependência, o que o sistema faz sem ela, para que uma
falha leve a parte que precisa dela e nada mais.

Decidir é o trabalho. Começa por ordenar o que o sistema faz pelo quanto importa:

| | o que é | sem a sua dependência |
|---|---|---|
| **essencial** | vender um ingresso | recusar com clareza, e nunca cobrar por nada |
| **importante** | mostrar um show e os lugares que sobram | responder de outro lugar, e dizer quão recente é |
| **útil** | limitar o ritmo de cada comprador | deixar passar por um tempo, e registrar |
| **opcional** | rastros, métricas | perder em silêncio; o SDK e o Prometheus já fazem isso |

Depois cada dependência ganha uma decisão, escrita no código em vez de descoberta durante a queda:

- **a réplica** cai: ler do primário, que tem os mesmos dados e só fica mais ocupado;
- **o primário** cai: responder as leituras com o último valor visto, marcado como velho; **pausar as
  vendas**, porque uma venda precisa do único lugar que sabe quais lugares sobram;
- **o Redis** cai: vender sem o limite por comprador, a falha aberta da aula 9;
- **o payments** cai: o disjuntor responde na hora e toda leitura segue, como a aula 9 mostrou.

Duas regras tornam honesta uma resposta degradada. **Dizer que ela está degradada**: uma contagem de
lugares vinda da memória leva a idade, e uma venda pausada diz *pausada*, não *erro*. E **degradar
primeiro o que é caro**: quando falta capacidade à bilheteria, são as recomendações na página de um
show que devem sair, não o botão de comprar. Um sistema que responde tudo devagar numa sobrecarga
escolheu não escolher.
