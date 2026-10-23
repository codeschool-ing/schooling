---
title: Staff, permissions and groups
version: 1
---

Every page the admin draws checks a permission first, and Django created four of them for each model
when lesson 4 migrated it:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.contrib.auth.models import Permission; print(list(Permission.objects.filter(content_type__app_label=\"events\").values_list(\"codename\", flat=True)))"
14 objects imported automatically (use -v 2 for details).

['add_event', 'change_event', 'delete_event', 'view_event', 'add_registration', 'change_registration', 'delete_registration', 'view_registration']
```

`view`, `add`, `change` and `delete`, per model. A user gets into the admin at all only when
`is_staff` is true, and then sees exactly the models and the buttons their permissions allow. A
**superuser** skips the checks, which is why `ana` saw everything.

## A group for organisers

Permissions are given to **groups**, and people are put in groups, so that "what an organiser may do"
is written once. Organisers of agenda may see and change events, and see registrations without
changing them. This script makes the group and puts Bruno in it, as a staff member; save it as
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

`get_all_permissions()` lists what Bruno has through his groups, and `has_perm` is the check every
admin page runs: no, he may not delete an event. Log in as him, and the front page shrinks:

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

**No *Add* link anywhere**, *Change* for events and *View* for registrations, and Django's own users
and groups are not on the page at all. The pages that are missing are not just hidden; asking for
them directly is refused:

```
ana@vm:~/agenda$ curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/events/event/3/delete/
403
ana@vm:~/agenda$ curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/auth/user/
403
```

**403 Forbidden**, for the delete page of an event and for the list of users. The admin checks on
every request, so a link copied from somebody else's screen does not carry their permissions with
it.

## Who should be staff

Staff accounts are few, belong to people the organisation knows, and each has the narrowest group
that does the job. Lesson 12 uses these same permissions outside the admin, to decide who may do
what on the site itself, and adds the rule permissions cannot express by themselves: an organiser
may change **their own** events, not everybody's.
