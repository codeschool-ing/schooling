"""Lesson 14: the stages of a request and its three limits, the lost answer, the four states of a screen."""
from fig import Fig

T = {
    "en": dict(
        tl_aria="A request drawn as five stages along a time line: find the server's address, open the connection, send the request, wait for the first byte, read the body. Above the first two, the connect timeout. Above the last two, the read timeout, the longest silence between two pieces of data, which restarts whenever data arrives. Below all five, the whole-request deadline, which AbortSignal.timeout sets. A marker at the wait for the first byte says that /hang stops there: connected, request sent, and no byte ever comes.",
        st=[["find the", "address"], ["open the", "connection"], ["send the", "request"], ["wait for the", "first byte"], ["read the", "body"]],
        connect="connect timeout", read="read timeout: the longest silence, restarted by every byte",
        whole="the whole-request deadline", hang="/hang stops here: no byte ever comes", time="time",
        tl_cap="Three limits on one request. Only the deadline at the bottom covers every stage, which is why it is the one a screen needs.",
        la_aria="A sequence between the phone and the server. The phone sends: add a 30-minute session. The server adds it and answers, but the answer is lost on the way back. The phone's deadline passes, it knows only that no answer came, and it sends the same request again. The server adds a second session. The week now says 210 minutes planned instead of 180.",
        phone="the phone", server="the server",
        m1="add a 30-minute session", s1="adds it: 180 → 210", m2="the answer is lost on the way",
        t1=["deadline passes:", "no answer came"], m3="add a 30-minute session, again", s2=["adds another:", "210 → 240"],
        la_cap="A timeout tells the phone that no answer arrived, not that nothing happened. A request that changes something can be done twice.",
        sa_aria="The four states of a screen that loads from the network. Loading leads to fresh when the server answers. When it does not, the screen looks for a saved copy: with one, it shows the stale state, the saved data and its age; without one, it shows the error state, what went wrong and a Try again button. Try again, from stale or from error, goes back to loading.",
        loading=["loading", "asking, with a deadline"], fresh=["fresh", "the week, as sent"],
        q=["a saved", "copy?"], stale=["stale", "the saved week, and its age"], error=["error", "what went wrong, and Try again"],
        ok="answered", fail="failed or timed out", yes="yes", no="no", again="Try again",
        sa_cap="Four states, and each says something different. Stale with its age, and an error with a way out, are the two most apps forget.",
    ),
    "pt": dict(
        tl_aria="Uma requisição desenhada como cinco etapas ao longo do tempo: achar o endereço do servidor, abrir a conexão, enviar a requisição, esperar o primeiro byte, ler o corpo. Acima das duas primeiras, o timeout de conexão. Acima das duas últimas, o timeout de leitura, o maior silêncio entre dois pedaços de dados, que recomeça sempre que chegam dados. Abaixo das cinco, o prazo da requisição inteira, que o AbortSignal.timeout define. Uma marca na espera do primeiro byte diz que o /hang para ali: conectado, requisição enviada, e nenhum byte chega.",
        st=[["achar o", "endereço"], ["abrir a", "conexão"], ["enviar a", "requisição"], ["esperar o", "primeiro byte"], ["ler o", "corpo"]],
        connect="timeout de conexão", read="timeout de leitura: o maior silêncio, zerado a cada byte",
        whole="o prazo da requisição inteira", hang="o /hang para aqui: nenhum byte chega", time="tempo",
        tl_cap="Três limites numa requisição. Só o prazo de baixo cobre todas as etapas, e é por isso que é dele que uma tela precisa.",
        la_aria="Uma sequência entre o celular e o servidor. O celular envia: adicionar uma sessão de 30 minutos. O servidor adiciona e responde, mas a resposta se perde na volta. O prazo do celular passa, ele só sabe que nenhuma resposta chegou, e envia a mesma requisição de novo. O servidor adiciona uma segunda sessão. A semana agora diz 210 minutos planejados em vez de 180.",
        phone="o celular", server="o servidor",
        m1="adicionar sessão de 30 minutos", s1="adiciona: 180 → 210", m2="a resposta se perde no caminho",
        t1=["o prazo passa:", "não veio resposta"], m3="adicionar sessão de 30 minutos, de novo", s2=["adiciona outra:", "210 → 240"],
        la_cap="Um timeout diz ao celular que nenhuma resposta chegou, não que nada aconteceu. Uma requisição que muda alguma coisa pode ser feita duas vezes.",
        sa_aria="Os quatro estados de uma tela que carrega pela rede. Carregando leva a atual quando o servidor responde. Quando não responde, a tela procura uma cópia salva: com ela, mostra o estado desatualizado, os dados salvos e a idade deles; sem ela, mostra o estado de erro, o que deu errado e um botão Tentar de novo. Tentar de novo, a partir de desatualizado ou de erro, volta a carregando.",
        loading=["carregando", "pedindo, com um prazo"], fresh=["atual", "a semana, como veio"],
        q=["há cópia", "salva?"], stale=["desatualizada", "a semana salva, e a idade"], error=["erro", "o que deu errado, e Tentar de novo"],
        ok="respondeu", fail="falhou ou estourou o prazo", yes="sim", no="não", again="Tentar de novo",
        sa_cap="Quatro estados, e cada um diz uma coisa diferente. Desatualizada com a idade, e um erro com saída, são os dois que a maioria dos apps esquece.",
    ),
}


def timeline(t):
    f = Fig("l14-timeline", 720, 230, t["tl_aria"])
    xs = [20, 160, 300, 440, 580]
    for i, (x, lines) in enumerate(zip(xs, t["st"])):
        f.box(x, 92, 120, 44, lines, stroke="amber" if i == 3 else "wire")
    for x in xs[:-1]:
        f.arrow([(x + 120, 114), (x + 140, 114)])
    # connect timeout over stages 1-2
    f.arrow([(20, 66), (280, 66)], color="phosphor", both=True)
    f.text(150, 54, t["connect"], fill="phosphor")
    # read timeout over stages 4-5
    f.arrow([(440, 66), (700, 66)], color="phosphor", both=True)
    f.text(570, 30, t["read"], fill="phosphor", size=9.5)
    # the whole deadline under everything
    f.arrow([(20, 162), (700, 162)], color="amber", both=True)
    f.text(360, 176, t["whole"], fill="amber", bold=True)
    f.text(500, 206, t["hang"], fill="paper-dim", italic=True)
    f.arrow([(500, 196), (500, 138)], dashed=True)
    f.text(690, 222, t["time"] + " →", anchor="end", fill="paper-dim", size=9)
    return f


def lost(t):
    f = Fig("l14-lost-answer", 720, 300, t["la_aria"])
    f.box(40, 14, 150, 30, [t["phone"]], stroke="phosphor", bold=True)
    f.box(530, 14, 150, 30, [t["server"]], stroke="amber", bold=True)
    f.arrow([(115, 44), (115, 290)], head=False, dashed=True, color="wire")
    f.arrow([(605, 44), (605, 290)], head=False, dashed=True, color="wire")
    f.arrow([(115, 70), (605, 90)], color="phosphor")
    f.text(360, 66, t["m1"])
    f.box(612, 98, 100, 30, [t["s1"]], size=9, stroke="amber")
    f.arrow([(605, 136), (380, 150)], dashed=True, color="paper-dim", head=False)
    f.text(372, 150, "✕", fill="amber", size=14)
    f.text(470, 160, t["m2"], fill="paper-dim", italic=True, size=9.5)
    f.box(8, 168, 100, 36, t["t1"], size=9, stroke="phosphor")
    f.arrow([(115, 214), (605, 234)], color="phosphor")
    f.text(360, 210, t["m3"])
    f.box(612, 240, 100, 36, t["s2"], size=9, stroke="amber", fill="amber")
    return f


def states(t):
    f = Fig("l14-states", 720, 260, t["sa_aria"])
    f.box(20, 100, 150, 50, t["loading"], stroke="wire")
    f.box(270, 20, 170, 50, t["fresh"], stroke="phosphor")
    f.box(290, 170, 130, 50, t["q"], stroke="wire", dashed=True)
    f.box(520, 110, 190, 50, t["stale"], stroke="amber")
    f.box(520, 190, 190, 50, t["error"], stroke="amber", size=9.5)
    f.arrow([(170, 112), (270, 52)], color="phosphor")
    f.text(200, 70, t["ok"], fill="phosphor", size=9.5)
    f.arrow([(170, 138), (290, 192)], color="amber")
    f.text(200, 188, t["fail"], fill="amber", size=9.5, anchor="start")
    f.arrow([(420, 186), (520, 140)])
    f.text(466, 150, t["yes"], size=9.5)
    f.arrow([(420, 206), (520, 214)])
    f.text(470, 222, t["no"], size=9.5)
    f.arrow([(615, 110), (615, 90), (95, 90), (95, 100)], dashed=True)
    f.text(560, 82, t["again"], fill="paper-dim", italic=True, size=9.5)
    f.arrow([(710, 215), (714, 215), (714, 250), (12, 250), (12, 125), (20, 125)], dashed=True)
    return f


def figures(lang):
    t = T[lang]
    return {
        "l14-timeline": timeline(t).json(t["tl_cap"]),
        "l14-lost-answer": lost(t).json(t["la_cap"]),
        "l14-states": states(t).json(t["sa_cap"]),
    }


EXAMPLES = {
    "timeouts": [
        {"language": "typescript", "file": "fetchweek.ts", "parts": [
            ('// fetchweek.ts: ask for the week with a deadline, a way to cancel, and a bounded retry\nimport { parseArgs } from "node:util";\n\nexport type Options = {\n  timeoutMs?: number; // the whole request: connecting, waiting, reading the body\n  signal?: AbortSignal; // aborted by the screen that asked, when it goes away\n  retries?: number; // extra attempts after the first, for a 5xx answer only\n  backoffMs?: number; // the first wait between attempts; each one after doubles\n};\n',
             "The four things a caller can decide. Every one is optional, so `fetchWeek(url)` on its own is a plain request with no limit at all, which is the case this section starts from.",
             "As quatro coisas que quem chama pode decidir. Todas são opcionais, então `fetchWeek(url)` sozinho é uma requisição simples sem limite nenhum, que é o caso por onde esta etapa começa."),
            ('export async function fetchWeek(url: string, o: Options = {}) {\n  let wait = o.backoffMs ?? 500;\n  for (let attempt = 1; ; attempt++) {\n    const stops: AbortSignal[] = [];\n    if (o.signal) stops.push(o.signal);\n    if (o.timeoutMs) stops.push(AbortSignal.timeout(o.timeoutMs));\n    const res = await fetch(url, { signal: AbortSignal.any(stops) });\n',
             "Each attempt gets a fresh deadline, made by `AbortSignal.timeout`. `AbortSignal.any` joins it to the screen's signal, so the request stops at whichever comes first: the deadline or the screen going away.",
             "Cada tentativa ganha um prazo novo, criado por `AbortSignal.timeout`. `AbortSignal.any` o junta ao sinal da tela, então a requisição para no que vier primeiro: o prazo ou a tela indo embora."),
            ('    if (res.ok) return res.json();\n    if (res.status < 500 || attempt > (o.retries ?? 0)) {\n      throw new Error(`HTTP ${res.status} after ${attempt} attempt(s)`);\n    }\n    console.log(`attempt ${attempt}: HTTP ${res.status}, waiting ${wait} ms`);\n    await new Promise((r) => setTimeout(r, wait));\n    wait *= 2;\n  }\n}\n',
             "Only a status of 500 or more is tried again, and only as many times as `retries` allows; anything else is thrown at once. The wait doubles after every failure. The next section runs this part.",
             "Só um status 500 ou maior é tentado de novo, e só quantas vezes `retries` permitir; o resto é lançado na hora. A espera dobra a cada falha. A próxima etapa roda esta parte."),
            ('// Run as `node fetchweek.ts PATH [--timeout MS] [--leave MS] [--retries N]`.\nif (process.argv[1]?.endsWith("fetchweek.ts")) {\n  const { values, positionals } = parseArgs({\n    allowPositionals: true,\n    options: { timeout: { type: "string" }, leave: { type: "string" }, retries: { type: "string" } },\n  });\n  const url = new URL(positionals[0] ?? "/week", "http://127.0.0.1:8014").href;\n  const screen = new AbortController();\n  if (values.leave) setTimeout(() => screen.abort(), Number(values.leave)).unref();\n',
             "This part runs only when the file is the one `node` was given, so `screen.ts` can import `fetchWeek` without starting it. `screen` stands for the screen that asked; `--leave` aborts it after that many milliseconds.",
             "Esta parte só roda quando o arquivo é o que o `node` recebeu, então o `screen.ts` pode importar `fetchWeek` sem disparar isto. `screen` representa a tela que pediu; `--leave` a aborta depois de tantos milissegundos."),
            ('  console.log(`asking ${url}`);\n  const start = performance.now();\n  try {\n    console.log(await fetchWeek(url, {\n      timeoutMs: values.timeout ? Number(values.timeout) : undefined,\n      signal: screen.signal,\n      retries: Number(values.retries ?? 0),\n    }));\n  } catch (e: any) {\n    console.log(`${e.name}: ${e.message}${e.cause?.code ? ` (${e.cause.code})` : ""}`);\n  }\n  console.log(`after ${((performance.now() - start) / 1000).toFixed(1)} s`);\n}',
             "Whatever happens is printed with its name, which is how the transcripts below tell a timeout from a cancellation, and with how long it took, to a tenth of a second.",
             "O que acontecer é impresso com o nome, que é como as transcrições abaixo distinguem um timeout de um cancelamento, e com quanto tempo levou, em décimos de segundo."),
        ]},
    ],
}
