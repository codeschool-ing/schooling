---
title: Da ameaça ao requisito
version: 1
---

Uma lista de ameaças responde à segunda das quatro perguntas. Nada nela protege ninguém até a
terceira ser respondida: **o que vamos fazer a respeito?** A resposta vem em dois passos, e equipes
que pulam o primeiro escrevem requisitos para ameaças que deveriam ter removido, aceitado ou
passado adiante.

**Primeiro, uma decisão.** O `security-fundamentals` (aula 3) apresentou os quatro jeitos de tratar
um risco, e um modelo de ameaças usa os mesmos quatro:

| decisão | o que significa | exemplo na Vereda |
|---|---|---|
| **mitigar** | construir ou mudar algo para a ameaça ficar menos provável ou menos danosa | verificar a assinatura do webhook (T01) |
| **eliminar** | remover o que torna a ameaça possível | parar de mandar o CPF ao gateway, para ele não poder ser vinculado (aula 5) |
| **transferir** | fazer outra pessoa carregá-la, por contrato ou seguro | o contrato do gateway o responsabiliza pelos dados de cartão que ele guarda |
| **aceitar** | decidir, registrado, conviver com ela | T14, até o visualizador do console ser trocado |

**Segundo, para as duas primeiras decisões, um requisito**: uma afirmação do que o sistema precisa
fazer, escrita de modo que alguém consiga conferir. Transferir termina num contrato e aceitar num
registro assinado; os dois são o assunto da aula 12. Esta aula é sobre o requisito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-chain\" aria-label=\"A cadeia de uma ameaça até a evidência, usando a T07. A ameaça: um paciente muda o número do exame e baixa o laudo de outra pessoa. A decisão: mitigar. O requisito, R10: o portal devolve um exame só ao paciente a quem ele pertence, e responde a qualquer outro pedido como se o exame não existisse. A verificação: um teste que pede o exame de outro paciente e espera a mesma resposta de um exame inexistente. Embaixo da cadeia, as outras três decisões: eliminar, transferir, aceitar, cada uma terminando em outro lugar.\"><defs><marker id=\"l08-chain-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"97.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">ameaça</text><rect x=\"20.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">T07</text><text x=\"97.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um paciente baixa</text><text x=\"97.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o laudo de outro</text><path d=\"M175.0 73.0 L195.0 73.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-chain-tm-ah-paper-dim)\"></path><text x=\"272.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">decisão</text><rect x=\"195.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"272.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mitigar</text><path d=\"M350.0 73.0 L370.0 73.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-chain-tm-ah-paper-dim)\"></path><text x=\"447.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">requisito</text><rect x=\"370.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">R10</text><text x=\"447.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exame só para</text><text x=\"447.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o dono</text><path d=\"M525.0 73.0 L545.0 73.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-chain-tm-ah-paper-dim)\"></path><text x=\"622.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">verificação</text><rect x=\"545.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"622.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um teste pede o</text><text x=\"622.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exame de outro</text><text x=\"20.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">as outras decisões terminam em outro lugar:</text><rect x=\"20.0\" y=\"160.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">eliminar</text><text x=\"130.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">remover a funcionalidade ou o dado</text><rect x=\"252.0\" y=\"160.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"362.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">transferir</text><text x=\"362.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um contrato ou seguro carrega</text><rect x=\"484.0\" y=\"160.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"594.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aceitar</text><text x=\"594.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma decisão assinada, com data</text><text x=\"362.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aula 12</text><text x=\"594.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aula 12</text></svg>", "caption": "Uma ameaça está tratada quando a cadeia chega a uma evidência. Um requisito que ninguém verifica é um desejo escrito no imperativo."}
```

### Mitigações se escrevem como comportamento

O erro comum é escrever a mitigação como tecnologia: "usar um WAF", "pôr MFA", "cifrar o banco".
Cada uma nomeia algo para comprar ou ligar, e nenhuma diz o que o sistema vai fazer depois.
**Um requisito nomeia o comportamento, e deixa o mecanismo para quem constrói**, a menos que o
mecanismo seja o ponto:

| mitigação como tecnologia | como requisito |
|---|---|
| "pôr MFA para a equipe" | o login da equipe exige segundo fator toda vez |
| "corrigir o IDOR" | o portal devolve um exame só ao paciente a quem ele pertence |
| "usar um WAF" | (nenhum requisito: era para qual ameaça?) |

A última linha é comum e vale pegar. Um controle proposto sem ameaça ao lado ou responde a uma
ameaça que ninguém anotou, e que deveria ser anotada, ou não responde a nada.

### Uma ameaça, vários requisitos, e o contrário

A T01 precisa de dois requisitos: a verificação da assinatura, e a conferência do valor que a aula
6 descobriu que uma assinatura não substitui. Um requisito também pode cobrir duas ameaças, como o
e-mail sobre um login novo cobre a T16 e a T17. Nenhum dos dois é problema. O que importa é que a
ligação esteja anotada, que é a seção sobre rastreabilidade.
