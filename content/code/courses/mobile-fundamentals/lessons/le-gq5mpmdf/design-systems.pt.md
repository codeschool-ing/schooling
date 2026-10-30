---
title: Dois design systems, e para que serve cada um
version: 1
---

**Um design system é um conjunto de decisões que alguém tomou uma vez para que ninguém precise
tomá-las de novo em cada tela.** Ele dá nome às peças de que uma tela é feita, diz onde cada uma fica
e para que serve, e fixa as cores, a tipografia e o espaçamento que elas compartilham. A imagem comum
é a de um guia de estilo, uma página de cores e um logotipo. Essa é a menor parte. A parte útil é o
acordo sobre comportamento: qual barra troca de seção, onde fica a ação principal, o que significa
uma folha que sobe da base da tela.

**Cada plataforma publica o seu, porque cada uma quer que os apps dela pareçam um lugar só.** Quem já
usou dez apps Android espera que o décimo primeiro ponha as seções na mesma barra e o voltar no mesmo
gesto, e quem usa iPhone espera o mesmo do próximo app de iPhone. Um app que segue o design do
sistema herda de graça o que dez apps já ensinaram. O do Google é o **Material Design**, hoje na
terceira versão, o Material 3, publicado por inteiro em `m3.material.io`. O da Apple são as **Human
Interface Guidelines**, as HIG, em `developer.apple.com/design/human-interface-guidelines`. Tudo o
que esta aula diz sobre os dois foi lido em 30 de outubro de 2026: o Material na documentação do
Android sobre o Material 3 no Compose e nas páginas de componentes dela, as HIG nas próprias páginas.
Essas páginas têm data e mudam. A página de toolbars das HIG diz que absorveu a antiga orientação
sobre a barra de navegação em junho de 2025.

## As peças que cada um nomeia

Os dois sistemas nomeiam os mesmos trabalhos e dão a eles formas e lugares diferentes. Este é o
vocabulário que o resto da aula usa:

| o trabalho | Material 3 | as HIG, no iPhone |
|---|---|---|
| o título da tela | uma **top app bar** | uma barra de navegação, com um **título grande** que encolhe quando a lista rola |
| a ação mais comum | um **botão de ação flutuante**, o FAB, "geralmente ancorado no canto inferior direito" | um botão na **toolbar**, no alto |
| trocar de seção | uma **barra de navegação** embaixo, para três a cinco destinos | uma **tab bar** embaixo |
| mais seções, uma tela maior | um **navigation rail** na lateral, ou uma **gaveta de navegação** que desliza | uma barra lateral, no iPad |
| uma tarefa curta por cima da tela | uma bottom sheet ou um diálogo | uma **sheet** |
| ícones | o conjunto de ícones do Material, `Icons` no Compose | os **SF Symbols**, desenhados para combinar com a fonte do sistema |
| profundidade | **elevação**, mostrada como um tom de cor além de uma sombra | **materiais**: o Liquid Glass para barras e controles, os materiais padrão dentro do conteúdo |

Duas linhas carregam mais do que o nome. A documentação do Android descreve a barra de navegação como
o lugar para "três a cinco destinos de igual importância", e o rail para três a sete, em layouts de
tablet ou desktop: a escolha entre os dois é a largura da tela, que é o assunto da aula 8. As HIG
dizem que a tab bar serve "para navegar, não para oferecer ações": uma ação pertence a uma toolbar.
As duas regras dizem a mesma coisa com duas grafias. **A barra de baixo leva de um lugar a outro;
ela não faz coisas.**

## No que cada um insiste

**O Material foi feito para receber tema.** O guia dele é um conjunto de papéis, *primary*, *on
primary*, *surface*, e uma escala tipográfica de quinze estilos com nome, e o app os preenche com os
próprios valores. No Android 12 em diante ele vai um passo além com a **cor dinâmica**: a
documentação do Android descreve um algoritmo que "deriva cores personalizadas do papel de parede do
usuário" e as oferece ao app, então o mesmo app pode ter aparências diferentes em dois celulares.

**As HIG foram feitas para deixar o sistema decidir.** Elas pedem a fonte do sistema, as cores do
sistema, os símbolos do sistema e as barras do sistema, para que um ajuste que o usuário muda, um
texto maior ou uma aparência escura, chegue a todos os apps ao mesmo tempo. A página sobre o modo
escuro diz isso com todas as letras: evite um ajuste de aparência próprio, porque as pessoas "podem
achar que o app está quebrado porque ele não responde" à escolha que fizeram para o sistema inteiro.

Nenhum dos dois é lei. **Um app que ignora qualquer um dos guias continua instalando e rodando**,
como disse a aula 1. O que ele perde é a vantagem que o usuário já trazia, e a próxima seção mostra
como isso fica numa tela do planner.
