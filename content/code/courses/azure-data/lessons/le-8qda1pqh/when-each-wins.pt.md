---
title: Quando cada um ganha
version: 1
---

**A escolha entre um data flow e um notebook raramente é sobre os dados; é sobre quem vai cuidar da
transformação pelos próximos três anos.** Os dois rodam Spark, os dois conseguem limpar a noite da
Quitanda, e os dois cobram um cluster por minuto. O que muda é como uma mudança é feita, revisada,
testada e desfeita. Esta seção resume o argumento da lição, ensinado a partir da documentação e das
duas seções praticadas; nada nela rodou no Azure.

## Lado a lado

| | mapping data flow | notebook |
|---|---|---|
| escrito | desenhando caixas no editor | escrevendo código |
| uma mudança, revisada | um diff de um script que o editor escreveu | um diff do código que alguém escreveu |
| testado | rodando num cluster contra um conjunto de teste | por uma função em quatro linhas, num laptop, como nesta lição |
| o que consegue fazer | as caixas que o Data Factory oferece, e a linguagem de expressões delas | tudo o que o Spark e as bibliotecas dele conseguem |
| o cluster | iniciado por execução pelo runtime do Azure, nada para cuidar | um pool, uma sessão ou um cluster, conforme a plataforma |
| para onde muda | pipelines do Data Factory e do Synapse; não os dataflows do Fabric | Synapse, Fabric e Databricks, com pequenas mudanças |
| a conta | vCore-horas da execução, mais partida e time to live | vCore-horas, unidades de capacidade ou DBUs, mais minutos ociosos |

## Quando um data flow ganha

**Um data flow ganha quando as pessoas donas da transformação não escrevem código, e a
transformação é do tipo que as caixas fazem bem**: juntar, derivar, filtrar e agregar tabelas que já
estão arrumadas. Um time de analistas que sabe SQL e Data Factory, e nada de Python, consegue
construí-lo e mudá-lo, ver linhas a cada passo no debug, e nunca encontrar um cluster. O preço vem
depois e em silêncio: uma transformação que ninguém consegue testar sem um cluster, um diff que
ninguém lê, e uma mudança de plataforma que exige desenhá-la de novo.

## Quando um notebook ganha

**Um notebook ganha quando a transformação vai crescer**, quando tem regras que valem testes, quando
precisa de uma biblioteca, um formato de arquivo ou uma API que as caixas não oferecem, ou quando o
time espera mudar entre Synapse, Fabric e Databricks. A noite da Quitanda é desse tipo: os totais com
vírgula são a primeira regra, a segunda será uma devolução que cancela um pedido, a terceira uma
promoção que muda como um total é calculado, e cada uma deve chegar com um teste que falha antes da
correção. O preço é um time que escreve bem código, e um cluster que alguém escolheu e dimensionou.

## E quando nenhum dos dois

**Uma noite pequena não precisa de Spark.** A seção da mesma noite limpou um dia da Quitanda num
processo Python; nesse tamanho um cluster passa mais tempo subindo que trabalhando, e a conta da
seção do relógio é só custo fixo. O Data Factory pode chamar esse código como uma Azure Function, e o
Fabric pode rodá-lo como um notebook Python sem sessão Spark por trás. A hora certa do Spark é quando
os dados param de caber na memória de uma máquina ou na janela de uma noite, e vale medir esse
momento em vez de começar por ele.
