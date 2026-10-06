---
title: Decidindo cada pedido
version: 1
---

Se cada pedido tem de ser julgado, alguma coisa precisa julgar. O SP 800-207 divide esse trabalho em
duas partes, e a divisão é o núcleo de uma arquitetura Zero Trust:

```schooling-figure
{"svg": "<svg id=\"sf-pdp-pep\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A decisão Zero Trust. À esquerda, o sujeito: um usuário num dispositivo. Um pedido vai ao ponto de aplicação da política, que fica na frente do recurso à direita. O ponto de aplicação pergunta ao ponto de decisão da política, acima dele, formado por um motor de política e um administrador de política. O ponto de decisão lê sinais de um provedor de identidade, da gestão de dispositivos e dos logs de atividade, e responde permitir ou negar.\"><defs><marker id=\"sf-pdp-pep-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-pdp-pep-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"200\" y=\"14\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor de</text><text x=\"255\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identidade</text><path d=\"M255 58 L255 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><rect x=\"320\" y=\"14\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"375\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gestão de</text><text x=\"375\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dispositivos</text><path d=\"M375 58 L375 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><rect x=\"440\" y=\"14\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">logs de</text><text x=\"495\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">atividade</text><path d=\"M495 58 L495 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><rect x=\"190\" y=\"84\" width=\"360\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">ponto de decisão da política (PDP)</text><text x=\"280\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">motor de política</text><text x=\"460\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">administrador de política</text><rect x=\"20\" y=\"196\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sujeito</text><text x=\"90\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana no notebook</text><rect x=\"300\" y=\"200\" width=\"140\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">PEP</text><rect x=\"570\" y=\"196\" width=\"130\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">recurso</text><text x=\"635\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a folha</text><path d=\"M160 226 L300 226\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><text x=\"230\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedido</text><path d=\"M440 226 L570 226\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-phosphor)\"></path><text x=\"505\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">se permitido</text><path d=\"M350 200 L350 148\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><path d=\"M390 148 L390 200\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-phosphor)\"></path><text x=\"340\" y=\"176.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pergunta</text><text x=\"400\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">permitir / negar</text><text x=\"370\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ponto de aplicação da política, na frente do recurso</text></svg>", "caption": "O ponto de aplicação pergunta; o ponto de decisão decide a partir de identidade, dispositivo e contexto.", "same": ["PEP"]}
```

O **ponto de aplicação da política (PEP)**, do inglês *policy enforcement point*, fica na frente do
recurso, e todo pedido passa por ele. Ele não decide nada sozinho. Recolhe o que o pedido apresenta,
pergunta e então abre a conexão ou a recusa. Na prática, um PEP é um gateway, um proxy reverso na
frente de uma aplicação, um agente num servidor ou a camada de login da própria aplicação.

O **ponto de decisão da política (PDP)**, de *policy decision point*, é onde a decisão é tomada. O NIST
o divide de novo num **motor de política**, que avalia o pedido contra a política, e num
**administrador de política**, que comunica o resultado ao PEP. Para um iniciante, o importante é o que
o PDP lê:

| sinal | a pergunta que responde | na livraria |
|---|---|---|
| identidade | quem é, e provou isso com força? | a ana, com senha e segundo fator |
| dispositivo | a máquina é gerenciada, atualizada, cifrada? | o notebook do escritório, atualizado semana passada |
| recurso | quão sensível é o que se quer? | o manual, ou a folha de pagamento |
| contexto | este pedido é normal para essa pessoa? | uma tarde de dia útil, de São Paulo |
| política | o que é permitido para essa combinação? | a equipe lê o manual de um aparelho gerenciado |

A decisão pode ser mais que sim ou não. Um pedido um pouco estranho, como a conta da ana às 3h de um
país novo, pode receber um novo pedido de segundo fator; um muito estranho pode ser recusado e gerar
um alerta para uma pessoa olhar.

### Por que os dois são separados

Separar aplicação de decisão quer dizer que **uma política pode ser aplicada em muitos lugares.** A
loja poderia pôr um PEP na frente do portal, outro na frente do servidor de arquivos e outro no banco,
e os três perguntariam ao mesmo PDP. Mude a política uma vez, e todo recurso a segue. Também quer dizer
que os PEPs podem ser simples e ficar perto dos recursos, enquanto a decisão, que precisa de mais
informação, mora num lugar só, onde essa informação é reunida.

Os sinais da tabela vêm de outros sistemas: um **provedor de identidade**, que conhece os usuários e os
fatores deles, um sistema de **gestão de dispositivos**, que sabe quais máquinas são da empresa e em
que estado estão, e logs que dizem o que é normal. A maior parte do esforço de adotar Zero Trust vai
para esses sistemas, e não para a decisão em si, e esse é um dos motivos de a aula 8, sobre identidade,
vir logo depois desta.
