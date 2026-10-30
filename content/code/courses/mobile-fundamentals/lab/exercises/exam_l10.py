"""The course exam, lesson 10: navigation shapes and back. Ids are assigned by the coordinator."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "medium",
  ("An app has two tabs. A person opens two screens in the first tab, switches to the second, and switches back. What do they find in the first tab?",
   "Um app tem duas abas. Uma pessoa abre duas telas na primeira aba, troca para a segunda e volta. O que ela encontra na primeira aba?"),
  hint=H(10), choices=[
   C(False, "The first tab's root, because a switch starts a tab again", "A raiz da primeira aba, porque uma troca recomeça a aba",
     "Each tab keeps its own stack across switches.", "Cada aba guarda a própria pilha entre trocas."),
   C(True, "The second screen they had opened", "A segunda tela que tinha aberto",
     "Right: a tab is a stack, left where it was.", "Isso: uma aba é uma pilha, deixada onde estava."),
   C(False, "The second tab's screen, pushed onto the first tab's stack", "A tela da segunda aba, empilhada na pilha da primeira",
     "Tabs do not push onto each other.", "Abas não empilham uma sobre a outra."),
   C(False, "Whatever the system restored after killing the process", "O que o sistema restaurou depois de matar o processo",
     "No process was killed in a tab switch.", "Nenhum processo morreu numa troca de aba."),
  ]),
Q(None, None, "quiz", "medium",
  ("On an iPhone, a person is on the first screen of a stack. What does the app offer for going back?",
   "Num iPhone, uma pessoa está na primeira tela de uma pilha. O que o app oferece para voltar?"),
  hint=H(10), choices=[
   C(True, "Nothing; there is no back button at a root", "Nada; não há botão de voltar numa raiz",
     "Right: iOS has no system back, and the app draws none where there is nothing under the screen.", "Isso: o iOS não tem voltar do sistema, e o app não desenha nenhum onde não há nada embaixo da tela."),
   C(False, "A system back gesture that leaves the app", "Um gesto de voltar do sistema que sai do app",
     "That is Android's behaviour.", "Esse é o comportamento do Android."),
   C(False, "A back button that closes the app", "Um botão de voltar que fecha o app",
     "Apps do not draw a button that leaves them.", "Apps não desenham um botão que sai deles."),
   C(False, "An up arrow to the previous app", "Uma seta de subir para o app anterior",
     "Up is Android's, and it never leaves the app.", "Subir é do Android, e nunca sai do app."),
  ]),
Q(None, None, "ordering", "hard",
  ("An Android app has tabs A (the start tab) and B. The person is on B with two screens on B's stack. Put the effects of four back presses in order.",
   "Um app Android tem as abas A (a inicial) e B. A pessoa está em B com duas telas na pilha de B. Ponha em ordem os efeitos de quatro toques em voltar."),
  hint=H(10), items=[("pop B's top screen", "desempilha a tela do topo de B"),
         ("pop B's second screen, leaving B's root", "desempilha a segunda tela de B, ficando na raiz de B"),
         ("switch to tab A", "troca para a aba A"),
         ("leave the app", "sai do app")]),
Q(None, None, "cloze", "medium",
  ("Android calls the back swipe that previews its destination before the finger lifts ___ back.",
   "O Android chama o deslize de voltar que mostra o destino antes de o dedo soltar de ___ back."),
  hint=H(10), blanks=[(["predictive"], ["predictive"])]),
Q(None, None, "matching", "medium",
  ("Match each navigation library to its platform's toolkit.", "Associe cada biblioteca de navegação ao toolkit da sua plataforma."),
  hint=H(10), pairs=[(("NavHost and navController", "NavHost e navController"), ("Jetpack Compose", "Jetpack Compose")),
         (("NavigationStack", "NavigationStack"), ("SwiftUI", "SwiftUI")),
         (("createNativeStackNavigator", "createNativeStackNavigator"), ("React Native", "React Native"))],
  distractors=[("Flutter", "Flutter")]),
]
