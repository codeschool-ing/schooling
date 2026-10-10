---
title: Arquitetura orientada a serviços
version: 1
---

Empresas grandes no fim dos anos 1990 tinham dezenas de aplicações que não conversavam entre si: um
sistema de faturamento comprado numa década, um de depósito escrito em outra, um banco de clientes
que ninguém ousava tocar. Ligá-las par a par era uma bagunça, e a **arquitetura orientada a
serviços**, SOA, foi a resposta que tomou forma no começo dos anos 2000: expor o que cada aplicação
faz como um *serviço* com um contrato publicado, e deixar qualquer outra aplicação usá-lo por esse
contrato.

Esses contratos em geral eram escritos em **WSDL**, uma descrição em XML das operações de um serviço,
e as mensagens viajavam como **SOAP**, um envelope XML sobre HTTP ou sobre uma fila de mensagens. A
aula 5 de `apis` olha o SOAP pelo lado de quem programa e precisa se integrar com um.

## O barramento

A peça que definia o SOA na prática era o **barramento de serviços corporativo**, o ESB (*enterprise
service bus*): um produto central pelo qual passava toda mensagem entre aplicações.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois desenhos. À esquerda, cinco aplicações ligadas umas às outras diretamente, com dez linhas entre elas. À direita, as mesmas cinco aplicações ligadas cada uma por uma linha a um barramento de serviços corporativo no meio, que roteia, transforma e orquestra as mensagens.\"><rect x=\"10\" y=\"10\" width=\"340\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"370\" y=\"10\" width=\"340\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">ponto a ponto: 10 ligações</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">um barramento no meio: 5 ligações</text><path d=\"M180 64 L261 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M180 64 L230 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M180 64 L130 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M180 64 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M261 119 L230 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M261 119 L130 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M261 119 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230 209 L130 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230 209 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M130 209 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"180\" cy=\"64\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"180\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 1</text><circle cx=\"261\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"261\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 2</text><circle cx=\"230\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"230\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 3</text><circle cx=\"130\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"130\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 4</text><circle cx=\"99\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"99\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 5</text><rect x=\"505\" y=\"131\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">ESB</text><circle cx=\"540\" cy=\"64\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"540\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 1</text><path d=\"M540 82 L540 131\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"627\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"627\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 2</text><path d=\"M610 124 L575 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"594\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"594\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 3</text><path d=\"M583 195 L551 157\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"486\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"486\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 4</text><path d=\"M497 195 L529 157\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"453\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"453\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 5</text><path d=\"M470 124 L505 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path></svg>", "caption": "Ponto a ponto, cinco sistemas precisam de até dez conexões; com um barramento, cinco. O barramento também virou o lugar onde as regras moravam, que é a parte que os microsserviços rejeitaram.", "same": ["app 1", "app 2", "app 3", "app 4", "app 5", "ESB"]}
```

O barramento fazia trabalho de verdade. Reduzia o número de conexões de uma por par para uma por
aplicação. Traduzia entre formatos, para o XML do faturamento e os registros de largura fixa do
depósito se encontrarem. Roteava mensagens pelo conteúdo. E orquestrava: um processo de negócio como
"receber um pedido" muitas vezes era escrito *no barramento*, como um fluxo de passos chamando um
serviço depois do outro.

**Essa última parte é onde deu errado.** As regras do negócio saíram das aplicações e foram para um
middleware compartilhado, de uma equipe central de integração. Toda mudança num processo era uma
mudança no barramento, na fila atrás das mudanças de todas as outras equipes. O barramento virou o
gargalo que devia eliminar, e muitas vezes também um ponto único de falha.

## O que sobreviveu

O SOA às vezes é lembrado como um fracasso, o que é injusto. A ideia central dele, de que uma
capacidade é oferecida por um contrato publicado e não pelo banco de dados, é a mesma ideia que a
aula 2 chamou de ser dono do dado. O que não sobreviveu foi o maquinário pesado em volta: XML por
toda parte, grandes produtos de fornecedores, e **inteligência no cano**. Integração corporativa
continua sendo um assunto grande por si só, e o curso `enterprise-software` trata dele na trilha
`software-architecture`.
