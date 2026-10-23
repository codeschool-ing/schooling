---
title: DRF permissions, per view and per object
version: 1
---

A DRF permission class has two methods, and they run at different moments:

| method | runs | sees | answers |
|---|---|---|---|
| `has_permission(request, view)` | before the view does anything | the request | may this user make this kind of request? |
| `has_object_permission(request, view, obj)` | when the view fetches one object | the request and the row | may they do it to this row? |

Both default to yes. The ownership rule belongs to the second. Save it as `events/permissions.py`:

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

Reading stays open to everybody; a write needs a superuser or the event's organiser. `message`
replaces DRF's generic sentence in the 403. Then the view, in `events/api.py`:

```schooling-example
{"language": "python", "file": "events/api.py", "parts": [{"code": "# events/api.py\nfrom django.db.models import Count\nfrom django.shortcuts import get_object_or_404\nfrom rest_framework import status, viewsets\nfrom rest_framework.decorators import api_view, permission_classes\nfrom rest_framework.permissions import AllowAny, DjangoModelPermissionsOrAnonReadOnly\nfrom rest_framework.response import Response\n\nfrom .models import Event\nfrom .permissions import IsOrganiserOrReadOnly\nfrom .serializers import EventSerializer, RegistrationSerializer\nfrom .services import RegistrationRefused, register\n\n\n", "note": "Two new imports: DRF's permission class built on Django's model permissions, and agenda's own."}, {"code": "class EventViewSet(viewsets.ModelViewSet):\n    serializer_class = EventSerializer\n    lookup_field = \"slug\"\n    permission_classes = [DjangoModelPermissionsOrAnonReadOnly, IsOrganiserOrReadOnly]\n\n    def get_queryset(self):\n        events = Event.objects.annotate(taken=Count(\"registrations\")).order_by(\"starts_at\")\n        venue = self.request.query_params.get(\"venue\")\n        if venue:\n            events = events.filter(venue=venue)\n        return events\n\n", "note": "**Both classes must agree.** `DjangoModelPermissionsOrAnonReadOnly` maps POST to `add_event`, PUT and PATCH to `change_event`, DELETE to `delete_event`, and lets anybody read."}, {"code": "    def perform_create(self, serializer):\n        serializer.save(organiser=self.request.user)\n\n\n", "note": "Whoever creates an event organises it."}, {"code": "@api_view([\"POST\"])\n@permission_classes([AllowAny])\ndef register_for_event(request, slug):\n    event = get_object_or_404(Event, slug=slug)\n    serializer = RegistrationSerializer(data=request.data)\n    serializer.is_valid(raise_exception=True)\n    try:\n        registration = register(event.pk, **serializer.validated_data)\n    except RegistrationRefused as refusal:\n        return Response({\"detail\": str(refusal)}, status=status.HTTP_409_CONFLICT)\n    return Response(RegistrationSerializer(registration).data, status=status.HTTP_201_CREATED)\n"}]}
```

**The two classes are both asked, and both must say yes.** The first answers the 401 for an
anonymous write and the 403 for a user with no permission for the method; the second, for a user
with the permission and the wrong event. The same doors, with the server reloaded:

```
ana@vm:~/agenda$ uv run python doors.py
                          anonymous      carla      bruno        ana
read Django Night               200        200        200        200
change Testing dojo             401        403        200        200
change Async workshop           401        403        403        200
create an event                 401        403        403        400
```

Every cell is now what agenda means. Carla is refused every write. Bruno changes the event he
organises and not ana's, and creating is refused because he has no `add_event`. Ana opens every
door, and her `400` for the empty creation is the serializer, behind a door that opened. What Bruno
reads in each 403:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17 | python3 -c "import json, sys; print(json.load(sys.stdin)['token'])" > drf-token.txt
ana@vm:~/agenda$ curl -s -X PATCH http://127.0.0.1:8000/api/events/async-workshop/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{"capacity": 30}'; echo
{"detail":"Only this event's organiser may change it."}
ana@vm:~/agenda$ curl -s -X POST http://127.0.0.1:8000/api/events/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{}'; echo
{"detail":"You do not have permission to perform this action."}
```

## What can go wrong here

**`has_object_permission` runs only when the view asks for the object.** `retrieve`, `update` and
`destroy` call `get_object()`, which calls it. A `list` never does, and neither does a function view
or a custom action that fetches rows by itself: on those, an object rule is silently not applied.
Filter the queryset instead when a list must show each user only their own rows.

**The two classes are ANDed.** DRF's permission classes can also be combined with `&`, `|` and
`~` in `permission_classes`, which is how a rule such as "the organiser, or anybody with
`delete_event`" is written without a class of its own.
