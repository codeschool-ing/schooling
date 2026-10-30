"""Exam questions for lesson 9: safe areas, insets and the keyboard."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q("@", "", "multiple-choice", "easy",
  ("Which of these are reported to an app as insets? Choose all that apply.",
   "Quais destes são informados a um app como insets? Escolha todos os que se aplicam."),
  hint=H(9), choices=[
   C(True, "The status bar", "A barra de status", "It covers the top edge.", "Ela cobre a borda de cima."),
   C(True, "The display cutout", "O recorte da tela", "The notch or camera hole.", "O entalhe ou o furo da câmera."),
   C(True, "The on-screen keyboard", "O teclado virtual", "The largest inset, while it is up.", "O maior inset, enquanto está aberto."),
   C(False, "The app's own tab bar", "A barra de abas do próprio app",
     "The app draws that itself; it is not a system inset.", "O app a desenha; ela não é um inset do sistema."),
  ]),
Q("@", "", "quiz", "medium",
  ("A screen is 800 tall with a bottom inset of 30 and a keyboard 320 tall. Where is the lowest edge a button may rest on while the keyboard is up?",
   "Uma tela tem 800 de altura, com inset de baixo de 30 e um teclado de 320. Qual é a borda mais baixa em que um botão pode se apoiar com o teclado aberto?"),
  hint=H(9), choices=[
   C(False, "770, the safe area's bottom", "770, a borda de baixo da área segura",
     "The keyboard reaches higher than the safe area's bottom.", "O teclado chega mais alto que a borda de baixo da área segura."),
   C(True, "480, the keyboard's top", "480, o topo do teclado",
     "Right: the higher of 800 - 320 and 800 - 30.", "Isso: a mais alta entre 800 - 320 e 800 - 30."),
   C(False, "450, the keyboard's top less the inset", "450, o topo do teclado menos o inset",
     "The two do not add; the higher edge wins.", "Os dois não se somam; vale a borda mais alta."),
   C(False, "800, the screen's bottom", "800, a borda de baixo da tela",
     "That is covered by both the inset and the keyboard.", "Essa é coberta pelo inset e pelo teclado."),
  ]),
Q("@", "", "quiz", "medium",
  ("An Android app targeting API level 36 runs on Android 16 and wants to avoid handling insets by opting out of edge to edge. What happens?",
   "Um app Android que mira o API level 36 roda no Android 16 e quer evitar tratar insets recusando o modo de ponta a ponta. O que acontece?"),
  hint=H(9), choices=[
   C(False, "The opt-out works as it did on Android 15", "A recusa funciona como funcionava no Android 15",
     "For apps targeting 36 on Android 16, the opt-out is disabled.", "Para apps que miram o 36 no Android 16, a recusa está desativada."),
   C(True, "It cannot; the app is drawn edge to edge anyway", "Não pode; o app é desenhado de ponta a ponta mesmo assim",
     "Right: the attribute is deprecated and disabled there.", "Isso: o atributo está obsoleto e desativado ali."),
   C(False, "The system adds the padding for the app", "O sistema acrescenta o espaço pelo app",
     "Edge to edge means the app handles the insets.", "Ponta a ponta quer dizer que o app trata os insets."),
   C(False, "The app is refused by the store", "O app é recusado pela loja",
     "The change is a runtime behaviour, not a store rule.", "A mudança é de comportamento em execução, não regra de loja."),
  ]),
Q("@", "", "cloze", "medium",
  ("In Compose, the modifier that pads a layout by the keyboard's inset is Modifier.___().",
   "No Compose, o modificador que acrescenta a um layout o espaço do inset do teclado é Modifier.___()."),
  hint=H(9), blanks=[(["imePadding"], ["imePadding"])], ignore_case=False),
Q("@", "", "quiz", "hard",
  ("A React Native screen wraps its content in SafeAreaView from react-native-safe-area-context and also adds paddingTop equal to useSafeAreaInsets().top. What will the user see?",
   "Uma tela React Native envolve o conteúdo na SafeAreaView do react-native-safe-area-context e ainda acrescenta paddingTop igual a useSafeAreaInsets().top. O que o usuário vai ver?"),
  hint=H(9), choices=[
   C(False, "Content under the status bar", "Conteúdo embaixo da barra de status",
     "That is what ignoring the insets looks like.", "É assim que ignorar os insets aparece."),
   C(False, "Exactly the right spacing", "Exatamente o espaço certo",
     "The inset is counted twice.", "O inset é contado duas vezes."),
   C(True, "An empty band above the content", "Uma faixa vazia acima do conteúdo",
     "Right: the insets are applied twice, and padding adds to them.", "Isso: os insets são aplicados duas vezes, e o padding se soma a eles."),
   C(False, "A crash, because the two conflict", "Uma falha, porque os dois conflitam",
     "Nothing fails; the layout is just wrong.", "Nada falha; o layout só fica errado."),
  ]),
]
