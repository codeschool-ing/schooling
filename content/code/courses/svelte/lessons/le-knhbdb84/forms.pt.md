---
title: Um formulário que envia
version: 1
---

**Um formulário é o elemento certo para qualquer coisa que coleta dados e age sobre eles, porque o
navegador dá a ele um comportamento que você teria de escrever à mão.** Enter em qualquer campo o
envia. `required`, `min` e `step` são conferidos antes do envio, com uma mensagem no idioma do próprio
aluno. E um leitor de tela o anuncia como formulário, com os campos em ordem. O `AddSession` é um `<p>`
com um botão desde a aula 5; esta seção o transforma num formulário.

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\tlet { onadd } = $props();\n\n\tlet date = $state('');\n\tlet minutes = $state(30);"},
 {"code": "\tfunction submit(event) {\n\t\tevent.preventDefault();\n\t\tonadd({ date, minutes });\n\t\tdate = '';\n\t}\n</script>", "note": "O handler recebe o evento de envio. `preventDefault()` impede o envio do próprio navegador, que recarregaria a página."},
 {"code": "<form onsubmit={submit}>\n\t<label>Date <input type=\"date\" required bind:value={date} /></label>\n\t<label>Minutes <input type=\"number\" min=\"5\" step=\"5\" required bind:value={minutes} /></label>\n\t<button>Add session</button>\n</form>", "note": "O `required` substitui o botão desabilitado: o navegador se recusa a enviar sem uma data, e diz por quê. Um `<button>` comum num formulário é um botão de envio."}
]}
```

Preencha uma data e aperte Enter, sem tocar no botão:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter
-- fill Date=2026-10-21
-- press Enter
at /
title: 255 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week (4 h 15 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
      - listitem:
        - checkbox "21 Oct 2026, 30 min"
        - text: 21 Oct 2026, 30 min
    - paragraph: 180 minutes for Linear algebra this week (3 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

A sessão do dia 21 está na lista e o campo de data está vazio de novo, pronto para a próxima.
**O Enter enviou o formulário**, porque é isso que Enter num campo de formulário faz, e o `submit`
rodou.

Aperte o botão sem data, e nada acontece:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Add session'
-- click Add session
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
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

O navegador conferiu o `required`, recusou o envio e mostrou uma mensagem ao lado do campo que o
`look` não consegue imprimir, porque ela é desenhada pelo navegador e não escrita na página. O handler
nunca rodou, então nada chegou à página.

## O que o `preventDefault` está impedindo

Tire a linha `event.preventDefault();` do `submit` e tente de novo:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter
-- fill Date=2026-10-21
-- press Enter
at /
title: 255 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week (4 h 15 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
      - listitem:
        - checkbox "21 Oct 2026, 30 min"
        - text: 21 Oct 2026, 30 min
    - paragraph: 180 minutes for Linear algebra this week (3 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**Continuou funcionando, e o motivo é o SvelteKit, não o navegador.** Sem `preventDefault`, o
navegador segue com o seu próprio trabalho depois que o `submit` rodou, que é mandar o formulário para
o endereço do seu `action`, aqui a mesma página, e carregar a resposta. Numa página HTML comum isso é
uma recarga: uma página nova, começando do arquivo de dados, sem a sessão que acabou de ser
acrescentada. O SvelteKit intercepta um formulário que envia com `GET`, como este faz por padrão, e
transforma o envio numa **navegação no cliente** para `/?`: a mesma página, então os componentes ficam
e o estado deles também. É por isso que a sessão do dia 21 continua lá.

Não conte com isso. A navegação roda de novo o carregamento de dados da página, que a partir da aula 13
é uma requisição ao servidor, e um formulário com `method="POST"` se comporta de outro jeito ainda, como
a aula 14 mostra com calma. Este formulário não é para ir a lugar nenhum: é um jeito de coletar dois
valores e chamar uma função. Diga isso com `event.preventDefault()`, e ponha a linha de volta.
