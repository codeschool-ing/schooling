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


def round_trip(T):
    c = Canvas(720, 235, T(
        "The FieldContract demo after 1.5 is typed into the hours field. The hours FormField emits "
        "update:modelValue with 1.5. The writable computed hours runs its setter, which writes minutes as 1.5 times "
        "60, rounded: 90. The ref minutes is now 90. From it, the minutes field shows 90, and the computed error, "
        "which only has a message above 240 minutes, is empty, so the minutes field's error goes. The hours getter, "
        "90 divided by 60, gives back 1.5.",
        "A demo FieldContract depois de 1.5 ser digitado no campo das horas. O FormField das horas emite "
        "update:modelValue com 1.5. O computed gravável hours roda o seu setter, que escreve minutes como 1.5 vezes "
        "60, arredondado: 90. O ref minutes agora é 90. A partir dele, o campo dos minutos mostra 90, e o computed "
        "error, que só tem mensagem acima de 240 minutos, fica vazio, então o erro do campo dos minutos some. O "
        "getter de hours, 90 dividido por 60, devolve 1.5."))
    c.text(95, 20, "FormField", mono=True, size=10.5, fill="var(--paper-dim)")
    c.rect(20, 34, 150, 56, fill="var(--panel)", stroke="var(--wire)")
    c.text(95, 52, T("the Minutes field", "o campo Minutes"), size=10)
    c.text(95, 72, "90", mono=True, size=11, fill="var(--phosphor)")
    c.rect(20, 140, 150, 56, fill="var(--panel)", stroke="var(--amber)")
    c.text(95, 158, T("the Hours field", "o campo Hours"), size=10)
    c.text(95, 178, T("1.5 typed", "1.5 digitado"), size=10.5, fill="var(--amber)")
    c.rect(290, 34, 170, 56, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(375, 52, "minutes", mono=True, size=10.5, fill="var(--phosphor)")
    c.text(375, 72, "ref: 300 → 90", mono=True, size=10)
    c.rect(290, 140, 170, 56, fill="var(--ink)", stroke="var(--amber)")
    c.text(375, 158, "hours", mono=True, size=10.5, fill="var(--amber)")
    c.text(375, 178, T("writable computed", "computed gravável"), size=10)
    c.rect(540, 34, 160, 56, fill="var(--ink)", stroke="var(--wire)")
    c.text(620, 52, "error", mono=True, size=10.5)
    c.text(620, 72, T("empty: 90 is not above 240", "vazio: 90 não passa de 240"), size=9.5)
    c.line(172, 168, 286, 168, stroke="var(--amber)", arrow=True)
    c.text(230, 156, "update:modelValue", mono=True, size=9, fill="var(--amber)")
    c.line(375, 138, 375, 94, stroke="var(--amber)", arrow=True)
    c.text(385, 116, T("set: × 60, rounded", "set: × 60, arredondado"), size=9.5, anchor="start", fill="var(--amber)")
    c.line(288, 62, 174, 62, stroke="var(--phosphor)", arrow=True)
    c.text(230, 50, ":model-value", mono=True, size=9, fill="var(--phosphor)")
    c.line(462, 62, 536, 62, stroke="var(--wire)", arrow=True)
    c.text(375, 218, T("get: 90 / 60 = 1.5, back in the Hours field", "get: 90 / 60 = 1.5, de volta no campo Hours"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("One write goes up through the contract, and everything that reads minutes follows it.",
                  "Uma escrita sobe pelo contrato, e tudo o que lê minutes a acompanha.")
    return c


FIGURES = [("accessible-errors", wiring), ("the-contract", round_trip)]
