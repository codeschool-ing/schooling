"""Lesson 11: how a verified link is verified, what happens when a link is
tapped, and links.ts as an annotated example."""
from fig import Fig

T = {
    "en": dict(
        aria1="How a verified link is verified, in four steps from left to right. The app is installed, and it declares a domain. The system fetches the domain's file over https: assetlinks.json on Android, apple-app-site-association on iOS. It compares the file with the app: the package and certificate fingerprint on Android, the team and bundle id on iOS. If they match, links to the domain open the app; if not, they open the browser.",
        s1=["the app is installed,", "and declares a domain"],
        s2=["the system fetches", "the domain's file"],
        s3=["it compares the file", "with the app"],
        ok=["match: links to the", "domain open the app"],
        bad=["no match: links", "open the browser"],
        an="Android", io="iOS",
        a3=["package +", "certificate fingerprint"], i3=["team id +", "bundle id"],
        https="over https, no redirect",
        cap1="Verification happens once the app is installed, not when a link is tapped. The tap only follows what was decided then.",
        aria2="What happens when a link is tapped, as a decision path. First: is the link https? If not, it uses a custom scheme: if an installed app claims the scheme, that app opens, or a dialog if several do; if none does, nothing opens. If the link is https: if an installed app is verified for the domain, that app opens on the screen; if not, the browser opens the address and the website answers.",
        tap="a link is tapped",
        q1=["is it an https", "address?"],
        q2=["does an installed app", "claim the scheme?"],
        q3=["is an installed app", "verified for the domain?"],
        yes="yes", no="no",
        r1=["that app opens, or a", "dialog if several do"],
        r2=["nothing opens"],
        r3=["the app opens, on", "the screen it names"],
        r4=["the browser opens the", "page, and the site answers"],
        cs="custom scheme",
        cap2="The system follows this path before any of the app's code runs. Only a verified https link has an answer in every branch.",
    ),
    "pt": dict(
        aria1="Como um link verificado é verificado, em quatro passos da esquerda para a direita. O app é instalado e declara um domínio. O sistema busca o arquivo do domínio por https: assetlinks.json no Android, apple-app-site-association no iOS. Ele compara o arquivo com o app: o pacote e a impressão digital do certificado no Android, o id do time e o bundle id no iOS. Se batem, os links para o domínio abrem o app; se não, abrem o navegador.",
        s1=["o app é instalado,", "e declara um domínio"],
        s2=["o sistema busca o", "arquivo do domínio"],
        s3=["ele compara o arquivo", "com o app"],
        ok=["bate: os links do", "domínio abrem o app"],
        bad=["não bate: os links", "abrem o navegador"],
        an="Android", io="iOS",
        a3=["pacote + impressão", "digital do certificado"], i3=["id do time +", "bundle id"],
        https="por https, sem redirecionar",
        cap1="A verificação acontece quando o app é instalado, não quando um link é tocado. O toque só segue o que foi decidido ali.",
        aria2="O que acontece quando um link é tocado, como um caminho de decisões. Primeiro: o link é https? Se não, usa um esquema próprio: se um app instalado reivindica o esquema, esse app abre, ou um diálogo se vários reivindicam; se nenhum, nada abre. Se o link é https: se um app instalado está verificado para o domínio, esse app abre na tela; se não, o navegador abre o endereço e o site responde.",
        tap="um link é tocado",
        q1=["é um endereço", "https?"],
        q2=["um app instalado", "reivindica o esquema?"],
        q3=["um app instalado está", "verificado no domínio?"],
        yes="sim", no="não",
        r1=["esse app abre, ou um", "diálogo se forem vários"],
        r2=["nada abre"],
        r3=["o app abre, na", "tela que o link nomeia"],
        r4=["o navegador abre a", "página, e o site responde"],
        cs="esquema próprio",
        cap2="O sistema segue este caminho antes de qualquer código do app rodar. Só um link https verificado tem resposta em todos os ramos.",
    ),
}


def verify(t):
    f = Fig("l11-verify", 720, 230, t["aria1"])
    f.box(10, 70, 150, 50, t["s1"], stroke="wire")
    f.box(190, 70, 150, 50, t["s2"], stroke="phosphor")
    f.box(370, 70, 150, 50, t["s3"], stroke="phosphor")
    f.box(556, 30, 154, 46, t["ok"], stroke="phosphor")
    f.box(556, 114, 154, 46, t["bad"], stroke="amber", fill="amber")
    f.arrow([(160, 95), (190, 95)])
    f.arrow([(340, 95), (370, 95)])
    f.arrow([(520, 88), (556, 56)], color="phosphor")
    f.arrow([(520, 102), (556, 134)], color="amber")
    f.text(265, 136, t["https"], size=8.5, fill="paper-dim", italic=True)
    f.text(265, 160, "assetlinks.json", mono=True, size=8.5, fill="paper-dim")
    f.text(265, 176, "apple-app-site-association", mono=True, size=8.5, fill="paper-dim")
    f.text(392, 138, t["an"], anchor="start", size=8.5, bold=True, fill="paper-dim")
    f.text(392, 151, t["a3"][0], anchor="start", size=8.5, fill="paper-dim")
    f.text(392, 163, t["a3"][1], anchor="start", size=8.5, fill="paper-dim")
    f.text(392, 182, t["io"], anchor="start", size=8.5, bold=True, fill="paper-dim")
    f.text(392, 195, t["i3"][0], anchor="start", size=8.5, fill="paper-dim")
    f.text(392, 207, t["i3"][1], anchor="start", size=8.5, fill="paper-dim")
    return f


def decide(t):
    f = Fig("l11-decide", 720, 300, t["aria2"])
    f.box(285, 12, 150, 32, [t["tap"]], stroke="paper", bold=True)
    f.box(285, 70, 150, 44, t["q1"], stroke="wire", dashed=True)
    f.arrow([(360, 44), (360, 70)])
    # left branch: custom scheme
    f.box(70, 150, 170, 44, t["q2"], stroke="wire", dashed=True)
    f.arrow([(285, 92), (155, 92), (155, 150)])
    f.text(220, 84, t["no"] + " · " + t["cs"], size=9, fill="paper-dim")
    f.box(10, 236, 150, 44, t["r1"], stroke="wire")
    f.box(180, 236, 110, 44, t["r2"], stroke="amber", fill="amber")
    f.arrow([(115, 194), (85, 236)])
    f.arrow([(195, 194), (235, 236)])
    f.text(84, 214, t["yes"], size=9, fill="paper-dim")
    f.text(232, 214, t["no"], size=9, fill="paper-dim")
    # right branch: https
    f.box(470, 150, 180, 44, t["q3"], stroke="wire", dashed=True)
    f.arrow([(435, 92), (560, 92), (560, 150)])
    f.text(498, 84, t["yes"], size=9, fill="paper-dim")
    f.box(400, 236, 150, 44, t["r3"], stroke="phosphor")
    f.box(560, 236, 156, 44, t["r4"], stroke="phosphor")
    f.arrow([(530, 194), (475, 236)], color="phosphor")
    f.arrow([(600, 194), (638, 236)], color="phosphor")
    f.text(486, 214, t["yes"], size=9, fill="paper-dim")
    f.text(636, 214, t["no"], size=9, fill="paper-dim")
    return f


def figures(lang):
    t = T[lang]
    s1 = None if lang == "en" else ["Android", "iOS", "bundle id"]
    return {
        "l11-verify": verify(t).json(t["cap1"], same=s1),
        "l11-decide": decide(t).json(t["cap2"]),
    }


EXAMPLES = {
    "the-parser": [
        {"language": "typescript", "file": "links.ts", "parts": [
            ('// links.ts: a link from outside the app, turned into a planner screen or refused\nimport { start, open, tap, type Nav } from "./backstack.ts";\n\nexport type Route = { screen: "courses" } | { screen: "course"; id: string } | { screen: "week" };\n\nconst HOST = "planner.example.com";\nconst ID = /^[a-z0-9-]{1,40}$/; // a course id as the planner writes them\n',
             "A `Route` is the whole list of places a link may lead, and there are three. Nothing in the type can say \"delete\" or \"send\", so no link can ask for either. `ID` is the shape of a course id: lower-case letters, digits and hyphens, never a title.",
             "Uma `Route` é a lista inteira de lugares aonde um link pode levar, e são três. Nada no tipo consegue dizer \"apagar\" ou \"enviar\", então nenhum link pode pedir isso. `ID` é o formato de um id de curso: letras minúsculas, dígitos e hífens, nunca um título."),
            ('// The parts of the path, the same for planner://course/sql and\n// https://planner.example.com/course/sql; anything else is refused.\nfunction parts(url: URL): string[] {\n  const path = url.pathname.split("/").filter((p) => p !== "");\n  if (url.protocol === "planner:") return [url.host, ...path];\n  if (url.protocol === "https:" && url.host === HOST) return path;\n  throw new Error(`not a planner link: ${url.protocol}//${url.host}`);\n}\n',
             "In `planner://course/sql` the URL parser reads `course` as the host, so it goes back at the front of the list. An `https` link counts only on the planner's own host, compared whole, port included. Every other scheme and host stops here.",
             "Em `planner://course/sql` o parser de URL lê `course` como o host, então ele volta para a frente da lista. Um link `https` só vale no host do próprio planner, comparado inteiro, porta incluída. Qualquer outro esquema ou host para aqui."),
            ('export function parse(link: string): Route {\n  if (!URL.canParse(link)) throw new Error("not a URL at all");\n  const p = parts(new URL(link));\n  if (p.length === 1 && p[0] === "courses") return { screen: "courses" };\n  if (p.length === 1 && p[0] === "week") return { screen: "week" };\n  if (p.length === 2 && p[0] === "course" && ID.test(p[1])) return { screen: "course", id: p[1] };\n  throw new Error(`no such screen: /${p.join("/")}`);\n}\n',
             "An allow-list, read top to bottom: three exact shapes are accepted and everything else falls through to the refusal. Checking the length first is what refuses a known screen with something extra on the end.",
             "Uma lista do que é permitido, lida de cima para baixo: três formatos exatos são aceitos e todo o resto cai na recusa. Conferir o tamanho primeiro é o que recusa uma tela conhecida com algo a mais no fim."),
            ('// The stacks a link opens: the screen it names, with the screens the app\n// would have shown before it put underneath, so that back and up still work.\nexport function toNav(route: Route): Nav {\n  if (route.screen === "course") return open(start(), `course:${route.id}`);\n  if (route.screen === "week") return tap(start(), "Week");\n  return start();\n}',
             "The route becomes lesson 10's `Nav`. A course opens with `courses` under it, the stack the student would have built by tapping, and the week is the Week tab at its root.",
             "A rota vira o `Nav` da aula 10. Um curso abre com `courses` embaixo, a pilha que a aluna teria montado tocando, e a semana é a aba Week na raiz."),
        ]},
    ],
}
