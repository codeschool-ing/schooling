"""The course exam, lesson 2: native, multiplatform and web wrappers."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "easy",
  ("Which approach draws every button, list and text field with an engine shipped inside the app, instead of the platform's own views?",
   "Que abordagem desenha cada botão, lista e campo de texto com um motor embarcado no app, em vez das views da própria plataforma?"),
  hint=H(2), choices=[
   C(False, "React Native", "React Native", "React Native creates the platform's own views at runtime.", "O React Native cria as views da própria plataforma em tempo de execução."),
   C(True, "Flutter", "Flutter", "Right. Flutter paints its own widgets with Impeller, which ships with the app.", "Isso. O Flutter pinta os próprios widgets com o Impeller, que vai junto com o app."),
   C(False, "Kotlin Multiplatform", "Kotlin Multiplatform", "It shares code below the screen and draws nothing itself.", "Ele compartilha código abaixo da tela e não desenha nada sozinho."),
   C(False, "Native Swift with SwiftUI", "Swift nativo com SwiftUI", "SwiftUI draws with iOS's own views.", "O SwiftUI desenha com as views do próprio iOS."),
  ]),
Q(None, None, "quiz", "medium",
  ("A Capacitor app needs the phone's contacts. Through what does the page's JavaScript reach them?",
   "Um app Capacitor precisa dos contatos do celular. Por onde o JavaScript da página chega até eles?"),
  hint=H(2), choices=[
   C(False, "Through the DOM, which exposes the contacts", "Pelo DOM, que expõe os contatos", "The DOM is the page; device features are on the far side of the border.", "O DOM é a página; os recursos do aparelho ficam do outro lado da fronteira."),
   C(False, "Through a platform channel", "Por um platform channel", "That is Flutter's mechanism.", "Esse é o mecanismo do Flutter."),
   C(True, "Through a plugin whose native half is written in Kotlin or Java and in Swift", "Por um plugin cuja metade nativa é escrita em Kotlin ou Java e em Swift",
     "Right. The page calls JavaScript, and the plugin's native half does the work.", "Isso. A página chama JavaScript, e a metade nativa do plugin faz o trabalho."),
   C(False, "Through expect and actual declarations", "Por declarações expect e actual", "Those are Kotlin Multiplatform's.", "Essas são do Kotlin Multiplatform."),
  ]),
Q(None, None, "multiple-choice", "medium",
  ("In which of these can lesson 1's planner.ts run without being rewritten? Choose all that apply.",
   "Em quais destes o planner.ts da aula 1 roda sem ser reescrito? Escolha todos os que se aplicam."),
  hint=H(2), choices=[
   C(True, "A React Native app", "Um app React Native", "Yes: it runs JavaScript.", "Sim: ele roda JavaScript."),
   C(True, "A Capacitor app's WebView", "A WebView de um app Capacitor", "Yes: a browser engine runs JavaScript.", "Sim: um motor de navegador roda JavaScript."),
   C(True, "Node.js in a terminal", "O Node.js num terminal", "Yes: that is where the course runs it.", "Sim: é onde o curso o roda."),
   C(False, "A native SwiftUI app", "Um app SwiftUI nativo", "Swift does not run TypeScript; the rules are rewritten in Swift.", "O Swift não roda TypeScript; as regras são reescritas em Swift."),
   C(False, "A Flutter app", "Um app Flutter", "Flutter runs Dart.", "O Flutter roda Dart."),
  ]),
Q(None, None, "cloze", "easy",
  ("A file that calls document.createElement fails in Node.js with ReferenceError: document is not ___.",
   "Um arquivo que chama document.createElement falha no Node.js com ReferenceError: document is not ___."),
  hint=H(2), blanks=[(["defined"], ["defined"])], ignore_case=True),
Q(None, None, "quiz", "hard",
  ("A team chose React Native to write the app once. Its main feature turns out to be a sensor no library supports. What has the choice now cost them?",
   "Uma equipe escolheu React Native para escrever o app uma vez. O recurso principal acaba sendo um sensor que nenhuma biblioteca suporta. O que a escolha passou a custar?"),
  hint=H(2), choices=[
   C(True, "Their own native module, in Kotlin and Swift", "Um native module próprio, em Kotlin e em Swift",
     "Right. The far side of the border is platform code, and here nobody has written it yet.", "Isso. O outro lado da fronteira é código da plataforma, e aqui ninguém o escreveu ainda."),
   C(False, "Nothing: JavaScript reaches any API", "Nada: o JavaScript alcança qualquer API", "JavaScript cannot call a platform API directly.", "O JavaScript não chama uma API da plataforma diretamente."),
   C(False, "Moving the sensor code into a WebView", "Levar o código do sensor para uma WebView", "A WebView reaches less of the device, not more.", "Uma WebView alcança menos do aparelho, não mais."),
   C(False, "Rewriting the screens in Dart, so Flutter can reach it", "Reescrever as telas em Dart, para o Flutter alcançá-lo", "Flutter would face the same border, through a platform channel.", "O Flutter enfrentaria a mesma fronteira, por um platform channel."),
  ]),
]
