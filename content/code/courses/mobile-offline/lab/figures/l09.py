"""Lesson 9: the retry loop, as an annotated example."""

EXAMPLES = {
    "what-to-retry": [{
        "language": "typescript", "file": "retry.ts",
        "parts": [
            ("// retry.ts: send one new session to the server, retrying what is worth retrying.\nimport { seeded, fullJitter } from \"./backoff.ts\";\n\nconst SERVER = \"http://127.0.0.1:8009/sessions\";\nconst BASE = 200, CAP = 5000, TRIES = 5, TIMEOUT = 2000; // milliseconds, and attempts in all\nconst random = seeded(7);\nconst body = JSON.stringify({ course: \"guitar\", date: \"2026-10-23\", minutes: 25 });\n",
             "Four numbers decide the policy: the first wait's ceiling, the longest wait, how many tries in all, and how long one try may take. The seed makes the waits repeat.",
             "Quatro números decidem a política: o teto da primeira espera, a espera mais longa, quantas tentativas ao todo e quanto uma tentativa pode durar. A semente faz as esperas se repetirem."),
            ("function worthRetrying(status: number): boolean {\n  return status >= 500 || status === 429 || status === 408;\n}\n",
             "The classification. A 5xx is the server's trouble, 429 asks the client to slow down and 408 says the request took too long; every other status is an answer to keep.",
             "A classificação. Um 5xx é problema do servidor, 429 pede ao cliente que vá mais devagar e 408 diz que a requisição demorou demais; todo outro status é uma resposta a guardar."),
            ("for (let attempt = 1; attempt <= TRIES; attempt++) {\n  let wait = fullJitter(attempt, BASE, CAP, random);\n  try {\n    const res = await fetch(SERVER, {\n      method: \"POST\", body, headers: { \"content-type\": \"application/json\" }, signal: AbortSignal.timeout(TIMEOUT),\n    });",
             "Each attempt has its own deadline. Without `AbortSignal.timeout`, a request to a server that accepted the connection and never answers would wait for ever.",
             "Cada tentativa tem o próprio prazo. Sem o `AbortSignal.timeout`, uma requisição a um servidor que aceitou a conexão e nunca responde esperaria para sempre."),
            ("    if (res.ok) {\n      console.log(`attempt ${attempt}: ${res.status}, saved as ${(await res.json()).id}`);\n      break;\n    }\n    if (!worthRetrying(res.status)) {\n      console.log(`attempt ${attempt}: ${res.status}, not retrying: ${(await res.json()).error}`);\n      break;\n    }",
             "A success ends the loop, and so does a status not worth retrying: the server's reason is printed and the operation is left for the person, as lesson 8's dead table does.",
             "Um sucesso encerra o laço, e um status que não vale repetir também: o motivo do servidor é impresso e a operação fica para a pessoa, como faz a tabela dead da aula 8."),
            ("    const after = Number(res.headers.get(\"retry-after\"));\n    if (after > 0) wait = Math.min(after * 1000, CAP);\n    console.log(`attempt ${attempt}: ${res.status}` + (attempt < TRIES ? `, waiting ${wait} ms${after > 0 ? \" as Retry-After asks\" : \"\"}` : \"\"));",
             "If the server named a wait in `Retry-After`, that replaces the computed one, still held under the cap.",
             "Se o servidor indicou uma espera em `Retry-After`, ela substitui a calculada, ainda limitada pelo teto."),
            ("  } catch (e) {\n    const why = (e as Error).name === \"TimeoutError\" ? \"timed out\" : \"no answer\";\n    console.log(`attempt ${attempt}: ${why}` + (attempt < TRIES ? `, waiting ${wait} ms` : \"\"));\n  }",
             "No answer at all, or no answer in time. Both are worth retrying, and both leave the client not knowing whether the server did the work.",
             "Nenhuma resposta, ou nenhuma resposta a tempo. As duas valem uma nova tentativa, e as duas deixam o cliente sem saber se o servidor fez o trabalho."),
            ("  if (attempt === TRIES) console.log(\"giving up for now; the operation stays in the outbox\");\n  else await new Promise((resolve) => setTimeout(resolve, wait));\n}",
             "After the last try the loop stops rather than waiting. The operation is still in the outbox, and the next drain starts again from attempt 1.",
             "Depois da última tentativa o laço para em vez de esperar. A operação continua na caixa de saída, e a próxima drenagem recomeça da tentativa 1."),
        ],
    }],
}

from fig import Fig

T = {
    "en": dict(
        aria="A time line from 0 to 16 seconds after an outage. With no jitter, every phone tries again at 1, 3, 7 and 15 seconds, all together. With full jitter, phone 1 tries at 0.6, 0.6, 2.7 and 10.6 seconds, phone 2 at 0.7, 1.4, 2.5 and 6.8, and phone 3 at 0.7, 0.8, 2.6 and 3.2: the same phones, spread out.",
        nj="no jitter: every phone", p="phone", sec="seconds after the outage",
        cap="The same four retries, from the waits schedule.ts printed. Without jitter every phone arrives at the same instants; with it, the arrivals spread across the window.",
    ),
    "pt": dict(
        aria="Uma linha do tempo de 0 a 16 segundos depois de uma queda. Sem jitter, todo celular tenta de novo aos 1, 3, 7 e 15 segundos, todos juntos. Com jitter total, o celular 1 tenta aos 0,6, 0,6, 2,7 e 10,6 segundos, o celular 2 aos 0,7, 1,4, 2,5 e 6,8, e o celular 3 aos 0,7, 0,8, 2,6 e 3,2: os mesmos celulares, espalhados.",
        nj="sem jitter: todo celular", p="celular", sec="segundos depois da queda",
        cap="As mesmas quatro novas tentativas, a partir das esperas que o schedule.ts imprimiu. Sem jitter todo celular chega nos mesmos instantes; com ele, as chegadas se espalham pela janela.",
    ),
}

ROWS = [[1000, 3000, 7000, 15000], [627, 632, 2741, 10589], [734, 1383, 2524, 6827], [720, 797, 2621, 3220]]


def figures(lang):
    t = T[lang]
    f = Fig("l09-herd", 720, 230, t["aria"])
    x = lambda ms: round(170 + ms * 0.033, 1)
    for s in range(0, 17, 2):
        f.arrow([(x(s * 1000), 30), (x(s * 1000), 186)], head=False, color="scan", width=0.8)
        f.text(x(s * 1000), 198, str(s), size=9, fill="paper-dim", mono=True)
    f.text(x(8000), 216, t["sec"], size=9.5, fill="paper-dim", italic=True)
    for n, row in enumerate(ROWS):
        y = 46 + n * 40
        label = t["nj"] if n == 0 else f"{t['p']} {n}"
        f.text(160, y, label, anchor="end", size=10, fill="amber" if n == 0 else "phosphor")
        for ms in row:
            f.rect(x(ms) - 4, y - 8, 8, 16, stroke="amber" if n == 0 else "phosphor",
                   fill="amber" if n == 0 else "phosphor", rx=2)
    return {"l09-herd": f.json(t["cap"])}
