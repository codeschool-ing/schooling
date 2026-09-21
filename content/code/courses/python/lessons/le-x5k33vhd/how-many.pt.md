---
title: Guloso por padrão, e o caractere que conserta
version: 1
---

```
*        zero ou mais
+        um ou mais
?        zero ou um
{3}      exatamente três
{2,4}    de dois a quatro
{2,}     dois ou mais
```

Cada um se aplica à coisa imediatamente antes dele: `ab+` é um `a` e um ou mais `b`; `(ab)+` é um
ou mais `ab`.

## Guloso

**`*` e `+` pegam o máximo que conseguem**, e depois devolvem caracteres um a um até o resto do
padrão caber.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 266\" role=\"img\" aria-label=\"A mesma string casada por um padrão guloso e um preguiçoso. A estrela gulosa pega tudo até o último fecha-colchete, porque aquilo ainda serve ao padrão. A estrela preguiçosa para no primeiro.\"> <text x=\"40\" y=\"34\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">gulosa</text> <text x=\"40\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--amber)\">&lt;(.*)&gt;</text> <text x=\"160\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\" xml:space=\"preserve\">&lt;a&gt; and &lt;b&gt;</text> <rect x=\"170.8\" y=\"92\" width=\"97.2\" height=\"5\" rx=\"2\" fill=\"var(--amber)\"></rect> <text x=\"420\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">'a&gt; and &lt;b'</text> <text x=\"40\" y=\"134\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">preguiçosa</text> <text x=\"40\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--phosphor)\">&lt;(.*?)&gt;</text> <text x=\"160\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\" xml:space=\"preserve\">&lt;a&gt; and &lt;b&gt;</text> <rect x=\"170.8\" y=\"192\" width=\"10.8\" height=\"5\" rx=\"2\" fill=\"var(--phosphor)\"></rect> <text x=\"420\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">'a'</text> <text x=\"360\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A gulosa está certa sobre a pergunta que lhe fizeram: tudo até o último fecha-colchete</text> <text x=\"360\" y=\"235\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">é mais do que tudo até o primeiro, e o padrão continuou servindo.</text> </svg>", "caption": "Nenhum dos dois é defeito. Uma estrela pega o máximo que pode e devolve caracteres só até o resto do padrão caber; um ponto de interrogação inverte por qual ponta ela começa."}
```

```python
re.search(r"<(.*)>", "<a> and <b>").group(1)      # 'a> and <b'
```

Isso não é um defeito. O `.*` casou tudo até o último `>`, porque tudo até o último `>` é mais que
tudo até o primeiro — e o padrão continuou cabendo.

## Preguiçoso

```python
re.search(r"<(.*?)>", "<a> and <b>").group(1)     # 'a'
```

`*?` e `+?` pegam o MÍNIMO que conseguem, e depois acrescentam um caractere por vez até o resto
caber. Uma interrogação, e o sentido se inverte.

## E a resposta melhor

```python
re.search(r"<([^>]*)>", "<a> and <b>").group(1)   # 'a'
```

"Qualquer coisa que não seja um `>`" diz o que você queria, não tem como passar do fecha-colchete,
e não depende de quem lê saber qual tipo de quantificador é este. **Descrever a forma vence
ajustar a gula**, e é mais rápido também.

## O `?` depois de um grupo

```python
r"colou?r"          # color ou colour
r"(\+\d{1,3} )?"    # um código de país opcional, presente ou não
```

O grupo opcional é como um padrão trata "esta parte pode não estar lá" — e quando ela está
ausente, o grupo dela é `None` e não uma string vazia, que é uma conferência que alguém esquece.

## O que está sempre errado

```python
r".*"
```

Sozinho, ele casa tudo, inclusive nada. Dentro de um padrão ele é a armadilha gulosa acima. **Se o
seu padrão tem um `.*` e você não sabe bem por quê, essa é a linha a olhar primeiro.**
