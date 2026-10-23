---
title: LDAP filters, escaped by the library
version: 1
---

**LDAP** is the protocol most organisations' staff directories speak, Microsoft's Active Directory
among them. A search sends a **filter** written in its own small language: `(cn=carla)` means "entries
whose common name is carla", `*` means "anything", and parentheses group conditions. The console
builds the filter with an f-string:

```python
        "ou=staff,dc=vereda,dc=example", f"(cn={request.args['name']})", attributes=["cn", "title"]
```

A receptionist who does not remember a name and types `*`, as many search boxes allow, receives every
member of staff:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k star
F                                                                        [100%]
=================================== FAILURES ===================================
___________________ test_a_star_is_a_character_not_everyone ____________________
/home/ana/sc/exams-convert/test_app.py:29: in test_a_star_is_a_character_not_everyone
    assert client.get("/staff?name=*").json == []
E   AssertionError: assert [{'name': 'an...e': 'physio'}] == []
E     
E     Left contains 3 more items, first extra item: {'name': 'ana', 'role': 'admin'}
E     Use -v to get more diff
=========================== short test summary info ============================
FAILED test_app.py::test_a_star_is_a_character_not_everyone - AssertionError:...
1 failed, 5 deselected in 0.15s
```

**The star was read as the filter's wildcard**, not as a character in a name. In this directory
"everyone" is three people and their roles; in a real one it is every account in the organisation,
with whatever attributes the search asks for. A name with parentheses in it, as some directories
store a department beside a name, breaks the filter outright, and the console answers `500`:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k parentheses 2>&1 | grep -E '^E |^ldap3|passed|failed'
E   AssertionError: assert None == []
E    +  where None = <WrapperTestResponse streamed [500 INTERNAL SERVER ERROR]>.json
E    +    where <WrapperTestResponse streamed [500 INTERNAL SERVER ERROR]> = get('/staff', query_string={'name': 'Silva (Pinheiros)'})
E    +      where get = <FlaskClient <Flask 'app'>>.get
ldap3.core.exceptions.LDAPInvalidFilterError: malformed filter
1 failed, 5 deselected in 0.17s
```

### The library's escaping

LDAP filters have no placeholders, so this is the case where **escaping** is the separate channel. RFC
4515, which defines the filter syntax, says how: each special character is written as a backslash and
its two hexadecimal digits, so `*` becomes `\2a` and means a star. `ldap3` provides the function:

```
(.venv) ana@vm:~/sc/exams-convert$ git diff
diff --git a/app.py b/app.py
index 4dc7da8..fecbd07 100644
--- a/app.py
+++ b/app.py
@@ -4,6 +4,7 @@ from pathlib import Path
 
 from flask import Flask, jsonify, render_template_string, request
 from ldap3 import MOCK_SYNC, Connection, Server
+from ldap3.utils.conv import escape_filter_chars
 
 app = Flask(__name__)
 EXAMS = Path("exams")
@@ -40,7 +41,7 @@ def exam_type(name):
 def find_staff():
     connection = directory()
     connection.search(
-        "ou=staff,dc=vereda,dc=example", f"(cn={request.args['name']})", attributes=["cn", "title"]
+        "ou=staff,dc=vereda,dc=example", f"(cn={escape_filter_chars(request.args['name'])})", attributes=["cn", "title"]
     )
     return jsonify([{"name": str(e.cn), "role": str(e.title)} for e in connection.entries])
 
```

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=no
.....F                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_note_is_shown_as_written - AssertionError: assert ...
1 failed, 5 passed in 0.19s
```

**The star now finds nobody, because nobody is called `*`, and the parentheses are searched for as
written.** Commit:

```
(.venv) ana@vm:~/sc/exams-convert$ git commit -qam "Escape the name in the LDAP filter"
```

Two more habits apply to directory searches. **Bind the application with an account that can read only
what the feature needs**, so a filter that goes wrong exposes the attributes the console needs and not
every account's details. And **ask for named attributes**, `["cn", "title"]` as here, rather than all of
them.
