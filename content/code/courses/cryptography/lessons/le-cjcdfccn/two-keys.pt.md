---
title: Uma chave pública e uma chave privada
version: 1
---

**A criptografia assimétrica dá a cada parte duas chaves: uma chave pública, que qualquer um pode
ter, e uma chave privada, que só o dono guarda.** Elas são feitas juntas, como um par, e o que uma
faz a outra desfaz. Isso elimina o problema que a aula 1 deixou aberto: o servidor da Vereda pode
publicar sua chave pública para a internet inteira, e o navegador de um paciente que nunca viu o
servidor ainda assim consegue usá-la.

## Um par é gerado, não escolhido

Um par de chaves é gerado por um programa a partir de bytes aleatórios, num passo só. No OpenSSL o
comando é o `genpkey`, com o nome do algoritmo:

```sh
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out server.key
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out server.key
openssl genpkey -algorithm ED25519 -out signer.key
```

Cada execução dá uma chave diferente, e é justamente essa a ideia, por isso o laboratório não usa
esses comandos. Os pares dele são derivados de rótulos fixos, pelo `drbg.py` da aula 1, para que as
transcrições abaixo saiam iguais na sua máquina. O arquivo que faz isso é o mais longo do
laboratório, e você não precisa acompanhá-lo agora: a parte do RSA é o assunto da próxima seção, e
o resto é uma chamada de biblioteca por algoritmo. O que importa agora é que ele faz a mesma conta
que o `genpkey`, partindo de bytes que qualquer um reconstrói em vez de bytes aleatórios.

```py
# ~/lab/tools/keys.py
"""The lab's key pairs, rebuilt from labels through drbg.py, so that yours are
the ones in the lessons. A real pair comes from `openssl genpkey`, which
draws fresh random bytes every time; this file does the same arithmetic
with bytes anybody can rebuild, which is only acceptable in a lab."""
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec, ed25519, rsa, x25519

import drbg

SMALL_PRIMES = [p for p in range(3, 2000) if all(p % d for d in range(2, int(p ** 0.5) + 1))]


def probable_prime(n: int, label: str) -> bool:
    """Miller-Rabin with 40 rounds, the test every RSA library runs."""
    for p in SMALL_PRIMES:
        if n % p == 0:
            return n == p
    d, s = n - 1, 0
    while d % 2 == 0:
        d, s = d // 2, s + 1
    for i in range(40):
        a = 2 + drbg.integer(f"{label}/witness/{i}", n.bit_length()) % (n - 3)
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True


def prime(label: str, bits: int, e: int = 65537) -> int:
    i = 0
    while True:
        # the top two bits set, so that p*q has all its bits; odd, of course
        c = drbg.integer(f"{label}/{i}", bits) | (3 << (bits - 2)) | 1
        if (c - 1) % e and probable_prime(c, f"{label}/{i}"):
            return c
        i += 1


def rsa_key(label: str, bits: int) -> rsa.RSAPrivateKey:
    e = 65537
    p, q = prime(label + "/p", bits // 2), prime(label + "/q", bits // 2)
    if p < q:
        p, q = q, p
    d = pow(e, -1, (p - 1) * (q - 1))
    return rsa.RSAPrivateNumbers(
        p=p, q=q, d=d, dmp1=d % (p - 1), dmq1=d % (q - 1), iqmp=pow(q, -1, p),
        public_numbers=rsa.RSAPublicNumbers(e, p * q)).private_key()


P256_ORDER = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551


def ec_key(label: str) -> ec.EllipticCurvePrivateKey:
    return ec.derive_private_key(1 + drbg.integer(label, 256) % (P256_ORDER - 1), ec.SECP256R1())


def ed25519_key(label: str) -> ed25519.Ed25519PrivateKey:
    return ed25519.Ed25519PrivateKey.from_private_bytes(drbg.stream(label, 32))


def x25519_key(label: str) -> x25519.X25519PrivateKey:
    return x25519.X25519PrivateKey.from_private_bytes(drbg.stream(label, 32))


def write_pair(key, path):
    """path.key, the private half in PKCS#8; path.pub, the public half."""
    with open(path + ".key", "wb") as f:
        f.write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                  serialization.NoEncryption()))
    with open(path + ".pub", "wb") as f:
        f.write(key.public_key().public_bytes(serialization.Encoding.PEM,
                                              serialization.PublicFormat.SubjectPublicKeyInfo))
```

Um segundo arquivo, curto, grava os pares desta aula em `keys/`:

```py
# ~/lab/tools/pairs.py
"""vcrypt pairs: write lesson 2's key pairs into keys/."""
import keys

keys.write_pair(keys.rsa_key("keys/rsa-2048", 2048), "keys/rsa-2048")
keys.write_pair(keys.rsa_key("keys/rsa-3072", 3072), "keys/rsa-3072")
keys.write_pair(keys.ec_key("keys/p256"), "keys/p256")
for who in ("ana", "bruno"):
    keys.write_pair(keys.ed25519_key("keys/ed25519-" + who), "keys/ed25519-" + who)
    keys.write_pair(keys.x25519_key("keys/x25519-" + who), "keys/x25519-" + who)
```

Salve os dois e rode uma vez. O RSA leva alguns segundos, porque achar um primo de 1.536 bits
significa testar candidatos até um passar:

```sh
cd ~/lab
vcrypt pairs
```

Aqui estão:

```
ana@lab:~/lab$ ls keys/rsa-2048.* keys/p256.* keys/ed25519-ana.*
keys/ed25519-ana.key
keys/ed25519-ana.pub
keys/p256.key
keys/p256.pub
keys/rsa-2048.key
keys/rsa-2048.pub
```

Cada par são dois arquivos. O `.key` é a chave privada e o `.pub` é a pública. Uma chave pública é
curta e pode ser impressa sem perigo:

```
ana@lab:~/lab$ cat keys/ed25519-ana.pub
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAputVssQeGrq75yYKhthuhas/ZiniEYjnFcuBvjmLkmc=
-----END PUBLIC KEY-----
```

Essa é a chave pública Ed25519 inteira da Ana, em PEM: Base64 entre duas linhas marcadoras, que a
aula 11 desmonta. Ela poderia ser colada num e-mail, numa página web ou num commit sem perder nada.

## A chave pública vem da privada

As duas metades não são independentes. **A chave privada contém tudo o que é preciso para calcular
a chave pública**, então o OpenSSL consegue reconstruir o `.pub` só a partir do `.key`:

```
ana@lab:~/lab$ openssl pkey -in keys/ed25519-ana.key -pubout | cmp - keys/ed25519-ana.pub && echo "derived from the private key: identical"
derived from the private key: identical
```

O caminho inverso é impossível, e a área inteira se apoia nessa assimetria. Calcular a chave
pública a partir da privada leva uma fração de segundo. Calcular a privada a partir da pública
exigiria resolver um problema matemático que ninguém sabe resolver em tempo razoável para chaves
do tamanho certo: a fatoração, no RSA, e o logaritmo discreto numa curva, nas curvas elípticas. As
duas próximas seções dizem o que é cada problema, no nível necessário para escolher entre eles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um par de chaves. À esquerda a chave privada, guardada pelo dono. Uma seta com o rótulo fácil, uma fração de segundo, vai até a chave pública à direita, que pode ser publicada. Uma seta tracejada de volta, da pública para a privada, tem o rótulo impossível na prática: fatoração ou logaritmo discreto.\"><defs><marker id=\"pair-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pair-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"60\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chave privada</text><text x=\"130\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ed25519-ana.key</text><rect x=\"490\" y=\"60\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chave pública</text><text x=\"590\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ed25519-ana.pub</text><polyline points=\"232,78 486,78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#pair-ah-phosphor)\"></polyline><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">fácil: uma fração de segundo</text><polyline points=\"488,114 234,114\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#pair-ah-amber)\"></polyline><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">impossível na prática</text><text x=\"360\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fatoração, ou um logaritmo discreto</text><text x=\"130\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fica com o dono</text><text x=\"590\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pode ser publicada</text></svg>", "caption": "A ligação entre as duas metades só corre num sentido."}
```

## O que um arquivo de chave pública diz

Pedido para descrever uma chave pública, o OpenSSL nomeia o algoritmo e imprime a própria chave:

```
ana@lab:~/lab$ openssl pkey -pubin -in keys/ed25519-ana.pub -noout -text
ED25519 Public-Key:
pub:
    a6:eb:55:b2:c4:1e:1a:ba:bb:e7:26:0a:86:d8:6e:
    85:ab:3f:66:29:e2:11:88:e7:15:cb:81:be:39:8b:
    92:67
```

Trinta e dois bytes, e nada mais. Não há nome de dono, nem data, nem domínio. **Uma chave pública,
sozinha, não diz de quem é.** Qualquer um pode gerar um par e afirmar que a metade pública é da
Vereda. Amarrar uma chave a um nome é o trabalho de um certificado, e as aulas 8 e 9 constroem essa
amarração. Até lá, uma chave pública recebida de algum lugar é tão confiável quanto o canal por
onde chegou.

## O que o arquivo da chave privada nunca pode fazer

O `.key` é o único segredo de tudo isso, e a forma de tratá-lo decide tudo:

- **ele nunca sai da máquina que o usa.** A chave privada de um servidor fica no servidor, ou
  melhor ainda num módulo de hardware que assina sem nunca exportá-la (a aula 8 volta a isso);
- **ele só pode ser lido pelo serviço que precisa dele**, o que no Linux significa modo `600` e o
  usuário do próprio serviço;
- **ele nunca é commitado**, colado num chamado ou enviado a um colega "só por um instante". A aula
  17 trata de quantas vezes isso acontece mesmo assim.

Uma chave privada que vazou é substituída, não consertada. O par é descartado, um novo é gerado, e
tudo o que confiava na chave pública antiga é avisado para parar de confiar.
