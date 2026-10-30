"""Lesson 16: the sandbox's folders on each platform, and a write that cannot be half-done."""
from fig import Fig

T = {
    "en": dict(
        sb_aria="Two sandboxes side by side. Android, the app's own folder: files and databases and shared preferences, kept and backed up by Auto Backup; no_backup, kept and not backed up; cache, not backed up, and the system may delete it when storage is low. iOS, the app's container: Documents, the user's documents, kept and backed up; Library, Application Support, kept and backed up; Library, Caches, not backed up, and the system may purge it; tmp, not backed up, purged when the app is not running. Other apps cannot reach into either.",
        android="Android: the app's own folder", ios="iOS: the app's container",
        kept="kept · backed up", kept_nb="kept · not backed up", purge="may be deleted by the system",
        other="other apps cannot reach in", gone="all of it goes when the app is uninstalled",
        sb_cap="The same three promises in two spellings: kept and backed up, kept and not backed up, and a cache the system may empty on its own.",
        at_aria="Two ways to save the settings, along a time line, with the process killed at the same moment in both. Writing prefs.json in place: the file is truncated, the new text is half written when the process dies, and the file is left holding half of each, which no longer parses. Writing prefs.json.tmp and then renaming it: the process dies while the temporary file is half written, and prefs.json still holds the old settings, whole.",
        r1="writing prefs.json in place", r2="writing prefs.json.tmp, then rename",
        a1=["prefs.json", "emptied"], a2=["half of the", "new text"], a3=["left half-written:", "it no longer parses"],
        b1=["prefs.json.tmp", "half-written"], b2=["prefs.json", "untouched"], b3=["the old settings,", "whole"],
        kill="the process is killed here",
        at_cap="Killed at the same moment, the first file is broken and the second is the old settings. A rename is the one step that is never half-done.",
        ok="rename: the old file or the new one, never half of each",
    ),
    "pt": dict(
        sb_aria="Duas caixas de areia lado a lado. Android, a pasta do próprio app: files, databases e shared preferences, mantidos e copiados pelo Auto Backup; no_backup, mantido e sem backup; cache, sem backup, e o sistema pode apagar quando falta espaço. iOS, o contêiner do app: Documents, os documentos do usuário, mantidos e com backup; Library, Application Support, mantido e com backup; Library, Caches, sem backup, e o sistema pode esvaziar; tmp, sem backup, esvaziado quando o app não está rodando. Outros apps não alcançam nenhum dos dois.",
        android="Android: a pasta do próprio app", ios="iOS: o contêiner do app",
        kept="mantido · com backup", kept_nb="mantido · sem backup", purge="o sistema pode apagar",
        other="outros apps não entram", gone="tudo vai embora quando o app é desinstalado",
        sb_cap="As mesmas três promessas em duas grafias: mantido e com backup, mantido e sem backup, e um cache que o sistema pode esvaziar por conta própria.",
        at_aria="Dois jeitos de salvar as configurações, ao longo do tempo, com o processo morto no mesmo instante nos dois. Escrevendo prefs.json no lugar: o arquivo é esvaziado, o texto novo está pela metade quando o processo morre, e o arquivo fica com metade de cada, e não é mais lido como JSON. Escrevendo prefs.json.tmp e depois renomeando: o processo morre com o arquivo temporário pela metade, e o prefs.json ainda guarda as configurações antigas, inteiras.",
        r1="escrevendo prefs.json no lugar", r2="escrevendo prefs.json.tmp, depois rename",
        a1=["prefs.json", "esvaziado"], a2=["metade do", "texto novo"], a3=["fica pela metade:", "não é mais JSON"],
        b1=["prefs.json.tmp", "pela metade"], b2=["prefs.json", "intocado"], b3=["as configurações", "antigas, inteiras"],
        kill="o processo é morto aqui",
        at_cap="Mortos no mesmo instante, o primeiro arquivo fica quebrado e o segundo guarda as configurações antigas. Um rename é o único passo que nunca fica pela metade.",
        ok="rename: o arquivo antigo ou o novo, nunca metade de cada",
    ),
}


def sandbox(t):
    f = Fig("l16-sandbox", 720, 300, t["sb_aria"])
    f.rect(14, 30, 336, 210, stroke="phosphor", fill="ink", dashed=True)
    f.rect(370, 30, 336, 210, stroke="phosphor", fill="ink", dashed=True)
    f.text(24, 18, t["android"], anchor="start", bold=True, fill="phosphor")
    f.text(380, 18, t["ios"], anchor="start", bold=True, fill="phosphor")
    a = [(["files/", "databases/", "shared_prefs/"], t["kept"], "wire"),
         (["no_backup/"], t["kept_nb"], "wire"),
         (["cache/"], t["purge"], "amber")]
    y = 44
    for names, note, stroke in a:
        h = 16 + 14 * len(names)
        f.rect(26, y, 312, h, stroke=stroke)
        for i, n in enumerate(names):
            f.text(38, y + 15 + i * 14, n, anchor="start", mono=True)
        f.text(330, y + h / 2, note, anchor="end", size=9.5, fill="amber" if stroke == "amber" else "paper-dim")
        y += h + 10
    b = [(["Documents/"], t["kept"], "wire"),
         (["Library/Application Support/"], t["kept"], "wire"),
         (["Library/Caches/"], t["purge"], "amber"),
         (["tmp/"], t["purge"], "amber")]
    y = 44
    for names, note, stroke in b:
        f.rect(382, y, 312, 36, stroke=stroke)
        f.text(394, y + 18, names[0], anchor="start", mono=True)
        f.text(686, y + 18, note, anchor="end", size=9.5, fill="amber" if stroke == "amber" else "paper-dim")
        y += 46
    f.text(360, 262, t["other"], italic=True, size=10, fill="paper-dim")
    f.text(360, 282, t["gone"], italic=True, size=10, fill="paper-dim")
    return f


def atomic(t):
    f = Fig("l16-atomic", 720, 250, t["at_aria"])
    f.text(20, 22, t["r1"], anchor="start", bold=True, fill="amber")
    f.text(20, 138, t["r2"], anchor="start", bold=True, fill="phosphor")
    xs = [20, 250, 480]
    for x, lines, s in zip(xs, [t["a1"], t["a2"], t["a3"]], ["wire", "wire", "amber"]):
        f.box(x, 36, 210, 44, lines, stroke=s)
    for x, lines, s in zip(xs, [t["b1"], t["b2"], t["b3"]], ["wire", "wire", "phosphor"]):
        f.box(x, 152, 210, 44, lines, stroke=s)
    for y in (58, 174):
        f.arrow([(230, y), (250, y)])
        f.arrow([(460, y), (480, y)])
    f.arrow([(355, 98), (355, 128)], color="amber", dashed=True, head=False)
    f.text(355, 112, "✕ " + t["kill"], fill="amber", size=9.5, anchor="start")
    f.text(360, 226, t["ok"], italic=True, size=9.5, fill="paper-dim")
    return f


def figures(lang):
    t = T[lang]
    return {
        "l16-sandbox": sandbox(t).json(t["sb_cap"]),
        "l16-atomic": atomic(t).json(t["at_cap"], same=None if lang == "en" else ["prefs.json", "prefs.json.tmp"]),
    }


EXAMPLES = {
    "a-database": [
        {"language": "typescript", "file": "store.ts", "parts": [
            ('// store.ts: the planner\'s courses and sessions in SQLite, and the week\'s total in SQL\nimport Database from "better-sqlite3";\nimport { mondayOf } from "./planner.ts";\n\nconst db = new Database("planner.db");\ndb.pragma("foreign_keys = ON");\n',
             "Opening `planner.db` creates the file if it is not there. SQLite enforces a session's `REFERENCES courses` only when foreign keys are switched on, which is one `pragma` per connection.",
             "Abrir o `planner.db` cria o arquivo se ele não existir. O SQLite só faz valer o `REFERENCES courses` de uma sessão quando as chaves estrangeiras estão ligadas, o que é um `pragma` por conexão."),
            ('db.exec(`\n  CREATE TABLE IF NOT EXISTS courses (\n    id    TEXT PRIMARY KEY,\n    title TEXT NOT NULL\n  );\n  CREATE TABLE IF NOT EXISTS sessions (\n    id        TEXT PRIMARY KEY,\n    course_id TEXT NOT NULL REFERENCES courses (id),\n    date      TEXT NOT NULL,\n    minutes   INTEGER NOT NULL,\n    done      INTEGER NOT NULL\n  );\n`);\n',
             "The two lists of lesson 1's `Plan`, as two tables. A session still points at its course by id, and now the database refuses one that points at nothing, as `addSession` did. SQLite has no boolean, so `done` is 0 or 1.",
             "As duas listas do `Plan` da aula 1, como duas tabelas. Uma sessão continua apontando para o curso pelo id, e agora o banco recusa uma que aponte para o nada, como o `addSession` fazia. O SQLite não tem booleano, então `done` é 0 ou 1."),
            ('const addCourse = db.prepare("INSERT OR IGNORE INTO courses (id, title) VALUES (?, ?)");\nconst addSession = db.prepare(\n  "INSERT OR IGNORE INTO sessions (id, course_id, date, minutes, done) VALUES (?, ?, ?, ?, ?)",\n);\ndb.transaction(() => {\n  addCourse.run("sql", "SQL Databases");\n  addCourse.run("mobile", "Mobile Fundamentals");\n  addSession.run("s1", "sql", "2026-10-19", 50, 1);\n  addSession.run("s2", "mobile", "2026-10-20", 40, 1);\n  addSession.run("s3", "sql", "2026-10-23", 60, 0);\n  addSession.run("s4", "mobile", "2026-10-27", 45, 0);\n  addSession.run("s5", "mobile", "2026-10-22", 30, 1);\n})();\n',
             "Lesson 1's week, with `s5` already done. The `?` are filled by `run`, never pasted into the SQL. The transaction writes all seven rows or none, and `OR IGNORE` leaves a row alone if its id is already there, so a second run adds nothing.",
             "A semana da aula 1, com `s5` já concluída. Os `?` são preenchidos pelo `run`, nunca colados no SQL. A transação grava as sete linhas ou nenhuma, e o `OR IGNORE` deixa em paz uma linha cujo id já existe, então uma segunda execução não acrescenta nada."),
            ('const monday = mondayOf(process.argv[2]); // "today" is given, as in week.ts\nconst totals = db\n  .prepare(\n    `SELECT sum(minutes) AS planned,\n            sum(CASE WHEN done THEN minutes ELSE 0 END) AS done\n       FROM sessions\n      WHERE date >= ? AND date < date(?, \'+7 days\')`,\n  )\n  .get(monday, monday);\nconsole.log({ monday, ...totals });\ndb.close();',
             "`weekTotal` from lesson 1, as one query. Dates written `YYYY-MM-DD` sort as text in date order, so the week is every date from Monday up to, not including, the Monday after.",
             "O `weekTotal` da aula 1, como uma consulta. Datas escritas `YYYY-MM-DD` se ordenam como texto na ordem das datas, então a semana é toda data da segunda-feira até a segunda seguinte, sem incluí-la."),
        ]},
    ],
}
