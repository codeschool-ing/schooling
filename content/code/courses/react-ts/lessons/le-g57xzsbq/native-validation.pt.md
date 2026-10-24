---
title: O que o navegador confere por você
version: 1
---

**O HTML consegue recusar um formulário antes de qualquer JavaScript rodar.** O `required` recusa um
campo vazio, o `min` e o `max` recusam um número fora da faixa, e o `type="date"` recusa texto que não
é data. Quando um formulário falha neles, o navegador nem dispara o `submit`, então o `addSession`
nunca é chamado. Os campos que falharam casam com o seletor CSS `:invalid`, que o `look --html`
consegue imprimir:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Add session' --quiet --html 'input:invalid'
-- click button Statistics
-- click button Add session
<input required="" type="date" name="date">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=500' --do 'click button Add session' --quiet --html 'input:invalid'
-- click button Statistics
-- fill Date=2026-10-24
-- fill Minutes=500
-- click button Add session
<input min="5" max="240" required="" type="number" value="30" name="minutes">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | sed -n '/list:/,/heading "Add/p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
    - listitem:
      - checkbox "Sat 24 Oct · 45 min"
      - text: Sat 24 Oct · 45 min
  - heading "Add a session" [level=2]
```

A data vazia foi recusada, depois um campo de minutos com 500, e só a terceira tentativa, uma data e
45 minutos, acrescentou uma sessão. **Nada inválido chegou ao planejador**, sem uma linha de código de
validação.

É um bom piso e um teto ruim. O que o navegador não dá:

- **As mensagens são dele.** O texto, a língua e a aparência são do navegador; aparecem num balão que
  some, e você não consegue pôr "A session is at most 240 minutes" nele sem JavaScript.
- **Aparecem uma de cada vez**, só para o primeiro campo que falhou.
- **Leitores de tela lidam com o balão de forma desigual**, e nada na página registra qual campo
  falhou depois que o balão some.
- **Ele conhece tipos, não regras.** "No máximo 240" cabe no `max`; "não mais que quatro horas num
  dia" não cabe em atributo nenhum.

Então mantenha os atributos, que não custam nada e ainda protegem o formulário se o seu script falhar,
e acrescente mensagens próprias por cima. Esse é um trabalho que vale entregar a uma biblioteca.
