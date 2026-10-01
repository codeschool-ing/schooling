---
title: Combinar uma chave em público
version: 1
---

A cifra simétrica precisa que as duas pontas tenham a mesma chave, e a rede é justamente por onde a
chave não pode ser enviada. O **acordo de chaves** (*key agreement*) resolve isso com um par de chaves
de cada lado: cada parte gera uma chave privada e uma chave pública, as duas trocam só as chaves
públicas, e cada uma combina **a sua própria chave privada com a chave pública da outra**. A matemática
faz as duas combinações darem o mesmo resultado, e quem viu só as duas chaves públicas não consegue
calculá-lo.

O algoritmo é o **X25519**, Diffie-Hellman sobre curva elíptica em Curve25519. `laptop` e `app` geram
cada um o seu par e imprimem a metade pública:

```
ana@laptop:~$ openssl genpkey -algorithm X25519 -out ana.key; openssl pkey -in ana.key -pubout -out ana.pub; cat ana.pub
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VuAyEA84o6hHj0QxUHnxfhUd9QBDfqfZ8gk7XhmmzgzLO4Ngg=
-----END PUBLIC KEY-----
ana@app:~$ openssl genpkey -algorithm X25519 -out app.key; openssl pkey -in app.key -pubout -out app.pub; cat app.pub
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VuAyEAXqvs8rPoiR1c5rUiQoemyebaBEzVltV928cFbPRcvCg=
-----END PUBLIC KEY-----
```

As chaves públicas, copiadas de um para o outro, são tudo o que passou entre eles. Cada lado então
deriva o segredo compartilhado a partir da sua própria chave privada e da chave pública do outro, e
mostra um hash dele em vez do segredo em si:

```
ana@laptop:~$ openssl pkeyutl -derive -inkey ana.key -peerkey app.pub | sha256sum
72338c44083582a3ee3985bcc7dc586b4109b1c4618220644dcb13513c29c5a2  -
ana@app:~$ openssl pkeyutl -derive -inkey app.key -peerkey ana.pub | sha256sum
72338c44083582a3ee3985bcc7dc586b4109b1c4618220644dcb13513c29c5a2  -
```

**Os mesmos 32 bytes nas duas máquinas**, e eles nunca viajaram. Esse segredo vira a chave de uma cifra
simétrica como a da seção anterior.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Acordo de chave entre laptop e app. Cada um cria uma chave privada, que nunca sai dele, e uma chave pública. Só as chaves públicas atravessam a rede. O laptop combina sua chave privada com a chave pública de app; app combina a sua chave privada com a chave pública do laptop. Os dois resultados são o mesmo segredo compartilhado, e ele nunca atravessou a rede.\"><defs><marker id=\"ka-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ka-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave privada: fica aqui</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"510\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave privada: fica aqui</text><path d=\"M220 50 L500 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-phosphor)\" marker-start=\"url(#ka-ah-phosphor)\"></path><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ana.pub → ← app.pub</text><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só as chaves públicas atravessam</text><rect x=\"20\" y=\"110\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana.key + app.pub</text><rect x=\"500\" y=\"110\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.key + ana.pub</text><path d=\"M120 66 L120 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-paper-dim)\"></path><path d=\"M600 66 L600 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-paper-dim)\"></path><rect x=\"230\" y=\"176\" width=\"260\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o mesmo segredo compartilhado</text><path d=\"M120 140 L120 191 L230 191\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-phosphor)\"></path><path d=\"M600 140 L600 191 L490 191\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-phosphor)\"></path></svg>", "caption": "O que atravessou a rede basta para conferir o resultado e não basta para calculá-lo."}
```

Duas propriedades dessa troca decidem como ela é usada:

- **Ela não prova nada sobre identidade.** O `laptop` calculou um segredo compartilhado com *quem quer
  que* tenha a chave privada correspondente a `app.pub`. Se alguém tivesse trocado `app.pub` pela sua
  própria no caminho, o `laptop` compartilharia um segredo com essa pessoa, perfeitamente cifrado. Saber
  de quem é a chave pública que você tem é o assunto inteiro das aulas 11 e 12.
- **Pares novos dão sigilo futuro** (*forward secrecy*). Quando os dois lados geram pares de chaves novos
  para cada sessão e os jogam fora depois, roubar uma chave de longo prazo mais tarde não abre gravações
  de sessões antigas. O TLS 1.3 e o WireGuard fazem isso.
