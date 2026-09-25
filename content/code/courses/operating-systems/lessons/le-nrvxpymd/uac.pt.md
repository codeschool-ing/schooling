---
title: Controle de Conta de Usuário
version: 1
---

Antes do Windows Vista, a sessão de um administrador rodava **tudo** como administrador: o navegador, o
anexo de e-mail, o jogo. O **Controle de Conta de Usuário**, o *UAC*, mudou isso, e é o motivo de um
administrador do Windows ver um aviso que um administrador do Linux não vê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Como funciona o Controle de Conta de Usuário. Quando um administrador entra, o Windows dá à sessão dois tokens: um padrão, com que tudo roda, e um completo. Um programa que precisa de mais mostra um aviso, e responder Sim roda aquele programa com o token completo. Um usuário padrão tem só o token padrão; o mesmo aviso pede nome e senha de um administrador, e aquele programa roda com o token completo do administrador.\"><defs><marker id=\"ua-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um administrador entra</text><rect x=\"20\" y=\"34\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">token padrão</text><text x=\"190\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tudo roda com este</text><rect x=\"20\" y=\"80\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">token completo</text><path d=\"M182 95 L380 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ua-ah)\"></path><text x=\"190\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Executar como administrador: &quot;Sim&quot;</text><rect x=\"382\" y=\"80\" width=\"318\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">só aquele programa roda com ele</text><text x=\"20\" y=\"158\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um usuário padrão</text><rect x=\"20\" y=\"174\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">token padrão</text><path d=\"M182 189 L380 189\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ua-ah)\"></path><text x=\"190\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pede nome e senha de um administrador</text><rect x=\"382\" y=\"174\" width=\"318\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">só aquele programa roda como o administrador</text></svg>", "caption": "Ser administrador no Windows quer dizer ser perguntado, não ser confiado de saída. Um usuário padrão é perguntado pela senha de outra pessoa, e esse é o ponto."}
```

Quando um administrador entra, o Windows monta **dois tokens**, os pacotes de grupos e privilégios que
um programa carrega. Tudo começa com o **padrão**. Quando um programa precisa de mais, instalar
software, gravar em `C:\Program Files`, mudar uma configuração do sistema, o Windows mostra um aviso:

- **Para um administrador**, o aviso pergunta **Sim ou Não**. É o aviso de *consentimento*. O Sim inicia
  aquele programa com o token completo, e nada mais muda.
- **Para um usuário padrão**, o mesmo aviso pede **nome e senha de um administrador**. É o aviso de
  *credenciais*, e é como a Ana instala algo no PC da recepção sem a recepcionista jamais ser
  administradora.

A tela escurece em volta do aviso. É a **área de trabalho segura**: outros programas não conseguem
desenhar nela nem clicar nela, então um malware não consegue responder Sim no seu lugar.

## Por que a conta do dia a dia deve ser padrão

O Sim do UAC é só uma pergunta, e as pessoas aprendem a clicar sem ler. **Uma conta padrão transforma
esse reflexo numa senha que outra pessoa guarda.** O arranjo do escritório fica:

1. Toda pessoa trabalha numa conta **padrão**.
2. A Ana tem uma conta de **administrador** que usa só quando um aviso pede, e a própria conta padrão
   para todo o resto, e-mail incluído.
3. O Administrador embutido fica desativado.

Clique com o botão direito num programa e escolha **Executar como administrador** para iniciá-lo
elevado de propósito, que é como se abre um Terminal elevado para os comandos da aula 13.
