---
title: MongoDB, a show as a document
version: 1
---

MongoDB stores **documents** in **collections**, inside a database. A document is a JSON object,
kept in a binary form called BSON that adds types JSON lacks, such as dates. Lesson 4's show page is
one document.

The data first. This script, saved as `shows.js`, builds a hundred show documents in a loop and
inserts them in one call:

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

Each show's venue is one of three, embedded with its city, and each has two artists and one price,
all inside the document. `db` is the database the shell is connected to.

Then the server, with a gigabyte of memory at most; the file copied into the container; and
`mongosh`, MongoDB's shell, running it against a database called `tickets`, which MongoDB creates on
first use:

```
ana@lab:~/tickets$ docker run -d --name mongo --memory 1g mongo:8.0.32
d67b3b5fc16f50698e8e322c5e4a51a9bac1adee4f2e72954313565b2cb5266e
ana@lab:~/tickets$ docker cp shows.js mongo:/tmp/shows.js
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets /tmp/shows.js
inserted 100 shows
```

The long hexadecimal line is the container's id, which Docker prints on every `docker run -d`; yours
is different. MongoDB takes a few seconds to accept connections; if `mongosh` runs before that, it fails to
connect, and running it again a moment later works.

## Asking for one, and asking by a field inside

`findOne` with an `_id` is the page of a show: the whole document, venue, artists and prices, in one
read and with no join:

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

The second query reaches **inside** the document. `"venue.name"` is the path to a field of the
embedded venue, and MongoDB filters on it as on any other field. The second argument is a
**projection**, the fields to return; `_id` comes unless excluded. The date is printed in UTC, so
`21:00` is six in the evening in São Paulo.

## No schema, until you need one

Nothing declared the shape of a show. A document with a misspelt field, `venu` instead of `venue`,
would be inserted without complaint, and would simply never match a query on `venue.name`. That is
the flexible schema of lesson 4, and its cost lands on every program that reads the collection.
MongoDB can enforce a JSON Schema on a collection when you ask it to, which is the usual answer once
a collection matters.
