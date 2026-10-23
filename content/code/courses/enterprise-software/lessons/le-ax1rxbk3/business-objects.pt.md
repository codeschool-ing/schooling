---
title: Business Objects, BW e novecentos relatórios
version: 1
---

Marcos Teles julga o SAP por uma coisa que ele vê todo mês: os relatórios. Quando Joana perguntou o
que ele queria da mudança para o S/4HANA, a resposta não tinha nada a ver com tabelas ou transportes.
Ele queria que o relatório do conselho parasse de discordar de si mesmo. **Na Serra Alta, os
relatórios são três camadas compradas da SAP: um data warehouse, uma camada semântica e uma
ferramenta de relatórios. O problema real não está em nenhuma das três, mas em novecentos
relatórios que não têm dono.** Esta seção é sobre essas camadas e esse problema.

## Como a BusinessObjects virou da SAP

A BusinessObjects era uma empresa de software francesa, fundada em 1990, cujo produto deixava as
pessoas fazerem perguntas a um banco de dados em palavras de negócio, em vez de SQL. Ela mesma tinha
comprado a Crystal Decisions, fabricante do Crystal Reports. A SAP comprou a BusinessObjects num
negócio concluído no começo de 2008, e o produto manteve o nome dentro da SAP: hoje é a plataforma
*SAP BusinessObjects Business Intelligence*, e a Serra Alta roda a versão 4.

Três peças dela importam para um arquiteto.

| peça | o que é | na Serra Alta |
|---|---|---|
| universo | uma camada semântica: nomes de negócio mapeados uma vez sobre tabelas, joins e cálculos | *Litros coletados*, *Fazenda*, *Centro* e *Vendas líquidas*, definidos para quem escreve relatórios |
| Web Intelligence | a ferramenta de consulta e relatórios que a maioria dos usuários conhece, pelo navegador | a maior parte dos 900 relatórios, da captação diária de leite à margem mensal por cliente |
| Crystal Reports | relatórios formatados ao milímetro, para imprimir ou gerar PDF | documentos enviados para fora da empresa, onde o leiaute faz parte do conteúdo |

**Um universo é onde moram as definições de uma empresa.** Quem escreve um relatório arrasta
*Vendas líquidas* e *Centro* para uma consulta, e o universo transforma isso em SQL com os joins e a
fórmula certos. Isso é uma força quando há um universo e uma fraqueza quando há vários. A Serra Alta
tem dois universos que definem *Vendas líquidas*: um desconta as devoluções e o outro não. Os
relatórios do comercial usam o primeiro e os do financeiro usam o segundo, então o relatório do
conselho traz dois números de vendas para o mesmo mês, que diferem pelas devoluções, e alguém
explica a diferença em toda reunião. Nada está quebrado. Duas definições estão sendo aplicadas
corretamente.

## O BW, o data warehouse por baixo

Os universos não consultam o ERP de produção. Eles consultam o SAP BW, o Business Warehouse, que a
Serra Alta roda desde 2013 e que está na versão 7.5.

O BW é um data warehouse feito para os dados da própria SAP. Ele tira dados do ECC por meio de
*extratores*, programas da SAP que sabem ler uma área de negócio, como ordens de venda ou documentos
de faturamento, e mandar só o que mudou desde a última execução. Ele guarda o resultado em
estruturas próprias. Uma delas, o *InfoCube*, é um esquema estrela com extensões da SAP: os fatos no
meio, as dimensões em volta. Se você fez `warehouse-modeling` nesta trilha, já viu a forma, e as
perguntas que ela respondia lá valem aqui também: qual a granularidade dos fatos, e o que acontece com
uma dimensão quando a coisa que ela descreve muda.

**O data warehouse lembra o que o ERP sobrescreve.** Quando uma padaria passa da região de vendas de
Juiz de Fora para a de Barbacena, o SAP altera o cadastro do cliente e a região antiga some dele. Um
relatório rodado no SAP poria todas as vendas passadas dessa padaria em Barbacena. O BW guardou a
região que cada venda tinha quando aconteceu, e é sobre ela que se calcula o bônus dos gerentes
regionais.

## Produção ou data warehouse

De tempos em tempos alguém na Serra Alta propõe tirar relatórios direto do SAP: sem carga noturna,
sem data warehouse, números deste segundo. Há dois argumentos contra isso no ECC, e um deles
enfraquece com o HANA.

O primeiro é carga. O banco do ECC está ajustado para as 1.400 ordens por dia e para os funcionários
que as digitam. **Um relatório que varre um ano de linhas de ordem no banco de produção às dez da
manhã disputa com as pessoas que estão tirando pedidos**, e num banco orientado a linhas essa
varredura é lenta e pesada. Esse é o argumento que o HANA enfraquece. No S/4HANA, um banco colunar
consegue responder muitas perguntas operacionais sobre dados ao vivo sem prejudicar as transações, e
a SAP entrega views analíticas dentro do próprio ERP exatamente para isso.

O segundo é história e alcance, e o HANA não mexe nele. A produção guarda o estado atual de um
sistema. O data warehouse guarda o passado, como mostra a região da padaria, e pode guardar mais do
que o SAP: as vendas da fábrica de queijos, que estão no Business Central, o funil do Salesforce.
**Relatório sobre dado ao vivo é o certo para perguntas sobre o agora; o data warehouse continua
certo para perguntas sobre o passado, e sobre mais de um sistema.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-reporting\" aria-label=\"Os relatórios da Serra Alta como quatro caixas da esquerda para a direita. O SAP ECC em produção guarda o estado atual de um sistema. Os extratores carregam toda noite o que mudou no BW 7.5, que guarda a história, como a região que cada venda tinha quando aconteceu. Os universos ficam sobre o BW e guardam as definições, inclusive duas definições diferentes de vendas líquidas. Os relatórios do Web Intelligence ficam sobre os universos: cerca de 900, dos quais cerca de 300 não foram abertos em um ano. Uma seta tracejada dos relatórios de volta à produção mostra a alternativa de relatar direto no SAP, que disputa com a entrada de pedidos e não tem história.\"><defs><marker id=\"l02-reporting-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-reporting-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"22.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><text x=\"95.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">produção</text><text x=\"95.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o estado atual</text><text x=\"95.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de um sistema</text><rect x=\"202.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">BW 7.5</text><text x=\"275.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o data warehouse</text><text x=\"275.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">história: a região</text><text x=\"275.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de cada venda</text><rect x=\"382.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">universos</text><text x=\"455.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">camada semântica</text><text x=\"455.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">definições: duas</text><text x=\"455.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vendas líquidas</text><rect x=\"562.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Web Intelligence</text><text x=\"635.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">relatórios</text><text x=\"635.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cerca de 900; cerca de</text><text x=\"635.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">300 sem abrir em um ano</text><path d=\"M169.0 150.0 L200.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-reporting-es-ah-phosphor)\"></path><path d=\"M349.0 150.0 L380.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-reporting-es-ah-phosphor)\"></path><path d=\"M529.0 150.0 L560.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-reporting-es-ah-phosphor)\"></path><text x=\"185.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">extratores, à noite</text><path d=\"M635.0 122.0 L635.0 76.0 L95.0 76.0 L95.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l02-reporting-es-ah-amber)\"></path><text x=\"365.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">relatar direto na produção: sem carga noturna, mas disputa com a entrada de pedidos e não guarda história</text><text x=\"365.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o dado ao vivo responde sobre o agora; o warehouse responde sobre o passado, e sobre mais de um sistema</text></svg>", "caption": "Três camadas compradas da SAP, e o atalho em volta delas. O atalho ganha frescor e perde história e alcance.", "same": ["BW 7.5", "SAP ECC", "Web Intelligence"]}
```

## Novecentos relatórios

A plataforma BusinessObjects guarda uma auditoria de quem abriu o quê. Na segunda semana Joana pediu
a Edson um ano dela, e o resultado foi o número que dá nome a esta seção: cerca de 900 relatórios do
Web Intelligence, e um terço deles, cerca de 300, sem ninguém abrir em doze meses.

A primeira proposta dela foi apagar esses 300. Edson pediu que ela esperasse, e Cláudia Mendes
explicou por quê. Alguns relatórios são abertos uma vez por ano: o que junta os registros de lote
para a auditoria anual da FSSC 22000, a valoração de estoque de fim de ano, uma simulação de recall
que as fábricas fazem a cada doze meses e que cai algumas semanas fora da janela da auditoria. **Um
relatório usado uma vez por ano parece morto para qualquer medição mais curta do que um ano e pouco**,
que é a mesma cautela que a seção anterior levantou sobre os objetos Z que só rodam no fechamento
anual.

Então a aposentadoria foi feita em passos, e os passos valem em geral.

1. **Medir por mais de um ciclo de negócio inteiro.** Um ano e um trimestre pega os relatórios anuais.
2. **Achar um dono para cada relatório**, perguntando quem o criou e quem o recebe. Um relatório sem
   dono depois de um mês de perguntas é arquivado, não apagado, e volta se alguém pedir.
3. **Agrupar os que sobram pelo que respondem.** Na Serra Alta, uns quarenta relatórios acabaram
   respondendo a uma pergunta só, a captação de leite do dia por centro, cada um com um filtro
   diferente.
4. **Acertar as definições antes do leiaute.** Os dois significados de *Vendas líquidas* são uma
   decisão de Marcos, e nenhuma ferramenta de relatório pode tomá-la por ele.

**O número de relatórios não mede o quanto uma empresa está bem informada**; está mais perto de
medir quantas pessoas precisaram de uma resposta e não acharam a que já existia. Os 300 relatórios
nunca abertos custam licença, atualização e teste toda vez que o BW ou a plataforma mudam, e vão
custar os três de novo se forem levados para o S/4HANA.

## Para onde a SAP está levando a análise de dados

Os produtos de análise mais novos da SAP são serviços na nuvem. O *SAP Analytics Cloud* cobre
painéis, planejamento e relatórios, e o *SAP Datasphere*, que antes se chamava Data Warehouse Cloud,
é o data warehouse dela na nuvem. O sucessor local do BW é o *BW/4HANA*. A BusinessObjects continua
com suporte, em datas que a SAP publica e revisa, e o time de Edson confere essas datas nas páginas
de manutenção da SAP em vez de confiar na memória, porque elas já mudaram antes.

Para a Serra Alta, a decisão sobre relatórios segue a decisão sobre o ERP. Se o ECC virar S/4HANA,
os extratores do BW precisam ser conferidos contra o modelo de dados novo, alguns relatórios vão para
a análise de dados de dentro do S/4HANA, e a pergunta sobre o data warehouse volta a ser feita. **O
que não deve mudar de sistema são os 300 relatórios que ninguém abre, nem as duas definições de um
mesmo número.** Isso sai mais barato de resolver agora, enquanto o sistema em que rodam ainda é
familiar para todo mundo, do que no meio de uma migração.
