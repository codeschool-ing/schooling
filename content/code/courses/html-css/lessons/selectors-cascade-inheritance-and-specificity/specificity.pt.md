---
title: Especificidade: a conta que decide quem ganha
---

Quando duas regras atingem o mesmo elemento e declaram a mesma propriedade, vence a mais específica. A especificidade é um trio de números — **(ids, classes, elementos)** — comparado da esquerda para a direita:

```css
p                 /* (0,0,1) */
.aviso            /* (0,1,0)  vence de p */
nav a.ativo       /* (0,1,2) */
#topo             /* (1,0,0)  vence de tudo acima */
```

O primeiro número esmaga os outros: **um id vence qualquer quantidade de classes**. É por isso que estilizar por id acaba forçando o próximo a usar `!important` — e uma vez que `!important` entra num arquivo, ele se espalha.

Empate de especificidade é desempatado pela ordem: a última regra escrita ganha.
