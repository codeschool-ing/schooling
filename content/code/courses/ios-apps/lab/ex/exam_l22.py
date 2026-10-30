import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-f4n4w1hz", "app-store-connect", "medium",
  ("Why can a new app record not be added on a fresh membership, according to App Store Connect help?", "Por que um registro de app novo pode não ser acrescentado numa assinatura recém-feita, segundo a ajuda do App Store Connect?"),
  ("The Business section.", "A seção Business."),
  [(F, ("The bundle identifier needs a week to activate", "O bundle identifier precisa de uma semana para ativar"), ("Nothing like that is described.", "Nada disso é descrito.")),
   (T, ("The Account Holder has not signed the latest agreement", "O Account Holder não assinou o acordo mais recente"), ("Right: it has to be signed in Business first.", "Isso: ele tem de ser assinado em Business antes.")),
   (F, ("Only Developers may add records", "Só Developers podem acrescentar registros"), ("Account Holder, App Manager or Admin may.", "Account Holder, App Manager ou Admin podem.")),
   (F, ("A first TestFlight build is required", "É exigido um primeiro build no TestFlight"), ("The record comes before any build.", "O registro vem antes de qualquer build."))], drill=False),
N("ex-ca635g4b", "testflight", "easy",
  ("At most how many internal testers can a TestFlight build have, according to the overview?", "No máximo quantos testadores internos um build do TestFlight pode ter, segundo o overview?"),
  ("App Store Connect users.", "Usuários do App Store Connect."),
  100, 0, None, drill=False),
Q("ex-3ad7sx50", "privacy-labels", "medium",
  ("The planner sends a request to a server that answers and keeps nothing. Is that data collected, in Apple's definition?", "O planner manda um pedido a um servidor que responde e não guarda nada. Esse dado é coletado, na definição da Apple?"),
  ("Longer than the request needs.", "Por mais tempo que o pedido exige."),
  [(T, ("No: it is not kept beyond the request", "Não: ele não é guardado além do pedido"), ("Right: discarded after servicing the request is not collecting.", "Isso: descartado depois de atender o pedido não é coletar.")),
   (F, ("Yes: anything sent off the phone is collected", "Sim: tudo o que sai do telefone é coletado"), ("The definition adds being kept longer than needed.", "A definição acrescenta ser guardado mais que o necessário.")),
   (F, ("Yes, and it is used to track", "Sim, e é usado para rastrear"), ("Tracking is sharing for advertising.", "Rastrear é dividir para publicidade.")),
   (F, ("Only if the server is in another country", "Só se o servidor estiver em outro país"), ("Where it is does not decide.", "Onde ele fica não decide."))], drill=False),
Q("ex-aa1cqs4m", "review-guidelines", "hard",
  ("A planner with one screen that shows a sum is submitted. Which guideline is it most at risk of?", "Um planner com uma tela que mostra uma soma é enviado. De qual diretriz ele mais corre risco?"),
  ("Not much functionality.", "Pouca funcionalidade."),
  [(F, ("5.1.1, since it stores a plan", "5.1.1, já que guarda um plano"), ("Storing a plan is not the risk here.", "Guardar um plano não é o risco aqui.")),
   (F, ("2.3, since the name is short", "2.3, já que o nome é curto"), ("A short name is fine.", "Um nome curto está bem.")),
   (T, ("4.2, Minimum Functionality", "4.2, Minimum Functionality"), ("Right: an app that does little may not be approved.", "Isso: um app que faz pouco pode não ser aprovado.")),
   (F, ("1.3, for children's apps with ads", "1.3, para apps infantis com anúncios"), ("The planner has no ads.", "O planner não tem anúncios."))], drill=False),
M("ex-bydqx989", "rejections", "medium",
  ("Match each rejection to its answer, from section 07.", "Ligue cada rejeição à sua resposta, da seção 07."),
  ("The table in section 07.", "A tabela da seção 07."),
  [(("No demo account given", "Nenhuma conta de demonstração"), ("Add one in App Review Information", "Acrescentar uma em App Review Information")),
   (("The camera prompt does not explain the use", "O pedido da câmera não explica o uso"), ("Rewrite the usage string", "Reescrever a frase de uso")),
   (("Accounts cannot be deleted", "Contas não podem ser apagadas"), ("Add deletion inside the app", "Acrescentar exclusão dentro do app"))],
  [("Ask for an expedited review", "Pedir revisão acelerada")], drill=False),
]
