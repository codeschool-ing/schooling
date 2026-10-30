import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-2tq3ckhp", "exam", "medium",
  ("Which change to an `@Observable` model makes SwiftUI read a view's body again?", "Qual mudança num modelo `@Observable` faz o SwiftUI ler de novo o body de uma view?"),
  ("Tracking is per property.", "O rastreamento é por propriedade."),
  [(F, ("Any change to any property of the model", "Qualquer mudança em qualquer propriedade do modelo"), ("Only properties the body read are tracked.", "Só as propriedades que o body leu são rastreadas.")),
   (T, ("A change to a property that body read", "Uma mudança numa propriedade que aquele body leu"), ("Right, the rule section 05 of lesson 3 ran.", "Isso, a regra que a seção 05 da aula 3 rodou.")),
   (F, ("A change made on the main actor, whatever it is", "Uma mudança feita no main actor, qualquer que seja"), ("Where the change happens is not what decides.", "Onde a mudança acontece não é o que decide.")),
   (F, ("A new instance of the model being created", "Uma nova instância do modelo sendo criada"), ("A new model nobody reads changes no body.", "Um modelo novo que ninguém lê não muda body nenhum."))], drill=False),
Q("ex-gmwwvj23", "exam", "medium",
  ("What does `some View` as a body's return type promise?", "O que o `some View` como tipo de retorno de um body promete?"),
  ("The compiler knows it; you do not write it.", "O compilador o conhece; você não o escreve."),
  [(T, ("One concrete type, hidden from the reader", "Um tipo concreto, escondido de quem lê"), ("Right: one type, which is why branches need a builder.", "Isso: um tipo, e por isso ramos precisam de um builder.")),
   (F, ("Any view at all, decided on each call", "Qualquer view, decidida a cada chamada"), ("That is closer to `any View` or `AnyView`.", "Isso está mais perto de `any View` ou `AnyView`.")),
   (F, ("A view that has no state", "Uma view que não tem estado"), ("Opaque types say nothing about state.", "Tipos opacos não dizem nada sobre estado.")),
   (F, ("A view type defined by SwiftUI rather than by you", "Um tipo de view definido pelo SwiftUI e não por você"), ("Your own views are behind `some View` all the time.", "As suas próprias views ficam atrás de `some View` o tempo todo."))], drill=False),
Q("ex-fnffwnv9", "exam", "hard",
  ("A view shows `if isEditing { TextField(…) } else { TextField(…) }`, the two fields identical except for a border. Why is the typed text lost when `isEditing` flips?", "Uma view mostra `if isEditing { TextField(…) } else { TextField(…) }`, os dois campos iguais a não ser por uma borda. Por que o texto digitado some quando `isEditing` vira?"),
  ("Two branches, two slots.", "Dois ramos, duas vagas."),
  [(F, ("TextField resets itself on every body run", "O TextField se zera a cada execução do body"), ("A field in the same slot keeps its state across runs.", "Um campo na mesma vaga mantém o estado entre execuções.")),
   (F, ("The border modifier clears the text", "O modificador de borda limpa o texto"), ("A border draws; it touches no text.", "Uma borda desenha; não mexe em texto.")),
   (T, ("Each branch is a new view with new state", "Cada ramo é uma view diferente, então o campo antigo e o seu estado são destruídos"), ("Right: structural identity.", "Isso: identidade estrutural.")),
   (F, ("SwiftUI sees two TextFields and merges them", "O SwiftUI vê dois TextFields e os junta"), ("It merges nothing; it removes one and inserts the other.", "Ele não junta nada; remove um e insere o outro."))], drill=False),
O("ex-c861dfeq", "exam", "medium",
  ("Order what happens when a model property a body read changes, using the model of lesson 3.", "Ordene o que acontece quando muda uma propriedade de modelo que um body leu, segundo o modelo da aula 3."),
  ("Mark, then redraw on the next frame.", "Marcar, depois redesenhar no próximo quadro."),
  [("The property changes", "A propriedade muda"), ("`onChange` marks the screen dirty", "O `onChange` marca a tela como suja"),
   ("The next frame finds it dirty", "O próximo quadro a acha suja"), ("The body runs again and its reads are recorded anew", "O body roda de novo e as leituras dele são registradas de novo")], drill=False),
C("ex-0haqrbn3", "exam", "easy",
  ("The Swift feature that turns the lines of a body into one value is a result ___.", "O recurso do Swift que transforma as linhas de um body num valor só é um result ___."),
  ("SwiftUI's is called ViewBuilder.", "O do SwiftUI se chama ViewBuilder."),
  ["builder"], ["builder"], drill=False),
]
