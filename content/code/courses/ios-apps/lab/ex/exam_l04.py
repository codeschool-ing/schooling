import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-y83zaps7", "exam", "medium",
  ("In SwiftUI layout, who decides a view's size?", "No layout do SwiftUI, quem decide o tamanho de uma view?"),
  ("The parent only offers.", "O pai só oferece."),
  [(F, ("The parent, which sets it", "O pai, que o define"), ("The parent proposes; it cannot change the answer.", "O pai propõe; não pode mudar a resposta.")),
   (T, ("The view, answering its parent's proposal", "A view, respondendo à proposta do pai"), ("Right: views choose their own size.", "Isso: as views escolhem o próprio tamanho.")),
   (F, ("The screen, which divides itself equally", "A tela, que se divide igualmente"), ("Nothing divides equally by default.", "Nada se divide igualmente por padrão.")),
   (F, ("The window group, once at launch", "O window group, uma vez na abertura"), ("Layout happens for every view, every time.", "O layout acontece para toda view, toda vez."))], drill=False),
Q("ex-vnrpkmvd", "exam", "hard",
  ("Two labels share an HStack too narrow for both. One has an ideal width of 60, the other 200. Following the model of lesson 4, which gives way?", "Dois rótulos dividem um HStack estreito demais para os dois. Um tem largura ideal de 60, o outro de 200. Seguindo o modelo da aula 4, qual cede?"),
  ("The least flexible is served first.", "O menos flexível é servido primeiro."),
  [(F, ("The 60-point one, because it is written first", "O de 60 pontos, porque vem escrito primeiro"), ("Service follows flexibility, not position.", "O serviço segue a flexibilidade, não a posição.")),
   (T, ("The 200-point one, served last with what remains", "O de 200 pontos, servido por último com o que sobra"), ("Right: the shorter label keeps its width.", "Isso: o rótulo mais curto fica com a sua largura.")),
   (F, ("Both lose the same number of points", "Os dois perdem o mesmo número de pontos"), ("The model does not split the shortfall evenly.", "O modelo não divide a falta igualmente.")),
   (F, ("Neither: the stack grows past the screen", "Nenhum: a stack cresce além da tela"), ("A stack works within what it was offered.", "Uma stack trabalha dentro do que lhe foi oferecido."))], drill=False),
Q("ex-83f264h2", "exam", "medium",
  ("What does a `GeometryReader` do with the space its parent offers?", "O que um `GeometryReader` faz com o espaço que o pai oferece?"),
  ("It returns a flexible preferred size.", "Ele devolve um tamanho preferido flexível."),
  [(T, ("Takes all of it, whatever its content needs", "Ocupa tudo, seja do que for que o conteúdo precise"), ("Right, which is why it usually needs a frame.", "Isso, e por isso quase sempre precisa de um frame.")),
   (F, ("Takes the ideal size of its content", "Fica com o tamanho ideal do conteúdo"), ("Its content decides nothing about its size.", "O conteúdo não decide nada sobre o tamanho dele.")),
   (F, ("Takes none until its content is drawn", "Não ocupa nada até o conteúdo ser desenhado"), ("It sizes itself from the proposal.", "Ele se dimensiona pela proposta.")),
   (F, ("Splits it with its siblings evenly", "Divide com os irmãos igualmente"), ("Sharing is the stack's job, not the reader's.", "Repartir é trabalho da stack, não do reader."))], drill=False),
C("ex-mca2f6a7", "exam", "easy",
  ("A view that expands along its stack's major axis, pushing siblings apart, is a ___.", "Uma view que se expande ao longo do eixo principal da stack, afastando os irmãos, é um ___."),
  ("It has a minimum length.", "Ele tem um comprimento mínimo."),
  ["Spacer"], ["Spacer"], drill=False),
M("ex-8ks4mjwp", "exam", "medium",
  ("Match each alignment to what it lines up.", "Ligue cada alinhamento ao que ele alinha."),
  ("Edges, baselines, corners.", "Bordas, linhas de base, cantos."),
  [(("`VStack(alignment: .leading)`", "`VStack(alignment: .leading)`"), ("The children's leading edges", "As bordas iniciais dos filhos")),
   (("`HStack(alignment: .firstTextBaseline)`", "`HStack(alignment: .firstTextBaseline)`"), ("The first lines of text, on the line letters sit on", "As primeiras linhas de texto, na linha em que as letras se apoiam")),
   (("`ZStack(alignment: .topTrailing)`", "`ZStack(alignment: .topTrailing)`"), ("The layers' top trailing corners", "Os cantos superiores finais das camadas"))],
  [("The order the children are served in", "A ordem em que os filhos são servidos")], drill=False),
]
