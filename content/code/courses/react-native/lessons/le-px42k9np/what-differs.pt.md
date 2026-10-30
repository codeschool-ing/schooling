---
title: O que de fato difere entre os dois
version: 1
---

**Quase todo app é igual nas duas plataformas; uma lista curta de coisas não é**, e cada item dela é um lugar
onde o usuário de uma plataforma espera algo que o usuário da outra estranharia. Estes são os que o planner
encontra, a partir das orientações de design das próprias plataformas, as *Human Interface Guidelines* da
Apple e o *Material Design* do Google.

## Voltar

**O Android tem uma ação de voltar do sistema** — um botão, ou um deslizar a partir da borda da tela na
navegação por gestos — que todo app precisa atender. O React Navigation, na aula 8, a atende por você voltando
uma tela. Um app que precisa intervir, para perguntar antes de descartar um formulário preenchido pela metade,
escuta com o `BackHandler`. **O iOS não tem voltar do sistema**: voltar é o botão no canto superior esquerdo de
uma tela empilhada, ou um deslizar a partir da borda esquerda, e os dois pertencem à navegação, que de novo a
aula 8 fornece.

## O topo e o pé da tela

As duas plataformas desenham por cima do app: uma **barra de status** no topo e, nos iPhones sem botão de
início, um **indicador de início** no pé; os celulares Android com navegação por gestos também têm uma barra
de gestos ali. Muitos celulares têm ainda um recorte para a câmera na borda de cima. O espaço que cada um
ocupa muda de modelo para modelo, e o app precisa manter o conteúdo fora dele. Esse é o assunto da próxima
seção.

## Desenho

| | iOS | Android |
|---|---|---|
| sombras | quatro propriedades de sombra | `elevation` |
| a fonte do sistema | San Francisco | Roboto |
| um controle apertado | escurece | uma onda, `android_ripple` num `Pressable` |
| um switch, um seletor de data, um alerta | desenhado pelo UIKit | desenhado pelo Android |

**Não copie a aparência de uma plataforma para a outra.** Uma onda num iPhone, ou uma linha que escurece no
Android, parece um app feito para outra pessoa. A prop `android_ripple` do `Pressable` dá ao Android a onda dele
e não faz nada no iOS, que é exatamente o formato de uma boa diferença de plataforma.

## Comportamento que mora fora do seu app

Permissões são pedidas de jeitos diferentes, e o Android 13 acrescentou uma que o iOS sempre teve, para
notificações; as aulas 13 e 16 são sobre as duas. O teclado empurra o conteúdo de jeitos diferentes, que é a
aula 11. Trabalho em segundo plano tem regras diferentes em cada uma, que é a aula 15. E as lojas revisam os
apps por regras diferentes, que é o curso `mobile-delivery`.

## E a diferença que é a web

O build web não tem barra de status, nem ação de voltar do tipo do celular, nem vibração, nem armazenamento
seguro. Ele é um substituto para os fins deste curso, e responde `"web"` quando perguntado. O planner mostra a
diferença numa frase no pé da tela, a partir dos três arquivos da seção anterior.
