import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-fzpvcwnj", "labels-values", "medium",
  ("A list of sessions changes one row from not done to done. With the state in the value, what does VoiceOver do?", "Uma lista de sessões muda uma linha de não feita para feita. Com o estado no valor, o que o VoiceOver faz?"),
  ("A value is what changes.", "O valor é o que muda."),
  [(F, ("Reads the whole label again from the start", "Lê o rótulo inteiro de novo desde o começo"), ("The label did not change.", "O rótulo não mudou.")),
   (T, ("Announces the new value", "Anuncia o valor novo"), ("Right: that is why state and label are kept apart.", "Isso: é por isso que estado e rótulo ficam separados.")),
   (F, ("Nothing until the screen is reloaded", "Nada até a tela recarregar"), ("A value change is announced as it happens.", "Uma mudança de valor é anunciada quando acontece.")),
   (F, ("Moves the focus to the top of the list", "Leva o foco para o topo da lista"), ("Focus stays where the person is.", "O foco fica onde a pessoa está."))], drill=False),
Q("ex-ha57w085", "traits", "medium",
  ("Why is a tappable `Image` with `onTapGesture` worse than a `Button` for a switch-control user too?", "Por que uma `Image` tocável com `onTapGesture` é pior que um `Button` também para quem usa controle por botão?"),
  ("Who knows it is a control?", "Quem sabe que é um controle?"),
  [(T, ("Only a `Button` is known to the system as something to activate", "Só um `Button` é conhecido pelo sistema como algo a ativar"), ("Right: the trait is what every assistive technology reads.", "Isso: o trait é o que toda tecnologia assistiva lê.")),
   (F, ("Images cannot be tapped by switch control", "Imagens não podem ser tocadas por controle por botão"), ("The problem is not knowing it is a control.", "O problema é não saber que é controle.")),
   (F, ("A `Button` is larger on screen", "Um `Button` é maior na tela"), ("Size depends on the content, not on the type.", "O tamanho depende do conteúdo, não do tipo.")),
   (F, ("`onTapGesture` is not available on iOS 17", "O `onTapGesture` não existe no iOS 17"), ("It exists; it just carries no trait.", "Existe; só não carrega trait."))], drill=False),
N("ex-pgdardg3", "contrast", "medium",
  ("`contrast.swift` measured the bright green tick on white. What ratio did it print? Give the first number, to two decimals.", "O `contrast.swift` mediu o visto verde vivo no branco. Que razão ele imprimiu? Dê o primeiro número, com duas casas."),
  ("It failed even as an icon.", "Falhou até como ícone."),
  2.22, 0, None, drill=False),
Q("ex-c56vhp66", "dynamic-type", "hard",
  ("A designer asks to cap the whole planner at the `large` text size so the layout never breaks. What is the course's answer?", "Um designer pede para limitar o planner inteiro no tamanho `large` para o layout nunca quebrar. Qual é a resposta do curso?"),
  ("Who chose the size?", "Quem escolheu o tamanho?"),
  [(F, ("Accept: layout stability is worth it", "Aceitar: estabilidade de layout vale a pena"), ("It removes the setting from the people who need it most.", "Tira o ajuste de quem mais precisa.")),
   (F, ("Accept, and use `.minimumScaleFactor` above it", "Aceitar, e usar `.minimumScaleFactor` acima disso"), ("Shrinking is the same refusal.", "Encolher é a mesma recusa.")),
   (T, ("Refuse: adapt the layout and keep the person's size", "Recusar: quem lê escolhe, e a tela se adapta"), ("Right: the cap is for the rare control that cannot grow.", "Isso: o limite é para o raro controle que não pode crescer.")),
   (F, ("Refuse, and use fixed point sizes instead", "Recusar, e usar tamanhos fixos em pontos"), ("Fixed sizes ignore the setting entirely.", "Tamanhos fixos ignoram o ajuste de vez."))], drill=False),
M("ex-mc0dvf2v", "grouping", "medium",
  ("Match each part of the planner to the grouping section 04 gives it.", "Ligue cada parte do planner ao agrupamento que a seção 04 lhe dá."),
  ("A button inside must stay a stop.", "Um botão dentro tem de continuar parada."),
  [(("A session row", "Uma linha de sessão"), ("`.ignore`, with its own label and value", "`.ignore`, com rótulo e valor próprios")),
   (("A course row with an *Add session* button", "Uma linha de curso com botão *Add session*"), ("`.contain`", "`.contain`")),
   (("A divider between weeks", "Um divisor entre semanas"), ("Hidden", "Escondido"))],
  [("`.combine`, with the button merged in", "`.combine`, com o botão fundido")], drill=False),
]
