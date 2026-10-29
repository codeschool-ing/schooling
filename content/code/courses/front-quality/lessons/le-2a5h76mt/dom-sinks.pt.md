---
title: Os lugares onde texto vira código
version: 1
---

**Um sink é qualquer lugar da interface do DOM que recebe um texto e faz mais com ele do que mostrá-lo.**
O cross-site scripting precisa de um, e a lista é curta o bastante para saber de cor, que é a defesa
prática: procure por eles numa revisão, e pergunte de cada um de onde veio o seu texto.

| sink | o que faz com um texto | o jeito seguro |
|---|---|---|
| `element.innerHTML = s` | interpreta como HTML e constrói o que ele descreve | `textContent`, ou `createElement` e `append` |
| `element.outerHTML = s` | o mesmo, trocando o elemento | como acima |
| `element.insertAdjacentHTML(where, s)` | o mesmo, ao lado do elemento | `insertAdjacentText`, ou `append` |
| `document.write(s)` | escreve marcação no documento enquanto ele carrega | nada; não há motivo para usá-lo |
| `a.href = s`, `iframe.src = s` | segue o endereço, e um endereço `javascript:` roda como código | conferir antes que `new URL(s).protocol` é `https:` ou `http:` |
| `element.setAttribute("onclick", s)` | um atributo de tratador de evento é código | `addEventListener` com uma função |
| `eval(s)`, `new Function(s)`, `setTimeout(s, …)` | roda o texto | funções, nunca textos |

**A coluna segura não é um fardo.** Toda linha tem uma alternativa comum que faz o que se queria, e a
própria view do planner usa a primeira do começo ao fim. Os frameworks fazem o mesmo por padrão: cada um
dos quatro escapa os valores escritos num template, e cada um tem um jeito nomeado de contornar isso, que
é a linha a procurar numa revisão de código escrito nele.

## Links são o que parece inofensivo

O `href` de um link tirado dos dados, o site de um curso por exemplo, é um sink por causa de um esquema:
`javascript:`. A checagem tem três linhas, e o planner a usaria no dia em que um curso tivesse um link:

```typescript
function safeLink(address: string): string | undefined {
  const url = new URL(address, location.href);
  return url.protocol === "https:" || url.protocol === "http:" ? url.href : undefined;
}
```

Tudo o que não for `http:` ou `https:` fica sem link nenhum, que é a ideia da lista de permissão da aula 7
aplicada a um endereço.
