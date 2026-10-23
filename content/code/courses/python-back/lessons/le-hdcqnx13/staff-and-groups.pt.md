---
title: Staff, permissões e grupos
version: 1
---

Toda página que o admin desenha confere uma permissão antes, e o Django criou quatro para cada modelo
quando a aula 4 o migrou:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.contrib.auth.models import Permission; print(list(Permission.objects.filter(content_type__app_label=\"events\").values_list(\"codename\", flat=True)))"
14 objects imported automatically (use -v 2 for details).

['add_event', 'change_event', 'delete_event', 'view_event', 'add_registration', 'change_registration', 'delete_registration', 'view_registration']
```

`view`, `add`, `change` e `delete`, por modelo. Um usuário só entra no admin quando o `is_staff` está
ligado, e aí vê exatamente os modelos e os botões que as permissões dele permitem. Um
**superusuário** pula as conferências, e é por isso que a `ana` via tudo.

## Um grupo para quem organiza

Permissões são dadas a **grupos**, e as pessoas são postas em grupos, para que "o que um organizador
pode fazer" seja escrito uma vez. Organizadores do agenda podem ver e alterar eventos, e ver
inscrições sem alterá-las. Este script cria o grupo e põe o Bruno nele, como staff; salve como
`organisers.py`:

```python
# organisers.py
from django.contrib.auth.models import Group, Permission, User

organisers, _ = Group.objects.get_or_create(name="Organisers")
organisers.permissions.set(
    Permission.objects.filter(
        content_type__app_label="events",
        codename__in=["view_event", "change_event", "view_registration"],
    )
)

bruno, _ = User.objects.get_or_create(username="bruno", defaults={"email": "bruno@example.org"})
bruno.set_password("m4-orchard-copper-17")
bruno.is_staff = True
bruno.save()
bruno.groups.add(organisers)

print(sorted(bruno.get_all_permissions()))
print(bruno.has_perm("events.delete_event"))
```

```
ana@vm:~/agenda$ uv run python manage.py shell < organisers.py
14 objects imported automatically (use -v 2 for details).

['events.change_event', 'events.view_event', 'events.view_registration']
False
```

O `get_all_permissions()` lista o que o Bruno tem pelos grupos, e o `has_perm` é a conferência que
toda página do admin roda: não, ele não pode apagar um evento. Entre como ele, e a página inicial
encolhe:

```
ana@vm:~/agenda$ curl -s -c ~/admin-cookies.txt -o /dev/null http://127.0.0.1:8000/admin/login/; TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -c ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&username=bruno&password=m4-orchard-copper-17&next=/admin/" http://127.0.0.1:8000/admin/login/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /admin/
ana@vm:~/agenda$ page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"
Site administration

                     Events
 Model name   Add link Change or view list link
   Events              Change
Registrations          View

Recent actions
```

**Nenhum link *Add* em lugar nenhum**, *Change* para eventos e *View* para inscrições, e os usuários e
grupos do próprio Django nem aparecem. As páginas que faltam não estão só escondidas; pedi-las
diretamente é recusado:

```
ana@vm:~/agenda$ curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/events/event/3/delete/
403
ana@vm:~/agenda$ curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/auth/user/
403
```

**403 Forbidden**, para a página de exclusão de um evento e para a lista de usuários. O admin confere
em toda requisição, então um link copiado da tela de outra pessoa não leva as permissões dela junto.

## Quem deve ser staff

Contas de staff são poucas, pertencem a pessoas que a organização conhece, e cada uma tem o grupo mais
estreito que dá conta do trabalho. A aula 12 usa essas mesmas permissões fora do admin, para decidir
quem pode fazer o quê no próprio site, e acrescenta a regra que as permissões sozinhas não expressam:
um organizador pode alterar **os próprios** eventos, não os de todo mundo.
