---
title: Por que um teste substitui uma dependência
version: 1
---

**O boxoffice não recebe dinheiro sozinho.** Para cada pedido ele chama um provedor de pagamento,
espera a resposta e confirma ou recusa o pedido conforme o que voltou. Até aqui essa chamada nunca
aconteceu: com `PAYMENTS_URL` vazio, o boxoffice aprova toda cobrança por conta própria, e é por isso
que todo pedido até agora trouxe um pagamento chamado `ch-local-ord-…`. Uma instalação de verdade
define a variável, e a partir daí uma parte do comportamento do boxoffice pertence a um programa que
outra pessoa roda.

Um teste do boxoffice ainda precisa cobrir essa parte. **A resposta de costume é pôr um substituto
onde o provedor estaria**: um servidor pequeno que responde como o provedor responde, rodado por você,
na sua máquina. São quatro motivos, e cada um é algo que o provedor de verdade não consegue dar a um
teste:

- **Dinheiro.** Uma cobrança num provedor de verdade é uma cobrança de verdade. Os provedores oferecem
  um sandbox para testes, com cartões de teste e sem dinheiro circulando, mas continua sendo o
  servidor deles, nas condições deles.
- **Falhas sob encomenda.** Os testes que mais importam são aqueles em que o pagamento dá errado: uma
  recusa, um erro, uma resposta que nunca chega. Ninguém consegue pedir a um provedor de verdade que
  demore demais às 10h15 de uma terça-feira, e a lição 13 precisa exatamente disso, em toda execução.
- **Velocidade e disponibilidade.** Um teste que atravessa a internet gasta o tempo do provedor e
  falha quando o provedor está fora do ar, então a sua suíte fica vermelha pela manhã ruim de outra
  pessoa.
- **Observação.** Um teste quer saber o que o boxoffice *mandou*: o valor, a referência, a chave de
  idempotência. O provedor não mostra as requisições que recebeu. Um substituto mostra.

## Como se chama um substituto

**O vocabulário vem do teste de unidade, onde os substitutos são objetos e não servidores.** Gerard
Meszaros deu nome a eles em *xUnit Test Patterns* (2007), e os nomes chegaram ao nível da rede sem
mudar:

| nome | o que faz | nesta lição |
|---|---|---|
| stub | responde o que mandaram responder, seja qual for a pergunta | todo substituto daqui, no mínimo |
| spy | um stub que também registra o que recebeu, para o teste ler depois | `payments-stub.mjs` e o WireMock |
| mock | guarda expectativas sobre as chamadas que deve receber, e ele mesmo reprova o teste se elas não chegarem | a verificação do WireMock, usada desse jeito |
| fake | uma implementação que funciona, simplificada: um banco de dados em memória, um provedor que guarda saldos | nenhum |

Na conversa, **"mock server" quer dizer qualquer um deles**, e o título desta lição também. Mesmo
assim vale ter a distinção na cabeça, porque ela diz o que um substituto consegue contar a você. Um
stub não consegue dizer nada sobre as requisições que recebeu, e um spy consegue. *Virtualização de
serviços* é a mesma ideia vendida como produto: um substituto de um serviço inteiro, gravado ou
modelado, mantido por um time para outros times.

## Onde fica a linha

**Substitua o que está fora da coisa sob teste, e nada do que está dentro dela.** Aqui a coisa sob
teste é o boxoffice, então o provedor de pagamento é substituído e o boxoffice roda como é, sem
mudanças, só com um endereço apontado para outro lugar. Substituir também uma parte do boxoffice seria
testar o substituto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 244\" role=\"img\" aria-label=\"Um cliente ou um teste manda requisições ao boxoffice, que fica dentro de uma fronteira tracejada marcada sob teste, sem mudanças. Do boxoffice, o PAYMENTS_URL leva ao provedor de pagamento, em produção, com dinheiro de verdade, as quedas dele e que não é seu, ou, numa linha tracejada, a um substituto, num teste, que responde o que você escreveu e registra o que recebeu.\"><defs><marker id=\"f11boundary-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"214\" y=\"58\" width=\"200\" height=\"124\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"314\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sob teste, sem mudanças</text><rect x=\"20\" y=\"95\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um cliente</text><text x=\"85\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ou um teste</text><rect x=\"239\" y=\"95\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"314\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"520\" y=\"30\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provedor de pagamento</text><text x=\"600\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">em produção</text><rect x=\"520\" y=\"160\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um substituto</text><text x=\"600\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">num teste</text><line x1=\"152\" y1=\"120\" x2=\"237\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11boundary-ah)\"></line><line x1=\"391\" y1=\"112\" x2=\"518\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11boundary-ah)\"></line><line x1=\"391\" y1=\"128\" x2=\"518\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#f11boundary-ah)\"></line><text x=\"455\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">PAYMENTS_URL</text><text x=\"600\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dinheiro real, as quedas dele, não é seu</text><text x=\"600\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">responde o escrito, registra o recebido</text></svg>", "caption": "O substituto troca o que fica fora da fronteira; o próprio boxoffice roda sem mudanças, com um endereço apontado para outro lugar."}
```

Esse desenho também mostra quanto custa um substituto. **Um teste contra um substituto prova que o
boxoffice trata as respostas que você escreveu.** Ele não diz nada sobre o provedor responder mesmo
desse jeito, e no dia em que o provedor mudar, o substituto continua respondendo como antes e todo
teste continua verde. A seção 06 faz isso acontecer de propósito e mostra como pegar.
