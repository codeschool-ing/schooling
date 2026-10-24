"""Lesson 5: the annotated server/api.mjs, and the figures."""
from fig import Fig

API = [
    ('// server/api.mjs\nimport http from "node:http";\nimport { randomBytes, scryptSync, timingSafeEqual } from "node:crypto";\nimport { readFileSync } from "node:fs";\n\nconst data = JSON.parse(readFileSync(new URL("../public/courses.json", import.meta.url), "utf8"));\n',
     "The planner's own data, read once when the server starts. Everything this server knows lives in memory, so stopping it forgets every change, as reloading the page did in lesson 1.",
     'Os próprios dados do planner, lidos uma vez quando o servidor sobe. Tudo o que este servidor sabe vive na memória, então pará-lo esquece toda mudança, como recarregar a página fazia na aula 1.'),
    ('const salt = randomBytes(16);\nconst users = new Map([["ana", scryptSync("correct horse battery staple", salt, 32)]]);\nconst plans = new Map([["ana", structuredClone(data)]]);\nconst logins = new Map();\n',
     "One account, `ana`, whose password is stored as a scrypt hash and never as itself. `plans` keeps her sessions apart from anybody else's, and `logins` maps each sign-in to whoever made it.",
     'Uma conta, `ana`, cuja senha é guardada como um hash scrypt e nunca como ela mesma. O `plans` mantém as sessões dela separadas das de qualquer outra pessoa, e o `logins` liga cada login a quem o fez.'),
    ('function passwordIsRight(name, password) {\n  const given = scryptSync(String(password), salt, 32);\n  const stored = users.get(name);\n  return stored !== undefined && timingSafeEqual(stored, given);\n}\n',
     'A password is right if its hash matches. The hash is computed even for a name that does not exist, so a wrong name and a wrong password take the same time, and `timingSafeEqual` compares in a time that does not depend on how many bytes agree.',
     'Uma senha está certa se o hash dela confere. O hash é calculado até para um nome que não existe, então um nome errado e uma senha errada levam o mesmo tempo, e o `timingSafeEqual` compara num tempo que não depende de quantos bytes coincidem.'),
    ('function cookie(req, name) {\n  for (const part of (req.headers.cookie ?? "").split(";")) {\n    const [key, value] = part.trim().split("=");\n    if (key === name) return value;\n  }\n  return undefined;\n}\n',
     'Reads one cookie out of the `Cookie` header the browser sends, which holds every cookie for this site as `name=value` pairs separated by semicolons.',
     'Lê um cookie do cabeçalho `Cookie` que o navegador manda, que traz todos os cookies deste site como pares `nome=valor` separados por ponto e vírgula.'),
    ('async function readJson(req) {\n  let text = "";\n  for await (const chunk of req) text += chunk;\n  try {\n    return JSON.parse(text);\n  } catch {\n    return {};\n  }\n}\n\nfunction send(res, status, body, headers = {}) {\n  res.writeHead(status, { "content-type": "application/json", ...headers });\n  res.end(JSON.stringify(body) + "\\n");\n}\n',
     'Two small helpers: read a JSON body, treating anything unreadable as empty, and send a JSON answer with a status and any extra headers.',
     'Dois ajudantes pequenos: ler um corpo JSON, tratando o que não dá para ler como vazio, e mandar uma resposta JSON com um status e os cabeçalhos extras.'),
    ('export function createApi() {\n  return http.createServer(async (req, res) => {\n    const path = new URL(req.url, "http://localhost").pathname;\n    const user = logins.get(cookie(req, "sid"));\n',
     'Every request starts the same way: find out who is asking, from the `sid` cookie, if it names a login the server remembers.',
     'Toda requisição começa igual: descobrir quem está pedindo, pelo cookie `sid`, se ele aponta para um login de que o servidor se lembra.'),
    ('    if (req.method === "POST" && path === "/api/login") {\n      const { name, password } = await readJson(req);\n      if (!passwordIsRight(name, password)) return send(res, 401, { error: "wrong name or password" });\n      const sid = randomBytes(32).toString("base64url");\n      logins.set(sid, name);\n      return send(res, 200, { name }, { "set-cookie": `sid=${sid}; HttpOnly; SameSite=Lax; Path=/` });\n    }',
     "Signing in. A right password gets a new session id, 32 random bytes, remembered on the server and sent to the browser in a cookie the page's scripts cannot read.",
     'O login. Uma senha certa ganha um id de sessão novo, 32 bytes aleatórios, guardado no servidor e mandado ao navegador num cookie que os scripts da página não conseguem ler.'),
    ('    if (req.method === "POST" && path === "/api/logout") {\n      return send(res, 200, {}, { "set-cookie": "sid=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0" });\n    }',
     'Signing out tells the browser to drop the cookie. Read what it does not do; lesson 6 does.',
     'O logout manda o navegador descartar o cookie. Repare no que ele não faz; a aula 6 faz.'),
    ('    if (req.method === "GET" && path === "/api/plan") {\n      if (!user) return send(res, 401, { error: "sign in first" });\n      return send(res, 200, plans.get(user));\n    }\n    send(res, 404, { error: "no such address" });\n  });\n}\n',
     'The plan, for whoever the cookie says is asking, and a 401 for nobody. Everything else is a 404.',
     'O plano, para quem o cookie diz que está pedindo, e um 401 para ninguém. Todo o resto é 404.'),
    ('if (import.meta.url === `file://${process.argv[1]}`) {\n  createApi().listen(3000, "127.0.0.1", () => console.log("api listening on http://127.0.0.1:3000"));\n}',
     'Listen on port 3000 when the file is run with `node`, and not when a test imports it, which lesson 6 does.',
     'Escutar na porta 3000 quando o arquivo é rodado com `node`, e não quando um teste o importa, o que a aula 6 faz.'),
]

EXAMPLES = {"the-server": [{"language": "javascript", "file": "server/api.mjs", "parts": API}]}

T = {
    "en": dict(
        aria="A sequence diagram with three lifelines: the planner in the browser, the identity provider, and the planner's API. 1: the planner makes a random code verifier and sends the browser to the provider's authorize address with its client id, its redirect address, a random state and the SHA-256 of the verifier, the code challenge. 2: the person signs in at the provider and agrees. 3: the provider sends the browser back to the redirect address with a one-time code and the same state. 4: the planner checks the state is the one it sent, and posts the code and the verifier to the provider's token address. 5: the provider checks that the SHA-256 of the verifier is the challenge it was given, and answers with an access token and, with OpenID Connect, an ID token. 6: the planner calls its API with the access token in the Authorization header.",
        who=["the planner, in the browser", "the identity provider", "the planner's API"],
        steps=[
            (0, 1, "1  /authorize?…&state&code_challenge"),
            (1, 1, "2  the person signs in, and agrees"),
            (1, 0, "3  back to redirect_uri?code=…&state=…"),
            (0, 1, "4  POST /token: code + code_verifier"),
            (1, 0, "5  access token (and an ID token)"),
            (0, 2, "6  Authorization: Bearer <access token>"),
        ],
        note="the verifier never travelled until step 4",
        cap="The authorization code flow with PKCE. A code stolen at step 3 is worthless without the verifier, which stayed in the planner until the code was exchanged.",
    ),
    "pt": dict(
        aria="Um diagrama de sequência com três linhas de vida: o planner no navegador, o provedor de identidade e a API do planner. 1: o planner gera um code verifier aleatório e manda o navegador para o endereço authorize do provedor com o seu client id, o seu endereço de retorno, um state aleatório e o SHA-256 do verifier, o code challenge. 2: a pessoa faz login no provedor e autoriza. 3: o provedor manda o navegador de volta para o endereço de retorno com um código de uso único e o mesmo state. 4: o planner confere que o state é o que ele mandou, e envia o código e o verifier para o endereço token do provedor. 5: o provedor confere que o SHA-256 do verifier é o challenge que recebeu, e responde com um access token e, com o OpenID Connect, um ID token. 6: o planner chama a sua API com o access token no cabeçalho Authorization.",
        who=["o planner, no navegador", "o provedor de identidade", "a API do planner"],
        steps=[
            (0, 1, "1  /authorize?…&state&code_challenge"),
            (1, 1, "2  a pessoa faz login, e autoriza"),
            (1, 0, "3  volta a redirect_uri?code=…&state=…"),
            (0, 1, "4  POST /token: code + code_verifier"),
            (1, 0, "5  access token (e um ID token)"),
            (0, 2, "6  Authorization: Bearer <access token>"),
        ],
        note="o verifier só viajou no passo 4",
        cap="O fluxo authorization code com PKCE. Um código roubado no passo 3 não serve sem o verifier, que ficou no planner até o código ser trocado.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l05-oauth", 720, 330, t["aria"])
    xs = [110, 370, 610]
    for x, name in zip(xs, t["who"]):
        f.box(x - 90, 12, 180, 30, [name], stroke="phosphor", size=9.5, bold=True)
        f.arrow([(x, 42), (x, 315)], head=False, color="wire", dashed=True)
    for i, (a, b, label) in enumerate(t["steps"]):
        y = 70 + i * 40
        if a == b:
            f.text(xs[a] + 10, y + 4, label, anchor="start", size=9, fill="amber")
            continue
        f.arrow([(xs[a], y), (xs[b], y)], color="amber" if b == 2 else "paper-dim")
        mid = (xs[a] + xs[b]) / 2
        f.text(mid, y - 9, label, mono=i in (0, 3, 5), size=8.5)
    f.text(xs[0] + 8, 302, t["note"], anchor="start", size=9, italic=True, fill="paper-dim")
    return {"l05-oauth": f.json(t["cap"])}
