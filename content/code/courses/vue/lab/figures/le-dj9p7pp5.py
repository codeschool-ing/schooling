from fig import Canvas


def wiring(T):
    c = Canvas(720, 220, T(
        "One form field and the three ids that join its parts. The label's for attribute names the input's id, "
        "v-2, so the label names the field. The input's aria-describedby names v-2-error, the id of the "
        "paragraph holding the message, so the message is read with the field. aria-invalid true marks the "
        "field as wrong. All three ids come from one useId call.",
        "Um campo de formulário e os três ids que ligam as partes dele. O atributo for do label nomeia o id do "
        "input, v-2, e assim o label dá nome ao campo. O aria-describedby do input nomeia v-2-error, o id do "
        "parágrafo com a mensagem, e assim a mensagem é lida junto com o campo. aria-invalid true marca o campo "
        "como errado. Os três ids vêm de uma chamada de useId."))
    c.rect(30, 20, 260, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(42, 40, '<label for="v-2">Minutes</label>', mono=True, size=10.5, anchor="start")
    c.rect(30, 86, 400, 52, fill="var(--ink)", stroke="var(--amber)")
    c.text(42, 104, '<input id="v-2" aria-invalid="true"', mono=True, size=10.5, anchor="start", fill="var(--amber)")
    c.text(42, 124, '       aria-describedby="v-2-error">', mono=True, size=10.5, anchor="start", fill="var(--amber)")
    c.rect(30, 164, 400, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(42, 184, '<p id="v-2-error">Between 5 and 240…</p>', mono=True, size=10.5, anchor="start")
    c.line(160, 62, 160, 84, stroke="var(--phosphor)", arrow=True)
    c.line(230, 140, 230, 162, stroke="var(--phosphor)", arrow=True)
    c.text(470, 40, T("names the field", "dá nome ao campo"), anchor="start", size=11, fill="var(--phosphor)")
    c.text(470, 112, T("is announced as invalid", "é anunciado como inválido"), anchor="start", size=11, fill="var(--amber)")
    c.text(470, 184, T("is read after the field", "é lido depois do campo"), anchor="start", size=11, fill="var(--phosphor)")
    c.line(294, 40, 462, 40, stroke="var(--wire)", dash="2 3")
    c.line(434, 112, 462, 112, stroke="var(--wire)", dash="2 3")
    c.line(434, 184, 462, 184, stroke="var(--wire)", dash="2 3")
    c.caption = T("The red text is for the eye; the ids are what a screen reader follows.",
                  "O texto vermelho é para o olho; os ids são o que um leitor de tela segue.")
    return c


FIGURES = [("accessible-errors", wiring)]
