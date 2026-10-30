---
title: Tipografia, cor e modo escuro em cada guia
version: 1
---

**Os dois guias respondem às mesmas três perguntas sobre a aparência de uma tela, qual fonte, quais
cores e o que acontece à noite, e respondem de pontas opostas.** O Material entrega ao app um
conjunto de lugares com nome e espera que ele os preencha. As HIG entregam ao app a fonte e as cores
do próprio sistema e esperam que ele as use, para que os ajustes do usuário cheguem até ele. O
planner precisa ficar à vontade nos dois, e a diferença decide o que ele anota para cada um.

## A fonte

**A escala tipográfica do Material tem quinze estilos com nome, em cinco grupos**: display,
headline, title, body e label, cada um em large, medium e small. A documentação do Android sobre o
Material 3 no Compose lista os padrões, todos em Roboto, e dá a cada um um tamanho e uma altura de
linha em `sp`: `bodyLarge` é 16/24, `titleLarge` 22/28, `labelSmall` 11/16. O app pode trocar a
família e os tamanhos; os nomes ficam, e os componentes pedem um nome em vez de um número.

**A resposta das HIG é a fonte do sistema, San Francisco, por meio de estilos de texto.** "San
Francisco (SF) é uma família de fontes sem serifa", nas palavras das HIG, com a SF Pro entre as
variantes. Um app raramente a nomeia: ele pede um **estilo de texto**, `.body`, `.headline`,
`.largeTitle`, e o sistema escolhe a fonte, o peso e o tamanho. A tabela das HIG para o iPhone dá
17 pontos para `.body` e 34 para `.largeTitle` no tamanho padrão, e repete a tabela mais onze vezes,
uma para cada tamanho que o usuário pode escolher, do xSmall ao maior tamanho de acessibilidade.

Essa repetição é o ponto, e ela se chama **Dynamic Type**. Quem escolhe um texto maior nos Ajustes
recebe texto maior em todo app que pediu estilos de texto, e nenhum num app que pediu "17 pontos". O
Android faz o mesmo com a unidade `sp`, que a documentação dele descreve como "escalada pela
preferência de tamanho de fonte do usuário". A aula 19 testa o que isso faz com um layout. **Para
esta aula, a regra é que um tamanho é pedido pelo papel dele**, nunca fixado como número, nas duas
plataformas.

| | Material 3 | as HIG, no iPhone |
|---|---|---|
| a família | Roboto por padrão, substituível | a fonte do sistema, San Francisco |
| como o texto pede um tamanho | um papel na escala, como `bodyLarge` | um estilo de texto, como `.body` |
| texto do corpo no tamanho padrão | 16 sp | 17 pt |
| o texto maior do usuário | o `sp` segue o ajuste de tamanho de fonte | o Dynamic Type, uma tabela por tamanho |

## As cores

**O Material nomeia as cores pelo papel.** *Primary* é "usada nos componentes principais, como
botões em destaque, estados ativos", *on primary* é a cor do que fica sobre a primary, *surface* é o
fundo sobre o qual as coisas ficam, *on surface* o texto sobre ele. A documentação do Android
descreve cada papel como vindo de uma cor-chave e de uma paleta tonal de treze tons. O app escolhe as
cinco cores-chave, e os papéis vêm delas.

**A cor dinâmica pode substituir essas escolhas.** No Android 12 em diante, um app que pede um
esquema de cor dinâmico recebe um derivado do papel de parede do usuário. A escolha é do app, não do
sistema: um app que quer o verde da marca em todo lugar mantém o próprio esquema e não pede.

**As HIG nomeiam as cores pelo significado, e guardam os valores.** As cores dinâmicas do sistema
"se adaptam automaticamente a contextos claros e escuros", e a página sobre cor pede que os apps
evitem "fixar no código os valores das cores do sistema", porque os valores mudam de uma versão para
outra. As cores de texto são *label*, *secondary label* e assim por diante, e um app que as usa nunca
precisa escolher um cinza. A marca entra como uma **tint**, a cor dos controles e dos links.

**A profundidade é a última diferença.** O Material 3 mostra uma superfície elevada principalmente
por um tom: um cartão mais alto é desenhado numa versão um pouco mais colorida da superfície, com ou
sem sombra. As HIG usam **materiais**, e desde 2025 o Liquid Glass, uma camada translúcida para
barras e controles que deixa o conteúdo de baixo aparecer.

## Modo escuro

**O modo escuro é um ajuste do sistema nas duas plataformas, e as duas esperam que o app o siga.** O
tema do Material define um esquema claro e um escuro, e o Compose escolhe um a partir de
`isSystemInDarkTheme()`. As HIG dizem que um ajuste de aparência próprio do app "dá mais trabalho às
pessoas", e pedem contraste suficiente "em todas as aparências": a página do modo escuro põe o piso
em 4,5:1 entre o texto e o fundo dele, uma razão que a aula 19 calcula. Então o planner precisa de um
valor escuro para cada cor que escolhe, escolhido e não calculado: inverter a paleta clara transforma
o verde fechado da marca num rosa malva, `#D090B1`, que ninguém escolheu. O conjunto escuro do
planner é próprio: uma superfície cinza quase preta, `#1C1B1F`, texto num branco suave, `#E6E1E5`, e
um verde mais claro, `#8FD3AE`, para o destaque.
