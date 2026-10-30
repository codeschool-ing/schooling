import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-yrydv1az", "exam", "medium",
  ("Why does the order of modifiers change what SwiftUI draws?", "Por que a ordem dos modificadores muda o que o SwiftUI desenha?"),
  ("Each modifier is a wrapper.", "Cada modificador é um embrulho."),
  [(F, ("SwiftUI applies them from last to first, so the last wins", "O SwiftUI os aplica do último ao primeiro, então o último vence"), ("They are applied in the order written, each wrapping the previous.", "São aplicados na ordem escrita, cada um embrulhando o anterior.")),
   (T, ("Each one wraps everything before it, and sees only that", "Cada um embrulha tudo o que vem antes, e só enxerga isso"), ("Right: a background wraps whatever came before it.", "Isso: um fundo embrulha o que veio antes dele.")),
   (F, ("Modifiers overwrite each other's properties", "Modificadores sobrescrevem as propriedades uns dos outros"), ("There are no properties to overwrite; each makes a new view.", "Não há propriedades a sobrescrever; cada um faz uma view nova.")),
   (F, ("Only environment modifiers depend on order", "Só os modificadores de ambiente dependem da ordem"), ("Those depend least; they reach every view inside them.", "Esses dependem menos; alcançam toda view dentro deles."))], drill=False),
Q("ex-rzvv4fqe", "exam", "hard",
  ("A helper `.when(condition) { … }` applies a modifier inside an `if`. What does it cost when the condition flips on a view that holds state?", "Uma auxiliar `.when(condition) { … }` aplica um modificador dentro de um `if`. O que ela custa quando a condição vira numa view que guarda estado?"),
  ("Two branches are two views.", "Dois ramos são duas views."),
  [(F, ("Nothing; SwiftUI sees the same view either way", "Nada; o SwiftUI vê a mesma view nos dois casos"), ("The view moves between the branches' slots.", "A view muda de vaga entre os ramos.")),
   (F, ("A compile error when the condition is a variable", "Um erro de compilação quando a condição é uma variável"), ("It compiles; the cost comes at run time.", "Compila; o custo vem em tempo de execução.")),
   (T, ("The view is recreated, and its state reset", "A view é recriada, e o estado dela zerado"), ("Right: put the condition in a value instead.", "Isso: ponha a condição num valor.")),
   (F, ("The modifier is applied twice", "O modificador é aplicado duas vezes"), ("It is applied in one branch and absent in the other.", "Ele é aplicado num ramo e falta no outro."))], drill=False),
Q("ex-1vbrc1zc", "exam", "medium",
  ("A badge must sit on an icon's corner without changing the row's layout. Which modifier fits?", "Um selo precisa ficar no canto de um ícone sem mudar o layout da linha. Qual modificador serve?"),
  ("It takes the size of the view it modifies.", "Ele fica com o tamanho da view que modifica."),
  [(T, ("`.overlay(alignment: .topTrailing) { … }`", "`.overlay(alignment: .topTrailing) { … }`"), ("Right: drawn in front at the icon's size.", "Isso: desenhado na frente, no tamanho do ícone.")),
   (F, ("`.padding(.topTrailing)`", "`.padding(.topTrailing)`"), ("Padding adds space and draws no badge.", "Padding acrescenta espaço e não desenha selo.")),
   (F, ("A `ZStack` with the icon and a large badge", "Um `ZStack` com o ícone e um selo grande"), ("A ZStack grows to its largest child.", "Um ZStack cresce até o maior filho.")),
   (F, ("`.hidden()` on the badge until it is needed", "`.hidden()` no selo até ele ser necessário"), ("Hidden keeps its space in the layout.", "Escondido mantém o espaço no layout."))], drill=False),
N("ex-6n10trz3", "exam", "medium",
  ("Text measuring 48 by 20 gets `.padding(16)`. How wide is the padding's layer?", "Um texto de 48 por 20 recebe `.padding(16)`. Qual a largura da camada de padding?"),
  ("Add the padding on both sides.", "Some o padding dos dois lados."), 80, drill=False),
C("ex-rkqc7ypc", "exam", "easy",
  ("A reusable chain of modifiers can be a type conforming to `View___`, applied with `modifier(_:)`.", "Uma cadeia reutilizável de modificadores pode ser um tipo que obedece a `View___`, aplicado com `modifier(_:)`."),
  ("Its method is body(content:).", "O método dele é body(content:)."),
  ["Modifier"], ["Modifier"], drill=False),
]
