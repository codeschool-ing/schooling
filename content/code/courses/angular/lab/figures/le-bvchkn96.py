from fig import Canvas


def tree(T):
    c = Canvas(720, 290, T(
        "Two columns joined by lines. On the left, the form model in the class: a FormGroup named form, holding a "
        "FormArray named dates, which holds FormControls at positions 0 and 1, and a FormControl named minutes. "
        "On the right, the template: the form element with [formGroup]=\"form\", a div with "
        "formArrayName=\"dates\", two date inputs with [formControlName] set to 0 and 1, and a number input with "
        "formControlName=\"minutes\". Each line joins a part of the model to the element bound to it.",
        "Duas colunas unidas por linhas. À esquerda, o modelo do formulário na classe: um FormGroup chamado form, "
        "com um FormArray chamado dates, que tem FormControls nas posições 0 e 1, e um FormControl chamado "
        "minutes. À direita, o template: o elemento form com [formGroup]=\"form\", um div com "
        "formArrayName=\"dates\", dois inputs de data com [formControlName] valendo 0 e 1, e um input numérico com "
        "formControlName=\"minutes\". Cada linha une uma parte do modelo ao elemento ligado a ela."))
    c.text(150, 18, T("in the class", "na classe"), size=10, weight="600", fill="var(--phosphor)")
    c.text(530, 18, T("in the template", "no template"), size=10, weight="600", fill="var(--amber)")
    left = [(40, 36, 220, "form: FormGroup"),
            (70, 92, 190, "dates: FormArray"),
            (100, 148, 160, "[0]: FormControl"),
            (100, 196, 160, "[1]: FormControl"),
            (70, 244, 190, "minutes: FormControl")]
    right = [(400, 36, 260, '<form [formGroup]="form">'),
             (420, 92, 240, '<div formArrayName="dates">'),
             (440, 148, 220, '<input [formControlName]="0">'),
             (440, 196, 220, '<input [formControlName]="1">'),
             (420, 244, 240, '<input formControlName="minutes">')]
    for (x, y, w, s) in left:
        c.rect(x, y, w, 32, stroke="var(--phosphor)")
        c.text(x + 10, y + 16, s, size=10, mono=True, anchor="start")
    for (x, y, w, s) in right:
        c.rect(x, y, w, 32, stroke="var(--amber)")
        c.text(x + 10, y + 16, s, size=9.5, mono=True, anchor="start")
    for (lx, ly, lw, _), (rx, ry, _, _) in zip(left, right):
        c.line(lx + lw, ly + 16, rx, ry + 16, stroke="var(--wire)", dash="4 3")
    # nesting lines on the left
    c.path("M 55 68 L 55 108 L 70 108", stroke="var(--paper-dim)")
    c.path("M 55 108 L 55 260 L 70 260", stroke="var(--paper-dim)")
    c.path("M 85 124 L 85 164 L 100 164", stroke="var(--paper-dim)")
    c.path("M 85 164 L 85 212 L 100 212", stroke="var(--paper-dim)")
    c.caption = T("The model is a tree in the class; the template names each part of it on the element that shows it.",
                  "O modelo é uma árvore na classe; o template nomeia cada parte dele no elemento que a mostra.")
    return c


FIGURES = [("form-array", tree)]
