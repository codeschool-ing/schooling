from fig import Fig

cu = Fig("controlled", 720, 230,
         {"en": "Two ways a field's value travels. Controlled: the value lives in React state, flows into the input as "
                "the value prop, and every keystroke calls onChange, which sets the state, which renders the input "
                "again. Uncontrolled: the value lives in the DOM input itself, and React reads it once, on submit, "
                "through FormData.",
          "pt": "Dois caminhos para o valor de um campo. Controlado: o valor mora no estado do React, entra no input "
                "pela prop value, e cada tecla chama onChange, que define o estado, que renderiza o input de novo. Não "
                "controlado: o valor mora no próprio input do DOM, e o React o lê uma vez, no envio, pelo FormData."},
         {"en": "Controlled: React holds the value. Uncontrolled: the DOM holds it until submit.",
          "pt": "Controlado: o React guarda o valor. Não controlado: o DOM guarda até o envio."})
cu.text(170, 20, {"en": "controlled", "pt": "controlado"}, anchor="middle", tone="phosphor", size=11.5)
cu.box(40, 40, 120, 40, "useState", mono=True, tone="phosphor")
cu.box(200, 40, 120, 40, "<input>", mono=True, tone="wire", text_tone="paper")
cu.arrow(162, 52, 198, 52, tone="phosphor")
cu.text(180, 34, "value", mono=True, tone="phosphor", anchor="middle", size=10)
cu.arrow(198, 72, 162, 72, tone="amber")
cu.text(180, 96, "onChange", mono=True, tone="amber", anchor="middle", size=10)
cu.text(180, 130, {"en": "every keystroke renders", "pt": "cada tecla renderiza"}, anchor="middle", tone="dim", size=10.5)
cu.text(180, 150, {"en": "the screen can react at once", "pt": "a tela pode reagir na hora"}, anchor="middle", tone="dim", size=10.5)
cu.text(540, 20, {"en": "uncontrolled", "pt": "não controlado"}, anchor="middle", tone="amber", size=11.5)
cu.box(400, 40, 120, 40, "<input name>", mono=True, tone="wire", text_tone="paper")
cu.box(560, 40, 140, 40, "onSubmit", mono=True, tone="amber")
cu.arrow(522, 60, 558, 60, tone="amber")
cu.text(540, 96, "new FormData(form)", mono=True, tone="amber", anchor="middle", size=10)
cu.text(540, 130, {"en": "typing renders nothing", "pt": "digitar não renderiza nada"}, anchor="middle", tone="dim", size=10.5)
cu.text(540, 150, {"en": "React reads the value once", "pt": "o React lê o valor uma vez"}, anchor="middle", tone="dim", size=10.5)
cu.line(360, 30, 360, 200, tone="wire", dashed=True)

FIGS = [cu]
