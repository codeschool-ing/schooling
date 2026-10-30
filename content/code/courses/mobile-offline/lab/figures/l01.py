"""Lesson 1: the sandbox, and what the backup takes from it."""
from fig import Fig

T = {
    "en": dict(
        aria="Two sandboxes side by side. Android, under /data/data/<package>/: files, databases and shared_prefs are backed up; cache and no_backup are left out; past 25 MB nothing is backed up. iOS, the app's container: Documents, Library/Application Support and Library/Preferences are backed up; Library/Caches and tmp are left out; there is no quota per app, only the person's iCloud storage.",
        a="Android", i="iOS", ia="the app's container",
        yes="backed up", no="left out",
        an="past 25 MB, none of it is backed up",
        inote="no quota per app: the person's iCloud storage",
        cap="Where a file goes decides whether the backup takes it. The folders left out are the ones that hold what can be fetched again.",
    ),
    "pt": dict(
        aria="Duas caixas de areia lado a lado. Android, em /data/data/<package>/: files, databases e shared_prefs entram no backup; cache e no_backup ficam de fora; acima de 25 MB nada entra no backup. iOS, o contêiner do app: Documents, Library/Application Support e Library/Preferences entram no backup; Library/Caches e tmp ficam de fora; não existe cota por app, só o armazenamento do iCloud da pessoa.",
        a="Android", i="iOS", ia="o contêiner do app",
        yes="entra no backup", no="fica de fora",
        an="acima de 25 MB, nada entra no backup",
        inote="sem cota por app: o iCloud da pessoa",
        cap="O lugar onde um arquivo fica decide se o backup o leva. As pastas deixadas de fora são as que guardam o que dá para buscar de novo.",
    ),
}

AND = [("files/", 1), ("databases/", 1), ("shared_prefs/", 1), ("cache/", 0), ("no_backup/", 0)]
IOS = [("Documents/", 1), ("Library/Application Support/", 1), ("Library/Preferences/", 1), ("Library/Caches/", 0), ("tmp/", 0)]


def panel(f, t, x, title, sub, rows, note):
    f.rect(x, 20, 330, 270, stroke="wire", fill="panel")
    f.text(x + 16, 42, title, anchor="start", bold=True, size=11, fill="phosphor")
    f.text(x + 16, 60, sub, anchor="start", mono=sub.startswith("/"), size=9.5, fill="paper-dim")
    for n, (name, kept) in enumerate(rows):
        y = 76 + n * 36
        f.rect(x + 16, y, 200, 28, stroke="phosphor" if kept else "wire", fill="ink", dashed=not kept)
        f.text(x + 26, y + 14, name, anchor="start", mono=True, size=9.5, fill="paper" if kept else "paper-dim")
        f.text(x + 228, y + 14, t["yes"] if kept else t["no"], anchor="start", size=9.5,
               fill="phosphor" if kept else "paper-dim", italic=not kept)
    f.text(x + 16, 272, note, anchor="start", size=9.5, fill="amber", italic=True)


def figures(lang):
    t = T[lang]
    f = Fig("l01-backup", 720, 310, t["aria"])
    panel(f, t, 20, t["a"], "/data/data/<package>/", AND, t["an"])
    panel(f, t, 370, t["i"], t["ia"], IOS, t["inote"])
    same = None if lang == "en" else ["Android", "iOS"]
    return {"l01-backup": f.json(t["cap"], same=same)}
