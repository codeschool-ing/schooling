---
title: O que uma função de hash promete
version: 1
---

**Uma função de hash criptográfica transforma uma entrada de qualquer tamanho numa saída de tamanho
fixo, o *digest* (resumo), e é construída para que ninguém consiga voltar do resumo para a entrada
nem achar duas entradas que compartilhem um resumo.** Ela não tem chave. Qualquer um pode calcular
o hash de qualquer coisa, e é isso que importa: ela é uma impressão digital pública, e a impressão
é útil porque não pode ser forjada.

## Tamanho fixo, entre o que entrar

O SHA-256 sempre devolve 256 bits, 64 dígitos hexadecimais. A carta de 170 bytes, o arquivo de
agendamentos de 512 bytes, a versão de 20.480 bytes e um megabyte de zeros saem todos do mesmo
tamanho:

```
ana@lab:~/lab$ sha256sum data/referral.txt data/slots.dat data/release/portal-2.4.1.tar
7c55ba550e02c3e33d50f2e4627f5e855b6cc9692e91eb72d15e5905f32abc4c  data/referral.txt
5e832af18cbeab6bd7bb6d2931668e0296498d2e5837980aee5e5d49ae3f8750  data/slots.dat
7a3cfae88053ea853e98e2211769a0cf9f605d6f761aff2878059628177a6a3f  data/release/portal-2.4.1.tar
ana@lab:~/lab$ head -c 1000000 /dev/zero | sha256sum
d29751f2649b32ff572b5e0a9f541ea660a50f94ff0beedfb0b692b924cc8025  -
```

É isso que torna um resumo útil como impressão digital: ele cabe numa coluna, num aviso na página
de download ou numa assinatura, qualquer que seja o tamanho do que descreve.

## Uma letra, outra impressão digital

Duas entradas que diferem por uma letra dão resumos sem nenhuma relação:

```
ana@lab:~/lab$ printf 'Eight sessions' | sha256sum
b40d32921f905e70f8414b6d7c06a112852fbbf0cd2856efe91981013a3f54fc  -
ana@lab:~/lab$ printf 'Eight session' | sha256sum
22c197768e113d6dbf8eacd22417f12c7ce5b2f17f5408d23e587896e8384c61  -
```

Não há semelhança parcial a explorar, nenhum resumo "quase igual" para uma entrada "quase igual".
Trocar uma letra por minúscula muda cerca de metade dos 256 bits:

```
ana@lab:~/lab$ vcrypt avalanche 'Eight sessions' 'eight sessions'
    'Eight sessions'  b40d32921f905e70f8414b6d7c06a112852fbbf0cd2856efe91981013a3f54fc
    'eight sessions'  c26b06836dfea0538e1300682b618f3560cc64346e2579b6f98059ca850651c5
132 of 256 bits differ
```

132 de 256 é a cara do acaso, e essa propriedade se chama **efeito avalanche**: uma alteração em
qualquer ponto da entrada se espalha pela saída inteira.

## As três promessas

Um hash criptográfico faz três promessas. Cada uma trata do que um atacante não consegue fazer, e
cada uma protege um uso diferente:

| promessa | o que ninguém consegue fazer | o que quebra se ela falhar |
|---|---|---|
| **resistência à pré-imagem** | dado um resumo, achar alguma entrada que o produza | hashes usados para esconder um valor |
| **resistência à segunda pré-imagem** | dada uma entrada, achar outra com o mesmo resumo | conferir um arquivo conhecido contra o hash publicado |
| **resistência a colisões** | achar duas entradas quaisquer com o mesmo resumo | assinaturas e certificados |

A última é a mais difícil de manter, por um motivo que é pura aritmética. Um resumo de *n* bits tem
2ⁿ valores possíveis. Achar uma pré-imagem leva cerca de 2ⁿ tentativas, mas achar **quaisquer**
duas entradas que colidam leva só cerca de 2ⁿ/² (o *limite do aniversário*: numa sala com 23
pessoas, provavelmente duas fazem aniversário no mesmo dia). Então um hash de 256 bits dá 128 bits
de resistência a colisões, o nível de segurança da tabela da aula 2, e um hash de 128 bits como o
MD5 dava no máximo 64.

## Colisões existem, e essa não é a falha

Uma função de entradas de qualquer tamanho para 256 bits precisa ter colisões: há infinitas
entradas e só 2²⁵⁶ resumos. A promessa não é que colisões não existam. **A promessa é que ninguém
consiga achar uma.** Quando alguém consegue, mais depressa que o limite do aniversário, o hash está
quebrado para todo uso que depende dessa promessa, e foi exatamente isso que aconteceu com o MD5 e
o SHA-1, assunto da seção 04 desta aula.

O que um hash não é: ele **não é cifragem**, porque nada sai de volta dele, e **não é, sozinho, um
jeito de guardar senhas**, porque para entradas curtas e adivinháveis o atacante não precisa
reverter nada, só testar candidatas. A aula 5 trata dessa diferença.
