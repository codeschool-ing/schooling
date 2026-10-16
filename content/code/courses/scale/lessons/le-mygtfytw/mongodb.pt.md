---
title: MongoDB, um show como documento
version: 1
---

O MongoDB guarda **documentos** em **coleções**, dentro de um banco. Um documento é um objeto JSON,
guardado numa forma binária chamada BSON que acrescenta tipos que o JSON não tem, como datas. A
página de show da aula 4 é um documento.

Os dados primeiro. Este script, salvo como `shows.js`, monta cem documentos de show num laço e os
insere de uma vez:

```javascript
// shows.js
const venues = ["Arena Sul", "Teatro Ipê", "Clube Norte"];
const shows = [];
for (let n = 1; n <= 100; n++) {
  shows.push({
    _id: `show-${n}`,
    name: `Show ${n}`,
    starts_at: new Date(Date.UTC(2026, 10, 1 + (n % 30), 21)),
    venue: { name: venues[n % 3], city: "São Paulo" },
    artists: [`Artist ${n}`, `Artist ${n + 1}`],
    prices: [{ section: "floor", cents: 10000 + n * 100 }],
  });
}
db.shows.drop();
const result = db.shows.insertMany(shows);
print(`inserted ${Object.keys(result.insertedIds).length} shows`);
```

A casa de cada show é uma de três, embutida com a cidade, e cada um tem dois artistas e um preço,
tudo dentro do documento. `db` é o banco ao qual o shell está conectado.

Depois o servidor, com no máximo um gigabyte de memória; o arquivo copiado para dentro do contêiner;
e o `mongosh`, o shell do MongoDB, rodando-o contra um banco chamado `tickets`, que o MongoDB cria no
primeiro uso:

```
ana@lab:~/tickets$ docker run -d --name mongo --memory 1g mongo:8.0.32
d67b3b5fc16f50698e8e322c5e4a51a9bac1adee4f2e72954313565b2cb5266e
ana@lab:~/tickets$ docker cp shows.js mongo:/tmp/shows.js
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets /tmp/shows.js
inserted 100 shows
```

A linha hexadecimal comprida é o id do contêiner, que o Docker imprime em todo `docker run -d`; o
seu é outro. O MongoDB leva alguns segundos para aceitar conexões; se o `mongosh` rodar antes
disso, ele não consegue conectar, e rodá-lo de novo um instante depois funciona.

## Pedindo um, e pedindo por um campo lá dentro

`findOne` com um `_id` é a página de um show: o documento inteiro, casa, artistas e preços, numa
leitura e sem join:

```
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets --eval 'db.shows.findOne({_id: "show-1"})'
{
  _id: 'show-1',
  name: 'Show 1',
  starts_at: ISODate('2026-11-02T21:00:00.000Z'),
  venue: { name: 'Teatro Ipê', city: 'São Paulo' },
  artists: [ 'Artist 1', 'Artist 2' ],
  prices: [ { section: 'floor', cents: 10100 } ]
}
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets --eval 'db.shows.find({"venue.name": "Teatro Ipê"}, {name: 1, starts_at: 1}).sort({starts_at: 1, _id: 1}).limit(3)'
[
  {
    _id: 'show-1',
    name: 'Show 1',
    starts_at: ISODate('2026-11-02T21:00:00.000Z')
  },
  {
    _id: 'show-31',
    name: 'Show 31',
    starts_at: ISODate('2026-11-02T21:00:00.000Z')
  },
  {
    _id: 'show-61',
    name: 'Show 61',
    starts_at: ISODate('2026-11-02T21:00:00.000Z')
  }
]
```

A segunda consulta alcança **dentro** do documento. `"venue.name"` é o caminho para um campo da casa
embutida, e o MongoDB filtra por ele como por qualquer outro campo. O segundo argumento é uma
**projeção**, os campos a devolver; o `_id` vem a menos que seja excluído. A data é impressa em UTC,
então `21:00` são seis da tarde em São Paulo.

## Sem esquema, até você precisar de um

Nada declarou o formato de um show. Um documento com um campo escrito errado, `venu` em vez de
`venue`, seria inserido sem reclamação, e simplesmente nunca bateria com uma consulta em
`venue.name`. Esse é o esquema flexível da aula 4, e o custo dele cai em todo programa que lê a
coleção. O MongoDB consegue exigir um JSON Schema numa coleção quando você pede, que é a resposta de
costume quando uma coleção passa a importar.
