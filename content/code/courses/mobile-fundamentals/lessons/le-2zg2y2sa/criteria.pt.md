---
title: As perguntas que decidem
version: 1
---

**Nenhuma abordagem é a melhor; existe só a melhor para uma equipe, um app e uma data.** O jeito
comum de escolher é perguntar qual ferramenta é mais rápida, mais nova ou mais popular, e toda
resposta a essa pergunta começa uma discussão que ninguém ganha, porque cada lado tem razão sobre um
app diferente. O jeito útil é fazer um conjunto fixo de perguntas sobre a sua própria situação e
deixar as respostas apontarem. Sete perguntas cobrem quase toda decisão desse tipo.

| critério | a pergunta que ele faz |
|---|---|
| linguagens | O que a equipe já escreve bem, hoje? |
| recursos do aparelho | De que recursos o app precisa, e quão novos eles são? |
| desempenho | Alguma coisa precisa se mover com fluidez sob carga: animação, listas longas, a câmera? |
| tempo até a loja | Em quanto tempo a primeira versão precisa estar nas lojas? |
| plataformas | Android, iOS ou os dois, e em que ordem? |
| custo a longo prazo | Quem mantém o app funcionando nos próximos cinco anos, e com quantos códigos? |
| contratação | A equipe consegue achar mais gente que escreva isso, onde ela contrata? |

## O que cada um pesa

**As linguagens da equipe pesam mais que qualquer benchmark.** Uma equipe de desenvolvedores web que
escreve TypeScript todo dia começa o React Native ou um embrulho já sabendo a linguagem, e começa
Kotlin e Swift sem saber nenhuma das duas. Uma equipe que escreve Kotlin para Android tem o ponto de
partida oposto, e o Kotlin Multiplatform deixa que ela mantenha essa linguagem para a lógica do iOS.

**Recursos do aparelho são uma pergunta sobre a fronteira da aula 2.** Um app que precisa da câmera,
de notificações e de armazenamento acha bibliotecas para eles em toda abordagem. Um app construído em
volta de um recurso que a Apple ou o Google lançaram este ano espera alguém escrever a ponte, ou a
escreve sozinho em Kotlin e Swift. Quanto mais novo e raro o recurso, mais forte o argumento a favor
do nativo.

**Desempenho importa onde alguma coisa se move.** A documentação do Android sobre taxa de quadros,
lida em 30 de outubro de 2026, diz que os aparelhos tradicionalmente atualizavam a tela numa taxa
única, em geral 60 Hz, e que muitos agora também suportam 90 ou 120 Hz. Um app que é listas e
formulários fica fluido em qualquer abordagem bem feita. Um app que anima sob o dedo do usuário, rola
milhares de fotos ou processa os quadros da câmera sente cada camada entre o código e a tela. A aula 6
mede quanto custa um quadro.

**O tempo até a loja conta o que já existe.** Uma equipe com um app web funcionando chega às lojas
mais cedo com um embrulho, porque as telas já estão escritas. Uma equipe começando do nada não ganha
muito tempo com um, e leva os limites da WebView em troca.

**O número de plataformas muda a conta do nativo.** Para uma plataforma, o nativo não custa nada a
mais: só existe um app. Para duas, o nativo quer dizer dois códigos, e toda funcionalidade, correção
e teste é feito duas vezes.

**O custo a longo prazo é pago anos depois da decisão.** Dois códigos nativos precisam de dois
conjuntos de habilidades enquanto o app viver. Um código multiplataforma precisa de um, mais quem
mantém as pontes na fronteira, mais o trabalho de acompanhar as atualizações da própria ferramenta.

**Contratação é o critério que as equipes esquecem até alguém sair.** A pergunta não é qual linguagem
é popular em geral, e sim se a equipe consegue substituir uma pessoa, na cidade ou no mercado onde
contrata, na linguagem que escolheu.

## Duas coisas que os critérios não são

**Não são uma nota das ferramentas.** "O Flutter é rápido" não diz nada até você saber o que o app
desenha. Cada critério é uma propriedade da sua situação, e a mesma ferramenta responde a ele de um
jeito diferente para duas equipes.

**E não têm a mesma importância.** Para um banco, recursos do aparelho e custo a longo prazo podem
dominar; para uma startup com três meses de dinheiro, o tempo até a loja domina. Quanto cada pergunta
pesa é a parte que só a equipe pode decidir, e a etapa depois da próxima torna isso visível.
