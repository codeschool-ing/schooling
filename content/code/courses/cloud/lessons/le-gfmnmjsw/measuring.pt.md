---
title: A conta como dados, e o número que importa
version: 1
---

A fatura do fim do mês é a forma menos útil que a conta assume. Ela chega tarde, é um total por serviço
e não aceita perguntas. **As mesmas cobranças estão disponíveis como dados**, e todo provedor oferece
dois jeitos de lê-las.

## Visões e exportações

O primeiro é um **explorador de custos**, uma tela que agrupa e filtra as cobranças: por serviço, por
região, por tag, por dia. A AWS o chama de Cost Explorer, o Google Cloud tem os relatórios de cobrança e
o Azure tem a análise de custos no Cost Management. Ele responde às perguntas da rotina da seção sobre
orçamentos: qual linha mudou, desde quando e sob qual tag.

O segundo é uma **exportação**: cada cobrança, uma linha por recurso por período, entregue como arquivos
ou num banco de dados que você pode consultar. A AWS entrega o Cost and Usage Report num bucket do S3; o
Google Cloud exporta os dados de cobrança para o BigQuery; o Azure grava exportações de custo numa conta
de armazenamento. As linhas trazem os mesmos campos que esta aula vem lendo na lista de preços, um tipo
de uso, uma quantidade, uma unidade e um custo, mais o recurso e as tags dele. Quando a conta vira uma
tabela, "quanto custou staging no último trimestre, por time" é uma consulta e não uma tarde.

As duas estão horas atrás do uso, pelo motivo que a seção sobre orçamentos deu, e as duas mostram
valores que ainda podem mudar até o mês ser fechado. Nenhuma é um medidor ao vivo.

## Custo unitário

Um total sozinho não diz se uma conta está saudável. A aplicação da estimativa desta aula custa 298,64
por mês; um ano depois, custa 900. Isso é um problema ou uma ótima notícia, e o total não sabe dizer
qual.

**Custo unitário é o total dividido pela coisa que o negócio vende**: custo por cliente, por mil
requisições, por pedido, por gigabyte processado. Digamos que a aplicação tinha 2.000 usuários ativos
quando custava 298,64: cerca de 0,15 por usuário por mês. Se um ano depois ela custa 900 para 12.000
usuários, são 0,075 por usuário. O total triplicou e **cada usuário ficou mais barato de
atender**, que é a cara de um desenho que escala bem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois gráficos ao longo de doze meses da mesma aplicação. À esquerda, o custo total por mês em USD sobe de 298.64 para 900. À direita, o custo por usuário ativo por mês cai de 0.15 para 0.075, enquanto os usuários crescem de 2.000 para 12.000.\"><defs><marker id=\"unit-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">custo total por mês, USD</text><path d=\"M60 220 L310 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 220 L60 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 199.0 L82.7 194.5 L105.5 187.2 L128.2 178.1 L150.9 167.8 L173.6 156.4 L196.4 144.0 L219.1 130.8 L241.8 116.8 L264.5 102.1 L287.3 86.7 L310.0 70.7\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"60.0\" cy=\"199.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"310.0\" cy=\"70.7\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"70.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">298.64</text><text x=\"304.0\" y=\"56.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">900</text><text x=\"60\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mês 1</text><text x=\"310\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mês 12</text><text x=\"380\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">custo por usuário ativo por mês, USD</text><path d=\"M420 220 L670 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420 220 L420 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420.0 76.0 L442.7 93.6 L465.5 106.7 L488.2 118.4 L510.9 129.4 L533.6 139.9 L556.4 149.9 L579.1 159.6 L601.8 169.0 L624.5 178.2 L647.3 187.2 L670.0 196.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"420.0\" cy=\"76.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><circle cx=\"670.0\" cy=\"196.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"430.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.15</text><text x=\"664.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.075</text><text x=\"420\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mês 1</text><text x=\"670\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mês 12</text><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no mesmo ano, os usuários ativos crescem de 2.000 para 12.000</text></svg>", "caption": "O exemplo desta seção, desenhado: o total triplica e cada usuário fica mais barato de atender. A linha entre os dois pontos é ilustrativa; só as pontas são os números da seção."}
```

A curva oposta é o sinal de alerta. Quando o custo por usuário sobe à medida que os usuários crescem,
alguma coisa no desenho cresce mais rápido que o negócio: logs guardados para sempre, uma consulta que
varre toda linha que já guardou, uma réplica por cliente, um NAT gateway levando um tráfego que dobra a
cada funcionalidade nova. Um total subindo é normal; **um custo unitário subindo é um defeito esperando
para ser achado**.

Escolher a unidade é uma decisão por si só. Ela deve ser algo que o produto já conta, que cresce com o
trabalho que o sistema faz e que uma pessoa de fora da engenharia entende. Custo por usuário ativo serve
para a maioria das aplicações; custo por gigabyte processado serve para um pipeline de dados; custo por
build serve para um sistema de CI. O número só é útil se for acompanhado todo mês, do mesmo jeito, para
que uma mudança nele seja uma mudança no sistema e não na aritmética.
