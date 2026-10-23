---
title: O que é um ERP
version: 1
---

A imagem comum de um ERP é a de um programa de contabilidade enorme, com telas demais. **Um ERP é um
conjunto de funções do negócio — finanças, vendas, compras, estoque, produção, pessoas — construído
sobre um único modelo de dados e um único banco, para que um evento no negócio atualize todas elas de
uma vez.** As telas são a parte menos interessante. O que faz dele um ERP é que, quando um caminhão de
iogurte sai da fábrica de Juiz de Fora, o estoque cai, o custo das mercadorias vendidas sobe, o
cliente passa a dever e o plano de produção da semana seguinte enxerga o buraco, na mesma transação e
sem ninguém copiar um número de um lugar para outro.

A sigla vem de *enterprise resource planning*, planejamento de recursos da empresa, um nome que
descreve melhor de onde ele veio do que o que ele faz hoje.

## De onde veio

A linhagem é curta, e explica por que o ERP tem forma de fábrica.

**Primeiro veio o MRP, planejamento das necessidades de materiais, nos anos 1960 e 1970.** Um
fabricante sabe o que pretende fazer na semana seguinte e do que cada produto é feito, a sua lista de
materiais. Com essas duas listas um computador calcula o que comprar e quando: quatro mil litros de
leite, duzentos quilos de fermento, onze mil potes e as tampas, cada coisa pedida cedo o bastante para
chegar antes de ser necessária. Joseph Orlicky, na IBM, registrou o método em *Material Requirements
Planning* (1975), e ele esteve entre os primeiros usos sérios de um computador num negócio.

**O MRP II, planejamento dos recursos de manufatura, ampliou a ideia nos anos 1980** para o resto da
fábrica: capacidade das máquinas, mão de obra e o dinheiro. Oliver Wight popularizou o nome e a
prática. Um plano que sabia que a linha de envase só rodava oito horas por dia finalmente conseguia
dizer que o pedido ia atrasar antes de ele atrasar.

**A palavra ERP é do Gartner, de por volta de 1990**, para sistemas que tinham ido além da fábrica
para vendas, finanças, compras e pessoal, e que dividiam um banco entre todos eles. O R/3 da SAP,
lançado em 1992, é o produto que a maioria imagina quando pensa num. A aula 2 é sobre ele.

## Os módulos, na Serra Alta

Um ERP é vendido e configurado em módulos. Os nomes mudam de fornecedor para fornecedor; as funções
não. Isto é o que o SAP da Serra Alta faz, com os nomes de módulo do próprio SAP, que as pessoas da
aula 2 usam o dia inteiro:

| módulo | o que registra | na Serra Alta |
|---|---|---|
| FI, contabilidade financeira | o razão geral, o que os clientes devem e o que se deve aos fornecedores | toda NF-e vira um contas a receber; todo pagamento de fazenda baixa um contas a pagar |
| CO, controladoria | custos por fábrica, produto e centro de custo | quanto custa fazer um litro de leite UHT em Juiz de Fora |
| SD, vendas e distribuição | cotações, pedidos, remessas, notas | cerca de 1.400 pedidos por dia de supermercados, distribuidores e do Portal B2B |
| MM, gestão de materiais | compras, entradas de mercadoria, estoque | o leite recebido das fazendas, as embalagens compradas dos fornecedores |
| PP, planejamento da produção | o que fazer, quando, em que linha | o plano semanal de cada fábrica |
| QM, gestão da qualidade | inspeções e resultados | os resultados de laboratório de cada lote |
| WM, gestão de armazém | onde cada palete está | as câmaras frias de Juiz de Fora e Barbacena |

**Uma fazenda é um fornecedor.** Isso surpreende quem chega de fora do setor, e é exatamente o que o
modelo de um ERP impõe. A Serra Alta compra leite de 1.900 fazendas, então cada uma é um cadastro de
fornecedor no SAP, com CPF ou CNPJ, conta bancária e condição de pagamento, na mesma tabela da empresa
que lhe vende papelão. O ERP não tem o conceito de fazenda. Tem o conceito de alguém a quem a Serra
Alta paga.

## Comprado e configurado, não escrito

**Ninguém na Serra Alta escreveu o SAP, e quase ninguém consegue mudar como ele funciona.** O
fornecedor escreveu os programas e o banco, e vende os dois com um modelo de como um negócio funciona:
como um pedido vira nota, como um pagamento baixa uma dívida, como um custo é rateado. O que o cliente
faz é **configurar** esse modelo, por parâmetros — muitos milhares deles num ERP grande — que escolhem
entre os comportamentos que o fornecedor previu. Que documentos uma venda gera, como uma nota é
numerada, que impostos valem em Minas Gerais.

Onde a configuração acaba, o cliente escreve código dentro do ERP, na linguagem do fornecedor e sob
as regras dele. A Serra Alta tem cerca de 1.800 objetos próprios assim. A aula 2 conta de novo,
porque cada um é algo que precisa ser carregado por toda atualização.

O modelo vem com uma afirmação junto: a de que o fornecedor viu milhares de empresas e o processo que
ele entrega está perto do melhor jeito de tocar uma. A afirmação é em parte verdadeira. Contabilidade
é contabilidade, e ninguém ganha vantagem competitiva com um jeito incomum de registrar um contas a
receber. Ela também é argumento de venda, e as partes de um negócio que são realmente dele raramente
cabem no padrão. **Separar uma coisa da outra é uma das coisas mais valiosas que um arquiteto faz numa
empresa assim**, e a aula 15 é sobre fazer isso com números.

## Quem vende

Quatro fornecedores atendem a maior parte das empresas grandes, e mais um atende boa parte do Brasil:

| fornecedor | produtos |
|---|---|
| SAP | o ECC, que a maioria das empresas grandes ainda roda, e o S/4HANA, o sucessor |
| Oracle | E-Business Suite e JD Edwards, de antes da nuvem; Fusion Cloud ERP e NetSuite depois |
| Microsoft | Dynamics 365 Finance e Supply Chain Management para empresas grandes; Business Central para as menores |
| Infor | edições por setor, para manufatura e distribuição entre outros |
| TOTVS | a fornecedora brasileira, com Protheus, RM e Datasul, mais forte entre empresas pequenas e médias |

Odoo e ERPNext são de código aberto e têm o mesmo formato em escala menor. Por isso a primeira seção
desta aula os citou como um jeito de ver um funcionando.

**Uma empresa grande raramente roda um só.** A Serra Alta roda SAP, e a queijaria que ela comprou em
2021 roda o Business Central da Microsoft, que a compra não desligou. A aula 3 é sobre conviver com
dois.

## Por que isso importa a um arquiteto

Tudo acima poderia ser a introdução de um curso para contadores. Está aqui por causa de uma
consequência, que o resto da aula desenvolve: **o ERP é o sistema de registro da maior parte do que a
empresa faz, e um sistema de registro molda todos os sistemas à sua volta.** O Portal B2B, o roteamento
dos caminhões no Rota e as telas do Salesforce do time de vendas existem para mostrar, mudar ou
acrescentar algo cuja versão verdadeira mora no SAP. Os desenhos deles são respostas a perguntas que o
ERP faz: o que é um cliente, quando uma venda conta, em que dia o mês acaba. As próximas três seções
mostram de onde vêm essas perguntas.
