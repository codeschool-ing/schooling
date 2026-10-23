---
title: Dois ERPs num grupo
version: 1
---

A Serra Alta roda SAP e a Mantiqueira roda Business Central, então desde 2021 o grupo tem dois ERPs,
e alguém precisa decidir se isso é um estado passageiro ou o desenho. Há três opções sérias: levar a
Mantiqueira para o SAP, manter os dois e ligar as operações, ou manter os dois e juntá-los só na
contabilidade do grupo. **A escolha depende menos de qualquer dos produtos do que de uma data**: a
manutenção principal do SAP para o ECC acaba no fim de 2027.

## O que a aquisição deixou

A Mantiqueira continua sendo uma pessoa jurídica separada, com CNPJ e contabilidade próprios,
controlada pela Serra Alta. As vendas entre as duas vão nos dois sentidos. A Serra Alta vende à
Mantiqueira o leite que os caminhões dela coletam para a fábrica de Alagoa, e a Mantiqueira vende à
Serra Alta cerca de 60% do seu queijo, que vai para as redes de supermercado junto com o resto da
linha da Serra Alta. Os outros 40% a Mantiqueira vende direto a cerca de 300 lojas e restaurantes do
sul de Minas, clientes que ela tinha muito antes da aquisição.

Toda venda intercompany é uma venda entre duas empresas, então cada uma precisa da sua NF-e, e cada
uma é digitada duas vezes: emitida num ERP e lançada à mão no outro. São umas 180 notas por mês e
dois dias de trabalho de um auxiliar de contas a pagar, e as diferenças aparecem no fechamento.

O fechamento é a outra metade. A contabilidade da própria Serra Alta fecha nos cinco primeiros dias
úteis (aula 1). A do grupo não, porque os controllers do Marcos Teles montam as demonstrações
consolidadas numa planilha. Eles exportam o balancete da Mantiqueira do Business Central, mapeiam à
mão as 212 contas dela no plano de contas do grupo da Serra Alta, eliminam os saldos intercompany e
somam o resultado aos números do SAP. Isso vai até o nono dia útil. O Marcos quer o grupo fechado no
quinto, como a empresa.

## A primeira resposta da Joana

O primeiro rascunho da Joana recomendava um ERP só. Seguia direto da aula 1: um banco de dados para o
negócio inteiro, um fluxo de documentos do pedido ao recebimento, e nenhuma conciliação porque nada é
copiado. A Mantiqueira viraria mais uma empresa (company code) no SAP da Serra Alta, os 41 usuários
dela virariam usuários do SAP, e o Business Central seria desligado.

O Edson Prado leu e fez uma pergunta: para qual SAP? O sistema ECC para onde a Mantiqueira iria sai
da manutenção principal no fim de 2027, e o projeto de S/4HANA que o substitui já está sendo
planejado (aula 2). **Migrar uma empresa para um sistema que você está prestes a deixar é migrá-la
duas vezes**: uma para o ECC, e de novo, com todo o resto, para o S/4HANA alguns anos depois. As duas
extensões de queijo da Mantiqueira seriam refeitas em ABAP para o ECC e depois reavaliadas para o
S/4HANA. A Joana tinha visto a forma certa, já que um ERP só para o grupo é um estado final razoável,
no momento errado.

## As três opções

A pergunta do Edson transformou uma proposta em três, e a Joana estimou o custo de cada uma com o
Edson, o Felipe Arruda e a consultoria de SAP. Os números são estimativas da própria Serra Alta, não
preços de mercado.

| | A: Mantiqueira para o SAP ECC | B: os dois, integrados na operação | C: os dois, consolidados nas finanças |
|---|---|---|---|
| o que passa entre os ERPs | tudo, uma vez: clientes, itens, pedidos em aberto, estoque, saldos | pedidos, entregas, notas, itens e preços, todo dia | um balancete mensal e os saldos intercompany |
| estimativa | R$ 2,1 milhões, 9 meses | R$ 650 mil, 5 meses | R$ 190 mil, 3 meses |
| o que fica para trás | uma segunda migração no projeto de S/4HANA | uns doze fluxos de integração novos para operar, e dois ERPs acoplados por eles | dois ERPs com operações separadas |
| o risco que a Joana anotou | a fábrica de queijo levada para um sistema que está saindo da manutenção | uma mudança em qualquer ERP quebra o fluxo de documentos do outro | a consolidação só é tão boa quanto o mapeamento de contas |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l03-options\" aria-label=\"Três painéis, um por opção, cada um com o SAP ECC em cima e o Business Central embaixo. Opção A, Mantiqueira para o SAP ECC: uma seta leva tudo uma vez, o Business Central é desligado, e a mudança se repete no projeto de S/4HANA; R$ 2,1 milhões e 9 meses. Opção B, integrados na operação: cinco setas nos dois sentidos para pedidos, entregas, notas, itens e preços, todo dia; R$ 650 mil, 5 meses e uns doze fluxos para operar. Opção C, consolidados nas finanças: uma seta, o balancete, uma vez por mês; R$ 190 mil e 3 meses.\"><defs><marker id=\"l03-options-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"8.0\" width=\"226.0\" height=\"314.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"123.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">A: para o SAP ECC</text><rect x=\"48.0\" y=\"53.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"123.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"48.0\" y=\"193.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"123.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"123.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 2,1 milhões, 9 meses,</text><text x=\"123.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e de novo para o S/4HANA</text><path d=\"M123.0 192.0 L123.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2.4\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><text x=\"131.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tudo, uma vez</text><text x=\"123.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">desligado</text><rect x=\"247.0\" y=\"8.0\" width=\"226.0\" height=\"314.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">B: integrados na operação</text><rect x=\"285.0\" y=\"53.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"285.0\" y=\"193.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"360.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 650 mil, 5 meses,</text><text x=\"360.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">~12 fluxos para operar</text><path d=\"M300.0 192.0 L300.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M330.0 89.0 L330.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M360.0 192.0 L360.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M390.0 89.0 L390.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M420.0 192.0 L420.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pedidos, entregas, notas,</text><text x=\"360.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">itens, preços: todo dia</text><rect x=\"484.0\" y=\"8.0\" width=\"226.0\" height=\"314.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"597.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">C: consolidados nas finanças</text><rect x=\"522.0\" y=\"53.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"597.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"522.0\" y=\"193.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"597.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"597.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 190 mil, 3 meses,</text><text x=\"597.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma leitura por mês</text><path d=\"M597.0 192.0 L597.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><text x=\"605.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">balancete,</text><text x=\"605.0\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mensal</text></svg>", "caption": "O que passa entre os dois ERPs em cada opção. A quantidade de setas é o acoplamento, e o custo de B é o que continua vindo depois que o projeto acaba.", "same": ["Business Central", "SAP ECC"]}
```

A opção B é a que mais parece arquitetura, e é a que a Joana combateu com mais força. Ela liga dois
fluxos de documentos: um pedido de compra da Serra Alta criaria um pedido de venda na Mantiqueira,
uma entrega no Business Central lançaria uma entrada de mercadoria no SAP, e uma nota num criaria uma
conta a pagar no outro. Cada um desses elos é uma dependência entre dois sistemas que são
customizados, atualizados e fechados cada um no seu calendário. Só o SAP fica fora do ar toda noite
de domingo para manutenção, e congelado durante o próprio fechamento. **Acoplar os fluxos de
documentos de dois ERPs dá a você os custos de um sistema só e a independência de nenhum dos dois**,
e faria isso justamente nos anos em que o SAP está sendo trocado por baixo dele.

## Como a integração funcionaria

Em qualquer opção, alguma coisa precisa ler o Business Central. Ele publica uma API REST construída
sobre OData versão 4, com endpoints padrão para o que uma integração financeira precisa (clientes,
itens, notas de venda, o razão), e um parceiro ou cliente pode publicar mais como extensões em AL. As
chamadas são autenticadas pelo Entra ID, e uma aplicação registrada no tenant pode chamar a API sem
ninguém logado, que é como uma integração agendada deve se identificar.

O tenant é o antigo da Mantiqueira. É a ponta solta da seção anterior voltando: a identidade da
própria integração moraria no diretório que ninguém governa, com um segredo que só o Felipe guarda. O
plano da Joana a registra lá mesmo assim, porque a mudança não está agendada, e acrescenta duas
coisas. O segredo vai para o cofre que o time do Rui Andrade usa, com a data de expiração na agenda
deles. E levar o Business Central para o tenant da Serra Alta entra na lista do projeto de S/4HANA em
vez da lista de ninguém.

Do lado do SAP, a integração usa as portas que a aula 2 descreve e roda na plataforma do Rui, como
todo outro fluxo para o SAP. As aulas 9 a 11 tratam de como um fluxo desses deve ser construído.

Uma integração compensa em qualquer opção, e ela não precisa da API de nenhum dos ERPs. Quando a
Mantiqueira vende queijo à Serra Alta, a SEFAZ autoriza uma NF-e: um documento XML com cada linha,
quantidade, preço e imposto da venda, assinado e já validado pelo fisco. O vendedor manda esse XML ao
comprador. **Os dados que o auxiliar redigita todo mês já chegam à Serra Alta, estruturados e
autorizados.** Carregá-los no SAP em vez de digitá-los acaba com a redigitação em A, B e C igualmente,
e o mesmo vale no outro sentido para o leite.

## A recomendação

A recomendação da Joana, como ela a escreveu para a Regina e o Marcos:

- consolidar no nível financeiro agora, que é a opção C. Todo mês, depois que a Mantiqueira fecha a
  contabilidade, uma integração lê o balancete pela API do Business Central, mapeia-o por uma tabela
  de contas que os controllers do Marcos mantêm, e concilia e elimina os saldos intercompany antes de
  o relatório do grupo ser produzido;
- carregar o XML das NF-e intercompany dos dois lados em vez de redigitá-lo;
- manter a operação da Mantiqueira no Business Central, e pôr um contrato de suporte com um parceiro
  de Business Central por trás do Felipe, que é a única pessoa de TI da Mantiqueira;
- decidir de novo dentro do projeto de S/4HANA, onde a pergunta passa a ser se a Mantiqueira é mais
  uma empresa no sistema novo: projetada uma vez, migrada uma vez.

A estimativa foi de R$ 240 mil e quatro meses. O Marcos aceitou porque ela punha o fechamento do
grupo no quinto dia útil. O Edson aceitou porque ela não acrescentava nada ao ECC. O Felipe ficou
aliviado por manter o sistema que conhece, e inquieto com o que a decisão do S/4HANA significaria
para ele. A Joana registrou isso como risco, porque um sistema que uma pessoa só entende é um sistema
com um único ponto de falha.

**A coexistência aqui é uma decisão, e não um padrão**: tem um motivo, um custo, uma data para ser
revista e um dono para cada peça. Dois ERPs que ninguém decidiu manter são os mesmos dois sistemas
sem nada disso. A aula 13 volta à coexistência como um estado deliberado, quando o Coleta estiver
sendo substituído, e a aula 15 a escolher o que construir e o que comprar.
