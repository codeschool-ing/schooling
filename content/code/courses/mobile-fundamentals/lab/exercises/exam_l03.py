"""The course exam, lesson 3: choosing an approach."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "medium",
  ("A team of three Swift developers is asked for an iPhone-only app that uses a camera feature Apple released this month. Which approach do the criteria point to?",
   "Uma equipe de três desenvolvedores Swift recebe um app só para iPhone que usa um recurso de câmera que a Apple lançou este mês. Para que abordagem os critérios apontam?"),
  hint=H(3), choices=[
   C(True, "Native, in Swift", "Nativa, em Swift",
     "Right: their language, one platform, and a feature too new for any bridge.", "Isso: a linguagem deles, uma plataforma, e um recurso novo demais para qualquer ponte."),
   C(False, "React Native, to be ready for Android later", "React Native, para estar pronto para Android depois",
     "Android is not asked for, and the new feature would need a native module in Swift anyway.", "O Android não foi pedido, e o recurso novo precisaria de um native module em Swift de qualquer jeito."),
   C(False, "A web wrapper, for speed", "Um embrulho web, pela velocidade",
     "There is no web app to reuse, and a brand-new camera feature is far from what a WebView reaches.", "Não há app web para reaproveitar, e um recurso de câmera recém-lançado está longe do que uma WebView alcança."),
   C(False, "Flutter, because it draws every pixel", "Flutter, porque desenha cada pixel",
     "Drawing is not the question here; the team's language and the feature are.", "Desenhar não é a questão aqui; a linguagem da equipe e o recurso são."),
  ]),
Q(None, None, "numeric", "medium",
  ("A matrix gives Flutter a score of 4 on performance. The weight of performance goes from 2 to 5. By how many points does Flutter's total rise?",
   "Uma matriz dá ao Flutter nota 4 em desempenho. O peso do desempenho passa de 2 para 5. Em quantos pontos o total do Flutter sobe?"),
  hint=H(3), value=12, tolerance=0),
Q(None, None, "quiz", "hard",
  ("Two options in a decision matrix swap places when one weight moves by a single point. What is the useful reading of that?",
   "Duas opções numa matriz de decisão trocam de lugar quando um peso muda um único ponto. Qual é a leitura útil disso?"),
  hint=H(3), choices=[
   C(False, "The matrix is wrong and should be abandoned", "A matriz está errada e deve ser abandonada",
     "Sensitivity is information, not a defect.", "Sensibilidade é informação, não defeito."),
   C(False, "The option that was first is still the right one", "A opção que estava em primeiro continua sendo a certa",
     "Nothing in a one-point lead says which is right.", "Nada numa vantagem de um ponto diz qual é a certa."),
   C(True, "The two are close, and the choice rests on that criterion", "As duas estão perto, e a escolha depende daquele critério",
     "Right: that is the weight the team has to agree on.", "Isso: esse é o peso em que a equipe precisa concordar."),
   C(False, "The scores were filled in by the wrong person", "As notas foram preenchidas pela pessoa errada",
     "The weight moved, not the scores.", "O peso mudou, não as notas."),
  ]),
Q(None, None, "ordering", "easy",
  ("Put the steps of an honest decision matrix in order.", "Ponha em ordem os passos de uma matriz de decisão honesta."),
  hint=H(3), items=[("write down how much each criterion matters", "anotar o quanto cada critério importa"),
                    ("score each approach against each criterion", "dar nota a cada abordagem em cada critério"),
                    ("total the columns and read the ranking", "somar as colunas e ler a ordem"),
                    ("move one weight to test how close the leaders are", "mudar um peso para testar o quanto os primeiros estão perto")]),
Q(None, None, "multiple-choice", "medium",
  ("Which routes does the mobile track's fork offer? Choose all that apply.", "Que caminhos a bifurcação da trilha mobile oferece? Escolha todos os que se aplicam."),
  hint=H(3), choices=[
   C(True, "Android with Kotlin", "Android com Kotlin", "Yes: kotlin, then android-apps.", "Sim: kotlin, depois android-apps."),
   C(True, "iOS with Swift", "iOS com Swift", "Yes: swift, then ios-apps.", "Sim: swift, depois ios-apps."),
   C(True, "Multiplatform with React Native", "Multiplataforma com React Native", "Yes: javascript, then react-native.", "Sim: javascript, depois react-native."),
   C(False, "Multiplatform with Flutter", "Multiplataforma com Flutter", "Flutter is looked at in react-native, not offered as a route.", "O Flutter é visto em react-native, não oferecido como caminho."),
  ]),
]
