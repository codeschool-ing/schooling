import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-vyxj0ht5", "swift-testing", "medium",
  ("Swift Testing runs tests in parallel by default. What does that demand of the tests?", "O Swift Testing roda testes em paralelo por padrão. O que isso exige dos testes?"),
  ("Order is not guaranteed.", "A ordem não é garantida."),
  [(F, ("That each test is marked `async`", "Que cada teste seja marcado `async`"), ("Synchronous tests run in parallel too.", "Testes síncronos também rodam em paralelo.")),
   (T, ("That no test depends on another having run first", "Que nenhum teste dependa de outro ter rodado antes"), ("Right: a test that does fails on some days.", "Isso: um teste assim falha em alguns dias.")),
   (F, ("That tests share one fixture to save time", "Que os testes dividam um fixture para poupar tempo"), ("Shared mutable state is what parallel runs break.", "Estado mutável dividido é o que execuções paralelas quebram.")),
   (F, ("That the machine has one core per test", "Que a máquina tenha um núcleo por teste"), ("The framework schedules them on what there is.", "O framework os distribui no que houver."))], drill=False),
Q("ex-dq2vpcwn", "parameterised", "medium",
  ("A parameterised test has seven arguments and one of them fails. What does the report show?", "Um teste parametrizado tem sete argumentos e um deles falha. O que o relatório mostra?"),
  ("Each run is a case of its own.", "Cada execução é um caso próprio."),
  [(F, ("Only that the test failed, with no argument", "Só que o teste falhou, sem argumento"), ("Each failing case is named by its argument.", "Cada caso que falha é nomeado pelo argumento.")),
   (F, ("Seven failures, since one case fails them all", "Sete falhas, já que um caso derruba todos"), ("The other six cases pass on their own.", "Os outros seis casos passam sozinhos.")),
   (T, ("The failing argument, and both sides of the comparison", "O argumento que falhou, e os dois lados da comparação"), ("Right: the `↳` lines print each side.", "Isso: as linhas `↳` imprimem cada lado.")),
   (F, ("Nothing until every case has been fixed", "Nada até todo caso ser corrigido"), ("It reports as it runs.", "Ele relata enquanto roda."))], drill=False),
N("ex-8mnvkxxr", "what-to-test", "medium",
  ("`llvm-cov report` printed the package's total line coverage. What percentage? Give it to two decimals.", "O `llvm-cov report` imprimiu a cobertura total de linhas do pacote. Que porcentagem? Dê com duas casas."),
  ("The `TOTAL` row, last column.", "A linha `TOTAL`, última coluna."),
  95.16, 0.01, None, drill=False),
Q("ex-as29737h", "ui-tests", "hard",
  ("A team wants a UI test for every rule the planner has. What is the course's objection?", "Um time quer um teste de interface para cada regra do planner. Qual é a objeção do curso?"),
  ("Where do the rules live?", "Onde moram as regras?"),
  [(T, ("The rules are tested faster, anywhere, in the package", "As regras são testadas mais rápido, em qualquer lugar, no pacote"), ("Right: UI tests stay few, for flows.", "Isso: testes de interface ficam poucos, para fluxos.")),
   (F, ("UI tests cannot check numbers", "Testes de interface não conferem números"), ("They can read a label; they are just slow and Mac-only.", "Eles leem um rótulo; só são lentos e só no Mac.")),
   (F, ("Xcode limits a project to ten UI tests", "O Xcode limita um projeto a dez testes de interface"), ("There is no such limit.", "Não existe esse limite.")),
   (F, ("UI tests need a paid developer account", "Testes de interface precisam de conta paga"), ("They run in the simulator for free.", "Rodam no simulador de graça."))], drill=False),
C("ex-xkwhbmaq", "xctest", "easy",
  ("In XCTest a test method's name has to start with ___.", "No XCTest o nome de um método de teste tem de começar com ___."),
  ("`testMondayOfASunday`.", "`testMondayOfASunday`."),
  ["test"], ["test"], drill=False),
]
