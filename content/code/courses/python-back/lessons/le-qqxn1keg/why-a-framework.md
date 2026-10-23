---
title: Why an API needs more than JsonResponse
version: 1
---

Lesson 2 answered with `JsonResponse`, and for reading three events that was enough. An API that
other programs use has more to do, and every one of these jobs would otherwise be written by hand in
each view:

| job | by hand | with Django REST Framework |
|---|---|---|
| reading a JSON body | `json.loads(request.body)`, and a 500 when it is not JSON | `request.data`, and a 400 that says where the JSON broke |
| validating it | an `if` per field | a **serializer**, which is a form for JSON |
| turning rows into JSON | a dictionary built by hand per model | the same serializer, the other way |
| status codes | remembered per view | named constants, and the right one for each failure |
| who may do what | a check in every view | **permission classes**, declared once |
| long lists | slicing by hand | **pagination**, declared once |
| the routes of a resource | five patterns per model | a **router** |

**Django REST Framework**, DRF, is the library that does them. It is not part of Django, but it is
what most Django APIs are written with; the `apis` course later in this track goes deeper into how an
API should be designed. Add it to the project:

```
ana@vm:~/agenda$ uv add djangorestframework
Resolved 8 packages in 183ms
Prepared 1 package in 54ms
Installed 1 package in 6ms
 + djangorestframework==3.18.3
```

## Two settings

It is a Django app, so it goes into `INSTALLED_APPS`, before `events`:

```
ana@vm:~/agenda$ sed -n '/^INSTALLED_APPS/,/^]/p' config/settings.py
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'events',
]
```

And DRF reads its settings from one dictionary, at the end of `config/settings.py`:

```
ana@vm:~/agenda$ sed -n '/^REST_FRAMEWORK/,/^}/p' config/settings.py
REST_FRAMEWORK = {
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 2,
}
```

**`IsAuthenticatedOrReadOnly`** is the default rule for every API view: anybody may read, and only
an authenticated user may write. **`PageNumberPagination`** with a `PAGE_SIZE` of 2 splits every list
into pages of two, a number chosen so that three events show what pagination does; a real API
uses 20 or 50. Both are defaults, and a view can say otherwise, which the registration endpoint
does.
