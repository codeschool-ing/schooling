---
title: O build escreve só as classes que você usa
version: 1
---

O Tailwind conhece milhares de classes, e a folha que ele escreveu é pequena. Ele **varreu os arquivos** da pasta atrás de qualquer coisa que pareça um dos seus nomes de classe, e escreveu regra só para os que encontrou:

```
ana@laptop:~/site$ grep -A2 "\.p-4 {" first/out.css
  .p-4 {
    padding: calc(var(--spacing) * 4);
  }
ana@laptop:~/site$ grep -c "p-5" first/out.css
0
ana@laptop:~/site$ probe first/index.html style "#content" padding-top,max-width style "#title" font-size,font-weight style "#poetry" border-left-color
main#content  padding-top: 16px
main#content  max-width: 768px
h1#title  font-size: 24px
h1#title  font-weight: 700
article#poetry  border-left-color: oklch(0.508 0.118 165.612)
```

`p-4` está na página, então há uma regra para ele: `padding: calc(var(--spacing) * 4)`. `p-5` não está, e a folha nem o menciona: **0**. A página então é renderizada como qualquer página, e o `probe` a lê como fez por doze aulas. O padding é **16px**, o `max-width` da coluna principal é **768px**, o título tem **24px** e é negrito, e a borda do cartão é verde.

A cor é impressa como **`oklch(0.508 0.118 165.612)`**. A paleta do Tailwind é escrita em **OKLCH**, um jeito de escrever cores por luminosidade, croma e matiz, escolhido para que passos iguais de luminosidade pareçam iguais ao olho. Os navegadores suportam desde 2023. Para uma cor que você mesmo escolhe, um valor hexadecimal continua funcionando, como mostra a seção 07.

## Build para produção

A varredura é o que mantém o arquivo pequeno, e o tamanho continua importando, seção 10 da aula 1. Para produção, **`--minify`** tira os espaços e os comentários:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd first -i input.css -o out.min.css --minify --silent
ana@laptop:~/site$ wc -c first/out.css first/out.min.css
 6749 first/out.css
 5868 first/out.min.css
12617 total
```

**6749** bytes como escrito, **5868** minificado, para uma página com uma dúzia de classes. A folha de um site inteiro costuma ficar em algumas dezenas de kilobytes, porque, por maior que o site seja, ele usa uma escala só. O `front-delivery` é onde esse build vira parte de como um site é publicado.
