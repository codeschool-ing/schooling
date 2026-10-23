---
title: Arquivos estáticos: o CSS, e de onde ele é servido
version: 1
---

Uma folha de estilo, uma imagem, um script: arquivos que são iguais para todo mundo e nunca passam por
uma view são **arquivos estáticos**. O Django os acha do mesmo jeito que acha templates, num diretório
`static/` dentro de cada app, com o nome do app repetido para dois apps não colidirem. Salve isto como
`events/static/events/agenda.css`:

```css
/* events/static/events/agenda.css */
body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 2rem auto; }
header a { font-weight: bold; text-decoration: none; }
.errorlist { color: #b00020; }
```

O template base faz o link com `{% static 'events/agenda.css' %}`, que transforma o caminho dentro de
`static/` no endereço em que o arquivo é servido:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/ | grep stylesheet
  <link rel="stylesheet" href="/static/events/agenda.css">
```

`/static/` é o `STATIC_URL` do `settings.py`. E o arquivo está lá:

```
ana@vm:~/agenda$ curl -sI http://127.0.0.1:8000/static/events/agenda.css | grep -E "^(HTTP|Content-Type|Content-Length)"
HTTP/1.1 200 OK
Content-Type: text/css
Content-Length: 206
```

**O `runserver` o serviu porque o `DEBUG` está ligado.** O app `staticfiles`, ligado pelo
`startproject`, acrescenta um handler para `/static/` ao servidor de desenvolvimento e a nada mais.
Com o `DEBUG` desligado, ou sob o Gunicorn, nada no Django serve esses arquivos, e isso é de
propósito: um processo Python é a peça mais lenta da pilha para entregar os mesmos bytes a todo
mundo.

## Em produção

Duas configurações e um comando mudam isso, e a aula 16 faz as três coisas:

| | o que faz |
|---|---|
| `STATIC_ROOT` | um diretório onde os arquivos estáticos de todos os apps são reunidos |
| `manage.py collectstatic` | copia o `static/` de cada app para o `STATIC_ROOT`, com os arquivos do próprio Django, inclusive os do admin |
| nginx na frente | serve o `STATIC_ROOT` em `/static/` diretamente, e passa todo o resto ao Django |

O template não muda: o `{% static %}` escreve o mesmo endereço nos dois lugares, e é por isso que todo
link para um arquivo estático deve passar por ele em vez de ser digitado.
