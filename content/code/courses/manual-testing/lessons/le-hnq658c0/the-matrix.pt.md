---
title: A matriz de compatibilidade
version: 1
---

Uma crença comum é que uma página web é igual em todo lugar, porque HTML e CSS são padrões e todo
navegador os segue. Os navegadores seguem, de perto, e mesmo assim diferem nos detalhes: a largura
com que uma fonte desenha uma palavra, a cara de um controle de formulário, o que um layout faz
quando falta espaço. **O teste de compatibilidade confere que o produto funciona em cada ambiente em
que seus usuários o rodam**, e para uma aplicação web como o boxoffice o ambiente é tudo o que fica
do lado do cliente na conexão.

## Quatro dimensões

O título desta aula as nomeia, e cada uma muda uma coisa diferente.

O **navegador** é na verdade duas coisas: um motor, que transforma a página em pixels, e uma versão
dele. Três motores desenham quase todas as páginas da web. O Blink desenha o Chrome, o Edge e
muitos navegadores menores; o Gecko desenha o Firefox; o WebKit desenha o Safari. Dois navegadores
com o mesmo motor costumam concordar entre si, e é entre motores diferentes que moram as
diferenças. No iPhone, durante a maior parte da história deles, Chrome, Firefox e Edge foram feitos
sobre o WebKit porque a Apple exigia, então o Chrome num iPhone tem mais em comum com o Safari do que
com o Chrome num celular Android.

O **sistema operacional** decide as fontes que a página usa como reserva, a cara dos botões e
menus, e quais navegadores existem: o Safari só roda nos sistemas da Apple.

O **dispositivo** decide a entrada e o tamanho: um mouse ou um dedo, um teclado físico ou um que
sobe e cobre metade da tela, uma janela de desktop ou um celular segurado com uma mão.

A **resolução**, para o layout, é a largura da janela em pixels CSS, a unidade em que uma página é
diagramada, e não o número de pontos da tela. Um celular cuja tela tem 1080 pixels físicos de
largura mostra páginas com 360 pixels CSS de largura, três pontos para cada pixel, para que o texto
continue num tamanho legível. Os 360 pixels do R8 são pixels CSS, e são o que o testador ajusta na
seção 04 desta aula.

## A matriz do R8

O R8 diz que toda página funciona numa tela de celular de 360 pixels de largura e no desktop, nas
versões atuais do Chrome, Firefox, Safari e Edge. Disposto como navegadores contra plataformas, isso
é uma **matriz de compatibilidade**:

| | Windows | macOS | celular Android | iPhone |
|---|---|---|---|---|
| Chrome | sim | sim | sim | sim, sobre WebKit |
| Firefox | sim | sim | sim | sim, sobre WebKit |
| Safari | navegador inexistente | sim | navegador inexistente | sim |
| Edge | sim | sim | sim | sim, sobre WebKit |

Existem catorze células de dezesseis. As colunas de desktop são testadas numa largura de desktop e
as de celular a 360, então cada célula já traz o seu tamanho. O Linux ficou de fora de propósito: os
clientes do teatro raramente o usam, e deixá-lo de fora é uma decisão que o plano deve registrar,
como a aula 1 disse de tudo o que fica de fora.

Cada navegador também tem versões, e **o "atual" se move debaixo da matriz enquanto ela é testada**.
Chrome, Edge e Firefox lançam cada um uma versão principal nova mais ou menos a cada quatro
semanas, e as atualizações maiores do Safari chegam com as atualizações de sistema da Apple. Uma
matriz precisa de uma regra para versões, a versão estável mais nova de cada um ou as duas últimas,
e essa é exatamente a pergunta sobre o R8 que Ana mandou à gerente do teatro na aula 6.

## Quanto custam catorze células

Uma passada completa pelos casos do boxoffice é mais ou menos uma manhã de trabalho para Ana.
Catorze células de manhãs são três semanas, e o plano da aula 1 dá a ela duas semanas para tudo,
compatibilidade incluída. Acrescentar versões multiplica de novo.

Então a matriz não é uma lista de tarefas. **Ela é a lista do que poderia ser testado**, e o valor
dela é tornar a escolha visível: cada célula que não roda é uma célula que alguém escolheu não
rodar, com um motivo, em vez de um navegador em que ninguém pensou. A próxima seção faz essa escolha
para o boxoffice, usando quem são os clientes do teatro e onde o boxoffice tem mais chance de
quebrar.

O teste de compatibilidade cobre mais do que navegadores quando o produto é instalado em vez de
visitado: um aplicativo de celular é testado em versões do Android e do iOS, um programa de desktop
em versões do Windows e dos outros programas com que conversa. O método é a mesma matriz com outros
cabeçalhos, e a mesma necessidade de escolher.
