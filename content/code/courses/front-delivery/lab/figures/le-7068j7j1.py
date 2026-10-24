from fig import Canvas


def pipeline(T):
    c = Canvas(720, 220, T(
        "A branch is pushed and a pull request opened. CI runs four steps on a clean machine: npm ci, tsc, the "
        "tests and the build. Red stops the merge; green lets it through to main, and the host then builds main "
        "and publishes it at the real address.",
        "Um branch é enviado e um pull request aberto. O CI roda quatro passos numa máquina limpa: npm ci, tsc, os "
        "testes e o build. Vermelho impede o merge; verde deixa passar para o main, e o host então constrói o main "
        "e o publica no endereço de verdade."))
    c.rect(20, 70, 120, 60, fill="var(--panel)")
    c.text(80, 92, T("pull request", "pull request"), size=10.5, weight="600")
    c.text(80, 112, T("from a branch", "de um branch"), size=9.5, fill="var(--paper-dim)")
    c.line(140, 100, 168, 100, stroke="var(--paper-dim)", arrow=True)
    c.rect(170, 30, 250, 140, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(295, 48, T("CI, on a clean machine", "CI, numa máquina limpa"), size=10.5, weight="600")
    for i, s in enumerate(["npm ci", "npx tsc", "npm test", "npx vite build"]):
        y = 74 + i * 24
        c.rect(190, y - 9, 18, 18, fill="none", stroke="var(--phosphor)", rx=3)
        c.text(199, y, str(i + 1), mono=True, size=9.5, fill="var(--phosphor)")
        c.text(220, y, s, mono=True, size=10, anchor="start")
    c.line(420, 70, 470, 50, stroke="var(--amber)", arrow=True)
    c.text(478, 46, T("red: no merge", "vermelho: sem merge"), anchor="start", size=10, fill="var(--amber)")
    c.line(420, 130, 470, 150, stroke="var(--phosphor)", arrow=True)
    c.rect(472, 130, 90, 40, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(517, 150, "main", mono=True, size=10.5)
    c.line(562, 150, 590, 150, stroke="var(--paper-dim)", arrow=True)
    c.rect(592, 125, 110, 50, fill="var(--panel)")
    c.text(647, 143, T("host builds", "o host constrói"), size=10)
    c.text(647, 160, T("and publishes", "e publica"), size=10)
    c.text(470, 196, T("green: merge allowed", "verde: merge liberado"), anchor="start", size=10, fill="var(--phosphor)")
    c.caption = T("The checks run before the merge, on every pull request, so a failure is a comment on a branch rather than a broken main.",
                  "As conferências rodam antes do merge, em todo pull request, então uma falha é um comentário num branch, e não um main quebrado.")
    return c


def previews(T):
    c = Canvas(720, 210, T(
        "The main branch builds to the production address. Three open pull requests each build to an address of "
        "their own, side by side, none of them touching production or each other. When a pull request closes, its "
        "preview goes.",
        "O branch main é construído para o endereço de produção. Três pull requests abertos são construídos cada um "
        "num endereço próprio, lado a lado, sem tocar a produção nem uns aos outros. Quando um pull request fecha, o "
        "preview dele vai embora."))
    c.rect(20, 30, 150, 44, fill="var(--panel)")
    c.text(95, 52, "main", mono=True, size=11)
    c.line(170, 52, 300, 52, stroke="var(--paper-dim)", arrow=True)
    c.rect(302, 30, 398, 44, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(320, 52, "planner.pages.dev", mono=True, size=10.5, anchor="start", fill="var(--phosphor)")
    c.text(690, 52, T("production", "produção"), anchor="end", size=10, fill="var(--paper-dim)")
    rows = [("PR #12", "fix-week", "a1b2c3d4"), ("PR #13", "green-heading", "e5f6a7b8"), ("PR #14", "durations", "c9d0e1f2")]
    for i, (pr, br, h) in enumerate(rows):
        y = 100 + i * 36
        c.rect(20, y - 14, 150, 28, fill="var(--panel)")
        c.text(30, y, pr, mono=True, size=10, anchor="start")
        c.text(160, y, br, mono=True, size=9.5, anchor="end", fill="var(--paper-dim)")
        c.line(170, y, 300, y, stroke="var(--paper-dim)", dash="4 3", arrow=True)
        c.rect(302, y - 14, 398, 28, fill="var(--panel)", stroke="var(--wire)")
        c.text(320, y, f"{h}.planner.pages.dev", mono=True, size=10, anchor="start")
        c.text(690, y, T("preview", "preview"), anchor="end", size=10, fill="var(--paper-dim)")
    c.caption = T("One preview per pull request, each at its own address; production moves only when main does.",
                  "Um preview por pull request, cada um no próprio endereço; a produção só muda quando o main muda.")
    return c


FIGURES = [("what-ci-is-for", pipeline), ("what-a-preview-is", previews)]
