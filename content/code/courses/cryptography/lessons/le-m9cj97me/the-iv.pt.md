---
title: O vetor de inicialização, e por que ele muda toda vez
version: 1
---

**Cifrar com uma chave fixa, um vetor fixo e um texto claro fixo dá um texto cifrado fixo.** Parece
inofensivo e não é: significa que um observador consegue perceber quando a mesma mensagem é enviada
duas vezes, sem decifrar nenhuma das duas. O vetor de inicialização existe para quebrar isso, e só
funciona se for diferente a cada vez.

## A mesma carta, três vezes

Aqui está a carta de encaminhamento cifrada três vezes com a mesma chave: duas vezes com o vetor de
`iv-a.hex`, uma vez com o vetor de `iv-b.hex`. A impressão digital de cada texto cifrado (um hash
SHA-256, assunto da aula 4) basta para compará-los:

```
ana@lab:~/lab$ for iv in iv-a iv-a iv-b; do openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/$iv.hex) -in data/referral.txt | sha256sum; done
a7b407d99a56b97554234ebc20be68db5ebdd9a35e1e0fe6a992664ba245ba64  -
a7b407d99a56b97554234ebc20be68db5ebdd9a35e1e0fe6a992664ba245ba64  -
3b88e135a7ac10ac7a0137ad9801623d89766aaf62ca9159e8acd3067faa4c43  -
```

Os dois primeiros são idênticos. Quem guardasse ou observasse as cartas cifradas da Vereda
descobriria que duas delas são a mesma carta, e com campos como um código de diagnóstico ou uma
resposta sim ou não, "igual àquela outra" muitas vezes é o segredo inteiro. O terceiro não tem
relação com os dois primeiros, embora a carta e a chave não tenham mudado. **É para isso que serve
um vetor: o mesmo texto claro sob a mesma chave nunca produz o mesmo texto cifrado duas vezes.**

## Não é secreto, mas nunca se repete

O vetor **não é segredo**. A decifragem precisa dele, então ele viaja com o texto cifrado,
geralmente como seus primeiros dezesseis bytes, e qualquer um pode lê-lo. O que ele precisa ser
depende do modo:

| modo | nome usado | o que precisa ser |
|---|---|---|
| CBC | IV | **imprevisível**: aleatório, sorteado de novo para cada mensagem |
| CTR | nonce ou contador inicial | **único** para a chave: nunca o mesmo valor duas vezes |
| GCM | nonce, 12 bytes | **único** para a chave, e uma repetição é pior que no CTR |

A diferença entre *imprevisível* e *único* é real. Um vetor CBC que alguém de fora consegue
adivinhar antes de a mensagem ser enviada, por exemplo o último bloco da mensagem anterior,
permitiu ao ataque BEAST contra o TLS 1.0 descobrir texto claro em 2011. Esse é um dos motivos de
o TLS 1.1 ter passado a usar um vetor aleatório explícito por registro. Um nonce de CTR ou GCM, por
outro lado, pode ser um simples contador, 1, 2, 3, desde que nunca se repita sob a mesma chave. O
TLS 1.3 monta o nonce de cada registro a partir de um número de sequência exatamente por isso: um
contador não se repete enquanto a conexão durar.

## Como um sistema real escolhe um

Neste laboratório os vetores são arquivos com valores fixos, para que as transcrições saiam iguais
para você. **Um programa real nunca escreve um vetor à mão.** Ele pede um vetor novo ao gerador de
números aleatórios do sistema operacional no momento em que cifra, por meio de `os.urandom`,
`crypto/rand`, `SecureRandom` ou `openssl rand`, e o guarda ao lado do texto cifrado:

```sh
iv=$(openssl rand -hex 16)
openssl enc -aes-256-cbc -K "$key" -iv "$iv" -in letter.txt -out letter.enc
printf '%s' "$iv" > letter.enc.iv
```

Dois limites práticos decorrem da tabela:

- **Um nonce GCM aleatório de 12 bytes pode colidir por acaso** depois de muitíssimas mensagens sob
  uma mesma chave. A NIST SP 800-38D limita uma chave a 2³² mensagens com nonces aleatórios; depois
  disso, a chave é trocada. Um contador não tem esse limite, mas exige que o contador sobreviva a
  reinicializações, e é aí que os sistemas costumam falhar (aula 17).
- **A função aleatória comum da linguagem não serve para gerar vetores.** `random.random()` em
  Python e `Math.random()` em JavaScript são previsíveis por projeto: foram feitas para repetir uma
  simulação, não para surpreender ninguém. Só o gerador criptográfico serve.

A maioria das bibliotecas elimina a escolha. As interfaces modernas da `cryptography` do Python,
do `crypto/cipher` do Go e da libsodium ou geram o nonce por você ou dão a ele um nome tão
destacado que passar uma constante parece errado. Prefira a interface que elimina a decisão.
