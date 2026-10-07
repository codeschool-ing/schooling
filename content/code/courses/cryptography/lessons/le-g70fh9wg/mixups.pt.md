---
title: As confusões, e como separá-las
version: 1
---

**Quatro operações, dois pares de chaves, e uma pergunta resolve todos os casos: o que a operação
está protegendo, e de quem?** Os erros abaixo são comuns em documentação, em entrevistas e em
código, e cada um já levou a um projeto real que protegia a coisa errada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma grade dois por dois. Colunas: de quem é a chave, minha ou do outro lado. Linhas: chave pública ou privada. A chave pública do outro lado cifra um segredo para ele. A minha chave privada assina. A chave privada do outro lado nunca fica comigo. A minha chave pública deixa os outros me verificarem e cifrarem para mim.\"><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">minha</text><text x=\"530\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">do outro lado</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pública</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">privada</text><rect x=\"120\" y=\"40\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">outros verificam as minhas assinaturas</text><text x=\"250\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e cifram para mim</text><rect x=\"400\" y=\"40\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">eu CIFRO um segredo para ele</text><text x=\"530\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só a chave privada dele abre</text><rect x=\"120\" y=\"130\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">eu ASSINO com ela</text><text x=\"250\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e decifro o que foi mandado para mim</text><rect x=\"400\" y=\"130\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"530\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca nas minhas mãos</text></svg>", "caption": "Qual chave, para qual trabalho, vista do lado de quem envia."}
```

## "Assinar é cifrar com a chave privada"

Essa frase está em toda parte, e só é verdadeira no RSA de livro, em que a mesma aritmética corre
nos dois sentidos. Ela é falsa para os algoritmos em uso hoje: ECDSA e Ed25519 não conseguem cifrar
nada, e as assinaturas RSA usam o preenchimento PSS, que a cifragem não usa. Pensar em assinar como
"cifrar" leva ao próximo erro, então vale abandonar a frase de vez. **Assinar produz uma prova
anexada a uma mensagem; não transforma a mensagem.**

## "A mensagem está assinada, então é confidencial"

Uma assinatura não esconde nada, como a seção 03 mostrou: a carta continuou legível ao lado da
assinatura. Uma equipe que assina seus arquivos de configuração os protegeu contra alterações, não
contra leitura. Se o conteúdo é secreto, ele também precisa ser cifrado.

## "A mensagem decifrou certo, então veio da pessoa certa"

Qualquer um consegue cifrar para uma chave pública. Um serviço de prontuários que aceita qualquer
requisição que consiga decifrar aceita requisições de todo mundo na internet. **Decifrar não prova
nada sobre o remetente**; só uma assinatura, ou a verificação com chave compartilhada da aula 6,
prova.

## "Um par de chaves faz os dois trabalhos"

Faz, matematicamente, com RSA. Não deveria. Um par usado para assinar e um par usado para receber
dados cifrados têm vidas diferentes:

- uma **chave de cifragem** precisa poder ser recuperada: se ela se perde, toda mensagem cifrada
  para ela se perde, então as organizações guardam uma cópia de custódia;
- uma **chave de assinatura** nunca pode ter cópia de custódia: se existe uma cópia em outro
  lugar, o não repúdio acabou, porque outra pessoa poderia ter assinado.

Então os dois são pares separados, e os certificados dizem para que trabalho serve cada chave (o
campo *key usage* da aula 9).

## "Cifrar com a minha própria chave pública não serve para nada"

Serve. Cifrar para a sua própria chave pública dá um arquivo que só a sua chave privada abre, e a
máquina que cifra não precisa de nenhum segredo para isso. Um servidor de backup pode cifrar toda
noite para uma chave pública cuja metade privada está offline num cofre; um ladrão que leva o
servidor de backup não leva nada que decifre os backups. A aula 14 monta esse arranjo.

## A regra numa tabela

| Eu quero… | Eu uso… | O outro lado usa… |
|---|---|---|
| mandar um segredo para alguém | **a chave pública dele** | a chave privada dele, para decifrar |
| provar que escrevi algo | **a minha chave privada** | a minha chave pública, para verificar |
| as duas coisas | assino com a minha, depois cifro com a dele | decifra com a dele, depois verifica com a minha |
