"""Lesson 11: the form screen, annotated, and the keyboard figure."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent.parent / "src" / "l11" / "AddSessionScreen.tsx").read_text().rstrip("\n").split("\n")
blocks, cur = [], []
for line in SRC:
    if line == "" and cur:
        blocks.append(cur); cur = []
    else:
        cur.append(line)
blocks.append(cur)
NOTES = [
 ("The form uses React Native's own components, the add mutation of the section on the server, the theme, and the validator.",
  "O formulário usa os componentes do próprio React Native, a mutation de acrescentar da seção do servidor, o tema e o validador."),
 ("A stack screen whose params are the course's id, as `RootParams` declares.", "Uma tela de pilha cujo parâmetro é o id do curso, como declara o `RootParams`."),
 ("**The draft is two strings**, never numbers, so a half-typed value is kept as typed. `errors` holds the sentences of the last failed save. `minutesRef` lets the date field's return key move on; `saved` and `dirty` decide whether leaving must ask.",
  "**O rascunho são duas strings**, nunca números, para um valor pela metade ficar como foi digitado. `errors` guarda as frases do último salvamento que falhou. O `minutesRef` deixa a tecla de retorno do campo de data seguir adiante; `saved` e `dirty` decidem se sair precisa perguntar."),
 ("The leaving guard of the section on leaving: when something is typed and not saved, stop the navigation and ask.",
  "A proteção de saída da seção sobre sair: quando há algo digitado e não salvo, interrompe a navegação e pergunta."),
 ("**Save validates first** and stops at the first refusal, with the sentences on screen. A server refusal is caught and left in `add.error`, which the form shows; only a success goes back.",
  "**Salvar valida antes** e para na primeira recusa, com as frases na tela. Uma recusa do servidor é capturada e fica em `add.error`, que o formulário mostra; só um sucesso volta."),
 ("The fields. Each has a visible label and an `aria-label`, the keyboard its content needs, and a return key that moves on or saves. Every error is a `role=\"alert\"`, announced when it appears. The view moves up for the keyboard on iOS; the scroll view lets a tap reach *Save* while it is open.",
  "Os campos. Cada um tem um rótulo visível e um `aria-label`, o teclado de que o conteúdo precisa, e uma tecla de retorno que segue adiante ou salva. Todo erro é um `role=\"alert\"`, anunciado quando aparece. A view sobe para o teclado no iOS; a scroll view deixa um toque chegar ao *Save* com ele aberto."),
 ("Sizes and spacing only; every colour comes from the theme.", "Só tamanhos e espaços; toda cor vem do tema."),
]
assert len(blocks) == len(NOTES), len(blocks)
parts = [("\n".join(b) + ("\n" if i < len(blocks) - 1 else ""), en, pt) for i, (b, (en, pt)) in enumerate(zip(blocks, NOTES))]
EXAMPLES = {"the-form": [{"language": "tsx", "file": "src/AddSessionScreen.tsx", "parts": parts}]}

T = {
 "en": dict(aria="Two phone screens with the keyboard open. On the left, without KeyboardAvoidingView, the keyboard covers the minutes field and the Save button. On the right, with it on iOS, padding equal to the keyboard's height pushes the form up, so the focused field and Save stay visible above the keyboard.",
   without="without", with_="with KeyboardAvoidingView", date="Date", minutes="Minutes", save="Save session", kb="keyboard", hidden="hidden under the keyboard",
   cap="The keyboard takes half the screen; the form has to move out of its way, and each platform does that differently."),
 "pt": dict(aria="Duas telas de celular com o teclado aberto. À esquerda, sem KeyboardAvoidingView, o teclado cobre o campo de minutos e o botão Save. À direita, com ele no iOS, um padding igual à altura do teclado empurra o formulário para cima, e o campo em foco e o Save continuam visíveis acima do teclado.",
   without="sem", with_="com KeyboardAvoidingView", date="Date", minutes="Minutes", save="Save session", kb="teclado", hidden="escondidos sob o teclado",
   cap="O teclado ocupa metade da tela; o formulário precisa sair do caminho dele, e cada plataforma faz isso de um jeito."),
}


def phone(f, x, t, moved):
    f.rect(x, 30, 200, 300, stroke="wire", fill="ink", rx=14)
    top = 50 if moved else 110
    f.box(x + 20, top, 160, 26, [t["date"]], size=9, anchor="start")
    f.box(x + 20, top + 40, 160, 26, [t["minutes"]], size=9, anchor="start", stroke="phosphor")
    f.box(x + 20, top + 80, 160, 26, [t["save"]], size=9, stroke="amber")
    f.rect(x + 2, 180, 196, 146, stroke="paper-dim", fill="panel", rx=6)
    f.text(x + 100, 254, t["kb"], size=10, fill="paper-dim", italic=True)


def figures(lang):
    t = T[lang]
    f = Fig("l11-keyboard", 720, 350, t["aria"])
    f.text(170, 18, t["without"], size=10, fill="amber", bold=True)
    f.text(510, 18, t["with_"], size=10, fill="phosphor", bold=True)
    f.rect(70, 30, 200, 300, stroke="wire", fill="ink", rx=14)
    f.box(90, 140, 160, 26, [t["date"]], size=9, anchor="start")
    f.rect(72, 180, 196, 146, stroke="paper-dim", fill="panel", rx=6)
    f.text(170, 230, t["kb"], size=10, fill="paper-dim", italic=True)
    f.text(170, 260, t["hidden"], size=9, fill="amber", italic=True)
    phone(f, 410, t, True)
    return {"l11-keyboard": f.json(caption=t["cap"], same=None if lang == "en" else ["Date", "Minutes", "Save session"])}
