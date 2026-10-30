"""Exam questions for lesson 19 (le-hb43cgpf). Ids are assigned by the coordinator."""
import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from exgen import Q, C

H = ("Lesson 19.", "Aula 19.")

QS = [
Q(None, None, "quiz", "easy",
  ("An icon-only button in an app declares no label. What does a screen reader user hear when focus reaches it?",
   "Um botão só de ícone num app não declara rótulo. O que ouve um usuário de leitor de tela quando o foco chega nele?"),
  hint=H, choices=[
   C(False, "A description of the icon, generated from its pixels", "Uma descrição do ícone, gerada a partir dos pixels",
     "Screen readers read declarations, not pixels.", "Leitores de tela leem declarações, não pixels."),
   C(True, "Its role, such as \"button\", and nothing that says what it does", "O papel, como \"botão\", e nada que diga o que ele faz",
     "Right: the label is the part that was missing.", "Isso: o rótulo é a parte que faltou."),
   C(False, "The app's name", "O nome do app",
     "The app's name is not a fallback for a control's label.", "O nome do app não substitui o rótulo de um controle."),
   C(False, "Nothing: elements without a label are skipped", "Nada: elementos sem rótulo são pulados",
     "A focusable control is still in the list; it is just unnamed.", "Um controle focável continua na lista; só fica sem nome."),
  ]),
Q(None, None, "numeric", "easy",
  ("Android's documentation asks for touch targets of at least how many dp on each side?",
   "A documentação do Android pede áreas de toque de pelo menos quantos dp de cada lado?"),
  hint=H, value=48, tolerance=0),
Q(None, None, "multiple-choice", "medium",
  ("Under WCAG 2.2, which of these need a contrast ratio of at least 3:1 rather than 4.5:1? Choose all that apply.",
   "Pela WCAG 2.2, quais destes precisam de razão de contraste de pelo menos 3:1 em vez de 4,5:1? Escolha todos os que se aplicam."),
  hint=H, choices=[
   C(True, "text of 18 points or more", "texto de 18 pontos ou mais", "Large-scale text needs 3:1.", "Texto em escala grande precisa de 3:1."),
   C(True, "the edge of a checkbox against its background", "a borda de uma caixa de seleção contra o fundo", "Non-text contrast, 1.4.11, asks 3:1.", "O contraste não textual, 1.4.11, pede 3:1."),
   C(False, "a 14-point regular caption", "uma legenda de 14 pontos, peso normal", "Ordinary text: 4.5:1.", "Texto comum: 4,5:1."),
   C(True, "text of 14 points in bold", "texto de 14 pontos em negrito", "14-point bold counts as large-scale.", "14 pontos em negrito conta como escala grande."),
  ]),
Q(None, None, "cloze", "medium",
  ("WCAG's Use of Color criterion says colour must not be the ___ visual means of conveying information.",
   "O critério Use of Color da WCAG diz que a cor não pode ser o ___ meio visual de transmitir informação."),
  hint=H, blanks=[(["only", "sole"], ["único", "unico"])]),
Q(None, None, "quiz", "hard",
  ("A list row's text is fixed at 17 points in a row 44 points tall. A user sets the largest accessibility text size on iOS. What happens, and what is the fix?",
   "O texto de uma linha de lista está fixo em 17 pontos numa linha de 44 pontos de altura. Um usuário escolhe o maior tamanho de texto de acessibilidade no iOS. O que acontece, e qual é a correção?"),
  hint=H, choices=[
   C(False, "The row clips its text; raise the fixed height to 60", "A linha corta o texto; subir a altura fixa para 60",
     "The text does not grow at all while it is fixed at 17; and a larger fixed height is still fixed.", "O texto nem cresce enquanto está fixo em 17; e uma altura fixa maior continua fixa."),
   C(True, "Nothing grows; use a text style and let the row's height follow", "Nada cresce; usar um estilo de texto e deixar a altura seguir",
     "Right: a fixed size ignores Dynamic Type, and a fixed row would clip once it does grow.", "Isso: um tamanho fixo ignora o Dynamic Type, e uma linha fixa cortaria quando ele crescer."),
   C(False, "The system enlarges it anyway; nothing to fix", "O sistema aumenta mesmo assim; nada a corrigir",
     "Only text styles follow Dynamic Type.", "Só estilos de texto seguem o Dynamic Type."),
   C(False, "The text grows to 53 points and fits, since rows stretch by default", "O texto cresce para 53 pontos e cabe, já que linhas esticam por padrão",
     "Fixed text does not grow, and a fixed height does not stretch.", "Texto fixo não cresce, e uma altura fixa não estica."),
  ]),
]
