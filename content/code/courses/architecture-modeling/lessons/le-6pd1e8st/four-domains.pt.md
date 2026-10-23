---
title: Quatro domínios de arquitetura
version: 1
---

**O TOGAF descreve uma empresa em quatro domínios de arquitetura: negócio, dados, aplicação e
tecnologia.** Cada um responde a uma pergunta diferente, e uma mudança na empresa costuma tocar os
quatro. A sigla em inglês é BDAT.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l08-domains\" aria-label=\"Os quatro domínios de arquitetura do TOGAF como camadas empilhadas, cada uma com o conteúdo da Carcará. Negócio: vender online e em 26 guichês, embarcar na porta do ônibus, operar a frota. Dados: passageiros, reservas, passagens, viagens, ônibus, pagamentos. Aplicação: venda de passagens, app de embarque, back office das estações, Frota, pacote financeiro. Tecnologia: uma região de nuvem, celulares dos motoristas, PCs e impressoras das estações, links de internet das estações. Dados e aplicação aparecem agrupados como arquiteturas de sistemas de informação.\"><rect x=\"130.0\" y=\"20.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Negócio</text><text x=\"145.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vender online e em 26 guichês · embarcar na porta · operar a frota</text><rect x=\"130.0\" y=\"86.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Dados</text><text x=\"145.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passageiros · reservas · passagens · viagens · ônibus · pagamentos</text><rect x=\"130.0\" y=\"152.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Aplicação</text><text x=\"145.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">venda de passagens · app de embarque · back office · Frota · finanças</text><rect x=\"130.0\" y=\"218.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Tecnologia</text><text x=\"145.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">região de nuvem · celulares · PCs e impressoras · links</text><path d=\"M118 92 L108 92 L108 206 L118 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"98.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">sistemas de</text><text x=\"98.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">informação</text></svg>", "caption": "A camada de negócio, no alto, é o que o C4 não desenha. As outras três são onde vivem os sistemas das aulas 2 e 3."}
```

| domínio | a pergunta | Carcará, hoje |
| --- | --- | --- |
| **arquitetura de negócio** | o que a organização faz, como está organizada, e quais processos e capacidades importam? | vender passagens on-line e em 26 balcões de rodoviária; embarcar na porta do ônibus; operar a frota |
| **arquitetura de dados** | que informação ela guarda, como está estruturada, e quem é o dono? | passageiros, reservas, passagens, viagens, ônibus, motoristas, pagamentos |
| **arquitetura de aplicação** | quais aplicações existem, o que cada uma faz, e como interagem? | ticketing, app de embarque, back office das rodoviárias, Frota, o pacote financeiro |
| **arquitetura de tecnologia** | que infraestrutura roda tudo isso: hardware, redes, plataformas? | uma região de nuvem, celulares dos motoristas, PCs e impressoras de recibo das rodoviárias, links de internet das rodoviárias |

O TOGAF agrupa os dois do meio como **arquiteturas de sistemas de informação**, porque dados e
aplicações costumam ser desenhados juntos.

## Por que quatro camadas

As camadas separam **o que o negócio faz** de **como ele é sustentado**. É essa separação que deixa
um arquiteto corporativo fazer as perguntas que atravessam sistemas:

- *Quais capacidades de negócio dependem do back office das rodoviárias?* Se a resposta é *vender
  para clientes que pagam em dinheiro* e *reembolsos em dinheiro*, aposentar o back office é uma
  mudança de negócio, e não só de TI.
- *Quais aplicações guardam dados de passageiros?* O ticketing, o back office e o pacote financeiro,
  e isso pesa para a LGPD e para os pedidos de exclusão que uma política de privacidade promete.
- *De que tecnologia o embarque depende?* Dos celulares dos motoristas e da sincronização, e por
  isso o ciclo de troca dos celulares é assunto de arquitetura.

## As camadas nos termos da aula 3

O modelo C4 da aula 3 vive quase inteiro nos domínios de **aplicação** e **tecnologia**: os
diagramas de contexto e de containers são arquitetura de aplicação, os de implantação são
arquitetura de tecnologia. O que o C4 não desenha é a camada de negócio acima deles, as capacidades
e os processos, e é essa parte que a arquitetura corporativa acrescenta. **Um contexto de sistema do
C4 responde *o que este sistema toca?*; uma arquitetura de negócio responde *o que a empresa faz, e
de quais sistemas cada parte dela precisa?***
