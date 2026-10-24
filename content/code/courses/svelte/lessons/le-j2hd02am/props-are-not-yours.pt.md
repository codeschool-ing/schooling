---
title: Uma prop não é sua para mudar
version: 1
---

**Um filho pode mudar o seu próprio estado e o estado que foi explicitamente autorizado a ligar, e
mais nada.** É uma regra fácil de quebrar sem querer, porque quando a página passa `sessions` como
prop, o filho recebe o próprio proxy da página, e mudá-lo funciona: a sessão aparece, os totais
mudam, tudo parece certo, e na versão abaixo nada reclama.

Aqui está a versão tentadora do `AddSession`. Ela recebe as sessões e as muda por conta própria, e é
até um pouco esperta: acrescentar numa data que já tem uma sessão do curso alonga essa sessão em vez
de criar uma segunda.

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\tlet { sessions, course } = $props();\n\n\tlet date = $state('');\n\tlet minutes = $state(30);", "note": "O array da página, recebido como prop, e o curso a que acrescentar."},
 {"code": "\tfunction add() {\n\t\tconst same = sessions.find((s) => s.course === course && s.date === date);\n\t\tif (same) same.minutes += minutes;\n\t\telse sessions.push({ id: sessions.length + 1, course, date, minutes, done: false });\n\t}\n</script>\n\n<p>\n\t<label>Date <input type=\"date\" bind:value={date} /></label>\n\t<label>Minutes <input type=\"number\" min=\"5\" step=\"5\" bind:value={minutes} /></label>\n\t<button disabled={!date} onclick={add}>Add session</button>\n</p>", "note": "Dois jeitos de mudar o estado da página a partir do filho: um objeto novo empurrado no array, ou uma propriedade de um objeto existente alterada."}
]}
```

com a página passando o que ele precisa, `<AddSession {sessions} course={selected} />`, no lugar da
linha do `onadd`. Acrescente uma sessão no dia 21, uma data sem nada, e depois trinta minutos no dia
24, que já tem uma hora de álgebra:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --fill 'Date=2026-10-21' --click 'Add session' --fill 'Date=2026-10-24' --click 'Add session'
console: [vite] connecting...
console: [vite] connected.
-- fill Date=2026-10-21
-- click Add session
-- fill Date=2026-10-24
-- click Add session
at /
title: 285 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 210 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 285 minutes this week (4 h 45 min)
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - checkbox "13 Oct 2026, 60 min" [checked]
      - text: 13 Oct 2026, 60 min
    - listitem:
      - checkbox "19 Oct 2026, 90 min" [checked]
      - text: 19 Oct 2026, 90 min
    - listitem:
      - checkbox "24 Oct 2026, 90 min"
      - text: 24 Oct 2026, 90 min
    - listitem:
      - checkbox "21 Oct 2026, 30 min"
      - text: 21 Oct 2026, 30 min
  - paragraph: 210 minutes for Linear algebra this week (3 h 30 min)
  - paragraph:
    - text: Date
    - textbox "Date": 2026-10-24
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

As duas funcionaram: há uma sessão nova no dia 21, e o dia 24 foi de 60 para 90 minutos. **E nada foi
impresso.** O estado da página foi mudado duas vezes por um componente que não é dono dele, uma vez
crescendo o seu array e outra mudando uma propriedade de um dos seus objetos, e o console ficou
calado.

O Svelte tem um aviso para isso, `ownership_invalid_mutation`, e ele é mais estreito que a regra. Ele
dispara quando o código atribui através da própria prop, como `sessions[0].minutes += 30` faria; a
mensagem diz o arquivo e a linha, e oferece as duas saídas, ligar a prop ou usar um callback. Aqui a
propriedade foi mudada através de `same`, uma variável local guardando um objeto achado no array, e o
array cresceu com `push`, e a conferência não vê nenhum dos dois.

## Por que isso importa, quando funciona

Porque a página deixa de saber como as sessões são criadas. Em "Ligando um valor a um campo de
formulário", o `add` da página decidia o id, o curso, e que uma sessão nova não está feita. Espalhe
isso por três componentes que mudam `sessions`, e no dia em que os ids tiverem de vir de outro lugar
haverá três lugares para mudar e nenhum jeito de achá-los lendo a página. **O dono de um estado
deveria ser o único código que muda a forma dele.** Um callback mantém isso verdadeiro: o filho diz o
que o aluno pediu, a página decide o que isso significa, inclusive se "acrescentar no dia 24" quer
dizer uma sessão mais longa ou uma segunda.

Então o aviso ajuda quando pega você, e desta vez não pegou. **A regra é o que se segue; o aviso é
uma conferência de parte dela.**

Volte o `AddSession.svelte` para a versão de "Ligando um valor a um campo de formulário", e a página
para `<AddSession onadd={add} />`.
