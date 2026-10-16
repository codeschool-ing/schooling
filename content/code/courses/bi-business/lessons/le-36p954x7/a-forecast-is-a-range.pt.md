---
title: Uma previsão é uma faixa
version: 1
---

Em janeiro de 2026 o Otávio Lins, o diretor financeiro, perguntou à Lívia quanto a Varanda ia vender
no primeiro trimestre. Ele precisava do número para o banco e para os pedidos de estoque, e queria um
número só. **A ideia errada é que uma previsão é um número. Uma previsão é um número, um horizonte e
uma faixa**, e a faixa é a parte que diz a quem decide quanto peso o número aguenta.

## Por que um número só engana

Toda previsão vai errar. As únicas perguntas são por quanto, e para que lado. Um número só esconde as
duas coisas: "R$ 22,0 milhões" parece um fato, e quando o trimestre fechar um pouco abaixo alguém vai
dizer que a previsão falhou, embora um erro desse tamanho sempre tenha sido provável. Pior, o Otávio
não tem como se planejar para um erro que ninguém avisou. Se a resposta honesta é "entre R$ 21,5 e
22,5 milhões", ele pode fazer os pedidos de estoque pelo meio e deixar o banco coberto pela ponta de
baixo.

**Uma faixa não é confissão de fraqueza.** É a informação de que a decisão precisa. Uma previsão de
22,0 que pode errar 2% e uma que pode errar 20% levam a pedidos de estoque diferentes, e só a faixa
diz qual das duas você tem.

## O horizonte

Uma previsão para a semana que vem é mais fácil que uma para o próximo dezembro, porque menos coisa
pode mudar no meio. **Toda previsão declara o seu horizonte**, a distância entre o último dado
conhecido e o período previsto, e toda faixa se alarga quando o horizonte cresce. O trimestre da
Lívia tem um horizonte de um a três meses a partir do fechamento de 2025. A próxima seção faz uma
previsão com horizonte de até seis meses, para ver quanto isso custa.

## Três métodos que só precisam do histórico

Antes de alguém construir um modelo estatístico, três métodos simples definem a régua. Cada um só
precisa do histórico de vendas que a Varanda já tem, e cada um cabe numa fórmula de planilha:

| método | a previsão de um mês é | o que ele supõe |
|---|---|---|
| ingênuo | o último mês conhecido | nada muda daqui em diante |
| sazonal ingênuo | o mesmo mês um ano antes | este ano repete o ano passado |
| sazonal ingênuo × crescimento | o mesmo mês um ano antes, vezes o crescimento recente | este ano repete o desenho do ano passado, no ritmo recente |

**O método ingênuo ignora a estação**, e na Varanda isso é fatal: uma previsão que diz que dezembro
vai vender o que junho vendeu erra dezembro em 40%, como a próxima seção mede. O sazonal ingênuo
mantém o desenho do ano mas supõe crescimento zero, então numa empresa que cresce todo ano ele erra
para o mesmo lado em quase todos os meses. O terceiro método mantém o desenho e acrescenta o ritmo,
mais ou menos como um gestor experiente faz a previsão de cabeça.

Esses métodos se chamam **linhas de base**. Um método mais sofisticado precisa superá-los para valer
o que custa, e muitas vezes não supera. Essa comparação é o assunto da aula 2 de `machine-learning`, e
a mesma disciplina vale aqui: antes de confiar em qualquer previsão, descubra como uma linha de base
teria se saído. A próxima seção faz isso para o segundo semestre de 2025, só com os dados que a Lívia
teria no fim de junho.
