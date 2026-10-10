---
title: Bom o suficiente para o que serve
version: 1
---

Dois lemas opostos circulam sobre qualidade. Um diz para sempre construir direito; o outro, para ir
rápido e consertar depois. Os dois tratam a qualidade como um único botão para o sistema inteiro.
**Qualidade é um encaixe entre um trabalho e aquilo para que ele serve**: quanto tempo o código vai
viver, com que frequência vai mudar e o que acontece quando estiver errado. A régua certa para o
código que paga os motoristas é a régua errada para um script que roda uma vez, e o trabalho da
arquiteta é dizer qual é qual.

## A régua muda de parte para parte

Renata escreveu a régua para seis tipos de trabalho na Carreto, e a tabela encerrou mais discussões
sobre "excesso de capricho" do que qualquer princípio tinha encerrado.

| o trabalho | quanto tempo vive | quanto custa estar errado | a régua |
|---|---|---|---|
| o razão dos repasses | anos, mudando todo mês | um motorista pago duas vezes, ou nenhuma | design revisado, testes em todo caminho do dinheiro, operações idempotentes |
| a emissão do CT-e | anos, mudando a cada leiaute | um caminhão que não pode sair, e possíveis multas | testes contra a validação da autoridade fiscal, uma rodada no ambiente de testes dela antes do release |
| o motor de cotação | anos, mudando toda semana | uma cotação abaixo do piso da ANTT, ou uma carga perdida por preço alto | testes da regra do piso e de todo tipo de cotação |
| um relatório mensal para o financeiro | meses | um número errado num slide, que uma pessoa provavelmente vai notar | uma segunda pessoa confere os totais |
| uma migração de dados avulsa | uma execução | rodar de novo | testada numa cópia de produção, depois apagada |
| um protótipo de kata | uma tarde | nada | nenhuma |

**A régua é definida pela consequência e pela vida útil, não por quão importante o time se sente.**
Uma migração avulsa pode mover um milhão de linhas e ainda merecer uma régua leve, porque o risco dela
é tratado ensaiando numa cópia, e não construindo o script para uma vida longa que ele nunca vai ter.
O motor de cotação não tem glamour e merece uma régua alta, porque uma cotação abaixo do piso da ANTT
é uma violação da lei com o nome da Carreto.

Algumas dessas réguas cabem nos padrões da aula 9, escritas com os motivos: "toda mudança em
Payments vai com testes nos caminhos do dinheiro" é um padrão com dono e motivo. Outras ficam como
julgamento, feito pelo time e revisado como parte de um design.

## Dívida deliberada, por escrito

Quando um time escolhe uma qualidade interna menor para ganhar tempo, ele contrai dívida técnica. O
quadrante da dívida técnica de Martin Fowler, de 2009, classifica a dívida com duas perguntas: foi
contraída de propósito ou sem perceber, e foi prudente ou imprudente? "Precisamos entregar agora e
lidar com as consequências" é deliberada e prudente, um empréstimo tomado sabendo o que se faz, com
plano de pagar. "Não temos tempo para design" é deliberada e imprudente. O curso `tech-strategy`
desmonta o quadrante na aula 4 dele e põe preço na dívida na aula 5, então esta seção fica estreita.

**A única dívida que uma arquiteta deveria aceitar é a deliberada e prudente, e deliberada quer dizer
escrita.** Um atalho que ninguém registrou vira, em menos de um ano, uma dívida que ninguém sabe
explicar: quem a contraiu mudou de lugar, o motivo se perdeu, e o que era um empréstimo parece uma
bagunça. Escrita, ela tem dono, motivo e data, o que a terceira seção mostra por inteiro.

## Uma data que ninguém move

O caso que testa tudo isso chegou no segundo trimestre de Renata. De tempos em tempos as
autoridades fiscais publicam uma nova versão do leiaute do CT-e, com campos novos e regras de
validação alteradas, junto com uma data a partir da qual documentos no leiaute antigo são rejeitados.
Depois dessa data, um CT-e que a Carreto emita no leiaute antigo é recusado, e um caminhão sem CT-e
autorizado não pode partir.

A Carreto ficou sabendo do novo leiaute com dez semanas de antecedência. **A data não era
negociável, porque não era da Carreto.** O time era só um pouco mais flexível. O código do CT-e vive
no monólito, três engenheiros de Payments o conhecem, e pôr gente que não conhece as regras fiscais a
dez semanas do prazo atrasaria os três, que é a lei de Brooks da seção anterior. Dois cantos do
triângulo estavam fixos, e o que sobrava para mover era o escopo.

## Achar o menor escopo que resolve

Renata e Bruno Farias passaram pelo trabalho item por item e fizeram uma pergunta a cada um: **o que
acontece no dia se isto não estiver feito?**

| item | se não estiver feito no dia | quando |
|---|---|---|
| os novos campos obrigatórios do frete rodoviário, cerca de 97% dos CT-es da Carreto | todos esses CT-es são rejeitados | até a data |
| as novas regras de validação | rejeições, um caminhão de cada vez | até a data |
| multimodal e outros casos raros, cerca de 3% dos CT-es | um analista do back-office os emite por um procedimento manual durante algumas semanas | quatro semanas depois |
| a tela do back-office que corrige um CT-e depois de emitido | as correções são feitas por um engenheiro, algumas por semana | um mês depois |
| reestruturar o gerador para que um leiaute seja um mapeamento separado e versionado | nada acontece no dia | não é preciso para a data |

A última linha não faz parte do escopo para a data, e é nela que as opções da próxima seção diferem.
**O bom o suficiente foi medido contra um único propósito, todo CT-e comum autorizado no dia**, e
contra esse propósito as linhas abaixo das duas primeiras podiam esperar. Fazer isso com o negócio na
sala importa: os 3% tratados à mão eram os embarques rodoferroviários da cooperativa de grãos, e
Helena combinou de ligar ela mesma para eles antes de acontecer.

Bom o suficiente não é uma régua mais baixa. As duas primeiras linhas tiveram a régua completa da
tabela anterior, testes contra a validação da autoridade fiscal incluídos, porque são as linhas em
que um erro deixa caminhões parados. O que se cortou foi escopo, nunca a qualidade do escopo que ficou.
