---
title: Compare and set
version: 1
---

Two clients that read a value, change it and write it back have the race lesson 8 met with counters.
`incr` settles it for numbers. For any other value, Memcached gives each item a **CAS token**, a number
that changes every time the item is written, and `gets` returns it as the last field of the `VALUE`
line:

```
ana@web:~$ printf 'set stock:2 0 0 1\r\n4\r\ngets stock:2\r\n' | nc -q1 127.0.0.1 11211
STORED
VALUE stock:2 0 1 6
4
END
```

The value is 4 and its token is 6. Call it the stock of book 2; a real shop keeps stock in its
database, and here it only stands for any value two clients both want to change. A client selling one
copy writes 3 with `cas`, naming the token it read, and **the write succeeds only if the token is still
the one it read**, which means nobody wrote the item in between:

```
ana@web:~$ t=$(printf 'gets stock:2\r\n' | nc -q1 127.0.0.1 11211 | awk 'NR==1{print $5}'); echo "token $t"; printf "cas stock:2 0 0 1 $t\r\n3\r\n" | nc -q1 127.0.0.1 11211; printf "cas stock:2 0 0 1 $t\r\n3\r\n" | nc -q1 127.0.0.1 11211
token 6
STORED
EXISTS
ana@web:~$ printf 'get stock:2\r\n' | nc -q1 127.0.0.1 11211
VALUE stock:2 0 1
3
END
```

The first `cas` stored 3, and storing changed the token. The second used the same old token, as a
second client that had read the stock at the same moment would, and got `EXISTS`: somebody wrote first.
That client reads again, finds 3, and writes 2. **Nothing was locked and no sale was lost**; the client
that lost the race did its work twice.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 320\" role=\"img\" aria-label=\"Three columns: client A, Memcached and client B. 1 and 2: both clients read the value 4 with token 6. 3: A writes 3 naming token 6 and is told STORED, and the token changes. 4: B writes 3 naming token 6 and is told EXISTS. 5: B reads again and gets 3 with the new token. 6: B writes 2 with the new token and is told STORED.\"><defs><marker id=\"fcas-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client A</text><rect x=\"280\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">memcached</text><rect x=\"520\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client B</text><line x1=\"110\" y1=\"44\" x2=\"110\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"44\" x2=\"350\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"590\" y1=\"44\" x2=\"590\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"75\" x2=\"113\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"230.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1. 4, token 6</text><line x1=\"350\" y1=\"110\" x2=\"587\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2. 4, token 6</text><line x1=\"110\" y1=\"150\" x2=\"347\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"230.0\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3. cas 3 with 6: STORED</text><line x1=\"590\" y1=\"190\" x2=\"353\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4. cas 3 with 6: EXISTS</text><line x1=\"350\" y1=\"230\" x2=\"587\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5. 3, new token</text><line x1=\"590\" y1=\"270\" x2=\"353\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6. cas 2 with it: STORED</text><text x=\"350\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the token changed at step 3</text></svg>", "caption": "Both clients read the same token. The first write changes it, so the second write is refused and that client starts again from a fresh read."}
```

`cas` is optimistic. It costs nothing when there is no conflict and one retry when there is, which
suits a value two clients rarely write at the same moment. A value everybody writes all the time, a
page-view counter for one, belongs in `incr`, which never has to retry.
