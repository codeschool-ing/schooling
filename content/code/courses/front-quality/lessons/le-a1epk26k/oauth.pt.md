---
title: OAuth 2.0, quando outra pessoa confere a senha
version: 1
---

**O OAuth 2.0 deixa um app agir por uma pessoa sem nunca ver a senha dela**: a pessoa faz login num
provedor em que já confia, e o provedor dá ao app um token dizendo o que ele pode fazer. Os botões
"entrar com" são isto, com o OpenID Connect por cima, e o planner poderia acrescentar um sem guardar
uma senha sequer.

*Nada nesta seção foi executado contra um provedor de verdade.* Todo provedor exige uma conta, um app
registrado e um endereço público para onde mandar as pessoas de volta, coisas que um curso não tem como
distribuir, e cada um tem o próprio console, que muda mais vezes do que esta página mudaria. O que vem
a seguir é o próprio protocolo, da RFC 6749 e da recomendação de segurança atual para ele, a RFC 9700,
publicada em janeiro de 2025; a documentação do provedor diz onde cada valor vai do lado dele.

## O fluxo que um app de navegador usa

Um app de página única é um **cliente público**: o código dele é entregue a cada visitante, então ele não
consegue guardar um segredo, e qualquer "client secret" nele está escrito no JavaScript da página para
quem quiser ler. O fluxo para um cliente público é o **authorization code com PKCE**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-oauth\" aria-label=\"Um diagrama de sequência com três linhas de vida: o planner no navegador, o provedor de identidade e a API do planner. 1: o planner gera um code verifier aleatório e manda o navegador para o endereço authorize do provedor com o seu client id, o seu endereço de retorno, um state aleatório e o SHA-256 do verifier, o code challenge. 2: a pessoa faz login no provedor e autoriza. 3: o provedor manda o navegador de volta para o endereço de retorno com um código de uso único e o mesmo state. 4: o planner confere que o state é o que ele mandou, e envia o código e o verifier para o endereço token do provedor. 5: o provedor confere que o SHA-256 do verifier é o challenge que recebeu, e responde com um access token e, com o OpenID Connect, um ID token. 6: o planner chama a sua API com o access token no cabeçalho Authorization.\"><defs><marker id=\"l05-oauth-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-oauth-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">o planner, no navegador</text><path d=\"M110 42 L110 315\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"280\" y=\"12\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">o provedor de identidade</text><path d=\"M370 42 L370 315\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"12\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">a API do planner</text><path d=\"M610 42 L610 315\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M110 70 L370 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1  /authorize?…&amp;state&amp;code_challenge</text><text x=\"380\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">2  a pessoa faz login, e autoriza</text><path d=\"M370 150 L110 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">3  volta a redirect_uri?code=…&amp;state=…</text><path d=\"M110 190 L370 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4  POST /token: code + code_verifier</text><path d=\"M370 230 L110 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">5  access token (e um ID token)</text><path d=\"M110 270 L610 270\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-amber)\"></path><text x=\"360.0\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">6  Authorization: Bearer &lt;access token&gt;</text><text x=\"118\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">o verifier só viajou no passo 4</text></svg>", "caption": "O fluxo authorization code com PKCE. Um código roubado no passo 3 não serve sem o verifier, que ficou no planner até o código ser trocado."}
```

Três valores nele fazem a defesa, e cada um responde a um ataque:

- **O `redirect_uri` precisa bater exatamente** com o que foi registrado no provedor. Senão o código do
  passo 3 poderia ser mandado para um endereço escolhido por outra pessoa.
- **O `state`** é um valor aleatório que o planner gera, guarda e confere quando o navegador volta. Uma
  resposta cujo `state` o planner não mandou é uma que ele não pediu, e é descartada: isso impede outro
  site de começar um login em seu nome.
- **O par PKCE** torna o código inútil para quem o interceptar, que é a próxima seção.

## O que não usar

Dois fluxos mais antigos ainda estão nos tutoriais. **O fluxo implícito** devolvia o access token direto
no endereço, no passo 3, onde ele cai no histórico do navegador e nos logs dos servidores; a RFC 9700 diz
para não usá-lo. **A concessão por senha** faz o app coletar a senha da pessoa e repassá-la, que é a
única coisa que o OAuth existe para evitar; a RFC 9700 a proíbe. Se uma biblioteca oferece qualquer um
dos dois, ela está desatualizada.

## Para onde o token vai depois do passo 5

A resposta do provedor é um token, e o app precisa guardá-lo em algum lugar e mandá-lo com as
requisições à sua API. Essa decisão é o assunto da aula 6, e o arranjo que ela recomenda para um app de
navegador tira o token da página por completo.
