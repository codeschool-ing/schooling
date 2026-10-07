---
title: O RSA, construído sobre a multiplicação de dois primos
version: 1
---

**A chave privada do RSA são dois números primos grandes, e a chave pública é o produto deles.**
Multiplicar dois primos é instantâneo; recuperá-los a partir do produto, *fatorar*, é um problema
que ninguém sabe resolver para números do tamanho que o RSA usa. Todo o resto do RSA é aritmética
que decorre desse único fato, e ela é pequena o bastante para ser feita à mão uma vez.

## O RSA com números que dá para conferir

O `vcrypt toyrsa` roda o RSA com os primos do exemplo clássico dos livros, 61 e 53, e cifra um
número. Cada linha da conta está nele:

```py
# ~/lab/tools/toyrsa.py
"""vcrypt toyrsa M: RSA with numbers small enough to follow by hand, on the
message M (a number below n). This is textbook RSA, with no padding, which
is NOT how RSA is used; lesson 2 says why."""
import sys

p, q, e = 61, 53, 17
m = int(sys.argv[1])
n, phi = p * q, (p - 1) * (q - 1)
d = pow(e, -1, phi)
print(f"p = {p}, q = {q}         two primes, kept secret")
print(f"n = p*q = {n}           public: the modulus")
print(f"phi = (p-1)(q-1) = {phi}   secret: needs p and q")
print(f"e = {e}                  public exponent")
print(f"d = e^-1 mod phi = {d}   private exponent")
c = pow(m, e, n)
print(f"encrypt m = {m}:  c = m^e mod n = {c}")
print(f"decrypt c = {c}:  m = c^d mod n = {pow(c, d, n)}")
```

Aqui ele cifra o número 65:

```
ana@lab:~/lab$ vcrypt toyrsa 65
p = 61, q = 53         two primes, kept secret
n = p*q = 3233           public: the modulus
phi = (p-1)(q-1) = 3120   secret: needs p and q
e = 17                  public exponent
d = e^-1 mod phi = 2753   private exponent
encrypt m = 65:  c = m^e mod n = 2790
decrypt c = 2790:  m = c^d mod n = 65
```

Leia de cima para baixo:

- os dois primos `p` e `q` são o segredo;
- o produto deles, `n = 3233`, é o **módulo**, e é público;
- `e = 17` é o **expoente público**. A chave pública é o par `(n, e)`;
- `d = 2753` é o **expoente privado**. Calculá-lo exige `phi`, e calcular `phi` exige `p` e `q`. É
  aí que a fatoração entra: quem consegue separar `n` em `p` e `q` consegue calcular `d`;
- cifrar é elevar à potência `e` módulo `n`, e decifrar é elevar à potência `d`. O 65 virou 2790 e
  voltou como 65.

Com `n = 3233`, qualquer um fatora o módulo de cabeça (é 61 × 53), então essa chave não protege
nada. Com uma chave real os mesmos passos valem, e só o tamanho muda.

## Uma chave RSA real

O `rsa-2048.key` do laboratório tem os mesmos campos, cada um um número com centenas de dígitos:

```
ana@lab:~/lab$ openssl pkey -in keys/rsa-2048.key -noout -text | grep -E "^[A-Za-z]"
Private-Key: (2048 bit, 2 primes)
modulus:
publicExponent: 65537 (0x10001)
privateExponent:
prime1:
prime2:
exponent1:
exponent2:
coefficient:
```

`modulus` é o `n`, `privateExponent` é o `d`, e `prime1` e `prime2` são `p` e `q`. Os três
últimos, `exponent1`, `exponent2` e `coefficient`, são valores pré-calculados que deixam a
decifragem umas quatro vezes mais rápida, usando os dois primos separadamente (o teorema chinês do
resto); eles não acrescentam nenhum segredo que os primos já não tivessem. O expoente público é o
mesmo em praticamente toda chave RSA em uso, 65537, escolhido porque deixa a cifragem e a
verificação rápidas. O módulo é a parte pública que importa, e seus primeiros 32 bytes são estes:

```
ana@lab:~/lab$ openssl rsa -pubin -in keys/rsa-2048.pub -noout -modulus | cut -c1-72
Modulus=D9944C6D90C6575AA00FA9CB1016916C04C1F9DDDA586A2BF4EF4C282F1D56FC
```

Um módulo de 2048 bits é um número de 617 dígitos decimais. O maior número do tipo RSA fatorado
publicamente é o RSA-250, de 829 bits, em 2020, depois de cerca de 2.700 anos de tempo de
processador. Essa distância é a margem de segurança, e a última seção desta aula diz quanto dela
manter.

## Por que o RSA real não é o de brinquedo

O brinquedo mostra a aritmética e omite o que torna o RSA seguro de usar. **O RSA cru, como acima,
nunca deve cifrar ou assinar nada real**, por dois motivos que um defensor precisa saber nomear:

- ele é **determinístico**: a mesma mensagem dá sempre o mesmo texto cifrado, então um observador
  consegue testar um palpite, cifrar "sim" com a chave pública e comparar. É o problema do ECB da
  aula 1 de novo;
- ele é **maleável**: multiplicar textos cifrados multiplica os textos claros, então um texto
  cifrado pode ser transformado num outro relacionado sem a chave.

O remédio é o **preenchimento** com aleatoriedade e estrutura antes da aritmética. Para cifrar, o
esquema atual é o **OAEP**, e para assinar, o **PSS**; o preenchimento mais antigo, PKCS#1 v1.5,
ainda está em toda parte nas assinaturas, e ainda é aceitável ali, mas sua forma de cifragem tem
um longo histórico de ataques contra servidores que revelam se o preenchimento era válido. As
bibliotecas aplicam o preenchimento quando você o nomeia, e o hábito seguro é usar uma interface
em que não dê para esquecer.

## Onde o RSA está hoje

O RSA ainda é o algoritmo mais comum em certificados, e todo navegador verifica assinaturas RSA o
dia inteiro. Mas ele vem perdendo terreno. O TLS 1.3 removeu o RSA como forma de *trocar chaves*,
mantendo-o só para assinaturas, por motivos que a aula 7 explica (o sigilo futuro). Projetos novos
preferem curvas elípticas, que dão a mesma força com chaves muito menores, e esse é o assunto da
próxima seção.
