---
title: Gestão do sistema, e a fazenda que não recebeu
version: 1
---

Os outros grupos do livro descrevem como um fluxo funciona. O último descreve como você descobre que
ele parou de funcionar, e o que ele fez com uma mensagem em particular. **Um fluxo que você não
consegue observar é um fluxo que você só depura perguntando às pessoas do que elas se lembram**, e
numa empresa em que as fazendas são pagas por uma cadeia de cinco sistemas, era exatamente assim que
corria a maioria das investigações na Serra Alta.

## Quinta-feira, 10 de setembro

As fazendas recebem no dia 10. Na quinta-feira, 10 de setembro, às quatro da tarde, o dono do Sítio
Boa Esperança, uma fazenda perto de Barbacena que vende leite para a Serra Alta há dezenove anos,
ligou para o time de relacionamento com produtores: o dinheiro não tinha chegado. A fazenda tinha
entregado leite dia sim, dia não, agosto inteiro. Alguém precisava achar o pagamento.

Entre o leite e o dinheiro há cinco saltos, e cada um conhece a fazenda por um nome diferente.

| salto | sistema | como ele conhece a fazenda |
|---|---|---|
| 1 | o Coleta registra cada coleta | produtor 004417 |
| 2 | o arquivo noturno vira entradas de mercadoria no SAP (aula 1) | fornecedor 300417 |
| 3 | o programa de pagamento do SAP, no dia 10, cria um documento de pagamento | documento de pagamento 1500048213 |
| 4 | um fluxo do IIB leva o arquivo de remessa CNAB 240 do SAP até o banco | uma linha no arquivo de remessa |
| 5 | o arquivo de retorno do banco diz o que aconteceu com cada pagamento | uma linha no arquivo de retorno |

Os saltos 1 e 2 foram rápidos: o Coleta tinha os litros, e o programa ABAP que carrega o arquivo
mantém uma tabela de código de produtor para número de fornecedor. O salto 3 também foi rápido,
porque dentro do SAP o fluxo de documentos liga as entradas de mercadoria ao pagamento (aula 1). O
salto 4 foi onde a pista esfriou. O fluxo de remessa escrevia um número sequencial próprio no campo de
referência de cada linha de pagamento, e não o número do documento de pagamento do SAP. Então a linha
do fornecedor 300417 só podia ser achada pelo valor e pela conta bancária. E o arquivo de retorno do
banco, que tinha chegado às 07:10 daquela manhã, se referia ao mesmo número sequencial, que não batia
com nada no SAP.

O financeiro e o time do Rui levaram até a tarde seguinte para estabelecer o que o arquivo de retorno
dizia desde o início: **o pagamento foi rejeitado porque a conta estava encerrada.** O produtor tinha
trocado de banco em julho, e a mudança tinha chegado ao cadastro do Coleta, mas não ao cadastro de
fornecedores do SAP. O dinheiro continuava na conta da Serra Alta. Ninguém tinha sido avisado, porque
nada ligava a rejeição a um fornecedor.

## O identificador de correlação, de ponta a ponta

A correção não foi um sistema novo. **Cada salto já tinha um identificador; o que faltava era um
identificador levado através dos saltos.** O layout CNAB 240 tem um campo para a referência do próprio
pagador em cada pagamento, e o banco a devolve no arquivo de retorno. Rui mudou o fluxo de remessa para
pôr ali o número do documento de pagamento do SAP. Do salto 3 ao 5, o pagamento agora tem um nome só,
e uma linha rejeitada no arquivo de retorno aponta direto para um documento, que aponta direto para um
fornecedor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l11-trace\" aria-label=\"Cinco saltos do pagamento de uma fazenda, da esquerda para a direita, cada um com o identificador pelo qual conhece a fazenda. Coleta: produtor 004417. Entradas de mercadoria no SAP: fornecedor 300417. Programa de pagamento no SAP: documento de pagamento 1500048213. Fluxo de remessa no IIB: a linha CNAB, com referência 1500048213. Arquivo de retorno do banco: referência 1500048213, rejeitado, conta encerrada. Os saltos um e dois se ligam por uma tabela de produtor para fornecedor; os saltos três a cinco compartilham uma referência, levada de ponta a ponta. Abaixo do fluxo do IIB, um wire tap copia cada mensagem para um message store, pesquisável por fornecedor e por referência.\"><defs><marker id=\"l11-trace-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-trace-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"74.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"74.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Coleta</text><text x=\"74.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">produtor</text><text x=\"74.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">004417</text><path d=\"M140.0 120.0 L152.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"154.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"218.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"218.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SAP: entradas</text><text x=\"218.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fornecedor</text><text x=\"218.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">300417</text><path d=\"M284.0 120.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"298.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"362.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"362.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SAP: pagamento</text><text x=\"362.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">doc. pagamento</text><text x=\"362.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1500048213</text><path d=\"M428.0 120.0 L440.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"442.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"506.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"506.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">IIB: remessa</text><text x=\"506.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linha CNAB, ref.</text><text x=\"506.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1500048213</text><path d=\"M572.0 120.0 L584.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"586.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"650.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">retorno do banco</text><text x=\"650.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ref.</text><text x=\"650.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1500048213</text><text x=\"650.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rejeitado: conta encerrada</text><path d=\"M14 70 L14 62 L278 62 L278 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"146.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ligados por uma tabela de-para</text><path d=\"M302 70 L302 62 L710 62 L710 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"506.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma referência, levada de ponta a ponta</text><circle cx=\"506.0\" cy=\"160.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><path d=\"M506.0 164.0 L506.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-phosphor)\"></path><text x=\"498.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">wire tap</text><rect x=\"406.0\" y=\"232.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"245.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">message store</text><text x=\"506.0\" y=\"258.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">busca por fornecedor ou por ref.</text></svg>", "caption": "Uma fazenda, cinco saltos, três identificadores. Onde uma referência é levada do pagamento ao banco e de volta, o rastreamento é uma busca; onde não é, é um cruzamento que alguém tem de fazer à mão.", "same": ["Coleta", "message store", "wire tap"]}
```

Esse é o identificador de correlação da seção desta aula sobre a linguagem de padrões, esticado sobre
uma transação de negócio inteira. **A regra é escolher o identificador no primeiro salto em que ele
existe e levá-lo sem mudança até o último**, em vez de deixar cada salto inventar o seu e manter uma
tabela de como eles se correspondem. Os saltos 1 e 2 ainda se ligam por uma tabela de-para, porque o
Coleta é anterior ao SAP na Serra Alta e os códigos de produtor dele são o que os produtores conhecem.
As aulas 13 e 14, que planejam a substituição do Coleta e movem os dados dele, voltam a isso.

## Wire tap, message store e message history

A segunda mudança tornou o fluxo do IIB observável. Três padrões fizeram isso.

Um *wire tap* copia cada mensagem de um canal para um segundo canal, sem mudar o que o fluxo principal
recebe. O livro o descreve como uma lista de destinatários simples com dois destinos, um dos quais é o
próprio próximo passo do fluxo. Aqui o segundo destino alimenta um repositório.

Um *message store* guarda o registro das mensagens que passaram, num lugar só, pesquisável pelos campos
sobre os quais as pessoas de fato perguntam. No fluxo de remessa, esses são o número do fornecedor, o
número do documento de pagamento, o valor e a hora. Quando a próxima fazenda ligar, a pergunta *o banco
recebeu este pagamento?* é uma busca, e não um projeto.

O *message history* é uma lista levada dentro da própria mensagem, à qual cada componente acrescenta
seu nome e um horário quando a mensagem passa. Onde um message store responde *o que passou por aqui?*,
o histórico responde *por onde esta mensagem andou?* sem perguntar a cada salto separadamente. Os
fluxos do IIB podem gravá-lo numa propriedade da mensagem em cada nó que importa.

Duas cautelas vêm com um repositório desses. **Uma cópia de cada mensagem é uma cópia de cada dado
pessoal que há nela**: a remessa leva contas bancárias e CPFs de produtores, então o repositório
precisa de controle de acesso e de um prazo de retenção, decididos antes de ele encher, não depois. E
um wire tap não pode ser capaz de parar o fluxo que observa. Se a gravação no repositório falhar, o
pagamento ainda precisa chegar ao banco, o que quer dizer que o tap grava numa fila e outra coisa
enche o repositório.

## O resto do grupo

Os padrões restantes tratam de operar um fluxo, mais do que de seguir uma mensagem.

| padrão | o que faz | na Serra Alta |
|---|---|---|
| control bus | administra os componentes por um canal próprio: iniciar, parar, configurar, informar | o time do Rui para e inicia fluxos e lê as estatísticas deles pela interface de administração do IIB |
| detour | manda as mensagens por passos extras, ligados e desligados pelo control bus | durante uma troca de tabela de preços, os pedidos fazem um desvio por um passo de validação que confere cada preço |
| mensagem de teste | injeta uma mensagem conhecida para verificar que o fluxo funciona de ponta a ponta | um pedido sintético para uma loja de teste, toda manhã às 05:00, antes de chegarem os pedidos reais das redes |
| channel purger | remove mensagens de um canal | limpa uma fila de teste entre execuções; nunca usado numa fila de produção sem antes tirar uma cópia |

O livro imaginou o *control bus* como mensagens num canal próprio. O IIB faz o mesmo trabalho pela
interface web e pelos comandos dele, e o padrão continua dizendo o que procurar: um lugar onde cada
componente pode receber ordem de parar e ser perguntado sobre como está.

Uma *mensagem de teste* (*test message*) precisa de uma propriedade acima de todas: **cada sistema
adiante precisa reconhecê-la como teste.** O pedido sintético da Serra Alta cita uma loja que só existe
num grupo de clientes de teste, e o ramo do SAP responde a ele sem criar ordem nenhuma. Se algum
sistema do caminho não conhecesse a loja, o pedido de teste viraria um pedido real, e uma ordem de
venda real na Serra Alta termina numa NF-e, um documento fiscal que a SEFAZ registrou.

Um *channel purger* é o padrão mais perigoso do livro para usar em produção, porque limpar uma fila
apaga o que estiver nela, e numa fila de produção isso são pedidos, pagamentos ou coletas de fazendas.
Mensagens que não podem ser processadas pertencem a um dead letter channel, onde alguém consegue vê-las
(aula 10), e não a uma limpeza.

## O que a fazenda de Barbacena mudou

Desde setembro, a trilha do pagamento de fazendas tem uma referência do programa de pagamento até o
banco e de volta, um message store no fluxo de remessa e um alerta quando um arquivo de retorno rejeita
qualquer pagamento. O pagamento rejeitado seguinte, em outubro, foi achado pelo alerta às 07:15 da
manhã em que chegou o arquivo de retorno, oito horas antes de alguém poder ter telefonado. **Os padrões
deste grupo são baratos de acrescentar enquanto o fluxo está sendo construído e caros de acrescentar
durante um incidente.** Esse é o argumento para desenhá-los no projeto, ao lado dos roteadores e
tradutores, em vez de deixá-los para a operação parafusar depois.
