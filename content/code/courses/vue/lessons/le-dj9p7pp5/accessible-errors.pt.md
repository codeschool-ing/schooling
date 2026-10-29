---
title: Erros que um leitor de tela consegue ouvir
version: 1
---

**Uma mensagem de erro que só aparece em vermelho embaixo de um campo não existe para um aluno que não
consegue vê-la.** Três atributos a fazem existir: `aria-invalid` diz que o campo está errado,
`aria-describedby` aponta o campo para a sua mensagem, para que a mensagem seja lida junto com o campo, e
uma região viva anuncia o que mudou depois de um envio. Os três já estão no `FormField` e no `SessionForm`
do planner.

Aperte o botão com o curso vazio e 500 minutos digitados:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'fill input[type=number] 500' --do 'click text=Add the session' --html form --text -
[vite] connecting...
[vite] connected.
-- fill input[type=number] 500
-- click text=Add the session
== the HTML of form
<form novalidate=""><div data-v-b9645e84="" class="field"><label data-v-b9645e84="" for="v-0">Course</label><select id="v-0" aria-invalid="true" aria-describedby="v-0-error"><option disabled="" value="">Choose…</option><option value="statistics">Statistics</option><option value="spanish">Spanish</option><option value="guitar">Guitar</option></select><p data-v-b9645e84="" id="v-0-error" class="error">Choose a course.</p></div><div data-v-b9645e84="" class="field"><label data-v-b9645e84="" for="v-1">Date</label><input data-v-b9645e84="" id="v-1" type="date"><!--v-if--></div><div data-v-b9645e84="" class="field"><label data-v-b9645e84="" for="v-2">Minutes</label><input data-v-b9645e84="" id="v-2" type="number" min="5" max="240" aria-invalid="true" aria-describedby="v-2-error"><p data-v-b9645e84="" id="v-2-error" class="error">Between 5 and 240 whole minutes.</p></div><button>Add the session</button><p role="status" class="saved"></p></form>
```

Leia o `<select>` e o `<input>` de minutos: **cada um tem `aria-invalid="true"` e um `aria-describedby`
que nomeia o `<p>` com a sua mensagem**, e o campo de data, que está certo, não tem nenhum dos dois. Quando
um usuário de leitor de tela vai para o campo de minutos, ele ouve algo como *"Minutes, spin button, 500,
invalid entry, Between 5 and 240 whole minutes."* A cor é para o olho; os atributos são para todo o resto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Um campo de formulário e os três ids que ligam as partes dele. O atributo for do label nomeia o id do input, v-2, e assim o label dá nome ao campo. O aria-describedby do input nomeia v-2-error, o id do parágrafo com a mensagem, e assim a mensagem é lida junto com o campo. aria-invalid true marca o campo como errado. Os três ids vêm de uma chamada de useId.\"><rect x=\"30\" y=\"20\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;label for=\"v-2\"&gt;Minutes&lt;/label&gt;</text><rect x=\"30\" y=\"86\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;input id=\"v-2\" aria-invalid=\"true\"</text><text x=\"42\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">       aria-describedby=\"v-2-error\"&gt;</text><rect x=\"30\" y=\"164\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;p id=\"v-2-error\"&gt;Between 5 and 240…&lt;/p&gt;</text><line x1=\"160\" y1=\"62\" x2=\"160\" y2=\"84\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,84.0 156.9,76.6 163.1,76.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"230\" y1=\"140\" x2=\"230\" y2=\"162\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"230.0,162.0 226.9,154.6 233.1,154.6\" fill=\"var(--phosphor)\"></polygon><text x=\"470\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">dá nome ao campo</text><text x=\"470\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">é anunciado como inválido</text><text x=\"470\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">é lido depois do campo</text><line x1=\"294\" y1=\"40\" x2=\"462\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"434\" y1=\"112\" x2=\"462\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"434\" y1=\"184\" x2=\"462\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "O texto vermelho é para o olho; os ids são o que um leitor de tela segue."}
```

## O que cada atributo faz

| atributo | em | o que um leitor de tela faz com ele |
|---|---|---|
| `<label for>` | o rótulo | dá nome ao campo |
| `aria-invalid="true"` | o campo | anuncia o campo como inválido quando ele é alcançado |
| `aria-describedby` | o campo, nomeando o id da mensagem | lê a mensagem depois do nome e do valor do campo |
| `role="status"` | o parágrafo que diz o que aconteceu | anuncia o seu texto novo quando ele muda, sem mover o foco |

O `aria-invalid` só é posto quando há um erro, e é tirado nos outros casos, como o `FormField` faz com
`undefined`. Um campo marcado como inválido antes de o aluno fazer qualquer coisa é anunciado como errado
na primeira visita, que é a versão para leitor de tela das três mensagens vermelhas que a última seção
evitou.

## Para onde vai o foco

Depois de um envio que falhou, um aluno que enxerga vê as mensagens vermelhas. Um usuário de teclado
continua no botão, e os erros estão acima dele. Duas escolhas são defensáveis: mover o foco para o
primeiro campo inválido, ou anunciar um resumo. O planner fica no simples e não faz nenhuma das duas na
falha, contando com que cada campo anuncie o seu próprio erro quando alcançado; **depois de um envio
bem-sucedido**, ele devolve o foco ao campo de curso, pronto para a próxima sessão, e a linha de status diz
o que foi adicionado. O template ref da aula 9 é o como, e o handler da próxima seção é onde isso acontece.

O WCAG 2.2 AA pede exatamente essas coisas, entre outras: erros identificados em texto, campos com
rótulos e mensagens de status anunciadas. As aulas 10 a 12 de `front-quality` levam o tipo de formulário
do planner pelo axe e por um leitor de tela por completo.
