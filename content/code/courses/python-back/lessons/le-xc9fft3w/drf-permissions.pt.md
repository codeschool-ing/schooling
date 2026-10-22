---
title: Permissões do DRF, por view e por objeto
version: 1
---

Uma classe de permissão do DRF tem dois métodos, e eles rodam em momentos diferentes:

| método | roda | vê | responde |
|---|---|---|---|
| `has_permission(request, view)` | antes de a view fazer qualquer coisa | a requisição | este usuário pode fazer este tipo de requisição? |
| `has_object_permission(request, view, obj)` | quando a view busca um objeto | a requisição e a linha | pode fazer isso com esta linha? |

Os dois respondem sim por padrão. A regra de posse pertence ao segundo. Salve como
`events/permissions.py`:

```python
# events/permissions.py
from rest_framework import permissions


class IsOrganiserOrReadOnly(permissions.BasePermission):
    message = "Only this event's organiser may change it."

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user.is_superuser or obj.organiser_id == request.user.id
```

Ler continua aberto a todos; uma escrita precisa de um superusuário ou do organizador do evento. O
`message` troca a frase genérica do DRF no 403. Depois a view, em `events/api.py`:

```schooling-example
{"language": "python", "file": "django/events/api.py", "parts": [{"code": "# events/api.py\nfrom django.db.models import Count\nfrom django.shortcuts import get_object_or_404\nfrom rest_framework import status, viewsets\nfrom rest_framework.decorators import api_view, permission_classes\nfrom rest_framework.permissions import AllowAny, DjangoModelPermissionsOrAnonReadOnly\nfrom rest_framework.response import Response\n\nfrom .models import Event\nfrom .permissions import IsOrganiserOrReadOnly\nfrom .serializers import EventSerializer, RegistrationSerializer\nfrom .services import RegistrationRefused, register\n\n\n", "note": "Dois imports novos: a classe de permissão do DRF construída sobre as permissões de model do Django, e a do próprio agenda."}, {"code": "class EventViewSet(viewsets.ModelViewSet):\n    serializer_class = EventSerializer\n    lookup_field = \"slug\"\n    permission_classes = [DjangoModelPermissionsOrAnonReadOnly, IsOrganiserOrReadOnly]\n\n    def get_queryset(self):\n        events = Event.objects.annotate(taken=Count(\"registrations\")).order_by(\"starts_at\")\n        venue = self.request.query_params.get(\"venue\")\n        if venue:\n            events = events.filter(venue=venue)\n        return events\n\n", "note": "**As duas classes precisam concordar.** A `DjangoModelPermissionsOrAnonReadOnly` liga POST a `add_event`, PUT e PATCH a `change_event`, DELETE a `delete_event`, e deixa qualquer um ler."}, {"code": "    def perform_create(self, serializer):\n        serializer.save(organiser=self.request.user)\n\n\n", "note": "Quem cria um evento o organiza."}, {"code": "@api_view([\"POST\"])\n@permission_classes([AllowAny])\ndef register_for_event(request, slug):\n    event = get_object_or_404(Event, slug=slug)\n    serializer = RegistrationSerializer(data=request.data)\n    serializer.is_valid(raise_exception=True)\n    try:\n        registration = register(event.pk, **serializer.validated_data)\n    except RegistrationRefused as refusal:\n        return Response({\"detail\": str(refusal)}, status=status.HTTP_409_CONFLICT)\n    return Response(RegistrationSerializer(registration).data, status=status.HTTP_201_CREATED)\n"}]}
```

**As duas classes são consultadas, e as duas precisam dizer sim.** A primeira responde o 401 de uma
escrita anônima e o 403 de um usuário sem a permissão do método; a segunda, o de um usuário com a
permissão e o evento errado. As mesmas portas, com o servidor recarregado:

```
ana@vm:~/agenda$ uv run python doors.py
                          anonymous      carla      bruno        ana
read Django Night               200        200        200        200
change Testing dojo             401        403        200        200
change Async workshop           401        403        403        200
create an event                 401        403        403        400
```

Toda célula agora é o que o agenda quer dizer. A Carla é recusada em toda escrita. O Bruno muda o
evento que organiza e não o da ana, e criar é recusado porque ele não tem `add_event`. A ana abre
toda porta, e o `400` dela na criação vazia é o serializer, atrás de uma porta que abriu. O que o
Bruno lê em cada 403:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17 | python3 -c "import json, sys; print(json.load(sys.stdin)['token'])" > drf-token.txt
ana@vm:~/agenda$ curl -s -X PATCH http://127.0.0.1:8000/api/events/async-workshop/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{"capacity": 30}'; echo
{"detail":"Only this event's organiser may change it."}
ana@vm:~/agenda$ curl -s -X POST http://127.0.0.1:8000/api/events/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{}'; echo
{"detail":"You do not have permission to perform this action."}
```

## O que pode dar errado aqui

**O `has_object_permission` só roda quando a view pede o objeto.** `retrieve`, `update` e `destroy`
chamam `get_object()`, que o chama. Um `list` nunca chama, nem uma view de função ou uma action
própria que busque linhas por conta: nelas, uma regra de objeto simplesmente não é aplicada, em
silêncio. Filtre o queryset quando uma lista precisar mostrar a cada usuário só as linhas dele.

**As duas classes são combinadas com E.** As classes de permissão do DRF também podem ser combinadas
com `&`, `|` e `~` em `permission_classes`, que é como se escreve uma regra como "o organizador, ou
quem tiver `delete_event`" sem uma classe própria.
