---
title: Alinhar e distribuir
---

Centralizar nos dois sentidos, que já foi um quebra-cabeça, hoje são três linhas. Em vez de mostrar as três soltas, vale ler uma barra de navegação inteira — que é onde essas propriedades realmente aparecem — com a explicação de cada trecho ao lado dele:

```schooling-example
{
  "language": "css",
  "file": "barra.css",
  "parts": [
    {
      "code": ".barra {\n  display: flex;",
      "note": "A partir daqui os filhos diretos de `.barra` são itens flex. Nada acontece com os netos — flex vale um nível só."
    },
    {
      "code": "  align-items: center;",
      "note": "Alinha no eixo **cruzado**. Com `flex-direction: row` (o padrão), o cruzado é a vertical: é isto que deixa a logo e os links na mesma altura mesmo tendo tamanhos diferentes."
    },
    {
      "code": "  gap: 24px;",
      "note": "O espaço entre os itens. `gap` não sobra na ponta, não colapsa, e dispensa o `:last-child { margin: 0 }` que todo CSS antigo carrega."
    },
    {
      "code": "  padding: 0 32px;\n}",
      "note": "Espaço interno da barra. Repare que ele NÃO é `gap`: um é a moldura, o outro é a distância entre os itens."
    },
    {
      "code": ".barra .menu {\n  margin-left: auto;\n}",
      "note": "O truque mais útil do flexbox. `margin: auto` come todo o espaço livre daquele lado, então este item — e tudo depois dele — é empurrado para a direita. Faz o que `justify-content: space-between` faria, mas para UM item, e sem mexer no resto."
    },
    {
      "code": ".barra .titulo {\n  min-width: 0;\n}",
      "note": "A linha mais misteriosa e mais útil. Um item flex não encolhe abaixo do próprio conteúdo por padrão, e um título longo estoura a barra em vez de reticenciar. `min-width: 0` devolve a permissão de encolher."
    }
  ],
  "output": "┌──────────────────────────────────────────────┐\n│ ◐ codeschool.ing   Trilhas          Entrar   │\n└──────────────────────────────────────────────┘\n  └ logo e título              └ empurrados pelo margin-left:auto"
}
```

No eixo principal, os valores que se usam são `flex-start`, `center`, `flex-end`, `space-between` (extremos colados nas pontas, espaço igual entre os itens) e `space-evenly` (espaço igual em toda parte, inclusive nas bordas).
