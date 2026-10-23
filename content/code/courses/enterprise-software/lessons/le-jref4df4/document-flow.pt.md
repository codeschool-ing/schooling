---
title: Uma venda deixa um rastro de documentos
version: 1
---

Quem desenvolve e chega a um ERP costuma imaginar os dados como linhas que são atualizadas: um pedido
com uma coluna de status que passa de *aberto* para *enviado* e para *faturado*. **Um ERP registra um
processo de negócio como uma cadeia de documentos, cada um criado por um passo e apontando para o
anterior, e um documento lançado não é editado depois.** Quem entende a cadeia entende onde outro
sistema pode entrar nela, e é a isso que se resume quase todo o desenho de uma integração com um ERP.

## Do pedido ao recebimento

Acompanhe uma venda. Na segunda-feira, uma rede de supermercados do Rio de Janeiro pede 600 caixas de
leite UHT integral para o seu centro de distribuição. Isto é o que o SAP da Serra Alta cria, em ordem:

1. **A ordem de venda.** Cliente, endereço de entrega, material, quantidade, preço, a data prometida.
   Nada se moveu ainda e ninguém deve nada. O SAP confere aqui o limite de crédito do cliente, e
   confere se 600 caixas podem ser prometidas para quarta.
2. **A remessa de saída.** Criada na terça a partir da ordem, quando o armazém recebe a instrução de
   prepará-la. Registra que fábrica despacha e quando.
3. **A saída de mercadoria.** Lançada quando o caminhão é carregado. É o primeiro passo que muda os
   livros: o estoque da câmara fria de Juiz de Fora cai 600 caixas, e o custo delas passa da conta de
   estoque para o custo das mercadorias vendidas.
4. **O documento de faturamento.** A nota, criada a partir da remessa. Dele sai uma NF-e, enviada à
   secretaria da fazenda do estado, que precisa autorizá-la antes de o caminhão poder sair da fábrica.
5. **O documento contábil.** Lançado com a nota: o cliente agora deve o valor à Serra Alta, como uma
   partida em aberto no contas a receber.
6. **O recebimento.** Trinta dias depois o dinheiro chega ao banco, o arquivo do banco é lido (a aula 9
   mostra o formato), e o pagamento baixa a partida em aberto.

Seis documentos, cada um com o seu número, cada um apontando para o antecessor. O SAP chama a cadeia
de **fluxo de documentos**, e qualquer usuário pode abrir a ordem e andar para a frente até o
pagamento, ou abrir o pagamento e andar para trás até a ordem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l01-order-to-cash\" aria-label=\"Seis documentos em fila, cada um criado a partir do anterior: ordem de venda, remessa, saída de mercadoria, documento de faturamento com a NF-e, documento contábil, recebimento. Uma linha tracejada acima diz que cada documento aponta para o anterior. Sob a saída de mercadoria: o estoque cai 600 caixas e o custo vai para o custo das mercadorias vendidas, a primeira mudança nos livros. Sob o documento contábil: o cliente deve o valor. Sob o recebimento: ele baixa a partida em aberto.\"><defs><marker id=\"l01-order-to-cash-es-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l01-order-to-cash-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"8.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ordem de</text><text x=\"60.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">venda</text><text x=\"60.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segunda</text><path d=\"M113.0 118.0 L127.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"128.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">remessa</text><text x=\"180.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">de saída</text><text x=\"180.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">terça</text><path d=\"M233.0 118.0 L247.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"248.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">saída de</text><text x=\"300.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mercadoria</text><text x=\"300.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quarta</text><path d=\"M353.0 118.0 L367.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"368.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">faturamento</text><text x=\"420.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">+ NF-e</text><text x=\"420.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quarta</text><path d=\"M473.0 118.0 L487.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"488.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">documento</text><text x=\"540.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contábil</text><text x=\"540.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quarta</text><path d=\"M593.0 118.0 L607.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"608.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recebimento</text><text x=\"660.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">do cliente</text><text x=\"660.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 dias depois</text><path d=\"M660.0 84.0 L660.0 66.0 L60.0 66.0 L60.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l01-order-to-cash-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada documento aponta para o anterior</text><path d=\"M300.0 170.0 L300.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"300.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">estoque − 600 caixas</text><text x=\"300.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">custo das vendas +</text><path d=\"M540.0 170.0 L540.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"540.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o cliente deve</text><text x=\"540.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma partida em aberto</text><path d=\"M660.0 170.0 L660.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"660.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">baixa a partida</text><text x=\"660.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">em aberto</text><text x=\"250.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">os três passos destacados mudam os livros</text></svg>", "caption": "Do pedido ao recebimento para 600 caixas de leite UHT. Nada é alterado no lugar: cada passo acrescenta um documento, e uma integração entra na cadeia no passo que ela representa.", "same": ["+ NF-e"]}
```

## A mesma forma nas compras

O leite entra pelo espelho dessa cadeia, chamado **procure to pay**, da compra ao pagamento. A fazenda
é um fornecedor; a coleta do caminhão é uma entrada de mercadoria; o extrato mensal de litros e
qualidade é a fatura do fornecedor, conferida contra as entradas; o pagamento no dia 10 a baixa. Na
Serra Alta o primeiro elo dessa cadeia nem está no SAP. O Coleta registra cada coleta e manda ao SAP,
toda noite, o total do dia de cada fazenda, num arquivo, e um programa do SAP transforma cada linha
numa entrada de mercadoria. A aula 9 desmonta esse arquivo, e a aula 13 é sobre substituir o sistema
que o escreve.

## Por que documentos e não linhas atualizadas

Três motivos, e cada um vira uma regra que um sistema de fora do ERP precisa respeitar.

**Um auditor precisa conseguir seguir o dinheiro.** Um documento que pudesse ser editado depois de
lançado deixaria qualquer um mudar o que os livros dizem que aconteceu, que é a única coisa que um
sistema contábil existe para impedir. Então um documento lançado é definitivo. **Um erro se corrige com
um documento novo que estorna o antigo**, e os dois ficam nos livros: a saída de mercadoria lançada na
fábrica errada é cancelada por um estorno e lançada de novo, e o auditor vê as três.

**Cada documento é o registro de uma decisão, de uma pessoa, num momento.** A ordem é o que o cliente
pediu. A remessa é o que o armazém concordou em despachar. A nota é o que foi cobrado. Quando o cliente
reclama que pediu 600 caixas e foi cobrado por 580, os dois documentos dizem exatamente onde a
diferença surgiu, e a remessa no meio diz por quê.

**O período fecha.** No fim de cada mês o time de finanças fecha o período contábil, e depois disso
nada mais pode ser lançado nele. Uma saída de mercadoria que aconteceu em 31 de outubro e é lançada em
3 de novembro cai em novembro. A aula 12 é sobre o que esse calendário faz com todo sistema que manda
dados para o ERP.

## Onde outro sistema pode entrar na cadeia

A cadeia explica o erro mais comum ao integrar com um ERP. **Um sistema de fora precisa entrar na
cadeia no passo que ele de fato representa, e deixar o ERP criar todo o resto.**

O Portal B2B recebe pedidos das padarias. A integração certa cria uma **ordem de venda** no SAP, e o
SAP então produz a remessa, a saída de mercadoria, a nota e o lançamento contábil pelas próprias
regras, com análise de crédito, impostos e estoque. O atalho tentador, já que a padaria pagou com
cartão, é criar a nota direto. Essa nota não apontaria para remessa nenhuma. Nenhum estoque sairia dos
livros, o armazém nunca saberia, e a contagem de estoque do fim do mês ficaria curta de todo pedido de
padaria que já passou pelo portal, sem nada ligando o buraco à causa.

A mesma regra vale para a leitura. **Um sistema que quer saber se um pedido foi despachado deve
perguntar pela saída de mercadoria, não olhar um campo de status na ordem.** O status da ordem é um
resumo que o SAP calcula para as próprias telas; a saída de mercadoria é o evento.

## Números, uma vez, para ter noção de escala

Num dia útil comum na Serra Alta, o SAP registra cerca de 1.400 ordens de venda, um número parecido de
remessas e notas, e cerca de 1.900 entradas de leite, uma para cada fazenda coletada. Cada uma é um
documento com número, data, usuário e ligação com o antecessor, e nenhuma é atualizada no lugar. Um
sistema que se integra com o ERP está entrando nesse fluxo, e precisa produzir documentos que o fluxo
consiga carregar.
