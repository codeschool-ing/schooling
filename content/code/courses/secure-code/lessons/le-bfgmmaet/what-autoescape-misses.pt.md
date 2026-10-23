---
title: O que o escape automático não faz por você
version: 1
---

O escape automático é o motivo de a maioria das páginas Flask estar certa, e ele cobre um contexto:
texto HTML e atributos HTML entre aspas. **Todo o resto continua sendo seu**, e a maior parte das
falhas reais de escape em código Flask ou Django mora nas brechas abaixo, e não num template que
esqueceu de escapar.

### Desligando

Três jeitos de dizer ao Jinja que um valor já é HTML seguro, e cada um desliga o escape para aquele
valor:

| | o que faz | quando está certo |
|---|---|---|
| o filtro `safe`, num template | marca o valor como HTML | para HTML que a própria aplicação gerou, nunca para algo que uma pessoa digitou |
| `Markup(value)`, no Python | o mesmo, no código | a mesma regra; é mais fácil de passar despercebido numa revisão que o filtro |
| `{% autoescape false %}` | desliga o escape num bloco inteiro | quase nunca |

`|safe` na mensagem de um paciente é o jeito habitual de um template Jinja ficar inseguro. A aula 7
mostra o que dá errado, e como uma mensagem que precisa manter alguma formatação é limpa em vez de
receber confiança.

### Montando HTML antes de o template ver

O escape acontece quando o template renderiza um valor. **HTML montado antes no Python**, com uma
f-string ou `+`, e passado com `|safe` porque senão apareceria como texto, já pulou o escape de
todos os valores dentro dele. A saída é passar os valores ao template e deixar que ele monte o HTML.

### Contextos que o escape não entende

- **Dentro de `<script>`, e em atributos de evento como `onclick="…"`.** O escape de HTML produz
  entidades HTML, e o motor de JavaScript lê o que sobra depois que o interpretador de HTML as
  desfez. Use `tojson` para dados num script, e mantenha dados fora dos atributos `on…`: ponha num
  atributo `data-` e leia pelo JavaScript.
- **Dentro de `<style>` e `style="…"`.** CSS tem sintaxe e escape próprios, e a regra prática é nunca
  pôr dados do usuário ali.
- **O destino de um link.** Escapar o `href` torna inofensivo o texto do endereço. Não transforma um
  endereço `data:` ou `javascript:` numa página web, e é por isso que a correção manteve uma lista de
  permissão de esquemas: a ideia da aula 2 aplicada à saída.

### Templates que não são HTML

O Flask só escapa automaticamente templates cujo nome termina em `.html`, `.htm`, `.xml`, `.xhtml`
ou `.svg`, além do `render_template_string`. Um template chamado `email.txt` que vira um e-mail HTML
não é escapado em nada. Dê aos templates o nome do que eles produzem, e confira a configuração quando
um projeto renderiza algo fora do comum.
