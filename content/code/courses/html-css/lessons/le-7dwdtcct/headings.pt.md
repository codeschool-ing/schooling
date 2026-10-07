---
title: Títulos e o esboço de uma página
version: 2
---

Os títulos são a coisa mais útil numa página para quem passa os olhos por ela, e a coisa que mais se erra. O HTML tem seis níveis, de `<h1>` a `<h6>`, e **o nível diz onde o título fica no esboço da página, não o tamanho dele**.

Leia só os títulos de uma página e eles devem funcionar como o sumário dela: um `<h1>` nomeando a página, `<h2>` para cada parte principal, `<h3>` para as partes dentro delas. A página de eventos, com uma seção por mês e um artigo por evento, tem este esboço:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois esboços de títulos. À esquerda, níveis que seguem em ordem: h1 Events, h2 October, h3 Poetry reading, h2 November, cada um recuado um passo sob o pai. À direita, um nível pulado: h1 Opening hours, depois dois títulos h4, Weekdays e Weekends, com os níveis h2 e h3 faltando entre eles, o que o axe aponta como heading-order.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">níveis que seguem em ordem</text><rect x=\"20\" y=\"36\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h1</text><text x=\"72\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Events</text><rect x=\"50\" y=\"74\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h2</text><text x=\"102\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">October</text><rect x=\"80\" y=\"112\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h3</text><text x=\"132\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Poetry reading: Hilda Hilst</text><rect x=\"50\" y=\"150\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h2</text><text x=\"102\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">November</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">um nível pulado</text><rect x=\"400\" y=\"36\" width=\"300\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h1</text><text x=\"452\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Opening hours</text><rect x=\"490\" y=\"112\" width=\"210\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h4</text><text x=\"542\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Weekdays</text><rect x=\"490\" y=\"150\" width=\"210\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h4</text><text x=\"542\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Weekends</text><rect x=\"430\" y=\"74\" width=\"260\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"440\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h2 e h3: faltando</text><text x=\"400\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">axe: heading-order</text></svg>", "caption": "Os níveis de título são um sumário. Um nível se escolhe pelo lugar no esboço, nunca pelo tamanho."}
```

O lado direito da figura é uma página de verdade, a de horários, em que alguém quis que os dois subtítulos ficassem pequenos e pegou o `<h4>`. Aqui está ela, como `headings.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Opening hours · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Opening hours</h1>
      <h4>Weekdays</h4>
      <p>10 am to 7 pm.</p>
      <h4>Weekends</h4>
      <p>10 am to 4 pm.</p>
    </main>
  </body>
</html>
```

E aqui está o que a árvore e o axe fazem dela:

```
ana@laptop:~/site$ probe headings.html tree axe
- main:
  - heading "Opening hours" [level=1]
  - heading "Weekdays" [level=4]
  - paragraph: 10 am to 7 pm.
  - heading "Weekends" [level=4]
  - paragraph: 10 am to 4 pm.
heading-order (moderate, 1 element): Heading levels should only increase by one
```

A árvore informa os níveis como foram escritos: 1, depois 4, depois 4. Para quem navega pelos títulos, isso diz que há dois níveis faltando, uma parte e uma subparte que a pessoa nunca encontrou. O axe, o verificador de acessibilidade da seção 11, aponta exatamente isso como **heading-order**. A correção é `<h2>`, e se `<h2>` é grande demais, isso é CSS: `h2 { font-size: 1.1rem; }` é a primeira regra da aula 5.

## Três regras que valem guardar

**Um `<h1>` por página, nomeando o que a página é.** Na página de eventos é *Events*, não o nome da loja, que todas as páginas compartilham e o título já carrega. O nome do site costuma ficar no header como link ou parágrafo, que é o que a versão semântica da seção anterior fez.

**Não pule níveis descendo.** De `<h2>` você vai para `<h3>`, não para `<h4>`. Voltar a subir é normal e necessário: depois do último `<h3>` de uma parte, a parte seguinte começa com um `<h2>`.

**Um título precisa de conteúdo embaixo.** Texto em negrito para parecer título não é título, e um título usado só porque o texto devia ser grande também não é: um slogan num `<h2>` põe no esboço uma seção que não tem nada dentro.

## Onde conferir

O DevTools tem um painel de acessibilidade ao lado dos estilos que mostra o papel e o nível de cada elemento, e extensões de navegador listam os títulos de uma página como esboço. As duas coisas mostram o mesmo que `probe tree`, que é a única visão dos títulos que importa: a que vai receber quem navega por eles.
