---
title: O barramento que cresceu
version: 1
---

Ninguém na Serra Alta decidiu pôr regras de negócio no barramento. Cada uma chegou como um pedido
razoável, num dia em que o barramento era o lugar mais rápido para fazer uma mudança, vindo de um
time que precisava dela até o fim do mês. **Um barramento acumula lógica do mesmo jeito que uma
tabela compartilhada acumula colunas: um acréscimo conveniente de cada vez, cada um defensável, e a
soma uma coisa que ninguém teria projetado.** Joana achou três regras assim na primeira quinzena
lendo fluxos. Ao fim do inventário da seção 07 desta aula, eram dezoito os fluxos que guardavam
uma.

## Três regras que moram no cano

A primeira é um desconto. Em 2023 o Portal B2B entrou no ar, e o time comercial queria que as
padarias tivessem 3% de desconto em todo pedido acima de R$ 1.500. O lugar certo para essa regra
era o preço do SAP, onde mora todo outro desconto, mas o backlog do time de SAP a jogava quatro
meses para a frente. O fluxo que leva os pedidos do portal ao SAP, `PB2B_ORDER_TO_SAP`, já estava
sendo escrito. O time de Rui acrescentou a regra em umas trinta linhas de ESQL, antes de o pedido
chegar ao SAP, e o portal entrou no ar na data.

Em 2025 o time comercial subiu o limite para R$ 1.800. Pediram ao time de SAP, que mudou no SAP,
onde todos achavam que a regra morava. O fluxo continuou aplicando 3% a partir de R$ 1.500 por cinco
meses, até que um auditor, conferindo uma amostra de notas, perguntou por que alguns pedidos
tinham um desconto que a tabela de preços não explicava. **Uma regra com duas casas é uma regra que
vai discordar de si mesma**, e nada em nenhum dos dois sistemas consegue dizer qual cópia é a
verdadeira.

A segunda é uma decisão sobre que fábrica despacha. As redes de supermercados mandam pedidos por
EDI, e o fluxo `EDI_ORDER_IN` escolhe a fábrica que atende cada item: manteiga de Lavras, leite em
pó de Barbacena e, para o leite UHT, Juiz de Fora, a não ser que o centro de distribuição da rede
fique ao sul de uma latitude escrita no fluxo. É uma decisão de logística. Ela pertence a quem
planeja estoque e caminhões, e foi parar no barramento porque o barramento era a primeira coisa a
ver o pedido.

A terceira é um bloqueio de crédito. Quando uma oportunidade do Salesforce vira pedido, o fluxo que
o cria no SAP pergunta antes ao SAP o saldo em aberto do cliente, compara com o limite de crédito e,
se o limite foi ultrapassado, manda o pedido com bloqueio de remessa e um e-mail para o financeiro.
O SAP tem a sua própria gestão de crédito; a regra do fluxo e a regra do SAP foram montadas com dois
anos de diferença por pessoas diferentes, e não usam o mesmo limite.

## Como reconhecer lógica num fluxo

Mover uma mensagem de um lugar para outro é integração. Mudar o formato dela é integração. Decidir
alguma coisa sobre o negócio não é, e em geral dá para ver, se você souber o que procurar. **Um
fluxo carrega lógica de negócio quando uma pessoa do negócio poderia pedir para mudá-la.** Três
sinais a denunciam:

- um número no código que pertence a alguém de fora da TI: um limite, um percentual, um teto, uma
  data;
- uma decisão que uma pessoa do negócio reconheceria e discutiria: que fábrica, se bloqueia, que
  preço;
- uma chamada a um terceiro sistema para decidir, e não para preencher um campo de que o receptor
  precisa.

Por esse teste, um fluxo que transforma `20261022` em `2026-10-22` não carrega nenhuma, e um fluxo
que descarta pedidos de clientes com nota vencida carrega uma política de crédito, por mais curto
que seja o seu código.

## O time virou uma fila

A segunda coisa que cresceu foi a espera. Toda mudança em qualquer integração da Serra Alta passa
pelo time de quatro pessoas de Rui, porque são as únicas que conhecem a ferramenta, o ESQL e o
processo de implantação, e porque um erro num fluxo pode parar o motor em que todos os outros
rodam. Em outubro de 2026, quando Joana conta, **23 pedidos de mudança estão esperando, e o pedido
médio esperou 9 semanas antes de alguém começar.** O time do Rota esperou 11 semanas para que um
campo fosse acrescentado à resposta do FarmRegistry.

Nada disso é preguiça. É a aritmética de um recurso compartilhado. O time é pequeno, o trabalho
chega de todos os projetos ao mesmo tempo, e cada mudança precisa ser testada num único ambiente de
teste compartilhado onde convivem 70 fluxos. As pessoas que sabem o que uma mudança deve fazer — o
time do portal, a administradora do Salesforce, os planejadores de logística — não podem fazê-la,
e as pessoas que podem fazê-la precisam aprender, a cada vez, o que ela deve fazer. **O time
central transforma toda mudança de integração numa passagem de bastão, e toda passagem de bastão é
uma fila.** Quanto maior a fila, mais times acham outro caminho em volta dela: um link direto com o
banco, uma planilha, um arquivo numa pasta compartilhada. Cada um desses é o problema de 2014
voltando pela porta dos fundos.

## Pontas inteligentes e canos burros

Em 2014, James Lewis e Martin Fowler publicaram um artigo descrevendo o estilo de arquitetura que
então começava a ser chamado de microsserviços. Uma das suas características foi posta numa frase
que pegou: **smart endpoints and dumb pipes**, pontas inteligentes e canos burros. A lógica mora
nos serviços que são donos dos dados e das decisões; o que os liga faz o mínimo possível — move a
mensagem, com confiabilidade, e mais nada. Eles escreveram isso explicitamente em contraste com o
ESB, onde o cano tinha virado a coisa mais inteligente do prédio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l08-logic\" aria-label=\"Dois painéis. À esquerda, o barramento que cresceu: o Portal B2B, o Salesforce e o EDI mandam para um barramento largo, que guarda três regras de negócio (um desconto de 3% acima de R$ 1.500, qual fábrica envia, um bloqueio de crédito) e repassa os pedidos ao SAP ECC. À direita, pontas inteligentes e canos burros: os mesmos três remetentes põem mensagens num cano fino de MQ que não guarda regra nenhuma, e o SAP ECC guarda as três decisões no seu próprio preço, logística e gestão de crédito.\"><defs><marker id=\"l08-logic-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o barramento que cresceu</text><rect x=\"118.0\" y=\"58.0\" width=\"150.0\" height=\"204.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"193.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ESB</text><rect x=\"126.0\" y=\"91.0\" width=\"134.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"193.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3% acima de R$ 1.500</text><rect x=\"126.0\" y=\"151.0\" width=\"134.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"193.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">qual fábrica envia</text><rect x=\"126.0\" y=\"211.0\" width=\"134.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"193.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">bloqueio de crédito</text><rect x=\"12.0\" y=\"86.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M100.0 100.0 L116.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"12.0\" y=\"146.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><path d=\"M100.0 160.0 L116.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"12.0\" y=\"206.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><path d=\"M100.0 220.0 L116.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"283.0\" y=\"140.0\" width=\"70.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP ECC</text><path d=\"M268.0 160.0 L281.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><text x=\"175.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">as regras moram no cano</text><path d=\"M362.0 40.0 L362.0 296.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"545.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">pontas inteligentes, canos burros</text><rect x=\"382.0\" y=\"86.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"426.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M470.0 100.0 L492.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"382.0\" y=\"146.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"426.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><path d=\"M470.0 160.0 L492.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"382.0\" y=\"206.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"426.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><path d=\"M470.0 220.0 L492.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"494.0\" y=\"70.0\" width=\"16.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MQ</text><path d=\"M510.0 160.0 L524.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"526.0\" y=\"82.0\" width=\"184.0\" height=\"156.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"618.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"533.0\" y=\"117.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"618.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">preço: 3% acima de R$ 1.800</text><rect x=\"533.0\" y=\"155.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"618.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">logística: qual fábrica envia</text><rect x=\"533.0\" y=\"193.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"618.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gestão de crédito</text><text x=\"545.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o cano move mensagens; o dono decide</text></svg>", "caption": "Onde a lógica fica. À esquerda, uma regra pode ser mudada no SAP e continuar rodando, sem mudança, no barramento; à direita, cada regra tem uma casa só, com o time que é dono dela.", "same": ["EDI", "ESB", "Portal B2B", "SAP ECC", "Salesforce"]}
```

Duas leituras erradas da frase são comuns, e as duas fariam mal à Serra Alta.

A primeira é que *burro* quer dizer *não confiável*. Não quer. O IBM MQ segurando uma mensagem até
o SAP voltar da janela de domingo é um cano burro no sentido de Lewis e Fowler: ele não sabe nem
quer saber o que há na mensagem. Entrega confiável, novas tentativas no nível do transporte,
roteamento por um destino declarado e monitoramento são coisas que um cano burro faz. **O que um
cano burro nunca faz é decidir alguma coisa sobre o negócio.**

A segunda é que pontas inteligentes significam não ter time de integração. O trabalho que o time de
Rui faz bem — operar o MQ, definir padrões de formato e de segurança para as mensagens, observar o
que passa e o que está parado, saber o que acontece quando o SAP reinicia — é mais necessário, e não
menos, quando doze times são donos cada um das suas integrações. O que muda é o trabalho: de
construir todo fluxo para operar a plataforma em que os fluxos rodam, e de fazer mudanças para
outros times para revisar as mudanças que esses times fazem.

## Quanto custa deixar a lógica onde está

Joana escreve o argumento para Regina em três linhas, cada uma com um número:

| custo | evidência na Serra Alta |
|---|---|
| regras com duas casas se separam | o desconto rodou com o limite antigo por cinco meses |
| a mudança espera por um time que não é dono da regra | 23 pedidos esperando, 9 semanas em média |
| o barramento não pode ser atualizado nem trocado sem decidir o negócio de novo | 18 fluxos guardam regras que teriam de ser reescritas, e acertadas com os seus donos, antes que qualquer um deles pudesse mudar de lugar |

A terceira linha é a que decide o futuro do barramento. Um barramento que só roteia e transforma
pode ser trocado por outro, ou por mensageria simples, em meses. **Um barramento que guarda as
regras do negócio só pode ser trocado depois de achar uma casa para essas regras**, e isso é um
projeto com o comercial, a logística e o financeiro na sala, não uma atualização de integração. A
seção 07 mostra como fazer.
