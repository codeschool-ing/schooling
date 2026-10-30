"""Lesson 12: the two platforms' no, the flow of asking, and permission.ts as
an annotated example."""
from fig import Fig

T = {
    "en": dict(
        aria1="The two platforms' no, compared as two rows of steps. Android: not asked, then a dialog, then no, then denied with the rationale call returning true, then a second dialog, then no, then denied for good. iOS: not asked, then a dialog, then no, then denied for good. From denied for good, on both, the only way back is the person turning the permission on in Settings.",
        notasked="not asked", dialog="dialog", no="no",
        denied=["denied", "rationale: true"], final="denied for good",
        settings=["the person turns it", "on in Settings"],
        cap1="Android gives one more dialog after a refusal, and iOS none. After the final no, asking shows nothing, on both.",
        aria2="The flow of asking for the reminder permission. The student taps remind me. If the permission is granted, the planner reminds. If it was refused for good, the planner plans without reminders and offers Settings. Otherwise, if Android's rationale call returns true, the planner first shows its own explanation; then the system dialog appears. A yes means the planner reminds; a no means it plans without reminders.",
        tap="the student taps “remind me”",
        q1=["granted", "already?"], q2=["refused", "for good?"], q3=["Android: rationale", "returns true?"],
        own=["the planner's own", "explanation"], sys=["the system's", "dialog"],
        remind="remind", without=["plan without reminders;", "offer Settings"],
        plain=["plan without", "reminders"],
        yes="yes", nn="no",
        cap2="The dialog is the last step, and only reached by a person who has just asked for the thing it guards.",
    ),
    "pt": dict(
        aria1="O não das duas plataformas, comparado em duas linhas de passos. Android: não perguntada, depois um diálogo, depois não, depois negada com a chamada de justificativa devolvendo true, depois um segundo diálogo, depois não, depois negada de vez. iOS: não perguntada, depois um diálogo, depois não, depois negada de vez. A partir de negada de vez, nas duas, o único caminho de volta é a pessoa ligar a permissão nos Ajustes.",
        notasked="não perguntada", dialog="diálogo", no="não",
        denied=["negada", "rationale: true"], final="negada de vez",
        settings=["a pessoa a liga", "nos Ajustes"],
        cap1="O Android dá mais um diálogo depois de uma recusa, e o iOS nenhum. Depois do não final, pedir não mostra nada, nas duas.",
        aria2="O fluxo de pedir a permissão de lembrete. A aluna toca em lembrar. Se a permissão está concedida, o planner lembra. Se foi recusada de vez, o planner planeja sem lembretes e oferece os Ajustes. Senão, se a chamada de justificativa do Android devolve true, o planner primeiro mostra a própria explicação; depois aparece o diálogo do sistema. Um sim faz o planner lembrar; um não faz ele planejar sem lembretes.",
        tap="a aluna toca em “lembrar”",
        q1=["já", "concedida?"], q2=["recusada", "de vez?"], q3=["Android: rationale", "devolve true?"],
        own=["a explicação do", "próprio planner"], sys=["o diálogo", "do sistema"],
        remind="lembrar", without=["planejar sem lembretes;", "oferecer os Ajustes"],
        plain=["planejar sem", "lembretes"],
        yes="sim", nn="não",
        cap2="O diálogo é o último passo, e só chega a ele quem acabou de pedir a coisa que ele protege.",
    ),
}


def noes(t):
    f = Fig("l12-two-noes", 720, 250, t["aria1"])
    f.text(14, 50, "Android", anchor="start", bold=True, size=10.5)
    f.text(14, 140, "iOS", anchor="start", bold=True, size=10.5)
    y = 32
    xs = [76, 168, 246, 314, 432, 510, 578]
    labels = [[t["notasked"]], [t["dialog"]], [t["no"]], t["denied"], [t["dialog"]], [t["no"]], [t["final"]]]
    ws = [84, 70, 60, 110, 70, 60, 130]
    kinds = ["wire", "phosphor", "amber", "wire", "phosphor", "amber", "amber"]
    for i, (x, w, lab, k) in enumerate(zip(xs, ws, labels, kinds)):
        f.box(x, y, w, 36, lab, stroke=k, size=9, fill="amber" if (k == "amber" and i == 6) else "paper")
        if i:
            f.arrow([(xs[i - 1] + ws[i - 1], y + 18), (x, y + 18)])
    y = 122
    ixs = [76, 168, 246, 578]
    iws = [84, 70, 60, 130]
    ilabs = [[t["notasked"]], [t["dialog"]], [t["no"]], [t["final"]]]
    ik = ["wire", "phosphor", "amber", "amber"]
    for i, (x, w, lab, k) in enumerate(zip(ixs, iws, ilabs, ik)):
        f.box(x, y, w, 36, lab, stroke=k, size=9, fill="amber" if i == 3 else "paper")
        if i:
            f.arrow([(ixs[i - 1] + iws[i - 1], y + 18), (x, y + 18)])
    f.box(548, 196, 156, 40, t["settings"], stroke="phosphor", size=9, dashed=True)
    f.arrow([(626, 158), (626, 196)], color="phosphor", dashed=True)
    f.arrow([(708, 50), (715, 50), (715, 216), (704, 216)], color="phosphor", dashed=True)
    return f


def flow(t):
    f = Fig("l12-flow", 720, 396, t["aria2"])
    f.box(250, 10, 220, 30, [t["tap"]], stroke="paper", bold=True)
    f.box(300, 62, 120, 40, t["q1"], stroke="wire", dashed=True)
    f.arrow([(360, 40), (360, 62)])
    f.box(560, 62, 130, 40, [t["remind"]], stroke="phosphor")
    f.arrow([(420, 82), (560, 82)], color="phosphor")
    f.text(490, 74, t["yes"], size=9, fill="paper-dim")
    f.box(300, 132, 120, 40, t["q2"], stroke="wire", dashed=True)
    f.arrow([(360, 102), (360, 132)])
    f.text(372, 117, t["nn"], anchor="start", size=9, fill="paper-dim")
    f.box(530, 132, 180, 40, t["without"], stroke="amber", fill="amber", size=9)
    f.arrow([(420, 152), (530, 152)], color="amber")
    f.text(475, 144, t["yes"], size=9, fill="paper-dim")
    f.box(290, 202, 140, 40, t["q3"], stroke="wire", dashed=True)
    f.arrow([(360, 172), (360, 202)])
    f.text(372, 187, t["nn"], anchor="start", size=9, fill="paper-dim")
    f.box(40, 202, 150, 40, t["own"], stroke="wire")
    f.arrow([(290, 222), (190, 222)])
    f.text(240, 214, t["yes"], size=9, fill="paper-dim")
    f.box(300, 274, 120, 40, t["sys"], stroke="phosphor")
    f.arrow([(360, 242), (360, 274)])
    f.text(372, 258, t["nn"], anchor="start", size=9, fill="paper-dim")
    f.arrow([(115, 242), (115, 294), (300, 294)])
    f.box(560, 274, 130, 40, [t["remind"]], stroke="phosphor")
    f.arrow([(420, 294), (560, 294)], color="phosphor")
    f.text(490, 286, t["yes"], size=9, fill="paper-dim")
    f.box(295, 344, 130, 40, t["plain"], stroke="amber", fill="amber", size=9)
    f.arrow([(360, 314), (360, 344)], color="amber")
    f.text(372, 329, t["nn"], anchor="start", size=9, fill="paper-dim")
    return f


def figures(lang):
    t = T[lang]
    return {
        "l12-two-noes": noes(t).json(t["cap1"], same=None if lang == "en" else ["Android", "iOS", "rationale: true"]),
        "l12-flow": flow(t).json(t["cap2"], same=None if lang == "en" else ["Android: rationale"]),
    }


EXAMPLES = {"the-model": [{"language": "typescript", "file": "permission.ts", "parts": [
    ('// permission.ts: one runtime permission, as each platform\'s documentation describes it\nexport type Platform = "android" | "ios";\nexport type State = "not-asked" | "granted" | "denied" | "denied-for-good";\nexport type Permission = { platform: Platform; state: State };\n\nexport function fresh(platform: Platform): Permission {\n  return { platform, state: "not-asked" };\n}\n',
     "A permission is a platform and a state, and nothing else. The four states are the ones the documentation names; `not-asked` and `denied-for-good` are the two an app cannot tell apart from Android's rationale call alone, which is why the model keeps them separate.",
     'Uma permissão é uma plataforma e um estado, e mais nada. Os quatro estados são os que a documentação nomeia; `not-asked` e `denied-for-good` são os dois que um app não distingue só pela chamada de justificativa do Android, e é por isso que o modelo os mantém separados.'),
    ('// Does asking show the system\'s dialog? Android shows it again after one\n// "no"; iOS shows it once, ever. After that, asking answers at once.\nexport function showsDialog(p: Permission): boolean {\n  if (p.state === "not-asked") return true;\n  return p.platform === "android" && p.state === "denied";\n}\n',
     'The rule that differs. A first request shows the dialog on both; after one no, only Android shows it again. In every other state the request answers at once, with no dialog for the person to see.',
     'A regra que difere. Um primeiro pedido mostra o diálogo nas duas; depois de um não, só o Android o mostra de novo. Em todo outro estado o pedido responde na hora, sem diálogo para a pessoa ver.'),
    ('// The person\'s answer to the dialog. A second "no" on Android, and the\n// first on iOS, is final: the dialog never comes back.\nexport function answer(p: Permission, yes: boolean): Permission {\n  if (yes) return { ...p, state: "granted" };\n  const final = p.platform === "ios" || p.state === "denied";\n  return { ...p, state: final ? "denied-for-good" : "denied" };\n}\n',
     '`final` is the whole difference between the platforms in one line: on iOS any no is final, on Android a no is final when one has already been given.',
     '`final` é a diferença inteira entre as plataformas numa linha: no iOS todo não é final, no Android um não é final quando já houve um antes.'),
    ('// Android\'s shouldShowRequestPermissionRationale(): true after one "no",\n// while one more dialog is still possible. iOS has no such call.\nexport function rationale(p: Permission): boolean {\n  return p.platform === "android" && p.state === "denied";\n}\n',
     '`true` only in the window between the two Android dialogs, which is when the documentation says to explain. Before any ask and after the final no it is `false` alike.',
     '`true` só na janela entre os dois diálogos do Android, que é quando a documentação manda explicar. Antes de qualquer pedido e depois do não final ela é `false` do mesmo jeito.'),
    ('// The person can always change their mind in the system\'s Settings app.\nexport function turnedOnInSettings(p: Permission): Permission {\n  return { ...p, state: "granted" };\n}\n',
     "The way back from any state, on either platform, and the person's choice alone: no call of the app's leads here.",
     'O caminho de volta de qualquer estado, nas duas plataformas, e só por escolha da pessoa: nenhuma chamada do app leva até aqui.'),
    ('// What the planner does next, in each state. Planning sessions never needs\n// the permission; only the reminder for a session does.\nexport function next(p: Permission): string {\n  if (p.state === "granted") return "send reminders";\n  if (p.state === "not-asked") return "ask when a reminder is wanted";\n  if (p.state === "denied") return "explain why, then ask once more";\n  return "plan without reminders; offer Settings";\n}',
     'What the planner does with the answer. Every state but `granted` still plans sessions; only the reminder waits on the permission.',
     'O que o planner faz com a resposta. Todo estado menos `granted` continua planejando sessões; só o lembrete depende da permissão.'),
]}]}
