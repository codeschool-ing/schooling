---
title: Ordem, !important e o atributo style
version: 1
---

Quando a especificidade empata, a ordem decide. Aqui estão três regras em `order.css`, duas delas idênticas, todas (0,1,1):

```css
.event h2 { color: #2f6f4e; }
.featured h2 { color: #7a5c00; }
.event h2 { color: #333333; }

.intro { color: #555555 !important; }
#events .intro { color: #8a1c1c; }
```

```
ana@laptop:~/site$ probe order.html rules '.featured h2' color
.event h2 (0,1,1)     color: #2f6f4e                  order.css
.featured h2 (0,1,1)  color: #7a5c00                  order.css
.event h2 (0,1,1)     color: #333333                  order.css
computed color: rgb(51, 51, 51)
```

As três casam com o título do evento em destaque. **A última do arquivo vence**, então o título fica `#333333`, e não o marrom que `.featured h2` foi escrito para dar. Alguém acrescentou uma regra para `.featured`, a regra estava certa, e uma duplicata esquecida mais abaixo no arquivo a sobrescreveu. Ler a lista de baixo para cima, como o DevTools a desenha, é como se encontra isso.

## `!important`

`!important` depois de um valor põe a declaração acima de toda declaração normal, seja qual for a especificidade:

```
ana@laptop:~/site$ probe order.html rules .intro color
.intro (0,1,0)          color: #555555 !important       order.css
#events .intro (1,1,0)  color: #8a1c1c                  order.css
computed color: rgb(85, 85, 85)
```

`#events .intro` é (1,1,0) e deveria vencer `.intro` em (0,1,0) com folga. Não vence, porque `.intro` disse `!important`. A única coisa que vence uma declaração `!important` é outra declaração `!important` com uma pretensão igual ou mais forte, e é assim que as folhas de estilo acabam com `!important` por toda parte: cada um é respondido com outro.

**Use-o para quase nada no seu próprio CSS.** Ele tem dois usos honestos: uma classe utilitária que precisa vencer onde quer que seja posta, como uma que esconde um elemento, e sobrescrever CSS que você não controla, como o de um widget de terceiros. Quando você o pega para resolver um problema de especificidade, o problema é um seletor em algum lugar mais específico do que precisava, e é isso que se conserta.

## O atributo `style`

Uma declaração num atributo `style` pertence ao próprio elemento e vence todo seletor de toda folha de estilos, seja qual for a especificidade, porque nem é casada por um seletor. Só um `!important` numa folha de estilos a vence. Isso a torna a coisa mais difícil de sobrescrever numa página, e é o motivo de a seção 02 dizer para deixá-la para os scripts. O DevTools a lista no topo do painel Styles como `element.style`.
