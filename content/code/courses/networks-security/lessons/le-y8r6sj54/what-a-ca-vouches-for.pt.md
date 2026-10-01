---
title: Pelo que uma autoridade certificadora responde
version: 1
---

A aula 11 terminou numa lacuna: uma assinatura só prova quem assinou se você já sabe de quem é a chave
pública que tem nas mãos. Duas partes que nunca se encontraram não podem trocar chaves pessoalmente,
e a internet tem bilhões de pares assim. **Uma infraestrutura de chaves públicas** (*public key
infrastructure*, PKI) fecha a lacuna com um terceiro em quem as duas já confiam.

Um **certificado** é uma declaração, assinada por uma **autoridade certificadora** (*certificate
authority*, CA): *esta chave pública pertence a este nome, por este período, para estes fins*. Um
cliente que confia na chave da CA pode conferir a assinatura e, assim, confiar no vínculo, sem nunca
ter encontrado o servidor.

A aula 6 de `networks` leu certificados como um cliente lê e os quebrou de quatro jeitos. Esta aula
está do outro lado do balcão: **operar** a autoridade, para os nomes da própria empresa, e decidir o
que ela vai e o que não vai assinar.

Aquilo pelo que uma CA de fato responde é mais estreito do que as pessoas supõem:

| um certificado diz | ele **não** diz |
|---|---|
| quem tem esta chave controlava este nome quando o certificado foi emitido | que o site é honesto, seguro ou legítimo |
| a CA verificou esse controle do jeito que a sua política determina | que a chave continua nas mãos certas hoje |
| o vínculo vale entre duas datas | que ninguém mais tem um certificado para o mesmo nome |

Um site de phishing pode ter um certificado perfeitamente válido para o nome parecido que registrou;
o cadeado diz que a conexão chega àquele nome e nada sobre o nome. O resto da aula trata de tornar a
declaração tão confiável quanto possível: de quem é o nome, qual é a chave e como retirar uma
declaração.
