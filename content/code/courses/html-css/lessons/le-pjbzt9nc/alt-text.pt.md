---
title: Texto no lugar de uma imagem
version: 1
---

Todo `<img>` precisa de um **atributo `alt`**, e a pergunta que ele responde não é "o que tem na imagem?", e sim **"o que eu escreveria aqui se não pudesse usar uma imagem?"**. O texto dele substitui a imagem para quem não consegue vê-la: quem usa leitor de tela, um leitor cuja conexão não carregou o arquivo, um buscador. Aqui estão os três casos em que toda imagem se encaixa:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>This week's find · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>This week's find</h1>
      <img src="cover.png" width="200" height="300"
           alt="First edition of Grande Sertão: Veredas, green cloth cover, spine faded">
      <img src="divider.png" width="400" height="8" alt="">
      <img src="cover.png" width="200" height="300">
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe alt.html tree axe
- main:
  - heading "This week's find" [level=1]
  - 'img "First edition of Grande Sertão: Veredas, green cloth cover, spine faded"'
  - img
image-alt (critical, 1 element): Images must have alternative text
```

**A primeira imagem traz informação**, então o `alt` dela diz o que o leitor precisa saber por ela: que livro, que edição, em que estado. A árvore a lista como **img** nomeada por esse texto.

**A segunda é decoração**, uma linha divisória, e o `alt` dela é vazio: `alt=""`. Isso não é um alt faltando; é uma declaração de que a imagem não diz nada. O navegador a deixa inteiramente fora da árvore, então um leitor de tela a pula, que é exatamente o certo: ouvir *imagem, divisória* entre cada seção é ruído.

**A terceira não tem `alt` nenhum**, e é a pior das três. A árvore mostra um **img** sem nada, e muitos leitores de tela recorrem então a ler o nome do arquivo, *cover ponto png*, que é como as pessoas acabam ouvindo `IMG_4031.jpg` em voz alta. O axe a apontou como **image-alt**, crítico.

## Como escrever um bom texto alternativo

- **Diga para que a imagem serve, no contexto.** A mesma foto da loja é *a fachada da Andorinha Books, Rua dos Pinheiros* na página de contato e pode ser decoração na página inicial.
- **Não comece com "imagem de" ou "foto de".** O leitor de tela já diz *imagem*.
- **Fique numa frase.** Se a imagem precisa de mais, um gráfico por exemplo, a explicação pertence ao texto da página, onde todo mundo pode lê-la.
- **Texto dentro da imagem vai no alt.** A foto de um cartaz que diz *Book swap, Saturday 10 am* tem isso como alt.
- **Dentro de um link, descreva para onde o link vai**, como a seção 09 da aula 2 mostrou.

A decisão entre os dois primeiros casos é a que importa: **se tirar a imagem perderia informação, descreva-a; se não perderia nada, `alt=""`.**
