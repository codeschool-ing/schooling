---
title: Uma rota é uma pasta
version: 1
---

**No SvelteKit, o endereço de uma página é o caminho de uma pasta dentro de `src/routes`, e a página é o
`+page.svelte` que está nela.** `src/routes/+page.svelte` é `/`, `src/routes/about/+page.svelte` é
`/about`, e um arquivo em `src/routes/courses/algebra/+page.svelte` seria `/courses/algebra`. Não existe
uma tabela de rotas para manter em dia com os arquivos: os arquivos são a tabela. As aulas 4, 8, 10 e 11
já usaram isso, para os experimentos em `/old`, `/keys`, `/timer` e `/hello`. Esta aula usa para o
próprio planner.

Os arquivos cujo nome começa com `+` são os que o SvelteKit lê: `+page.svelte`, `+layout.svelte`,
`+error.svelte` e, a partir da aula 13, o `+page.js` e o `+page.server.js` ao lado deles. Qualquer outra
coisa numa pasta de rota, um componente usado só ali ou uma função auxiliar, é ignorada pelo roteador e
pode ficar ao lado da página que a usa.

O planner precisa de uma segunda página que não seja o planner: uma curta, dizendo o que é a aplicação.
Salve como `src/routes/about/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/about/+page.svelte", "parts": [
 {"code": "<svelte:head>\n\t<title>About · Study planner</title>\n</svelte:head>", "note": "`<svelte:head>` põe elementos no `<head>` do documento. Cada página define o seu próprio título, que o navegador mostra na aba e um leitor de tela anuncia primeiro."},
 {"code": "<h1>About the planner</h1>\n<p>\n\tThe study planner lists your courses, the sessions you plan for each, and the minutes in your week.\n\tIt keeps everything on this computer, in one small file, and asks nobody for anything.\n</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "Um link para outra página da aplicação é um `<a href>` comum. Não existe um componente especial de link."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/about --click 'Back to the planner'
-- click Back to the planner
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 90 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

O `look` imprimiu `at /`: o link funcionou, e a página do planner está aparecendo. O que a árvore não
consegue mostrar é **como** ela chegou lá, e essa é a parte interessante.

## Navegação no cliente

**O SvelteKit intercepta os cliques em links para as suas próprias páginas e não recarrega.** Ele busca
o código da página nova, se ainda não o tem, renderiza essa página no lugar da antiga e atualiza o
endereço com a History API. Voltar e Avançar funcionam, e abrir um link numa aba nova também, porque os
endereços são reais: o servidor consegue renderizar cada um deles sozinho, que foi o que aconteceu
quando o `look` abriu `/about` diretamente.

A diferença importa mais para o planner do que para a maioria das páginas. Um recarregamento começa o
navegador do zero, então todo o estado na memória, a semana, qualquer sessão acrescentada, se perde: a
aula 7 descreveu o que um formulário teria custado numa página HTML comum. Uma navegação no cliente
mantém as partes da página que os dois endereços compartilham, que são o assunto da próxima seção, e as
partes do estado que moram nelas.
