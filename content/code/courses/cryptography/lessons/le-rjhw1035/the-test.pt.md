---
title: A pergunta que separa as duas coisas
version: 1
---

**Para decidir se algo está cifrado, pergunte: existe uma chave secreta, e quem a tem?** Se não há
chave, é codificação. Se a chave viaja junto com os dados ou vem dentro do software que os lê, é
ofuscação. Só quando a chave fica num lugar que quem lê os dados não alcança é que é cifragem.


```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma árvore de decisão com uma pergunta: existe uma chave secreta? Não: codificação, reversível por qualquer um. Sim, mas ela vai junto com os dados ou dentro do software: ofuscação, reversível por qualquer um com o software. Sim, e ela fica longe dos dados: cifragem, reversível só por quem tem a chave.\"><defs><marker id=\"q-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"240\" y=\"16\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">existe uma chave secreta?</text><polyline points=\"300,56 120,120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><text x=\"185\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><polyline points=\"420,56 480,76\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><text x=\"462\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><rect x=\"20\" y=\"122\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">codificação</text><text x=\"120\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qualquer um reverte</text><rect x=\"400\" y=\"78\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">onde mora a chave?</text><polyline points=\"480,114 370,140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><text x=\"380\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com os dados ou no software</text><polyline points=\"620,114 620,138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><rect x=\"250\" y=\"142\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">ofuscação</text><text x=\"350\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qualquer um com o software</text><rect x=\"500\" y=\"142\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">cifragem</text><text x=\"600\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só quem tem a chave</text><text x=\"628\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">longe dos dois</text></svg>", "caption": "Uma pergunta sobre a chave decide qual das três você está vendo."}
```

## A mesma senha, cifrada de verdade

Aqui está a senha do sistema de agendamento selada com AES-GCM sob uma chave que, num sistema real,
moraria num gerenciador de segredos e não ao lado do arquivo:

```
ana@lab:~/lab$ printf 'V-db-s3cret-2026' > db-password.txt; vcrypt seal --key keys/aes-256.hex --nonce 0000000000000000000000d1 db-password.txt db-password.gcm
sealed db-password.txt: 12-byte nonce + 16 bytes of ciphertext + 16-byte tag -> db-password.gcm
```

Guardado como texto, o resultado é Base64 de novo, e não parece mais misterioso que o Secret do
Kubernetes:

```
ana@lab:~/lab$ base64 -w0 db-password.gcm; echo
AAAAAAAAAAAAAADReYwrJG5TfYQM8/zMJWhgXKwvqnPe0cNCairT6G/wxo8=
```

Mas decodificar o Base64 dá só bytes: o nonce de 12 bytes (zeros e `321` aqui, o valor fixo do
laboratório), depois o texto cifrado e a etiqueta:

```
ana@lab:~/lab$ base64 -w0 db-password.gcm | base64 -d | od -c | head -2
0000000  \0  \0  \0  \0  \0  \0  \0  \0  \0  \0  \0 321   y 214   +   $
0000020   n   S   } 204  \f 363 374 314   %   h   `   \ 254   / 252   s
```

Nada nesses bytes leva de volta à senha sem a chave. Com ela, a senha volta:

```
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex db-password.gcm; echo
V-db-s3cret-2026
```

Então **a versão cifrada é tão secreta quanto a chave**. Ponha o `aes-256.hex` no mesmo diretório da
configuração, no mesmo repositório ou na mesma imagem de contêiner, e isto vira ofuscação de novo,
com uma matemática melhor.

## O teste numa tabela

| | exemplo | chave | quem consegue reverter |
|---|---|---|---|
| **codificação** | Base64, hex, PEM, codificação de URL | nenhuma | qualquer um |
| **ofuscação** | ROT13, XOR com uma constante, código minificado | dentro do software | qualquer um com o software |
| **hash** | SHA-256, Argon2id | nenhuma, e nada volta | ninguém reverte; dá para testar candidatos (aula 5) |
| **cifragem** | AES-GCM, RSA-OAEP | guardada longe dos dados | só quem tem a chave |

O hash tem linha própria porque é a outra confusão comum: "as senhas estão cifradas com SHA-256"
mistura duas coisas diferentes. Um hash não pode ser decifrado por ninguém, nem pelo dono, e se ele
protege alguma coisa depende do trabalho da aula 5.

## Lendo um sistema com o teste

Quando um documento, um fornecedor ou um colega diz que os dados estão "cifrados", as perguntas
úteis em seguida são todas sobre a chave: qual algoritmo, onde está a chave, quem e o que consegue
ler a chave, como ela é trocada. Se ninguém sabe responder a segunda pergunta, os dados não estão
cifrados em nenhum sentido que importe, e as aulas 14 e 17 tratam de construir a resposta direito.
