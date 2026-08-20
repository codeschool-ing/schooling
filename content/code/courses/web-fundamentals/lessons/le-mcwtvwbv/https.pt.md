---
title: HTTPS: o mesmo HTTP, dentro de um túnel
---

**HTTPS é HTTP passando por TLS.** Os métodos, cabeçalhos e códigos são idênticos; o que muda é que tudo isso viaja cifrado.

O TLS entrega três coisas ao mesmo tempo, e vale saber quais: **confidencialidade** (ninguém no caminho lê), **integridade** (ninguém altera sem se denunciar) e **autenticidade** (o certificado prova que aquele servidor é mesmo o dono do domínio). É a terceira que o cadeado representa — e é por isso que cadeado não significa "site confiável", significa "é mesmo o site cujo nome está na barra".

O que o TLS **não** esconde: o nome do domínio que você acessou e o volume de dados trafegado ficam visíveis para a rede. O caminho, os parâmetros e o conteúdo, não.
