---
title: Passwords, kept as bcrypt and checked once
version: 1
---

The common picture of a password store is a table of encrypted passwords, which the server decrypts
to compare with what was typed. Anything the server can decrypt, whoever copies its data and its key
can decrypt too. A server never needs to read a password back. It only needs to check one, so it
keeps a **hash**: the output of a one-way function, from which the password cannot be computed.

Not any hash. SHA-256 was designed to be cheap, and cheap is what somebody guessing passwords against
a stolen table wants: every guess costs them one hash. A **password hash** is expensive on purpose,
and **bcrypt** is the one Spring Security uses by default. These are the two stored in
`SecurityConfig`:

```
{bcrypt}$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG
{bcrypt}$2a$10$IhwPr4UgX7fq7bh90QHtOeHgfrzp1Ut63qywnXNfc3YgBAKgO76hS
```

Each one carries everything needed to check a password against it, in five pieces:

| piece | in ana's | what it is |
|---|---|---|
| `{bcrypt}` | `{bcrypt}` | Spring's label, not bcrypt's: which encoder checks this hash |
| `$2a$` | `$2a$` | the version of bcrypt |
| `10$` | `10$` | the **cost**: 2¹⁰ rounds of bcrypt's expensive step; 11 doubles the time |
| 22 characters | `ZGOqa4SybKybYWez.kObuO` | the **salt**, random for every hash |
| 31 characters | `lRJidwtH0M8N11oKrIWVxl4mA422MiG` | the hash of the salt and the password |

## Making a hash

The two hashes came from a short program. It sits in your home directory rather than in the
project, because it is a tool you run once and not part of the bookshop. Create
`~/HashPassword.java`:

```java
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class HashPassword {
    public static void main(String[] args) {
        BCryptPasswordEncoder bcrypt = new BCryptPasswordEncoder();
        String hash = bcrypt.encode(args[0]);
        System.out.println(hash);
        System.out.println("matches its own hash: " + bcrypt.matches(args[0], hash));
        if (args.length > 1) {
            System.out.println("matches the hash given: " + bcrypt.matches(args[0], args[1]));
        }
    }
}
```

It needs `spring-security-crypto` and the logging library that jar writes through. Both are already
in `~/.m2`, and the dependency plugin of lesson 1 can write the project's whole class path to a file,
which `java` then reads. Run the program twice with the same password, and the second time give it
the hash stored for ana:

```
ana@vm:~$ PENDING hash
```

**The same password gave two different hashes, and each one checks.** The salt differs, and the salt
is in the hash, so `matches` reads it back out and hashes the candidate with it. Ana's stored hash,
made on another day with a third salt, checks too. The salt is what makes a precomputed table of
common passwords useless, and what stops two users who chose the same password from having the same
hash, which would tell anybody reading the table that they had.

A password typed on the command line lands in your shell's history. That is acceptable for the
bookshop's two passwords, which this lesson prints anyway; for a real one, read it with
`System.console().readPassword()`, which does not echo it either.

The prefix is the other half. `PasswordEncoderFactories.createDelegatingPasswordEncoder()` builds an
encoder that reads `{bcrypt}`, `{argon2}`, `{pbkdf2}` and a few more, and passes each hash to the
encoder its prefix names. **The stored string says how it was made**, so a system can move to a newer
algorithm for new passwords while every old hash keeps working until its owner next signs in.

## Slow on purpose, and therefore checked once

**HTTP Basic** sends the user name and the password in an `Authorization` header on every request,
in base64, which is an encoding and not encryption: anybody who sees the request reads the password.
Basic is acceptable only over HTTPS, and this course's bookshop answers plain HTTP on `localhost`,
where nothing crosses a network.

It would also cost a bcrypt check on every request. Here is that cost, measured: five requests for a
token, which run bcrypt, and then five requests carrying a token, which do not:

```
ana@vm:~$ PENDING timing
```

The printed numbers are seconds per request, and they vary from run to run. The ones that run bcrypt
are the slow ones, and that slowness is the protection.
So the bookshop asks for the password once, at `/auth/token`, and answers with a token that every
later request carries instead:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A sequence between ana's client and the bookshop. First, POST /auth/token with HTTP Basic: the server checks the password with bcrypt and answers with a token. Then each request carries the token as a bearer header, and the server checks its signature and expiry, with no password involved. This repeats until the token expires.\"><defs><marker id=\"sq-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"70\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana's client</text><rect x=\"480\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the bookshop</text><line x1=\"150\" y1=\"48\" x2=\"150\" y2=\"330\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"560\" y1=\"48\" x2=\"560\" y2=\"330\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"30\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">once</text><path d=\"M 150 92 L 558 92\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sq-ah)\"></path><text x=\"355.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST /auth/token</text><text x=\"355.0\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Authorization: Basic YW5h…</text><rect x=\"570\" y=\"96\" width=\"140\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bcrypt: slow on purpose</text><path d=\"M 560 140 L 152 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sq-ah)\"></path><text x=\"355.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {&quot;accessToken&quot;:&quot;eyJ…&quot;}</text><path d=\"M 150 200 L 558 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sq-ah)\"></path><text x=\"355.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /orders/1</text><text x=\"355.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Authorization: Bearer eyJ…</text><rect x=\"570\" y=\"204\" width=\"140\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signature and exp: fast</text><path d=\"M 560 244 L 152 244\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sq-ah)\"></path><text x=\"355.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><path d=\"M 150 270 L 558 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sq-ah)\"></path><text x=\"355.0\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST /orders</text><text x=\"355.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Authorization: Bearer eyJ…</text><rect x=\"570\" y=\"274\" width=\"140\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"289\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signature and exp: fast</text><path d=\"M 560 314 L 152 314\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sq-ah)\"></path><text x=\"355.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201</text><path d=\"M 128 180 L 118 180 L 118 316 L 128 316\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"108\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">every request, until exp</text></svg>", "caption": "The password crosses the network once, to obtain a token. Every request after that carries the token, which the server checks without the password and without looking anything up."}
```

A wrong password gets 401 and the right one gets the token:

```
ana@vm:~$ PENDING wrong-password
```

The users here live in memory, in `SecurityConfig`, which is enough for two accounts and wrong for a
shop. A real one keeps them in a table and gives Spring Security a `UserDetailsService` that reads
it; `JdbcUserDetailsManager` is the ready-made one. The checking does not change: a stored hash with
its prefix, and the delegating encoder.
