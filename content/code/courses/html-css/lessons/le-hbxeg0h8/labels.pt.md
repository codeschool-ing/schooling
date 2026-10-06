---
title: Todo campo tem um rótulo
version: 1
---

Um campo sem rótulo é uma caixa e um palpite. **`<label>`** é o elemento que diz para que serve um campo, e o navegador faz duas coisas com ele: transforma o texto do rótulo no **nome acessível** do campo, e faz um clique no texto pôr o cursor no campo, o que importa para quem tem a mira instável e para quem está no celular.

Há dois jeitos de ligar um rótulo ao campo, e um jeito em que as pessoas acham que ligaram e não ligaram. Aqui estão os três:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Newsletter · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Newsletter</h1>
      <form action="subscribe" method="post">
        <label for="name">Your name</label>
        <input id="name" name="name">

        <label>Email <input name="email" type="email"></label>

        <input name="city" placeholder="City">

        <button>Subscribe</button>
      </form>
    </main>
  </body>
</html>
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Um elemento label com for=&quot;name&quot; acima de um elemento input com id=&quot;name&quot; e name=&quot;name&quot;. Uma seta liga o for do label ao id do input. Três resultados: o nome acessível do campo vira Your name, clicar nas palavras põe o cursor no campo, e os dois se ligam pelo id onde quer que estejam. O atributo name é outra coisa: é o que o servidor recebe.\"><defs><marker id=\"ah4\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&lt;label for=&quot;name&quot;&gt;Your name&lt;/label&gt;</text><rect x=\"20\" y=\"100\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&lt;input id=&quot;name&quot; name=&quot;name&quot;&gt;</text><path d=\"M148 60 C 148 80, 108 82, 108 98\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></path><text x=\"170\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">for aponta o id do campo</text><text x=\"430\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">name é o que o servidor recebe</text><path d=\"M212 98 C 212 84, 330 80, 424 80\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"34\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">O nome acessível do campo vira Your name.</text><text x=\"34\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Clicar nas palavras põe o cursor no campo.</text><text x=\"34\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Os dois se ligam pelo id, onde quer que estejam.</text></svg>", "caption": "O id liga o rótulo ao campo; name é outro atributo, para a requisição."}
```

**Com `for` e `id`**, o primeiro campo: o `for` do rótulo aponta o `id` do campo. Eles podem então ficar em qualquer lugar da página, e é isso que deixa o CSS livre para posicioná-los.

**Envolvendo**, o segundo: o campo fica dentro do rótulo, e nada precisa de `id`. É mais curto, e alguns layouts ficam mais difíceis de montar assim.

**Só com um `placeholder`**, o terceiro: o texto cinza dentro da caixa. Aqui está o que o navegador fez dos três:

```
ana@laptop:~/site$ probe labels.html tree axe
- main:
  - heading "Newsletter" [level=1]
  - text: Your name
  - textbox "Your name"
  - text: Email
  - textbox "Email"
  - textbox "City"
  - button "Subscribe"
axe: no violations
```

Os três campos têm nome, inclusive *City*, e o axe não achou nada. Isso merece uma leitura cuidadosa, porque é um caso de verificação aprovando um campo que continua mal rotulado. Quando nada mais nomeia um campo, o navegador recorre ao placeholder, então um leitor de tela consegue dizer *City*. Mas **o placeholder some assim que alguém digita**, e quem está no meio do formulário, ou volta para corrigi-lo, vê uma caixa preenchida e nenhuma pista do que ela pedia. Os designs costumam estilizá-lo num cinza claro difícil de ler. E clicar nele não faz nada que um clique na caixa não faria, enquanto um rótulo é um segundo alvo, maior. O rótulo é obrigatório; um placeholder pode acrescentar um exemplo, *05422-000*, ao lado dele, nunca substituí-lo.

## O rótulo é o que se clica

Um teste de dois segundos: clique nas palavras ao lado de um campo. Se o cursor cai no campo, eles estão ligados. Se nada acontece, são dois elementos sem relação que por acaso estão um ao lado do outro, e quem usa leitor de tela ouve uma caixa sem nome. O painel de acessibilidade do DevTools também mostra o nome calculado; `probe describe`, na seção 08, o imprime.
