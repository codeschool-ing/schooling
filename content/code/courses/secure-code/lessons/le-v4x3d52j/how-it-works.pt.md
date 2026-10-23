---
title: Uma requisição real com a intenção de outra pessoa
version: 1
---

As aulas 10 a 13 garantiram que o portal sabe **quem** manda uma requisição e **o que** essa pessoa
pode fazer. A falsificação de requisição entre sites, **CSRF** na sigla em inglês, é o caso em que as
duas respostas estão certas e a requisição ainda não é o que a pessoa queria.

Ela se apoia num comportamento do navegador, e esse comportamento não é um bug. **Um navegador anexa
os cookies de um site a toda requisição que manda para esse site**, seja qual for a página que causou
a requisição. É isso que mantém você logado quando segue um link de um e-mail para o seu banco. Também
quer dizer que uma página de qualquer outro site, que a lucia por acaso tenha aberta, consegue fazer o
navegador dela mandar uma requisição ao portal, e o cookie de sessão do portal vai junto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l09-cross\" aria-label=\"Como uma requisição forjada chega ao portal. O navegador da lucia tem duas abas: numa ela está logada no portal, na outra lê uma página de outro site. Essa página contém um formulário endereçado à rota de troca de e-mail do portal. Quando o formulário é enviado, o navegador manda a requisição ao portal e anexa o cookie de sessão do portal, porque anexa os cookies de um site a toda requisição para esse site. O portal vê uma sessão válida e uma mudança bem formada, e não tem como saber que a lucia nunca viu o formulário.\"><defs><marker id=\"l09-cross-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o navegador da lucia</text><rect x=\"20\" y=\"34\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"36\" y=\"48\" width=\"228\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aba 1: o portal, logada</text><rect x=\"36\" y=\"108\" width=\"228\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"127.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aba 2: uma página de outro site</text><text x=\"150.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tem um formulário apontado para o portal</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o portal</text><rect x=\"520\" y=\"70\" width=\"170\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"100.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sessão válida</text><text x=\"605.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mudança bem formada</text><text x=\"605.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\"></text><text x=\"605.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">intenção de quem?</text><path d=\"M264 134 L520 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-cross-ah-amber)\"></path><text x=\"392\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /account/email</text><text x=\"392\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">+ o cookie do portal, anexado pelo navegador</text></svg>", "caption": "O navegador anexa o cookie do portal a toda requisição para o portal, seja qual for a página que a iniciou."}
```

Do lado do portal, a requisição é perfeita: uma sessão válida, um formulário bem formado, uma paciente
logada pedindo para trocar o e-mail. **O portal não tem como saber que a lucia nunca viu o
formulário.** Se a troca passar, o outro site escolheu o e-mail dela, e a próxima mensagem de "esqueci
minha senha" vai para uma caixa de entrada que não é dela.

### O que ela precisa, e o que não precisa

Uma requisição forjada funciona quando três coisas são verdade ao mesmo tempo:

1. **A ação muda algo** de que o outro site tira proveito: um e-mail, um telefone, uma senha, um
   agendamento, um pagamento.
2. **A sessão viaja num cookie** que o navegador anexa sozinho. Uma aplicação que manda as credenciais
   num cabeçalho definido pelo próprio JavaScript, como o `Authorization`, não fica exposta do mesmo
   jeito, porque a página de outro site não consegue fazer o navegador acrescentar esse cabeçalho.
3. **Todo valor de que a requisição precisa é previsível.** O campo de e-mail é o que o outro site
   quiser; nada no formulário é segredo.

O CSRF **não** deixa o outro site ler a resposta. O navegador mantém as respostas de um site longe dos
scripts de outro. É uma falha de **escrita**: o que a requisição forjada faz fica feito, e ninguém vê
o resultado.

### As três defesas

Cada defesa quebra uma dessas três condições, e esta aula constrói todas:

- **Um token** quebra a terceira: todo formulário leva um valor aleatório que o portal deu à própria
  página, e uma requisição sem ele é recusada.
- **O `SameSite`** quebra a segunda: o navegador para de anexar o cookie a requisições que outro site
  inicia.
- **Uma verificação de origem** lê o cabeçalho `Origin` que o navegador acrescenta à requisição, e
  recusa uma mudança cuja origem não é o portal.

A primeira condição é uma regra de projeto, não uma defesa: **uma requisição `GET` nunca muda nada.**
Links, imagens e pré-carregamentos mandam `GET`, e cada um é uma requisição que a pessoa não escolheu.
Tudo nesta aula protege os outros métodos: `POST`, `PUT`, `PATCH`, `DELETE`.
