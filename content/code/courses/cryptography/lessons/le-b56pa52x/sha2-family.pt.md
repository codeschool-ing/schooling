---
title: As famílias, e quais estão em vigor
version: 1
---

**Quatro famílias de funções de hash estão em uso diário, e só duas delas servem para segurança
hoje: SHA-2 e SHA-3.** MD5 e SHA-1 continuam instalados em toda parte e continuam sendo calculados
todo dia, e é por isso que eles aparecem onde não deveriam. A carta do laboratório, passada por
cada um:

```
ana@lab:~/lab$ for h in md5 sha1 sha256 sha512 sha3-256; do printf "%-9s %s\n" $h $(openssl dgst -$h -r data/referral.txt | cut -d" " -f1); done
md5       332f92433f21aa59ed87b03193c49e82
sha1      88fd3a934445ac8893896ddc006ec0c41f275248
sha256    7c55ba550e02c3e33d50f2e4627f5e855b6cc9692e91eb72d15e5905f32abc4c
sha512    36bbfbbcda296d46d3c4ce9e9c090cb768262aec6727bf7e73a8419eab4b3adf0b032aee4917739e455bc5e518a48be59eff6ced89a2579a307fefa3da435a0c
sha3-256  c99600ac85b5605d9d8e78d0319c3fdafa11b09bfa150abe70263a942a020a71
```

O tamanho do resumo é a primeira coisa que os diferencia:

```
ana@lab:~/lab$ for h in md5 sha1 sha256 sha512 sha3-256; do printf "%-9s %3s bits\n" $h $(( $(openssl dgst -$h -r data/referral.txt | cut -d" " -f1 | tr -d "\n" | wc -c) * 4 )); done
md5       128 bits
sha1      160 bits
sha256    256 bits
sha512    512 bits
sha3-256  256 bits
```

## As quatro famílias

| família | ano | resumo | situação |
|---|---|---|---|
| **MD5** | 1992 | 128 bits | quebrado para colisões desde 2004; nunca para segurança |
| **SHA-1** | 1995 | 160 bits | quebrado para colisões desde 2017; sendo aposentado em toda parte |
| **SHA-2** (SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/256) | 2001 | 224 a 512 bits | **em vigor**; o SHA-256 é o padrão em quase todo lugar |
| **SHA-3** (SHA3-256, SHA3-512, SHAKE) | 2015 | 224 a 512 bits | **em vigor**; um projeto diferente, mantido como reserva |

O SHA-2 e o SHA-1 compartilham uma construção interna, chamada Merkle–Damgård: a entrada é
processada em blocos, cada um misturado num estado corrente, e o estado final é o resumo. Quando o
SHA-1 mostrou fraquezas em 2005, ninguém podia garantir que o SHA-2 não iria atrás, então o NIST
fez um concurso público por algo construído de outro jeito. O Keccak venceu e virou o SHA-3 em
2015, com uma construção *esponja* que não compartilha nada com o SHA-2. O SHA-2 resistiu desde
então, então o SHA-3 não é um substituto, mas um estepe: se o SHA-2 cair um dia, o próximo padrão
já está nas bibliotecas.

Fora do NIST, o **BLAKE2** e o **BLAKE3** são hashes modernos e rápidos, usados dentro do WireGuard,
do Argon2 (aula 5) e de muitas ferramentas de sincronização de arquivos. São escolhas sólidas onde
nenhum padrão exige SHA-2.

## Uma propriedade do SHA-256 que importa depois

Como o SHA-256 e o SHA-512 entregam todo o seu estado interno, quem conhece o resumo de uma
mensagem e o tamanho dela consegue calcular o resumo dessa mensagem **com mais bytes acrescentados
no fim**, sem conhecer a mensagem. Essa é a *propriedade de extensão de comprimento*. Ela não quebra
nenhuma das três promessas da seção anterior, e é inofensiva para checksums e assinaturas. Ela
importa num mau uso específico: montar uma verificação como `SHA-256(segredo + mensagem)`, em que
alguém poderia estender a mensagem e produzir uma verificação válida sem o segredo.

O SHA-512/256 (o SHA-512 com a saída truncada), o SHA-3 e o BLAKE2 não têm essa propriedade. Mas a
resposta de verdade não é escolher um hash que a evite: é nunca montar uma verificação com chave à
mão, e usar o **HMAC**, que a aula 6 constrói e que é seguro com qualquer um desses hashes.

## Que nome digitar

Para qualquer coisa nova, `sha256` é a resposta, a menos que um padrão diga outra coisa: `sha256sum`
na linha de comando, `hashlib.sha256` no Python, `crypto/sha256` no Go. Use SHA-384 ou SHA-512 onde
um perfil pedir 192 ou 256 bits de segurança, tipicamente ao lado de P-384 ou AES-256 em perfis de
governo. **MD5 e SHA-1 servem para ler dados antigos e para mais nada.**
