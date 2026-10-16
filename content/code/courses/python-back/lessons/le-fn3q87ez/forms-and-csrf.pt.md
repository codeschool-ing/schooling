---
title: Um formulário, o token dele, e o redirecionamento depois
version: 1
---

Inscrever-se num evento é um **formulário**: um nome, um endereço de e-mail, um botão. A classe
`Form` do Django descreve os campos uma vez e faz três trabalhos com essa descrição: escreve os inputs
HTML, valida o que volta e converte em valores Python. Salve isto como `events/forms.py`:

```python
# events/forms.py
from django import forms


class RegistrationForm(forms.Form):
    name = forms.CharField(max_length=100)
    email = forms.EmailField()
```

O `EmailField` é um `CharField` com um validador de e-mail. Todo campo é **obrigatório**, a menos que
diga o contrário, e a validação roda no servidor, faça o navegador o que fizer.

## A view, respondendo aos dois métodos

A view de detalhe agora mostra o formulário num GET e o processa num POST. Este é o
`events/views.py` inteiro, com a view da lista da seção de templates:

```schooling-example
{"language": "python", "file": "events/views.py", "parts": [{"code": "# events/views.py\nfrom django.http import Http404\nfrom django.shortcuts import redirect, render\n\nfrom .data import EVENTS, REGISTRATIONS\nfrom .forms import RegistrationForm\n\n\n", "note": "Dois imports são novos: `render` monta uma resposta a partir de um template, e `redirect` responde 302."}, {"code": "def find_event(slug):\n    for event in EVENTS:\n        if event[\"slug\"] == slug:\n            return event\n    raise Http404(f\"No event called {slug}\")\n\n\n", "note": "**Achar um evento virou uma função**, porque as duas views precisam disso."}, {"code": "def event_list(request):\n    q = request.GET.get(\"q\", \"\")\n    events = [e for e in EVENTS if q.lower() in e[\"title\"].lower()]\n    return render(request, \"events/event_list.html\", {\"events\": events, \"q\": q})\n\n\n", "note": "`render(request, template, context)` preenche o template com o dicionário e devolve um `HttpResponse`."}, {"code": "def event_detail(request, slug):\n    event = find_event(slug)\n    taken = sum(1 for r in REGISTRATIONS if r[\"slug\"] == slug)\n", "note": "A mesma URL responde aos dois métodos: o GET mostra o formulário, o POST o envia."}, {"code": "    if request.method == \"POST\":\n        form = RegistrationForm(request.POST)\n", "note": "**Um formulário vinculado**, montado a partir de `request.POST`. O `is_valid()` roda as conferências de cada campo e preenche o `cleaned_data`."}, {"code": "        if form.is_valid() and taken >= event[\"capacity\"]:\n            form.add_error(None, \"This event is full.\")\n", "note": "Uma regra que nenhum campo conhece, acrescentada como erro do formulário inteiro. Depois do `add_error`, o `is_valid()` é falso."}, {"code": "        if form.is_valid():\n            REGISTRATIONS.append({\"slug\": slug, **form.cleaned_data})\n            return redirect(\"events:detail\", slug=slug)\n", "note": "**O sucesso redireciona** em vez de renderizar, para um reload não postar duas vezes."}, {"code": "    else:\n        form = RegistrationForm()\n    context = {\"event\": event, \"form\": form, \"taken\": taken}\n    return render(request, \"events/event_detail.html\", context)\n", "note": "Um formulário não vinculado para o GET, e os dois casos caem no mesmo `render`."}]}
```

A URL de detalhe aponta de novo para uma função em vez da classe da aula 2, em `events/urls.py`:

```python
# events/urls.py
from django.urls import path

from . import views

app_name = "events"
urlpatterns = [
    path("", views.event_list, name="list"),
    path("<slug:slug>/", views.event_detail, name="detail"),
]
```

E o template de detalhe, `events/templates/events/event_detail.html`:

```html
{# events/templates/events/event_detail.html #}
{% extends "base.html" %}

{% block title %}{{ event.title }} · agenda{% endblock %}

{% block content %}
<h1>{{ event.title }}</h1>
<p>{{ event.starts_at|date:"l j F Y, H:i" }}, {{ event.venue }}</p>
<p>{{ taken }} of {{ event.capacity }} seats taken.</p>

<form method="post">
  {% csrf_token %}
  {{ form.as_p }}
  <button type="submit">Register</button>
</form>
{% endblock %}
```

O `{{ form.as_p }}` escreve cada campo como um parágrafo com o rótulo, o input e os erros. O
`{% csrf_token %}` escreve o campo oculto de que esta seção inteira depende. Eis o resultado:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/ | sed -n "/<main>/,/<\/main>/p"
  <main>
    
<h1>Async Python workshop</h1>
<p>Thursday 19 November 2026, 14:00, Public Library, lab 2</p>
<p>0 of 12 seats taken.</p>

<form method="post">
  <input type="hidden" name="csrfmiddlewaretoken" value="MYBHQiLxmaEdu2q7VrHz55wlCzEd6kcDTv3vqts8ZlevCwy0tdsrqYLkHOMYDVsc">
  <p>
    <label for="id_name">Name:</label>
    <input type="text" name="name" maxlength="100" required id="id_name">
    
    
  </p>

  
  <p>
    <label for="id_email">Email:</label>
    <input type="email" name="email" maxlength="320" required id="id_email">
    
    
      
    
  </p>
  <button type="submit">Register</button>
</form>

  </main>
```

`required`, `maxlength` e `type="email"` vieram das definições dos campos, então o navegador confere
isso antes de enviar. **Isso é uma conveniência para a pessoa, não uma conferência para o
servidor**: qualquer coisa que não use a página, como o curl, manda o que quiser.

## O token

O `csrfmiddlewaretoken` oculto é a resposta ao 403 da aula 2. Um POST sem ele é recusado, exatamente
como antes:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" -d "name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/async-workshop/
403
```

O GET que serviu a página também definiu um cookie, `csrftoken`, e o campo oculto leva um valor
derivado do mesmo segredo. **Um POST só é aceito quando os dois batem.** Uma página de outro site
consegue fazer o seu navegador postar no agenda, e o navegador até anexa os cookies do agenda, mas
essa página não consegue ler o HTML do agenda para saber o token, então o POST dela falha. Isso é
cross-site request forgery, CSRF, e o middleware e a tag do template são a defesa inteira.

O curl consegue fazer o que um navegador faz: guardar o cookie e mandar o token de volta.

```
ana@vm:~/agenda$ curl -s -c cookies.txt -o /dev/null http://127.0.0.1:8000/events/async-workshop/ && grep -o "csrftoken.*" cookies.txt | cut -c1-24
csrftoken	koSxdqUYgJvQ44
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -si -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /events/async-workshop/
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats
<p>1 of 12 seats taken.</p>
```

A inscrição foi aceita, e a resposta não foi uma página, mas **302 Found**, de volta ao mesmo
endereço. Esse é o padrão **Post/Redirect/Get**: depois de um POST que mudou algo, redirecione, para
que a página em que a pessoa termina tenha vindo de um GET. Recarregar repete o GET, e ninguém é
inscrito duas vezes por apertar F5.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Uma sequência entre o navegador e o agenda. O navegador recebe a página, que define um cookie csrftoken e leva o mesmo segredo num campo oculto. Ele envia o formulário com o cookie e o token, e o agenda grava a inscrição e responde 302 para o mesmo endereço. O navegador segue com um GET e vê a contagem atualizada. Um formulário enviado de outro site não traz token e é recusado com 403.\"> <defs><marker id=\"pg-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"pg-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"110\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o navegador</text> <text x=\"560\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">agenda</text> <path d=\"M110 36 L110 300\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M560 36 L560 300\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M114 60 L554 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"54\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /events/async-workshop/</text> <path d=\"M556 90 L116 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200: o formulário, um token oculto</text> <text x=\"335\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Set-Cookie: csrftoken=…</text> <path d=\"M114 140 L554 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST: cookie + token + nome, e-mail</text> <path d=\"M556 170 L116 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">302 Location: /events/async-workshop/</text> <text x=\"335\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gravado; agora mande o navegador embora</text> <path d=\"M114 220 L554 220\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /events/async-workshop/</text> <path d=\"M556 250 L116 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200: 1 of 12 seats taken</text> <text x=\"335\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recarregar esta página repete um GET, não o POST</text> <path d=\"M300 288 L554 288\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#pg-b)\"></path> <text x=\"296\" y=\"292\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">formulário de outro site: sem token, 403</text> </svg>", "caption": "Duas defesas numa troca só: o token prova que o formulário veio deste site, e o redirecionamento depois de um POST bem-sucedido faz com que recarregar a página nunca inscreva alguém duas vezes.", "same": ["agenda", "Set-Cookie: csrftoken=…"]}
```

## Quando o formulário está errado

Um endereço sem `@`:

```
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Carla&email=carla.example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -B1 -A1 errorlist

  <ul class="errorlist" id="id_email_error"><li>Enter a valid email address.</li></ul>
  <p>
```

O `is_valid()` deu falso, então a view caiu no `render` com o formulário **vinculado**, e o template
imprimiu o erro ao lado do campo, com o que a pessoa digitou ainda nele. A mensagem,
`Enter a valid email address.`, é a do próprio validador.

## Uma regra que nenhum campo conhece

Doze lugares. Mais onze inscrições os preenchem:

```
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); for i in $(seq 2 12); do curl -s -o /dev/null -w "%{http_code} " -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Person $i&email=p$i@example.org" http://127.0.0.1:8000/events/async-workshop/; done; echo
302 302 302 302 302 302 302 302 302 302 302 
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats
<p>12 of 12 seats taken.</p>
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -w "%{http_code}\n" -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Davi&email=davi@example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -E "errorlist|^[0-9]{3}$"
  <ul class="errorlist nonfield"><li>This event is full.</li></ul>
200
```

A décima terceira recebeu o formulário de volta com `This event is full.` e um 200, porque nada foi
gravado e não há para onde redirecionar. O erro pertence ao formulário inteiro, não a um campo, e é
por isso que a view o acrescentou com `add_error(None, …)` e o template o imprimiu acima dos campos.

**Dois avisos sobre essa regra do jeito que está.** As inscrições moram numa lista Python, então
somem quando o `runserver` reinicia, e a conferência é uma contagem seguida de um append: duas
requisições chegando juntas podem ambas ver onze e ambas fazer o append. A aula 4 leva as inscrições
para o PostgreSQL e faz o banco garantir tanto a unicidade de um e-mail por evento quanto a
capacidade, que é onde mora uma regra que precisa valer sob carga.
