---
title: O que é hidratação
version: 1
---

**Hidratação é o momento em que um script no navegador assume o HTML que o servidor desenhou, sem
desenhá-lo de novo.** A página chegou pronta. O texto está certo, os botões estão lá, e nenhum deles
faz nada, porque um botão em HTML é só a descrição de um botão: o que acontece quando ele é apertado
mora no JavaScript, e o JavaScript ainda não rodou. Hidratar é prender esse comportamento aos
elementos que já estão na tela.

O planner das aulas 1 e 3 não hidratava. O seu script buscava os dados de novo e trocava o `<main>`
inteiro por uma cópia idêntica de si mesmo. Isso funciona, e joga fora a única coisa que a
renderização no servidor pagou, uma página pronta, repetindo tanto a requisição quanto o trabalho.

## As três coisas de que a hidratação precisa

Para assumir uma página em vez de redesenhá-la, o script tem de conseguir responder a três
perguntas:

1. **De quais dados esta página foi desenhada?** Sem eles o script não sabe o que a página quer
   dizer: qual sessão um botão marca como feita, a qual curso o formulário acrescenta. A seção "O que
   cada um manda além do HTML" da aula 2 mostrou a resposta de cada framework, uma cópia dos dados
   dentro da página.
2. **O HTML é o que eu teria desenhado?** Se o servidor e o navegador discordam, a ideia que o script
   tem da página e a página na tela são duas coisas diferentes. Isso é um **hydration mismatch**, uma
   divergência de hidratação, e a seção "Uma divergência, feita de propósito" cria uma.
3. **Onde vai cada pedaço de comportamento?** No planner todo clique vai para um listener no `<main>`,
   então a resposta é trivial. Um framework percorre a sua árvore de componentes sobre os elementos
   existentes e prende os tratadores de cada componente ao elemento que ele teria criado.

```schooling-figure
@fig
```

## A janela que ela deixa

Entre o momento em que uma página renderizada no servidor aparece e o momento em que a hidratação
termina, a página parece pronta e não está. Essa lacuna é o assunto da seção "A janela em que os
cliques se perdem", e é o principal custo que a renderização no servidor acrescenta: a renderização
no cliente não mostra nada até a página funcionar, e a no servidor mostra uma página que ainda não
funciona. **Qual é melhor depende do tamanho da lacuna**, e a lacuna é o tempo de baixar, interpretar
e rodar o JavaScript da página, e é por isso que a aula 2 o pesou.
