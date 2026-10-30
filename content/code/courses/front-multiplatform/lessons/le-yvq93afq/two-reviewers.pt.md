---
title: Duas pessoas vão julgar o embrulho
version: 1
---

**Um app embrulhado é julgado duas vezes antes de dar certo**: uma pelo revisor de uma loja, que decide
se ele pode ser publicado, e depois por cada pessoa que o instala, que decide se fica com ele. As duas
fazem a mesma pergunta com palavras diferentes: isto é um app, ou um site numa moldura? As aulas 2 a 5
construíram a moldura. Esta aula é sobre a resposta, e é a mais cara do curso de errar, porque costuma
ser descoberta tarde: na revisão, ou na primeira semana de avaliações.

## O que as lojas dizem

**A Apple diz isso nas App Store Review Guidelines, seção 4.2, "Minimum Functionality"**: um app deve
incluir recursos, conteúdo e interface que o levem além de um site reempacotado, e um que não é útil,
único ou "com cara de app" não pertence à loja. A regra seguinte, 4.2.2, nomeia os casos que ela tem em
mente: apps que são principalmente marketing, recortes da web, agregadores de conteúdo ou uma coleção
de links. Nenhuma das duas regras menciona Capacitor ou WebViews. **O teste é o que o app faz, não como
ele é construído**: muitos apps embrulhados são publicados, e muitos nativos são recusados pela mesma
regra.

**O Google Play diz isso na política de spam**, que cobre apps cujo propósito principal é mostrar um
site numa WebView, em particular um site que quem desenvolve não possui nem administra, ou que copia
conteúdo de outro lugar. Um app que é o próprio serviço de quem o desenvolve, fazendo coisas ali para
quem o usa, não é o assunto dessa regra.

*Os dois documentos mudam, e os revisores os aplicam com julgamento e não por uma lista de conferência.
Leia a versão atual de cada um antes de enviar; o resumo acima é o que eles diziam quando este curso foi
escrito.*

## O que uma pessoa percebe

Um revisor passa minutos com um app; quem o instala passa semanas. O que essas pessoas percebem não é a
WebView, são os lugares onde o app não se comporta como os outros do celular delas:

- **o gesto ou o botão de voltar não faz nada**, ou sai do app quando deveria voltar uma tela;
- **dá para selecionar texto e dar zoom na página** onde nada mais no celular permite;
- **um toque espera**, porque a tela é desenhada por uma página lenta, e uma lista engasga ao rolar;
- **nada funciona sem rede**, porque o app esperava a rede que um site sempre tem;
- **o app esquece** onde a pessoa estava toda vez que o sistema o fecha em segundo plano.

**Cada um desses pode ser resolvido dentro da WebView**, e cada solução é trabalho web que você sabe
fazer: tratar o botão de voltar com o plugin `App` do Capacitor, uma folha de estilo que desliga a
seleção e o zoom onde eles não fazem sentido, uma página menor, um cache, salvar o estado como a aula 4
fez. O planner já acerta alguns e não acerta outros, e as próximas seções descobrem quais antes de um
revisor descobrir.
