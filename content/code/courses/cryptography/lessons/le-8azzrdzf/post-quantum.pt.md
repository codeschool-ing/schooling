---
title: Depois do computador quântico: ML-KEM e trocas híbridas
version: 1
---

**Um computador quântico grande o bastante, rodando o algoritmo de Shor, resolveria tanto o problema
da fatoração por trás do RSA quanto o logaritmo discreto por trás do Diffie-Hellman e das curvas
elípticas.** Toda troca de chaves desta aula cairia. Essa máquina ainda não existe, e ninguém sabe
dizer quando existirá. A resposta já está sendo implantada mesmo assim, por causa de uma propriedade
do tráfego gravado.

## Por que isso importa antes de a máquina existir

A seção 04 mostrou que o tráfego gravado continua legível para quem obtiver a chave depois. Um
computador quântico é um jeito de obtê-la. Tráfego gravado hoje e protegido só pela X25519 poderia
ser decifrado no dia em que uma máquina dessas rodar. Isso se chama **"coletar agora, decifrar
depois"** (*harvest now, decrypt later*), e significa que o prazo para dados que precisam continuar
secretos por vinte anos, como prontuários médicos, já chegou. As assinaturas são menos urgentes: uma
assinatura forjada precisa da máquina no momento da falsificação, então há tempo para substituí-las
antes que ela exista.

## ML-KEM, o substituto da troca

Em agosto de 2024, o NIST publicou seus três primeiros padrões pós-quânticos: a **FIPS 203 (ML-KEM)**
para estabelecer chaves, e a **FIPS 204 (ML-DSA)** e a **FIPS 205 (SLH-DSA)** para assinaturas. O
ML-KEM, vindo do projeto Kyber, se apoia num problema sobre reticulados que nenhum algoritmo quântico
conhecido resolve com eficiência.

Ele é um **mecanismo de encapsulamento de chave** (KEM) em vez de uma troca: um lado publica uma
chave pública, o outro a usa para produzir um segredo compartilhado e um texto cifrado que o
carrega, e o primeiro lado recupera o segredo com sua chave privada. O efeito é o mesmo, os dois
lados terminam com um segredo de 32 bytes, e o tamanho desse segredo também. A `cryptography` do
Python tem o ML-KEM-768 na versão que o laboratório fixou, e o `vcrypt kem` cria um par de chaves,
encapsula uma vez e mostra os tamanhos:

```py
# ~/lab/tools/kem.py
"""vcrypt kem: an ML-KEM-768 key pair, one encapsulation, and the sizes.
Encapsulation is randomised, so the secret itself is never printed."""
from cryptography.hazmat.primitives.asymmetric import mlkem

import drbg

k = mlkem.MLKEM768PrivateKey.from_seed_bytes(drbg.stream("keys/mlkem768", 64))
pub = k.public_key()
secret, ciphertext = pub.encapsulate()
print(f"ML-KEM-768 public key      {len(pub.public_bytes_raw()):5} bytes")
print(f"encapsulation (ciphertext) {len(ciphertext):5} bytes")
print(f"shared secret              {len(secret):5} bytes")
print(f"decapsulated secret matches: {'yes' if k.decapsulate(ciphertext) == secret else 'no'}")
```

Todo o resto é maior:

```
ana@lab:~/lab$ vcrypt kem
ML-KEM-768 public key       1184 bytes
encapsulation (ciphertext)  1088 bytes
shared secret                 32 bytes
decapsulated secret matches: yes
```

Compare com a chave pública da X25519, inteira:

```
ana@lab:~/lab$ openssl pkey -pubin -in keys/x25519-ana.pub -noout -text
X25519 Public-Key:
pub:
    49:36:f3:2c:15:64:30:b6:58:5f:07:9e:a2:fd:8f:
    7d:81:2d:4f:9a:1f:15:a4:4d:18:2c:1b:4c:3d:00:
    69:12
```

32 bytes contra 1.184 da chave pública, e 1.088 do que o outro lado devolve. Mensagens maiores são
o principal custo prático da transição.

## Híbrido, porque ninguém aposta num problema só

O ML-KEM é novo, e algoritmos novos já surpreenderam: o SIKE, um dos candidatos do NIST, foi
quebrado em 2022 num computador comum. Então a resposta implantada é **híbrida**: rodar a X25519 e
o ML-KEM-768 juntos e derivar as chaves de sessão dos dois segredos. Um atacante precisa quebrar os
dois, um com um computador quântico e o outro com uma matemática que ninguém tem. No TLS 1.3 esse é
o grupo **X25519MLKEM768**, ligado por padrão nas versões atuais do Chrome, do Firefox e da
Cloudflare, e aceito pelo OpenSSL a partir da versão 3.5. O OpenSSL deste laboratório, 3.0, é
anterior a isso, e é por isso que a captura usa o ML-KEM da biblioteca do Python.

## O que fazer a respeito agora

- **Inventário** de onde a troca de chaves acontece e de qual biblioteca a faz, a mesma lição do MD5
  e do SHA-1 na aula 4. A migração é uma atualização de biblioteca na maioria dos lugares e uma troca
  de hardware em alguns.
- Prefira o grupo **híbrido** onde a sua pilha TLS o oferecer, começando por tudo o que carrega
  dados de vida longa.
- **A criptografia simétrica sobrevive.** O algoritmo de Grover só reduz pela metade o tamanho
  efetivo de uma chave, então o AES-256 mantém 128 bits de força, e o SHA-256 mantém seus usos. Nada
  das aulas 1, 4 ou 5 precisa ser substituído por isso.
- O plano de transição do NIST propõe descontinuar os algoritmos RSA e de curvas elípticas até 2030
  e proibi-los até 2035. Qualquer coisa construída agora ainda estará rodando então.
