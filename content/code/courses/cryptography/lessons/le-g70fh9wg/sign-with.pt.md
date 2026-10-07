---
title: Para provar autoria, assine com a sua chave privada
version: 1
---

**Uma assinatura é feita com a chave privada de quem assina e verificada com a chave pública de
quem assina.** Só quem tem a chave privada poderia tê-la produzido, e qualquer um que tenha a chave
pública consegue verificá-la. Esse é o segundo trabalho, e ele usa o par ao contrário da seção
anterior: a chave secreta agora fica do lado de quem envia.

## A Ana assina o encaminhamento

A clínica da Ana manda encaminhamentos para a Vereda, e a Vereda quer saber se um encaminhamento
veio mesmo da Ana e não foi alterado no caminho. A Ana assina a carta com a chave privada Ed25519
dela:

```
ana@lab:~/lab$ openssl pkeyutl -sign -rawin -inkey keys/ed25519-ana.key -in data/referral.txt -out referral.sig
ana@lab:~/lab$ od -An -tx1 referral.sig
 71 23 41 e1 5e 79 68 83 2b 55 e1 59 a6 58 0a b6
 81 31 38 e8 77 b5 eb 8d b0 e8 63 fb 58 f3 00 13
 de b0 6f 7d 4e 5c 63 7c 3d 06 9a 12 62 c3 f9 a7
 65 dd cc 1b 4a 8f 73 d5 ed dc 3a 11 8c 51 5e 08
```

A assinatura tem 64 bytes, o tamanho fixo da Ed25519 que a aula 2 mediu. A Ed25519 é
determinística, então assinar a mesma carta de novo dá exatamente esses bytes; é por isso que a
transcrição é igual na sua máquina.

A Vereda a verifica com a chave **pública** da Ana, que obteve antes por um canal em que confia:

```
ana@lab:~/lab$ openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-ana.pub -in data/referral.txt -sigfile referral.sig
Signature Verified Successfully
```

## O que uma assinatura pega

A assinatura cobre cada byte da carta. Alguém muda o número de sessões de oito para doze e mantém
a assinatura da Ana:

```
ana@lab:~/lab$ sed "s/Eight sessions/Twelve sessions/" data/referral.txt > altered.txt
ana@lab:~/lab$ openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-ana.pub -in altered.txt -sigfile referral.sig
Signature Verification Failure
```

E a carta certa, verificada com a chave pública de outra pessoa, também falha, porque não foi a
chave do Bruno que fez esta assinatura:

```
ana@lab:~/lab$ openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-bruno.pub -in data/referral.txt -sigfile referral.sig
Signature Verification Failure
```

Essas duas falhas são as duas garantias que uma assinatura dá:

- **integridade**: a carta é, byte a byte, a que foi assinada;
- **autenticidade**: ela foi assinada por quem tem a chave privada correspondente à chave pública
  usada na verificação.

Uma terceira decorre da segunda, e é o que diferencia assinaturas das verificações com chave
compartilhada da aula 6: o **não repúdio**. Só a Ana tem a chave privada dela, então a Ana não pode
alegar depois que a própria Vereda produziu a assinatura. Com uma chave que os dois lados
compartilham, qualquer um dos dois poderia ter produzido.

## O que uma assinatura não faz

Olhe de novo a carta assinada: ela é o `data/referral.txt`, inalterado e legível. **Assinar não
esconde nada.** A assinatura viaja ao lado da mensagem, e a mensagem continua tão legível quanto
era. Um e-mail assinado, um pacote de software assinado e um certificado assinado são todos
públicos; a assinatura diz quem responde por eles, não quem pode lê-los.

E a garantia é tão boa quanto a chave pública usada para verificar. Se a Vereda tivesse recebido
a "chave pública da Ana" de um atacante, ela teria verificado as assinaturas do atacante e as
aceitado. Qual chave pública pertence a quem é a pergunta que os certificados respondem, nas aulas
8 e 9.
