---
title: Quando uma medida vira meta
version: 1
---

**Um número usado para julgar pessoas deixa de medir o que media, porque as pessoas começam a trabalhar no número.**
O economista Charles Goodhart fez a observação sobre política monetária em 1975, e a antropóloga Marilyn Strathern
deu a ela a forma em geral citada: *quando uma medida vira meta, ela deixa de ser uma boa medida.* Chama-se **lei de
Goodhart**, e o teste está cheio dela.

Não é uma reclamação sobre gente trapaceando. A maior parte do estrago é feita por pessoas honestas fazendo o que foi
pedido. Se o número é o que se recompensa, o número é o que melhora, pelo caminho mais barato disponível, e o caminho
mais barato raramente passa pela qualidade.

## O padrão, cinco vezes

| a meta | o que as pessoas razoavelmente fazem | o que acontece com a qualidade |
|---|---|---|
| mais casos de teste por sprint | escrevem casos menores e mais óbvios | a cobertura do que importa não se mexe |
| mais defeitos achados por pessoa | relatam cada sintoma separado; evitam investigações longas | os defeitos sutis, que levam um dia cada, deixam de ser achados |
| menos defeitos abertos na entrega | fecham defeitos como "não vamos corrigir" ou os rebaixam no último dia | a entrega parece limpa e não está |
| mais cobertura de código | escrevem testes que executam linhas sem conferir resultados | aula 7: uma linha executada não é uma linha conferida |
| lead time menor no quadro | movem cartões para *pronto* antes de testá-los | aula 13: o diagrama fica lindo |

Cada linha já apareceu neste curso, em geral como alerta. Aqui estão num lugar só, porque são o mesmo erro.

## Por que números de teste são especialmente vulneráveis

A maioria dos números de teste conta **atividade** ou **defeitos**, e os dois são fáceis de mudar sem mudar o
produto. A atividade pode ficar maior sendo dividida; os defeitos podem ficar menos não olhando, ou mais olhando o
trivial. Um número que pode ser movido sem mover a qualidade vai ser, assim que o bônus de alguém depender dele.

Há um segundo efeito, mais quieto. Um time medido por defeitos achados começa a ver quem desenvolve como a fonte da sua
pontuação, e a abordagem do time todo da aula 5 morre ali mesmo. O teste vira uma disputa entre quem escreve defeitos e
quem os acha, que é exatamente a relação contra a qual este curso argumenta desde o começo.

## Teatro de métricas

Quando os números param de informar decisões e começam a ser encenados, o resultado é o **teatro de métricas**: um
painel atualizado toda semana, apresentado em toda revisão, em que ninguém acredita e com que ninguém age. Os sinais são
fáceis de ver:

- os números sempre andam para o lado certo;
- ninguém sabe dizer a que decisão levou a última mudança num número;
- as pessoas gastam mais tempo produzindo o relatório do que o relatório economiza;
- uma pergunta sobre um número é respondida com uma história sobre por que está tudo bem.

O remédio não é mais números. São menos, cada um com uma pergunta acima, olhados por quem toma decisões, e nunca usados
para classificar as pessoas que os produzem.
