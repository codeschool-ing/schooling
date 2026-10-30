import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-rkxs67qp", "exam", "medium",
  ("Where does a SwiftUI app keep state that every window must share?", "Onde um app SwiftUI guarda o estado que toda janela precisa compartilhar?"),
  ("Each window gets new storage for its views' @State.", "Cada janela ganha armazenamento novo para o @State das suas views."),
  [(F, ("In `@State` inside the first screen", "Num `@State` dentro da primeira tela"), ("That is one copy per window.", "Isso é uma cópia por janela.")),
   (T, ("In a model created once, in the App", "Num modelo criado uma vez, no App"), ("Right: the App lives as long as the process.", "Isso: o App vive enquanto o processo viver.")),
   (F, ("In `@SceneStorage`, which every scene reads", "No `@SceneStorage`, que toda cena lê"), ("SceneStorage is per scene, not shared.", "O SceneStorage é por cena, não compartilhado.")),
   (F, ("In the `WindowGroup`'s closure, as a local constant", "No closure do `WindowGroup`, como constante local"), ("The closure is a template run per window.", "O closure é um modelo rodado por janela."))], drill=False),
Q("ex-hzgds64h", "exam", "medium",
  ("According to Apple's documentation, what should an app expect once its scene is in the background?", "Pela documentação da Apple, o que um app deve esperar quando a cena está em segundo plano?"),
  ("It may not get another chance.", "Pode não haver outra chance."),
  [(F, ("To keep running until the person closes it", "Continuar rodando até a pessoa fechá-lo"), ("People rarely close apps, and iOS may end one.", "As pessoas raramente fecham apps, e o iOS pode encerrar um.")),
   (F, ("A launch callback before it returns", "Um callback de abertura antes de voltar"), ("There is no such callback in SwiftUI.", "Não existe esse callback no SwiftUI.")),
   (T, ("To be terminated soon after", "Ser encerrado logo depois"), ("Right, which is why saving happens on the way there.", "Isso, e por isso salvar acontece no caminho até lá.")),
   (F, ("To be moved back to inactive within a second", "Voltar para inativa em um segundo"), ("Nothing promises a return.", "Nada promete uma volta."))], drill=False),
N("ex-3pwqwcnh", "exam", "easy",
  ("How many moves between phases does a scene make from active, to the home screen, and back to active?", "Quantos movimentos entre fases uma cena faz de ativa, para a tela inicial, e de volta a ativa?"),
  ("Through inactive both ways.", "Passando por inativa nos dois sentidos."), 4, drill=False),
Q("ex-v1e0taq4", "exam", "hard",
  ("A team saves the plan only when the person taps a Save button. Which failure does the scene phase let them avoid?", "Uma equipe salva o plano só quando a pessoa toca num botão Salvar. Qual falha a fase da cena deixa evitar?"),
  ("What can iOS do to an app in the background?", "O que o iOS pode fazer a um app em segundo plano?"),
  [(F, ("Two windows showing different plans", "Duas janelas mostrando planos diferentes"), ("That is about where state lives, not when it is saved.", "Isso é sobre onde o estado mora, não quando é salvo.")),
   (T, ("Unsaved work, lost when iOS ends the app", "Trabalho perdido se o iOS encerrar o app"), ("Right: saving on leaving active covers it.", "Isso: salvar ao sair de ativa cobre esse caso.")),
   (F, ("A body that runs twice", "Um body que roda duas vezes"), ("That is ordinary and cheap, lesson 3.", "Isso é normal e barato, aula 3.")),
   (F, ("A bundle identifier that changes", "Um bundle identifier que muda"), ("Unrelated to saving.", "Sem relação com salvar."))], drill=False),
C("ex-9eq0st2y", "exam", "medium",
  ("Small UI state such as which course was open, restored per scene by SwiftUI, goes in a property marked `@___`.", "Um estado pequeno de interface, como qual curso estava aberto, restaurado por cena pelo SwiftUI, vai numa propriedade marcada `@___`."),
  ("Its name says where it is kept.", "O nome diz onde ele é guardado."),
  ["SceneStorage"], ["SceneStorage"], drill=False),
]
