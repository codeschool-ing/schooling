---
title: Quando há tokens, mantenha-os fora da página
version: 1
---

**Um app que faz login das pessoas pelo OAuth recebe tokens, e o lugar mais seguro para um token é onde
os scripts da página não alcançam de jeito nenhum: um servidor pequeno do próprio app.** O padrão tem
nome, **backend for frontend**, BFF, e a orientação atual da IETF para apps de navegador, *OAuth 2.0 for
Browser-Based Applications*, o põe em primeiro entre os arranjos que descreve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-bff\" aria-label=\"Três caixas da esquerda para a direita. O navegador, rodando a página do planner, guarda só um cookie de sessão HttpOnly e Secure, e nenhum script da página consegue lê-lo. Ele manda cada requisição, com o cookie, para o BFF, um servidor pequeno do próprio app. O BFF guarda o access token e o refresh token, e anexa o access token a cada requisição que repassa à API. O provedor de identidade fica acima do BFF, que conversa com ele para trocar o código e renovar os tokens. Uma linha tracejada marca o limite do que um script da página alcança: só a caixa do navegador.\"><defs><marker id=\"l06-bff-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"92\" width=\"196\" height=\"126\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></rect><text x=\"110\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">o que um script da página alcança</text><text x=\"110\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">o navegador</text><rect x=\"26\" y=\"122\" width=\"168\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a página do planner</text><text x=\"110.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">guarda: cookie __Host-sid</text><text x=\"390\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">o BFF</text><rect x=\"300\" y=\"122\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o servidor do próprio app</text><text x=\"390.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">guarda: access token,</text><text x=\"390.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">refresh token</text><text x=\"630\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">a API</text><rect x=\"570\" y=\"122\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">confere o</text><text x=\"630.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">access token</text><rect x=\"300\" y=\"14\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o provedor de identidade</text><path d=\"M194 157 L300 157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-bff-ah-paper-dim)\"></path><text x=\"247\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">requisição + cookie</text><path d=\"M480 157 L570 157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-bff-ah-paper-dim)\"></path><text x=\"525\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">requisição + access token</text><path d=\"M450 122 L450 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-bff-ah-paper-dim)\" marker-start=\"url(#l06-bff-ah-paper-dim)\"></path><text x=\"458\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">código, renovação</text></svg>", "caption": "Os tokens moram num servidor; o navegador guarda um cookie que não quer dizer nada para script nenhum. Um script na página ainda manda requisições enquanto roda, mas vai embora sem nada.", "same": ["refresh token", "access token"]}
```

O BFF faz no servidor os passos 4 e 5 do fluxo da aula 5: ele recebe o código, faz a troca com o
verifier, e guarda o access token e o refresh token. O navegador recebe o que recebeu nesta aula, um
cookie de sessão `HttpOnly`, `Secure` e `__Host-`. Cada requisição da página vai ao BFF com esse cookie,
e o BFF anexa o access token no caminho para a API. **Um script na página consegue fazer requisições
pelo BFF enquanto roda, e não consegue levar os tokens embora**, que é a diferença entre uma tarde ruim e
uma conta roubada.

## Quando a página precisa guardar um

Alguns apps não conseguem ter um servidor próprio na frente da API. A orientação para esses é um
conjunto de limites, e cada um estreita quanto vale um token roubado:

- **Guarde o access token na memória**, numa variável, nunca no `localStorage` nem no `sessionStorage`.
  Um recarregamento o perde, e o app pega outro.
- **Dê a ele vida curta**: minutos, não horas. Quem define isso é o provedor, e pedir menos é permitido.
- **Faça rodízio do refresh token.** Cada vez que o app usa um refresh token para pegar um access token
  novo, o provedor emite também um refresh token novo e passa a recusar o antigo. Um refresh token
  roubado e usado duas vezes mostra ao provedor que duas partes o têm, e encerra a família inteira.
- **Amarre os tokens ao navegador que os recebeu** onde o provedor dá suporte, com o DPoP (RFC 9449): um
  par de chaves gerado no navegador, e cada requisição assinada com ele, então um token copiado para
  outro lugar não serve sem a chave.

Nenhum desses é tão forte quanto o BFF, porque cada um supõe que um script vai rodar na página algum dia
e pergunta só quanto ele consegue levar. É a suposição certa, e a aula 9 é sobre torná-la menos
provável.

## O arranjo do próprio planner

O planner não tem OAuth, então não precisa de BFF: o próprio servidor dele é o que confere a senha e
guarda o login, e o navegador guarda um cookie que não quer dizer nada para script nenhum. **Esse é o
arranjo ao qual todos os mais fortes tentam voltar.** Os testes desta aula o mantêm no lugar: um no
navegador, de que o cookie não é legível; três no servidor, de que ele está marcado certo, de que o
logout o encerra e de que ele acaba sozinho.
