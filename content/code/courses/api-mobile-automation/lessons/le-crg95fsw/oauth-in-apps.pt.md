---
title: OAuth num app, que o boxoffice não tem
version: 1
---

**Um app num celular não consegue guardar segredo, então ele faz as pessoas entrarem sem um: o fluxo
authorization code com PKCE.** O boxoffice implementa só client credentials, o grant para
programas, e nada nesta seção pode ser rodado contra ele. A seção está aqui porque as lições 14 a 22
testam apps, e todo app que faz uma pessoa entrar com uma conta de outro lugar usa este fluxo. O que
vem a seguir é a sequência e o que quem testa confere em cada passo.

A imagem errada é a de um app guardando um `client_secret` como o `ci-tests` faz. Qualquer coisa
embarcada num app pode ser tirada dele: um pacote Android é um arquivo zip, e as strings dentro dele
podem ser listadas em minutos. Um segredo num app é um segredo de que todo usuário tem uma cópia.
Então o app é um **cliente público**: tem um id e nenhum segredo, e prova quem é de outro jeito, um
login de cada vez.

## A sequência

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 382\" role=\"img\" aria-label=\"Uma sequência entre quatro partes: o app, o navegador, o servidor de autorização e a API. 1, o app cria um verifier, o guarda, e calcula o challenge como o SHA-256 dele. 2, o app abre a página de login no navegador, que manda o challenge, o state e o redirect_uri ao servidor de autorização. 3, a pessoa entra. 4, o servidor de autorização manda um code e o state de volta, pelo navegador, ao app. 5, o app manda o code e o verifier ao servidor de autorização. 6, o servidor confere se o SHA-256 do verifier é igual ao challenge e responde com um token. 7, o app chama a API com Authorization: Bearer e o token.\"><defs><marker id=\"f03pkce-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o app</text><line x1=\"90\" y1=\"48\" x2=\"90\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"200\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o navegador</text><line x1=\"270\" y1=\"48\" x2=\"270\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"380\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor de autorização</text><line x1=\"450\" y1=\"48\" x2=\"450\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"550\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a API</text><line x1=\"620\" y1=\"48\" x2=\"620\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"98\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">1 um verifier, guardado</text><text x=\"98\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">challenge = seu SHA-256</text><line x1=\"92\" y1=\"112\" x2=\"268\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"180\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">2 abre a página de login</text><line x1=\"272\" y1=\"112\" x2=\"448\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"360\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">challenge, state, redirect_uri</text><text x=\"458\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">3 a pessoa entra</text><line x1=\"448\" y1=\"188\" x2=\"272\" y2=\"188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"360\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">4 code, state</text><line x1=\"268\" y1=\"188\" x2=\"92\" y2=\"188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"180\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">de volta ao app</text><line x1=\"92\" y1=\"234\" x2=\"448\" y2=\"234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"100\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">5 code + verifier</text><text x=\"458\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6 SHA-256 do verifier</text><text x=\"458\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">= o challenge?</text><line x1=\"448\" y1=\"302\" x2=\"92\" y2=\"302\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"100\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">token</text><line x1=\"92\" y1=\"340\" x2=\"618\" y2=\"340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"100\" y=\"331\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">7 Authorization: Bearer …</text></svg>", "caption": "O challenge passa pelo navegador; o verifier vai só do app ao servidor, então um code interceptado não serve para nada sozinho.", "same": ["4 code, state", "5 code + verifier", "7 Authorization: Bearer …", "challenge, state, redirect_uri", "token"]}
```

1. O app inventa uma string aleatória, o **code verifier**, e a guarda para si. Ele calcula o **code
   challenge**, o SHA-256 do verifier em base64url.
2. Ele abre o navegador do sistema na página de login do servidor de autorização, mandando o id de
   cliente, o endereço para onde voltar (`redirect_uri`), um `state` aleatório e o challenge.
3. A pessoa entra e concorda, na página do próprio servidor de autorização; o app nunca vê a senha.
4. O navegador é mandado de volta ao `redirect_uri` do app com um **authorization code** de vida
   curta e o mesmo `state`.
5. O app manda o code e o **verifier** ao endpoint de token.
6. O servidor calcula o hash do verifier, compara com o challenge do passo 2 e, só se baterem,
   responde com um token. O app então chama a API com ele, como `Bearer`, exatamente como na seção 05.

O truque está nos passos 2 e 5. O challenge passou pelo navegador, onde outros apps do celular
poderiam vê-lo; o verifier nunca passou. Um ladrão que intercepta o code no passo 4 não tem o
verifier, e o code sozinho não compra nada.

## Fazendo um challenge

Os passos 1 e 2 não precisam de nada além do Node, e vê-los torna o resto concreto. Um verifier de 32
bytes aleatórios, em base64url, e o challenge dele:

```
ana@laptop:~/boxoffice$ VERIFIER=$(node -e 'console.log(require("crypto").randomBytes(32).toString("base64url"))')
ana@laptop:~/boxoffice$ echo "$VERIFIER"
HQlLaW4Kfn7xX4jhuZdsF6xQp-ppHCrVmd1ZjpL8ayg
ana@laptop:~/boxoffice$ node -e 'console.log(require("crypto").createHash("sha256").update(process.argv[1]).digest("base64url"))' "$VERIFIER"
k9BLhA-dAVMkLd_DRFx53uZKZrZgF_KtvnGNjYrX0Zs
```

O verifier tem 43 caracteres, o mínimo que a RFC 7636 permite, e é diferente a cada execução. O
challenge é o que um hash sempre é: a mesma entrada dá a mesma saída, e nada na saída devolve a
entrada. Rode a última linha duas vezes e ela imprime o mesmo challenge; rode a primeira de novo e
tudo muda.

## O que quem testa confere

Nada disto foi rodado para este curso, porque o boxoffice não tem servidor de autorização. Cada item
é uma requisição que você pode fazer contra um que tenha, com uma recusa como resposta esperada:

| verificação | como | esperado |
|---|---|---|
| o code é usado uma vez | trocar o mesmo code duas vezes | a segunda troca recusada, `invalid_grant` |
| o verifier precisa bater | trocar um code com outro verifier | recusada, `invalid_grant` |
| o challenge é obrigatório | começar o fluxo sem `code_challenge` | recusado, se o servidor exige PKCE |
| o `redirect_uri` bate exatamente | pedir um code com um endereço diferente em um caractere | recusado, e nenhum redirecionamento para ele |
| o `state` é conferido | voltar ao app com um `state` que ele não mandou | o app ignora a resposta |
| nenhum segredo no app | procurar no app compilado qualquer coisa com nome de segredo | nada encontrado |

As duas últimas são testes do app, não do servidor, e pertencem à segunda metade deste curso. As
outras são testes do servidor de autorização de outra pessoa, que uma equipe raramente escreve. O
que uma equipe tem de seu é a configuração, a lista de valores de `redirect_uri` permitidos e as
durações, e é ali que essas verificações acham alguma coisa.
