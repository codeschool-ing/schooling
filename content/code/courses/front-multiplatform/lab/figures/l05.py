"""Lesson 5: one interface, three implementations, joined by a name."""
from fig import Fig

T = {
 "en": dict(aria="One plugin from the inside. The planner imports the KeepAwake interface from src/definitions.ts. registerPlugin('KeepAwake') in src/index.ts joins it, by that name, to three implementations: src/web.ts for the browser, which uses the Screen Wake Lock API; KeepAwakePlugin.kt for Android, which sets FLAG_KEEP_SCREEN_ON on the window; and KeepAwakePlugin.swift for iOS, which sets isIdleTimerDisabled. Capacitor calls the one for the platform the app runs on.",
   app=["the planner calls", "KeepAwake.keepAwake()"], iface=["src/definitions.ts:", "the interface"], reg=["registerPlugin(\"KeepAwake\")", "in src/index.ts"],
   web=["web: src/web.ts", "Screen Wake Lock API"], android=["Android: Kotlin", "FLAG_KEEP_SCREEN_ON"], ios=["iOS: Swift", "isIdleTimerDisabled"],
   name="the same name, and the same method names, on all three sides",
   cap="The planner sees one interface. Behind it are three programs in three languages, and only the name joins them."),
 "pt": dict(aria="Um plugin por dentro. O planner importa a interface KeepAwake de src/definitions.ts. O registerPlugin('KeepAwake') em src/index.ts a liga, por esse nome, a três implementações: src/web.ts para o navegador, que usa a Screen Wake Lock API; KeepAwakePlugin.kt para o Android, que liga a FLAG_KEEP_SCREEN_ON na janela; e KeepAwakePlugin.swift para o iOS, que liga o isIdleTimerDisabled. O Capacitor chama a da plataforma onde o app roda.",
   app=["o planner chama", "KeepAwake.keepAwake()"], iface=["src/definitions.ts:", "a interface"], reg=["registerPlugin(\"KeepAwake\")", "em src/index.ts"],
   web=["web: src/web.ts", "Screen Wake Lock API"], android=["Android: Kotlin", "FLAG_KEEP_SCREEN_ON"], ios=["iOS: Swift", "isIdleTimerDisabled"],
   name="o mesmo nome, e os mesmos nomes de método, nos três lados",
   cap="O planner vê uma interface. Atrás dela estão três programas em três linguagens, e só o nome os liga."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l05-plugin", 720, 230, t["aria"])
    f.box(20, 40, 170, 46, t["app"], stroke="wire", size=9.5)
    f.box(220, 40, 160, 46, t["iface"], stroke="phosphor", size=9.5)
    f.box(410, 40, 170, 46, t["reg"], stroke="amber", size=9.5)
    f.arrow([(190, 63), (220, 63)])
    f.arrow([(380, 63), (410, 63)])
    for x, lines in zip([60, 270, 480], [t["web"], t["android"], t["ios"]]):
        f.box(x, 140, 180, 46, lines, stroke="wire", size=9.5)
    f.arrow([(495, 86), (150, 140)])
    f.arrow([(495, 86), (360, 140)])
    f.arrow([(495, 86), (570, 140)])
    f.text(360, 212, t["name"], size=9, fill="paper-dim", italic=True)
    same = None if lang == "en" else ["src/definitions.ts:", "KeepAwake.keepAwake()", "registerPlugin(\"KeepAwake\")", "Screen Wake Lock API", "FLAG_KEEP_SCREEN_ON", "isIdleTimerDisabled", "web: src/web.ts", "Android: Kotlin", "iOS: Swift"]
    return {"l05-plugin": f.json(t["cap"], same=same)}
