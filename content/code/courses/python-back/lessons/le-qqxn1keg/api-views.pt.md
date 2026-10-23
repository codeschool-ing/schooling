---
title: As views da API, e as URLs que um roteador escreve
version: 1
---

As views da API vão num módulo próprio, `events/api.py`. Uma classe cuida de tudo sobre eventos, e uma
função cuida da inscrição:

```schooling-example
{"language": "python", "file": "events/api.py", "parts": [{"code": "# events/api.py\nfrom django.db.models import Count\nfrom django.shortcuts import get_object_or_404\nfrom rest_framework import status, viewsets\nfrom rest_framework.decorators import api_view, permission_classes\nfrom rest_framework.permissions import AllowAny\nfrom rest_framework.response import Response\n\nfrom .models import Event\nfrom .serializers import EventSerializer, RegistrationSerializer\nfrom .services import RegistrationRefused, register\n\n\n", "note": "Tudo o que a API responde mora em `events/api.py`, fora as views HTML."}, {"code": "class EventViewSet(viewsets.ModelViewSet):\n    serializer_class = EventSerializer\n    lookup_field = \"slug\"\n\n", "note": "**Um `ModelViewSet` são cinco views numa classe**: listar, buscar um, criar, atualizar e apagar. O `lookup_field = \"slug\"` põe slugs nas URLs em vez de ids numéricos."}, {"code": "    def get_queryset(self):\n        events = Event.objects.annotate(taken=Count(\"registrations\")).order_by(\"starts_at\")\n        venue = self.request.query_params.get(\"venue\")\n        if venue:\n            events = events.filter(venue=venue)\n        return events\n\n\n", "note": "O queryset de que todas essas views partem: a anotação da aula 4, uma ordem explícita já que um `GROUP BY` descarta a do modelo, e um filtro da query string."}, {"code": "@api_view([\"POST\"])\n", "note": "**Uma view-função, ao estilo do DRF.** O `@api_view` transforma o `request` no do DRF, com `request.data` lido do JSON, e deixa a função devolver um `Response`."}, {"code": "@permission_classes([AllowAny])\ndef register_for_event(request, slug):\n    event = get_object_or_404(Event, slug=slug)\n", "note": "Inscrever-se é aberto a qualquer um, diga o padrão do projeto o que disser."}, {"code": "    serializer = RegistrationSerializer(data=request.data)\n    serializer.is_valid(raise_exception=True)\n", "note": "O `raise_exception=True` transforma dados inválidos num 400 com os erros do serializer, sem um `if`."}, {"code": "    try:\n        registration = register(event.pk, **serializer.validated_data)\n    except RegistrationRefused as refusal:\n        return Response({\"detail\": str(refusal)}, status=status.HTTP_409_CONFLICT)\n    return Response(RegistrationSerializer(registration).data, status=status.HTTP_201_CREATED)\n", "note": "**O mesmo serviço que o formulário chama**, então a API ganha a trava e a regra de capacidade de graça. Uma recusa é um **409 Conflict**: a requisição estava bem formada e o estado do evento a recusou."}]}
```

O `EventViewSet` é uma classe que responde a cinco tipos de requisição, e um **roteador** escreve os
padrões de URL para ela. Salve a tabela de URLs da API como `events/api_urls.py`:

```python
# events/api_urls.py
from django.urls import path
from rest_framework.routers import DefaultRouter

from . import api

router = DefaultRouter()
router.register("events", api.EventViewSet, basename="event")

urlpatterns = [
    path("events/<slug:slug>/registrations/", api.register_for_event, name="register"),
    *router.urls,
]
```

E monte-a sob `/api/` no `config/urls.py`:

```python
# config/urls.py
from django.contrib import admin
from django.urls import include, path
from django.views.generic import TemplateView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("about/", TemplateView.as_view(template_name="about.html"), name="about"),
    path("events/", include("events.urls")),
    path("api/", include("events.api_urls")),
]
```

O `DefaultRouter` acrescenta uma raiz que lista os recursos que ele conhece:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/ | python3 -m json.tool
{
    "events": "http://127.0.0.1:8000/api/events/"
}
```

## Ler um evento

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/django-night/ | python3 -m json.tool
{
    "slug": "django-night",
    "title": "Django Night",
    "starts_at": "2026-11-12T19:00:00-03:00",
    "venue": "Community Centre, room 3",
    "capacity": 40,
    "description": "",
    "taken": 1
}
```

O detalhe é a saída do serializer, desta vez com `taken` porque o queryset do viewset faz a anotação.
Todo evento na API é endereçado pelo slug, que é o que o `lookup_field` pediu.

## A página para pessoas

Peça o mesmo endereço em HTML, como um navegador faz:

```
ana@vm:~/agenda$ curl -si -H "Accept: text/html" http://127.0.0.1:8000/api/events/django-night/ | grep -E "^(HTTP|Content-Type)"
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
```

**O DRF respondeu com uma página web**: a *API navegável*, que mostra o JSON, os métodos permitidos e,
para um usuário logado, um formulário para cada escrita. Qual formato volta é decidido pelo cabeçalho
`Accept` da requisição, a **negociação de conteúdo**, e todo endpoint ganha a página de graça. É uma
conveniência de desenvolvimento que vale manter, e uma API cujos únicos clientes são programas pode
desligá-la com o `DEFAULT_RENDERER_CLASSES`.
