from fig import Canvas


def tracking(T):
    c = Canvas(720, 260, T(
        "Two ways to find what a statement depends on. Above, Svelte 4: the compiler reads the text of "
        "$: shown = describe(), finds one name, describe, which never changes, and concludes the statement never "
        "needs to re-run; the reads of label and week inside the function are invisible to it. Below, Svelte 5: "
        "$derived(describe()) runs, and while it runs the function reads label and week, so both signals record it "
        "as a reader.",
        "Dois jeitos de descobrir de que uma instrução depende. Em cima, o Svelte 4: o compilador lê o texto de "
        "$: shown = describe(), acha um nome, describe, que nunca muda, e conclui que a instrução nunca precisa rodar "
        "de novo; as leituras de label e week dentro da função ficam invisíveis para ele. Embaixo, o Svelte 5: "
        "$derived(describe()) roda, e enquanto roda a função lê label e week, então os dois signals o registram como "
        "leitor."))
    c.text(20, 22, T("Svelte 4: decided once, at build time, from the text", "Svelte 4: decidido uma vez, no build, a partir do texto"),
           size=11, weight="600", anchor="start", fill="var(--amber)")
    c.rect(20, 36, 230, 40, fill="var(--ink)", stroke="var(--wire)")
    c.text(135, 56, "$: shown = describe();", mono=True, size=10.5)
    c.line(250, 56, 318, 56, stroke="var(--paper-dim)", arrow=True)
    c.rect(320, 36, 170, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(405, 50, T("names it contains:", "nomes que contém:"), size=9.5, fill="var(--paper-dim)")
    c.text(405, 66, "describe", mono=True, size=10.5)
    c.line(490, 56, 538, 56, stroke="var(--paper-dim)", arrow=True)
    c.rect(540, 36, 160, 40, fill="var(--ink)", stroke="var(--amber)")
    c.text(620, 56, T("never re-runs", "nunca roda de novo"), size=10.5, fill="var(--amber)")
    c.rect(320, 88, 170, 30, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(405, 103, T("label, week: not seen", "label, week: não vistos"), size=9.5, fill="var(--paper-dim)")
    c.text(20, 150, T("Svelte 5: recorded while it runs", "Svelte 5: registrado enquanto roda"),
           size=11, weight="600", anchor="start", fill="var(--phosphor)")
    c.rect(20, 164, 230, 40, fill="var(--ink)", stroke="var(--wire)")
    c.text(135, 184, "$derived(describe())", mono=True, size=10.5)
    c.line(250, 184, 318, 184, stroke="var(--paper-dim)", arrow=True)
    c.rect(320, 164, 170, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(405, 178, T("reads while running:", "leituras ao rodar:"), size=9.5, fill="var(--paper-dim)")
    c.text(405, 194, "label, week", mono=True, size=10.5)
    c.line(490, 184, 538, 184, stroke="var(--paper-dim)", arrow=True)
    c.rect(540, 164, 160, 40, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(620, 184, T("re-runs when either changes", "roda de novo se um mudar"), size=10, fill="var(--phosphor)")
    c.text(360, 240, T("same function, same text: only the second sees inside it",
                       "mesma função, mesmo texto: só o segundo enxerga dentro dela"), size=10, fill="var(--paper-dim)")
    c.caption = T("$: knew what a line looked like; a rune knows what it did.",
                  "O $: sabia como a linha parecia; uma rune sabe o que ela fez.")
    return c


FIGURES = [("reactive-statements", tracking)]
