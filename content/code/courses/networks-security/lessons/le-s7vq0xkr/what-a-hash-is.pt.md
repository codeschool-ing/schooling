---
title: Uma impressão digital para qualquer quantidade de dados
version: 1
---

Uma **função de hash criptográfica** transforma qualquer entrada, de um byte a um disco inteiro, num
valor de tamanho fixo, o seu **digest**. O SHA-256, o usado em todo este curso, sempre produz 256 bits,
impressos como 64 dígitos hexadecimais. Duas instruções que diferem em um caractere:

```
ana@laptop:~$ printf "transfer 100 to 4471\n" | sha256sum
b27a1ded929f467f0ca682df32680cff4a8285222ac4b386ddfe12b9ae362bfc  -
ana@laptop:~$ printf "transfer 900 to 4471\n" | sha256sum
c4f9711cc5c2cf98b63f8d91d382be4ea460e81fa1618e555448b2e4980e869e  -
```

Um dígito mudou na mensagem e **nada reconhecível sobrevive no digest**. Isso não é coincidência
dessas duas entradas; é o projeto. E o tamanho não depende da entrada: um milhão de bytes zero e
nada nenhum dão, ambos, 64 dígitos:

```
ana@laptop:~$ head -c 1000000 /dev/zero | sha256sum; printf "" | sha256sum
d29751f2649b32ff572b5e0a9f541ea660a50f94ff0beedfb0b692b924cc8025  -
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  -
```

A última linha é o digest da entrada vazia, `e3b0c442…`, o mesmo em todo computador, o que facilita
reconhecê-lo num log: alguma coisa calculou o hash de um arquivo que estava vazio.

Três propriedades tornam um hash útil para segurança, e cada uma descarta um ataque pelo nome:

| propriedade | significa | descarta |
|---|---|---|
| **resistência à pré-imagem** (*preimage resistance*) | a partir de um digest, não se consegue achar uma entrada que o produza | recuperar uma mensagem a partir da sua impressão digital |
| **resistência à segunda pré-imagem** | dada uma entrada, não se consegue achar outra com o mesmo digest | trocar um arquivo por outro diferente que passa na conferência |
| **resistência a colisões** (*collision resistance*) | não se consegue achar *quaisquer* duas entradas com o mesmo digest | preparar dois documentos de antemão, um para mostrar e outro para usar |

O MD5 e o SHA-1 já foram usados do mesmo jeito, e **colisões foram demonstradas para os dois**. Eles
continuam bons para notar uma corrupção acidental e já não são aceitáveis onde alguém possa estar
tentando enganar a conferência. O SHA-256 e seus irmãos maiores, e o SHA-3, são as escolhas atuais.

**Um hash não tem chave.** Qualquer um pode calcular o digest de qualquer coisa, e é exatamente por
isso que um digest sozinho prova menos do que as pessoas supõem. A próxima seção mostra quanto menos.
