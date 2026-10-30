"""Exam questions for lesson 8: layouts that stretch across windows."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q("@", "", "ordering", "easy",
  ("Put Android's width classes in order, from the narrowest windows to the widest.",
   "Ponha as classes de largura do Android em ordem, das janelas mais estreitas às mais largas."),
  hint=H(8), items=[("compact", "compact"), ("medium", "medium"), ("expanded", "expanded"),
                    ("large", "large"), ("extra-large", "extra-large")]),
Q("@", "", "multiple-choice", "medium",
  ("Which of these are sound reasons for a layout to change shape? Choose all that apply.",
   "Quais destes são bons motivos para um layout mudar de forma? Escolha todos os que se aplicam."),
  hint=H(8), choices=[
   C(True, "The window moved from medium to expanded width", "A janela passou da largura medium para expanded",
     "A change of size class is the signal to switch.", "Uma mudança de classe de tamanho é o sinal para trocar."),
   C(True, "The window's height dropped below 480 dp", "A altura da janela caiu abaixo de 480 dp",
     "Compact height is a class change too.", "Altura compact também é uma mudança de classe."),
   C(False, "The device model is a tablet", "O modelo do aparelho é um tablet",
     "Size classes are not about the device.", "Classes de tamanho não são sobre o aparelho."),
   C(False, "The screen has more than 400 dpi", "A tela tem mais de 400 dpi",
     "Density changes pixels per dp, not the layout.", "A densidade muda pixels por dp, não o layout."),
  ]),
Q("@", "", "quiz", "medium",
  ("A list-detail app is in one pane on a foldable; the user opens it and it becomes two panes. What must carry over?",
   "Um app de lista e detalhe está em um painel num dobrável; o usuário o abre e ele vira dois painéis. O que precisa ser mantido?"),
  hint=H(8), choices=[
   C(True, "The selected item", "O item escolhido",
     "Right: it is state, shown as the top screen in one pane and the highlighted row in two.", "Isso: é estado, mostrado como a tela de cima em um painel e a linha destacada em dois."),
   C(False, "The one-pane layout until the app restarts", "O layout de um painel até o app reiniciar",
     "The layout follows the window as it changes.", "O layout segue a janela conforme ela muda."),
   C(False, "The window's old width in dp", "A largura antiga da janela em dp",
     "The old width no longer exists.", "A largura antiga não existe mais."),
   C(False, "The density bucket of the outer screen", "O bucket de densidade da tela externa",
     "Density has nothing to do with the panes.", "A densidade não tem nada a ver com os painéis."),
  ]),
Q("@", "", "quiz", "hard",
  ("A news app's article column fills the full width of every window. On a 1280 dp tablet in landscape, what is the problem and the usual fix?",
   "A coluna de artigo de um app de notícias ocupa a largura inteira de toda janela. Num tablet de 1280 dp em paisagem, qual é o problema e a correção usual?"),
  hint=H(8), choices=[
   C(False, "The text is too small; switch it to dp", "O texto é pequeno demais; trocar para dp",
     "Text size is not the issue, and text should be sp.", "O tamanho do texto não é a questão, e texto deve ser sp."),
   C(True, "Lines are too long to read; cap the width and centre it", "As linhas ficam longas demais para ler; limitar a largura e centralizar",
     "Right: fill up to a maximum, then stop.", "Isso: ocupar até um máximo, e parar."),
   C(False, "Nothing; filling is always right", "Nada; preencher está sempre certo",
     "Filling past a readable width is the common mistake.", "Preencher além de uma largura legível é o erro comum."),
   C(False, "The app must lock itself to portrait", "O app precisa se travar em retrato",
     "A lock does not stop windows changing size.", "Uma trava não impede as janelas de mudar de tamanho."),
  ]),
Q("@", "", "quiz", "medium",
  ("On iOS, how should a layout decide whether it has room for a sidebar?",
   "No iOS, como um layout deve decidir se tem espaço para uma barra lateral?"),
  hint=H(8), choices=[
   C(False, "By the device model, iPhone or iPad", "Pelo modelo do aparelho, iPhone ou iPad",
     "The guidelines say device type is not useful for layout.", "As diretrizes dizem que o tipo de aparelho não serve para layout."),
   C(False, "By whether the phone is in landscape", "Por o celular estar em paisagem",
     "Orientation does not say how much space there is.", "A orientação não diz quanto espaço existe."),
   C(True, "By its horizontal size class", "Pela classe de tamanho horizontal",
     "Right: it describes the space actually available.", "Isso: ela descreve o espaço de fato disponível."),
   C(False, "By the screen's scale factor, @2x or @3x", "Pelo fator de escala da tela, @2x ou @3x",
     "Scale is density, not space.", "Escala é densidade, não espaço."),
  ]),
]
