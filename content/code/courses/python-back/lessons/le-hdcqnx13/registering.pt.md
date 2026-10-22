---
title: Registrar um modelo
version: 1
---

Um modelo aparece no admin quando é **registrado**. O registro mais curto é uma linha por modelo.
Troque o `events/admin.py`, que o `startapp` deixou vazio:

```python
# events/admin.py
from django.contrib import admin

from .models import Event, Registration

admin.site.register(Event)
admin.site.register(Registration)
```

O `runserver` recarrega, e a página inicial ganha uma seção nova:

```
ana@vm:~/agenda$ page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"
Site administration

      Authentication and Authorization
Model name Add link Change or view list link
  Groups   Add      Change
  Users    Add      Change

                     Events
 Model name   Add link Change or view list link
   Events     Add      Change
Registrations Add      Change

Recent actions
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"Um model admin registrado produz cinco páginas: a lista, incluir, alterar, excluir e histórico, cada uma no próprio endereço sob /admin/events/event/. Cada página confere uma permissão antes de mostrar qualquer coisa: view, add, change, delete, e view de novo para o histórico.\"> <defs><marker id=\"pg5-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"105\" y=\"115\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">@admin.register(Event)</text> <text x=\"105\" y=\"133\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class EventAdmin</text> <rect x=\"250\" y=\"20\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"40\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a lista</text> <text x=\"540\" y=\"40\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/admin/events/event/</text> <rect x=\"570\" y=\"24\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"40\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.view_event</text> <path d=\"M190 120 L244 36\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"62\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"82\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">incluir</text> <text x=\"540\" y=\"82\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/add/</text> <rect x=\"570\" y=\"66\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.add_event</text> <path d=\"M190 120 L244 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"104\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"124\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">alterar</text> <text x=\"540\" y=\"124\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/3/change/</text> <rect x=\"570\" y=\"108\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.change_event</text> <path d=\"M190 120 L244 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"146\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"166\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">excluir</text> <text x=\"540\" y=\"166\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/3/delete/</text> <rect x=\"570\" y=\"150\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"166\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.delete_event</text> <path d=\"M190 120 L244 162\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"188\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">histórico</text> <text x=\"540\" y=\"208\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/3/history/</text> <rect x=\"570\" y=\"192\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.view_event</text> <path d=\"M190 120 L244 204\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <text x=\"635\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">conferida em toda requisição</text> </svg>", "caption": "Registrar um modelo é um decorador; as cinco páginas e as conferências de permissão vêm junto, e esse é o painel que a aula 1 chamou de gratuito."}
```

A página de lista já funciona, sem nada configurado:

```
ana@vm:~/agenda$ page /admin/events/event/ | sed -n "/^Select event to change/,/^[0-9]* events/p"
Select event to change

  * Add event

Action: [- Select an option -  ] Run 0 of 3 selected

[ ]         Event
[ ]      Django Night
[ ] Async Python workshop
[ ]      Testing dojo

Pagination events

3 events
```

Cada linha é o `__str__` do evento, o título, e é por isso que a aula 4 escreveu um. Um modelo sem
`__str__` mostra `Event object (1)` aqui, que é o primeiro sinal de que está faltando um.

## O que veio com a linha

Sem mais uma linha de código, o `admin.site.register(Event)` deu ao agenda:

- uma **lista** de todos os eventos, paginada, com uma caixa de seleção por linha e uma ação de
  excluir;
- um formulário de **inclusão** e um de **alteração** montados a partir dos campos do modelo, com a
  validação de cada campo: um slug que não é slug, uma capacidade abaixo de zero, um título de mais de
  200 caracteres, tudo recusado com uma mensagem ao lado do campo;
- uma página de **exclusão** que lista o que mais vai ser apagado junto com a linha, porque a chave
  estrangeira diz `CASCADE`, e pede confirmação;
- um **histórico** de toda mudança feita pelo admin, com quem a fez e quando.

É um painel que uma equipe levaria semanas para construir, e o motivo de a aula 1 ter citado o admin
entre as suposições do Django. O resto desta aula o configura, e a última seção é sobre para o que ele
não serve.
