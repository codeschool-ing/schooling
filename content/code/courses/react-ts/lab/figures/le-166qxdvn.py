from fig import Fig

u = Fig("union", 720, 230,
        {"en": "Before: one shape with status, courses, sessions, retry and retrying all present at once, so a loading "
               "planner could carry an empty courses list. After: three shapes. Loading has only status. Failed has "
               "status, retry and retrying. Ready has status, courses and sessions. Every shape also has the two "
               "actions.",
         "pt": "Antes: uma forma com status, courses, sessions, retry e retrying todos presentes ao mesmo tempo, então um "
               "planejador carregando podia levar uma lista de cursos vazia. Depois: três formas. Loading tem só status. "
               "Failed tem status, retry e retrying. Ready tem status, courses e sessions. Toda forma também tem as duas "
               "ações."},
        {"en": "Each status carries only the fields that mean something in it.",
         "pt": "Cada status carrega só os campos que fazem sentido nele."})
u.text(105, 22, {"en": "before", "pt": "antes"}, anchor="middle", tone="amber", size=11.5)
u.box(20, 36, 170, 150, ["status", "courses: []", "sessions: []", "retry", "retrying"], mono=True, tone="amber", size=10.5)
u.text(105, 206, {"en": "every field, always", "pt": "todo campo, sempre"}, anchor="middle", tone="dim", size=10.5)
u.text(470, 22, {"en": "after", "pt": "depois"}, anchor="middle", tone="phosphor", size=11.5)
for i, (title, fields) in enumerate([("'loading'", []), ("'failed'", ["retry", "retrying"]), ("'ready'", ["courses", "sessions"])]):
    x = 240 + i * 160
    u.box(x, 36, 145, 110, [f"status: {title}"] + fields, mono=True, tone="phosphor", size=10.5)
u.text(470, 170, "+ toggleDone · addSession", mono=True, anchor="middle", tone="dim", size=10)
u.text(470, 206, {"en": "a field exists only where it means something", "pt": "um campo só existe onde faz sentido"},
       anchor="middle", tone="dim", size=10.5)

FIGS = [u]
