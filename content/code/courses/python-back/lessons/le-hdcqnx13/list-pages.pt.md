---
title: Páginas de lista com que dá para trabalhar
version: 1
---

Uma lista de títulos é um começo. Quem organiza quer a data, o local, o quanto cada evento está cheio,
um jeito de buscar e um jeito de estreitar a lista. Tudo isso é configuração numa classe
**`ModelAdmin`**. Este é o `events/admin.py` inteiro para o resto da aula; o inline, a ação e a
página das inscrições são o assunto das três seções seguintes:

```schooling-example
{"language": "python", "file": "events/admin.py", "parts": [{"code": "# events/admin.py\nimport csv\n\nfrom django.contrib import admin\nfrom django.db.models import Count\nfrom django.http import HttpResponse\n\nfrom .models import Event, Registration\n\n\n", "note": "Tudo o que o admin mostra é configurado aqui, no `admin.py` do próprio app `events`."}, {"code": "class RegistrationInline(admin.TabularInline):\n    model = Registration\n    fields = [\"name\", \"email\", \"created_at\"]\n    readonly_fields = [\"created_at\"]\n    extra = 0\n\n\n", "note": "**Um inline** põe as linhas de um modelo dentro da página de outro: as inscrições de cada evento, como tabela. O `extra = 0` não acrescenta linhas vazias além da de incluir."}, {"code": "@admin.action(description=\"Download registrations as CSV\")\ndef registrations_csv(modeladmin, request, queryset):\n    response = HttpResponse(content_type=\"text/csv\")\n    writer = csv.writer(response)\n    writer.writerow([\"event\", \"name\", \"email\", \"registered\"])\n    for r in Registration.objects.filter(event__in=queryset).select_related(\"event\"):\n        writer.writerow([r.event.slug, r.name, r.email, r.created_at.isoformat()])\n    return response\n\n\n", "note": "**Uma ação** é uma função que a página de lista oferece para as linhas que você marca. Esta responde com um arquivo CSV em vez de uma página."}, {"code": "@admin.register(Event)\nclass EventAdmin(admin.ModelAdmin):\n    list_display = [\"title\", \"starts_at\", \"venue\", \"capacity\", \"taken\"]\n    list_filter = [\"venue\"]\n    search_fields = [\"title\", \"description\"]\n", "note": "**O `@admin.register`** registra o modelo com esta configuração. O `list_display` escolhe as colunas, o `list_filter` a barra lateral, o `search_fields` onde a caixa de busca procura."}, {"code": "    prepopulated_fields = {\"slug\": [\"title\"]}\n    inlines = [RegistrationInline]\n    actions = [registrations_csv]\n\n", "note": "O `prepopulated_fields` preenche o slug a partir do título enquanto você digita, no navegador."}, {"code": "    def get_queryset(self, request):\n        return super().get_queryset(request).annotate(taken=Count(\"registrations\"))\n\n", "note": "**Uma consulta para a lista inteira**: o `annotate` da aula 4, para a coluna de lugares ocupados não custar um `COUNT` por linha."}, {"code": "    @admin.display(ordering=\"taken\", description=\"seats taken\")\n    def taken(self, event):\n        return event.taken\n\n\n", "note": "Uma coluna que não é campo, ordenável por meio da anotação."}, {"code": "@admin.register(Registration)\nclass RegistrationAdmin(admin.ModelAdmin):\n    list_display = [\"name\", \"email\", \"event\", \"created_at\"]\n    list_filter = [\"event\"]\n    search_fields = [\"name\", \"email\"]\n", "note": "As inscrições ganham uma página de lista própria, filtrada por evento."}]}
```

A página de lista, depois que o `runserver` recarrega:

```
ana@vm:~/agenda$ page /admin/events/event/ | sed -n "/^Select event to change/,/^[0-9]* events/p"
Select event to change

  * Add event

Filter

Show counts

By venue

  * All
  * Community Centre, room 3
  * Public Library, lab 2

Search events

Search [                                        ] [Search]
Action: [- Select an option -         ] Run 0 of 3 selected

[ ]         Title                                        Venue           Capacity Seats taken
                                Starts at
[ ]     Django Night      Nov. 12, 2026, 7 p.m. Community Centre, room 3 40       1
[ ] Async Python workshop Nov. 19, 2026, 2 p.m. Public Library, lab 2    12       12
[ ]     Testing dojo      Nov. 26, 2026, 7 p.m. Community Centre, room 3 20       2

Pagination events

3 events
```

**Cada coluna do `list_display` é uma coluna na página**, e `Seats taken` é a anotação: o método
`taken` devolve o número que o `Count` da aula 4 pôs em cada linha, e o `ordering="taken"` torna a
coluna ordenável por ele. A data sai formatada no horário de São Paulo, pelo `TIME_ZONE`, exatamente
como os templates do próprio site fazem. A barra lateral, `By venue`, vem do `list_filter`, com um
link por valor distinto.

## Busca

A caixa de busca procura em todo campo do `search_fields`, sem diferenciar maiúsculas:

```
ana@vm:~/agenda$ page "/admin/events/event/?q=dojo" | sed -n "/^Select event to change/,/^[0-9]* event/p"
Select event to change

  * Add event

Filter

Show counts

By venue

  * All
  * Community Centre, room 3
  * Public Library, lab 2

Search events

Search [dojo                                    ] [Search] 1 result (3 total)
Action: [- Select an option -         ] Run 0 of 1 selected

[ ]    Title                                    Venue           Capacity Seats taken
                       Starts at
[ ] Testing dojo Nov. 26, 2026, 7 p.m. Community Centre, room 3 20       2

Pagination events

1 event
```

`1 result (3 total)` é o admin sendo preciso sobre o que filtrou. Por trás está o `icontains` da aula
4 em cada campo, ligados por `OR`. Um campo de busca que segue uma relação, como
`registrations__email`, busca através do join, e numa tabela grande é uma consulta que vale olhar
com o `explain()` antes.

## Três configurações que vale conhecer

| | o que faz |
|---|---|
| `list_per_page` | linhas por página, 100 por padrão |
| `date_hierarchy = "starts_at"` | uma fileira de links para descer por ano, mês e dia |
| `list_select_related` | segue chaves estrangeiras na consulta única da lista, o `select_related` da aula 4 |

**A contagem de consultas de uma lista do admin é problema seu, não do Django.** Uma coluna do
`list_display` que lê um objeto relacionado, `event.organiser.email` por exemplo, roda uma consulta por
linha, a menos que o queryset faça o join. O `get_queryset` é onde isso se resolve, como o `taken` já
está resolvido aqui.
