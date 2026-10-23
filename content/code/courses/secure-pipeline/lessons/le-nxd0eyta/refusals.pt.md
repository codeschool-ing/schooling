---
title: O que a verificação recusa
version: 1
---

Uma checagem que só foi vista passando é uma checagem que ninguém testou. **O valor do `cosign
verify` está no que ele recusa**, e duas recusas importam na prática: uma imagem que ninguém
assinou sob um nome em que você confia, e uma assinatura feita com uma chave em que você não
confia. As duas já estão nesta máquina, porque a primeira seção moveu `main` para uma imagem
própria.

### A tag que se moveu

`main` aponta para a imagem com o label a mais, que ninguém assinou. Pergunte por ela pela tag:

```
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true localhost:5000/linkbox:main; echo "exit status $?"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no signatures found
error during command execution: no signatures found
exit status 10
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true localhost:5000/linkbox:$(git rev-parse --short HEAD) > /dev/null
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5000/linkbox:de3591e --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
```

O `cosign` resolveu `main` para o digest, procurou uma assinatura sobre esse digest, não achou
nenhuma e saiu com status 10. **A assinatura sobre a imagem original não acompanhou a tag**, porque
ela nunca foi sobre a tag. O segundo comando pergunta pela tag do commit, que ainda aponta para o
digest assinado, e passa; uma verificação por tag é uma verificação do digest que a tag nomeia
naquele momento, que é a pergunta que um deploy faz.

É para esse resultado que serviam as regras da tabela da primeira seção. Um deploy que roda `cosign
verify` contra `linkbox:main` antes de cada pull recusa a tag movida na próxima tentativa, seja
quem for que a moveu e por melhor que fosse o acesso dessa pessoa ao registry.

### Uma chave que não é a da CI

Crie um segundo par de chaves, como faria alguém que quisesse ver a própria imagem aceita, e
verifique a assinatura verdadeira contra a chave pública dele:

```
ana@vm:~/linkbox$ mkdir ~/other-key && cd ~/other-key && COSIGN_PASSWORD= cosign generate-key-pair && cd ~/linkbox
Private key written to cosign.key
Public key written to cosign.pub
ana@vm:~/linkbox$ cosign verify --key ~/other-key/cosign.pub --insecure-ignore-tlog=true $REF; echo "exit status $?"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
error during command execution: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
exit status 1
```

A assinatura está lá e é válida, para a outra chave. **`Found: 0, Expected 1` quer dizer que
nenhuma assinatura da imagem foi verificada com a chave dada**, e o status de saída é 1. A mensagem
fala em atestações porque o `cosign` 3 guarda uma assinatura no mesmo formato de envelope que usa
para atestações; a checagem é a mesma de um jeito ou de outro.

Por isso o `cosign.pub` tem de vir de algum lugar em que quem verifica confia, nunca do registry ao
lado da imagem. Quem consegue enviar uma imagem consegue enviar uma chave pública junto com a mesma
facilidade. Neste curso a chave fica em `~/ci/keys`; num time ela é publicada uma vez, num
repositório com revisão protegida, ou fica com o controlador de admissão do cluster, e a seção
sobre SLSA e assinatura sem chave diz o que a substitui de vez.

### O que cada resposta quer dizer

| o que o `cosign verify` informa | o que quer dizer | o que um deploy faz |
|---|---|---|
| a verificação passa | o digest foi assinado por quem tem esta chave | implanta esse digest |
| `no signatures found`, status 10 | ninguém assinou estes bytes, qualquer que seja a tag | recusa |
| `Found: 0, Expected 1`, status 1 | alguém assinou, mas não com esta chave | recusa |

**Toda resposta além da primeira é uma recusa, e um deploy trata todas igual.** Ele não precisa
saber qual das duas deu errado para saber que não deve fazer o pull.

### O que uma assinatura não diz

**Uma assinatura válida diz quem respondeu pela imagem, nunca que a imagem é segura.** A CI assina
o que passou pelos estágios dela. Se a varredura da aula 8 tinha uma lacuna, a imagem assinada tem
a mesma lacuna, e a assinatura a faz parecer mais confiável, não menos vulnerável. Uma assinatura
também não diz o que há dentro da imagem nem como ela foi construída: a imagem pode ter saído de
qualquer commit, em qualquer branch, por qualquer script que o commit trouxesse. Essas são
perguntas sobre os bytes, e a CI também pode respondê-las, como declarações assinadas próprias. As
duas próximas seções fazem a CI assinar toda imagem que envia e anexar essas declarações a ela.
