---
title: O que custa ter uma suíte
version: 1
---

A primeira nota de Joana sobre o IBM BPM tinha quatro linhas. Três processos, uma licença renovada
todo ano para uma coisa que um desenvolvedor mantém, e um time de produto no fim do corredor que
escreve Kotlin todo dia. Reconstruir os três processos como serviços, escreveu ela, seis semanas de
trabalho, e parar de pagar a IBM. Era a nota de alguém que passou oito anos construindo, e estava
errada de um jeito que vale estudar. **O preço de uma suíte não é a licença. É tudo o que a empresa
colocou dentro do produto e teria de carregar para fora dele.**

O gatilho foi um pedido de Denise Okada. O escritório dela queria um quarto processo no IBM BPM, a
requalificação anual de fornecedores, com o argumento de que a plataforma já estava paga. Regina pediu
a Joana uma avaliação antes que alguém dissesse sim. Esta seção acompanha essa avaliação, custo por
custo.

## A lógica está no formato do fornecedor

Os diagramas de processo no IBM BPM são desenhados em BPMN, que é um padrão, então é tentador achar
que os processos são portáveis. O diagrama é o de menos. Por trás de cada caixa há algo que só o
produto entende: um formulário feito como Coach, um script preso a um passo, um serviço de
integração, uma definição de variável, uma regra sobre quem pode pegar uma tarefa. **Exportar o
diagrama exporta a figura e deixa o comportamento para trás.**

Vinícius produziu o inventário que as quatro linhas de Joana tinham pulado:

| o quê | quantos |
| --- | --- |
| aplicações de processo | 3 |
| formulários (Coaches) | 27 |
| serviços de integração, a maioria chamando fluxos no barramento | 14 |
| scripts presos a passos | 41 |
| timers | 6 |
| instâncias abertas | 1.986, das quais 61 vivas |
| anos de histórico em que os auditores se apoiam | 12 |

Cada linha é trabalho numa reconstrução. Os 27 formulários são 27 telas para desenhar de novo, com
usuários que conhecem as antigas. Os 14 serviços de integração têm cada um uma contraparte no
barramento que a aula 8 herda, e alguns deles codificam tratamento de erro que ninguém escreveu. Os
41 scripts guardam regras de negócio: o limite de crédito de R$ 150.000 é uma delas, e também a regra
de que uma fazenda com atestado sanitário vencido não chega ao passo do contrato.

## As habilidades são raras, e uma pessoa as tem

A Serra Alta tem uma pessoa capaz de mudar esses processos. Vinícius é bom, e é um ponto único de
falha no sentido mais simples: se ele sair, a empresa continua rodando os processos, porque o motor
os roda, mas não consegue mudá-los. As mudanças passam a esperar uma consultoria, com o preço e os
prazos de uma consultoria.

Joana procurou pessoas com IBM BPM no perfil a uma distância de Juiz de Fora que dê para ir todo dia
e achou duas. A habilidade não está morrendo em toda parte, mas **o grupo de pessoas que conhece um
produto encolhe em todo mercado onde ele deixa de ser instalado**, e a empresa que fica com o produto
continua pagando por essa escassez em salário, em terceirizados ou em mudanças que não são feitas. A
correção mais barata de toda a avaliação é também a mais urgente: um segundo desenvolvedor
trabalhando ao lado do Vinícius este ano, seja qual for a decisão sobre o produto.

## A licença cresce com alguma coisa

A IBM licencia boa parte do seu middleware por capacidade de processamento, medida em processor
value units ou em núcleos de processador virtuais, e alguns produtos por usuário autorizado, com uma
taxa anual de assinatura e suporte além da licença em si. A métrica que o contrato usa decide o que
faz a conta crescer. **Antes de assinar, descubra o número do seu próprio negócio que a métrica da
licença acompanha**, porque esse número vai mudar. Uma métrica por usuário cresce quando o escritório
da Denise põe os 40 técnicos de campo como usuários de um processo novo; uma métrica por núcleo cresce
quando o motor precisa de mais servidores.

A Serra Alta paga à IBM cerca de R$ 310.000 por ano em assinatura e suporte do BPM. É o número da
Serra Alta, tirado da sua própria fatura, e não diz nada sobre o que a IBM cobra de qualquer outra
empresa. É o número que a primeira nota de Joana queria economizar. É também o único custo desta
página que está impresso numa fatura, e é por isso que recebe atenção desproporcional ao seu tamanho.
A aula 15 põe todos os custos de um sistema numa tabela só, três anos à frente, e mostra como os que
não vêm em fatura decidem a maior parte das decisões.

## Upgrades são projetos

A Serra Alta instalou a 8.5 em 2014 e não fez upgrade desde então. A cada ano a distância aumentou: o
produto mudou de nome, saíram versões novas, e o sistema operacional, o banco de dados e o runtime
Java por baixo envelheceram junto. Um upgrade agora não é um fim de semana. É um projeto, com testes
próprios de três processos, 27 formulários e 14 integrações, e um plano para as instâncias que
estiverem rodando na hora.

Joana não sabe qual é hoje a posição de suporte da IBM para a 8.5, e não chuta. Ela pede por escrito
ao time de conta da IBM três coisas: a situação de suporte da versão instalada, o caminho suportado
até o Business Automation Workflow e quanto esse caminho custa. **Uma data de suporte citada de
memória, ou de um blog, é um fato sobre o contrato de outra pessoa.**

## A saída

Há dois caminhos amplos para sair, e nenhum é de graça.

**Ficar com a suíte.** Pagar a assinatura, subir para uma versão suportada, treinar um segundo
desenvolvedor e manter os processos onde estão. O motor continua fazendo bem a parte difícil. O custo
é a licença, o projeto de upgrade e a escassez de habilidades, todo ano.

**Reimplementar em outro lugar.** Levar cada processo para onde ele cabe melhor: um motor aberto no
código da própria Serra Alta, uma plataforma que a empresa já tem, ou um produto comprado. Cada
processo então precisa do modelo reconstruído, dos formulários reconstruídos, das integrações
reapontadas, das instâncias em andamento escoadas ou migradas, e do histórico exportado para algum
lugar legível. Feitas direito, as seis semanas de Joana viraram uma estimativa de sete meses para dois
desenvolvedores, fora o histórico.

Nenhum dos dois é o padrão. O movimento útil é parar de tratar os três processos como uma decisão só.
Eles diferem em quanto tempo as instâncias vivem, em quantos sistemas tocam e em quantas vezes mudam.

## Perguntas a fazer antes de comprar uma suíte

A maior parte do custo de uma suíte é decidida antes de alguém usá-la. Estas são as perguntas que
Joana agora faz a qualquer produto de processos, inclusive aos que a Serra Alta já tem:

- O que contém a exportação de um processo, e que comportamento fica para trás no produto?
- Como as instâncias em execução são tratadas quando um processo muda: lado a lado, migradas, ou as
  duas coisas?
- Onde fica o histórico, por quanto tempo, e a empresa consegue tirar relatórios dele sem o
  fornecedor?
- Qual é a métrica da licença, e que número do nosso negócio ela acompanha?
- Quantas pessoas no nosso mercado conseguem mudar processos nesse produto, e quanto custam?
- O que envolve um upgrade, e com que frequência o fornecedor espera um?
- Se saíssemos em cinco anos, o que levaríamos, e em que formato?

Nenhuma delas é sobre o modelador, e todas são sobre o motor e o contrato.

## A avaliação de Joana

A nota que Joana mandou a Regina não tinha quatro linhas.

> O IBM BPM fica por enquanto, e não recebe um quarto processo. A requalificação de fornecedores
> entra na mesma decisão que os outros três, em vez de aumentar o que teríamos de mover.
>
> Neste trimestre: um segundo desenvolvedor ao lado do Vinícius. Exportar o histórico das 1.925
> instâncias mortas, conciliar os 315 cadastros de fornecedor com o SAP e encerrá-los com o aval da
> Denise e do financeiro. Implantar uma versão do cadastro de fazenda sem o ramo do *Fomento
> leiteiro*. Acrescentar uma nova tentativa que conheça a janela de domingo do SAP, e um alerta sobre
> a idade da tarefa mais antiga de cada grupo. Começar uma exportação noturna do histórico para o data
> warehouse.
>
> Por escrito, da IBM: a situação de suporte da 8.5, o caminho até o Business Automation Workflow e o
> custo dele.
>
> Depois, um processo de cada vez. A aprovação de crédito primeiro: as instâncias dela duram quatro
> dias, então ela escoa em uma semana, e só toca o Salesforce e o SAP. O cadastro de fazenda por
> último, porque a Denise e eu vamos modelá-lo de novo do zero, e o futuro dele está amarrado ao do
> Coleta.

A aula 7 é essa sessão de modelagem. As aulas 13 a 15 são o futuro do Coleta, e decidem o do cadastro
de fazenda junto.
