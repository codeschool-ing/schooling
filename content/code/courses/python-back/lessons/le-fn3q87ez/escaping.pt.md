---
title: Escape, a defesa que vem de graça
version: 1
---

O template da lista imprime de volta o termo buscado: `Results for {{ q }}`. O que a pessoa digitou
na barra de endereço vai para a página. Então experimente digitar HTML:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/events/?q=<b>dojo</b>" | grep Results
<p>Results for &lt;b&gt;dojo&lt;/b&gt;</p>
```

**O Django escapou.** `<` virou `&lt;` e `>` virou `&gt;`, e o navegador mostra os caracteres em vez de
lê-los como uma tag. Toda `{{ variável }}` é escapada desse jeito a menos que algo diga o contrário,
e esse é o padrão certo: um template não tem como saber se uma variável veio do código ou de um
estranho.

## Por que isso importa

Se `q` fosse impresso cru, um link para `/events/?q=<script>…</script>` rodaria esse script no
navegador de quem abrisse o link, **com a sessão dessa pessoa neste site**. Isso é cross-site
scripting, e é o defeito mais comum em aplicações web que montam HTML à mão. A defesa não é filtrar a
entrada "perigosa", o que sempre deixa um caso passar. É **escapar na saída**, em todo lugar, que é o
que o template faz sem ninguém pedir.

A busca comum continua funcionando, porque o escape só muda os cinco caracteres que significam algo
em HTML:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/events/?q=dojo" | grep -A4 "<ul>"
<ul>
  
  <li>
    <a href="/events/testing-dojo/">Testing dojo</a>,
    Thu 26 Nov, 19:00 at Community Centre, room 3
```

## Desligar o escape, e quando não fazer isso

`{{ valor|safe }}` e `mark_safe()` em Python dizem ao Django que um texto já é HTML e deve ser
impresso como está. Eles existem para HTML **que a própria aplicação produziu**: a saída de um
renderizador de Markdown em que você confia, um fragmento montado pelo seu código com toda variável
escapada. **Nunca são para algo que uma pessoa digitou**, e um `|safe` numa variável que veio de um
formulário é o defeito que esta seção descreve, com o nome de um filtro em cima.

Um contexto ainda pede cuidado. Dentro de um bloco `<script>`, escapar HTML não basta, porque as
regras de texto do JavaScript são outras. O filtro do Django para esse caso é o `json_script`, que
escreve um valor na página como JSON dentro de uma tag que um script lê, e é seguro onde um
`{{ valor }}` colado no JavaScript não é.
