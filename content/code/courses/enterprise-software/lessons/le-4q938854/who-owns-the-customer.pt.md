---
title: Quem é dono do cliente
version: 1
---

Dois sistemas da Serra Alta guardam um registro chamado cliente. O SAP tem cerca de 9.800, todas as
empresas para quem ela vende. O Salesforce tem cerca de 3.100 Accounts, as redes de supermercados,
as lojas delas e os distribuidores de que os 140 representantes cuidam. **Quase todas essas Accounts
também são clientes do SAP, descritas duas vezes, por dois sistemas que
mudam em dias diferentes por motivos diferentes.** A pergunta de arquitetura não é qual sistema está
certo. É qual sistema tem o direito de estar certo sobre cada fato.

## A resposta errada que Joana deu primeiro

Na terceira semana, Joana propôs que o Salesforce virasse o mestre de clientes. Os motivos dela eram
bons. Um cliente aparece primeiro no Salesforce, como prospect, meses antes de alguém no SAP ouvir
falar dele. Os representantes conhecem os compradores, as visitas e as reclamações, e o SAP não sabe
nada disso. O Salesforce tem uma interface mais limpa e uma API melhor. Na fintech, o sistema mais
próximo do cliente era o dono do cliente.

Marcos Teles, o CFO, respondeu numa frase: o cliente é quem a gente fatura. **Uma NF-e não pode ser
emitida sem a razão social, o CNPJ, a inscrição estadual e o endereço fiscal, e o SAP é o sistema que
a emite**, lança o contas a receber, confere o limite de crédito e cobra. Se o Salesforce fosse dono
desses campos, toda fatura dependeria de uma cópia chegando ao SAP a tempo e inteira, e um CNPJ
errado seria uma nota rejeitada pela SEFAZ, e não um erro de digitação num CRM.

Joana retirou a proposta na mesma tarde. O que ela guardou foi a pergunta certa: não qual sistema é
dono do cliente, e sim **qual sistema é dono de cada campo**.

## A posse é por campo, não por registro

A aula 1 separou dados mestres de dados transacionais. O cliente é dado mestre, e na Serra Alta ele
está dividido ao meio:

| campo ou registro | sistema de registro | do outro lado |
|---|---|---|
| razão social, CNPJ, inscrição estadual | SAP | cópia somente leitura no Salesforce |
| endereço fiscal | SAP | cópia somente leitura no Salesforce |
| estrutura de emissor da ordem, recebedor da mercadoria, recebedor da fatura e pagador | SAP | somente leitura no Salesforce, como hierarquia de contas |
| limite de crédito e condições de pagamento | SAP | somente leitura no Salesforce; o representante pede uma mudança, nunca a digita |
| faturas em aberto e o que está vencido | SAP | a cópia noturna em `Invoice__c` |
| contatos: os compradores, os gerentes de categoria | Salesforce | não existem no SAP |
| oportunidades, visitas, anotações | Salesforce | não existem no SAP |
| casos: reclamações, dúvidas sobre recall | Salesforce | os dados de qualidade por trás deles ficam no SAP e no Documentum |
| o representante dono da conta | Salesforce | enviado ao SAP para os relatórios de vendas |

Cada linha tem **exatamente um sistema que pode mudar o valor**, e toda cópia é somente leitura onde
chega. No Salesforce isso é imposto, não pedido: a segurança por campo e os layouts de página tornam
os campos do SAP não editáveis para todo mundo, menos para o usuário da própria integração.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l04-ownership\" aria-label=\"O SAP ECC à esquerda e o Salesforce à direita, cada um listando os campos de que é dono. O SAP é dono da razão social, do CNPJ e da inscrição estadual, do endereço fiscal, da estrutura de parceiros (emissor da ordem, recebedor da mercadoria, recebedor da fatura, pagador), do limite de crédito e das condições de pagamento, e das faturas com o que está vencido. O Salesforce é dono dos contatos, das oportunidades e visitas, dos casos e do representante dono da conta. Entre eles, uma seta cheia do SAP para o Salesforce leva toda noite cópias somente leitura dos campos do SAP; uma seta tracejada do Salesforce para o SAP leva o pedido de criação de cliente. Embaixo, os dois ids que cada lado guarda: o número de cliente SAP na Account, como external id único, e o Id de 18 caracteres do Salesforce no cliente do SAP.\"><defs><marker id=\"l04-ownership-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-ownership-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15.0\" y=\"20.0\" width=\"230.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC</text><text x=\"130.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">dono do que se fatura</text><rect x=\"27.0\" y=\"80.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">razão social, CNPJ, inscrição estadual</text><rect x=\"27.0\" y=\"112.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endereço fiscal</text><rect x=\"27.0\" y=\"144.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">emissor, recebedores, pagador</text><rect x=\"27.0\" y=\"176.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limite de crédito, condições de pagamento</text><rect x=\"27.0\" y=\"208.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">faturas e o que está vencido</text><rect x=\"475.0\" y=\"20.0\" width=\"230.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Salesforce</text><text x=\"590.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">dono do relacionamento</text><rect x=\"487.0\" y=\"80.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contatos: compradores, gerentes</text><rect x=\"487.0\" y=\"112.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">oportunidades e visitas</text><rect x=\"487.0\" y=\"144.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">casos: reclamações, recalls</text><rect x=\"487.0\" y=\"176.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o representante dono da conta</text><path d=\"M250.0 112.0 L470.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-ownership-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"133.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toda noite: cópias</text><text x=\"360.0\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">somente leitura</text><path d=\"M470.0 196.0 L250.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-ownership-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedido de criação</text><text x=\"360.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de um cliente novo</text><rect x=\"15.0\" y=\"270.0\" width=\"690.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">os ids que cada lado guarda</text><text x=\"190.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no cliente do SAP:</text><text x=\"190.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o Id de 18 caracteres do Salesforce</text><text x=\"530.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na Account, external id único:</text><text x=\"530.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SAP_Customer_Number__c</text></svg>", "caption": "Um dono por campo. Cada cópia é somente leitura onde chega, e cada lado guarda o id do outro, então nada precisa ser casado por nome ou por CNPJ.", "same": ["SAP ECC", "Salesforce"]}
```

A Serra Alta aprendeu a regra do somente leitura do jeito caro. Até 2021, o endereço fiscal podia ser
editado nos dois sistemas, e havia uma sincronização em cada sentido. Um representante corrigiu no
Salesforce o endereço de um distribuidor que tinha se mudado; naquela noite a sincronização do SAP
para o Salesforce, que rodava depois, gravou o antigo de volta. A NF-e seguinte saiu com o endereço
antigo, a entrega foi para o novo, e o recebimento do distribuidor recusou a carga porque os
documentos não batiam. **Um campo que dois sistemas podem mudar é um campo em que a última
sincronização a rodar vence, em silêncio, e ninguém fica sabendo que houve disputa.**

## O golden record, e as duplicatas embaixo dele

O nome que o mercado dá à versão única e confiável de um cliente é **golden record**, e a disciplina
de mantê-la é a **gestão de dados mestres**, ou MDM. Empresas grandes compram ferramentas para isso;
a do próprio SAP é o Master Data Governance, em que os pedidos de criação ou alteração de um cliente
passam por aprovação antes de chegar ao ERP. A Serra Alta não tem uma ferramenta dessas. Na prática o
SAP é o golden record dela para o cliente legal, e a tabela de campos acima é a sua governança.

Um golden record não impede que duplicatas sejam digitadas. Em 2025 Talita comparou cada Account do
Salesforce com todas as outras pelo CNPJ e encontrou **214 pares de Accounts que eram a mesma
empresa**. A maioria tinha o CNPJ digitado uma vez com pontos, barra e traço e outra vez como catorze
dígitos. Em algumas ele faltava de um dos lados. Os representantes tinham criado a segunda cópia
porque não acharam a primeira.

O Salesforce tem as ferramentas para a primeira metade da cura: as **matching rules** decidem quando
dois registros parecem ser a mesma empresa, e as **duplicate rules** decidem o que acontece então, um
aviso ou uma recusa no momento de salvar. A regra da Serra Alta agora compara o CNPJ guardado só com
dígitos e recusa uma segunda Account com o mesmo. A segunda metade, juntar 214 pares sem perder as
visitas e os casos pendurados em cada um, levou um mês de Talita.

**O CNPJ acha duplicatas; ele não é a chave pela qual dois sistemas se juntam.** Os oito primeiros
dígitos identificam a empresa e os quatro seguintes o estabelecimento, então as lojas de uma rede
compartilham a raiz e diferem depois dela. O SAP também pode ter mais de um número de cliente para o
mesmo CNPJ: um emissor e um pagador separado, ou a mesma empresa em duas áreas de vendas. Um join por CNPJ
poria as faturas erradas na Account errada na primeira vez que isso acontecesse. O join é por ids, e
cada sistema guarda os do outro.

## Ids dos dois lados

**Cada Account carrega o seu número de cliente do SAP, e cada cliente do SAP carrega o seu Id do
Salesforce.** O primeiro é `SAP_Customer_Number__c`, o campo mostrado como arquivo na seção 03: dez
caracteres, external id, único. Ser external id é o que deixou as faturas da seção 04 apontarem a sua
Account pelo número SAP, sem consulta. Ser único é o que impede uma segunda Account de reivindicar o
mesmo cliente do SAP.

O segundo é um campo customizado que o time de Edson acrescentou ao cadastro de clientes no SAP. Ele
guarda o Id da Account no Salesforce, e **guarda a forma de 18 caracteres**. Um id de registro do
Salesforce vem em duas formas: 15 caracteres que diferenciam maiúsculas de minúsculas, e 18
caracteres, os mesmos 15 com mais três que codificam as maiúsculas, para que o id continue único
quando comparado sem levar a caixa em conta. As telas de busca do SAP, as planilhas e metade das
ferramentas de uma integração comparam sem levar a caixa em conta. Guarde a forma de 15 caracteres e
duas Accounts diferentes podem, um dia, parecer a mesma.

## O cliente que o Salesforce conhece primeiro

Um cliente novo nasce no Salesforce e vira real no SAP, e a sequência entre uma coisa e outra é onde
as duas posses se encontram:

1. Um representante cria uma Account para uma rede regional como prospect. Ela tem nome, contatos e
   uma oportunidade, e nenhum número de cliente do SAP.
2. A oportunidade é ganha. O representante preenche os dados fiscais e pede a criação do cliente, o
   que publica um Platform Event.
3. Um fluxo do IIB recebe o evento e inicia o processo de aprovação de crédito no IBM BPM, que a aula
   6 descreve. O financeiro aprova um limite e as condições de pagamento.
4. O SAP cria o cliente, com o seu número, o seu limite de crédito e a sua estrutura de parceiros, e
   guarda o Id da Account no Salesforce.
5. O fluxo grava o número SAP de volta em `SAP_Customer_Number__c`, e a Account vira cliente.
6. Só agora um pedido para ela pode ser mandado ao SAP. Uma regra de validação recusa um pedido numa
   Account sem número SAP.

**A janela entre os passos 1 e 5 é legítima, e o desenho precisa dizer o que é permitido nela.** Na
Serra Alta, um prospect pode ter contatos, visitas e oportunidades, e não pode ter pedido, limite de
crédito nem tabela de preços, porque é o SAP que concede essas coisas. Quando o passo 3 diz não, a
Account continua prospect, e o representante vê o porquê na Account, com o motivo que o financeiro
deu.

Esse foi o formato com que Joana terminou, e ele deu à proposta original dela aquilo em que ela
estava certa. O cliente começa mesmo no Salesforce. Ele só não vira cliente ali.
