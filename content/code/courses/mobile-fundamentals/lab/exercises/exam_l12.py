"""The course exam, lesson 12: permissions. Ids are assigned by the coordinator."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "medium",
  ("A fitness app asks for location, the camera and notifications on its first screen. On iOS the person refuses all three. What has the app lost?",
   "Um app de exercícios pede localização, câmera e notificações na primeira tela. No iOS a pessoa recusa as três. O que o app perdeu?"),
  hint=H(12), choices=[
   C(False, "Nothing; it may ask again when each feature is used", "Nada; pode pedir de novo quando cada recurso for usado",
     "On iOS later requests do not show a dialog again.", "No iOS pedidos seguintes não mostram diálogo de novo."),
   C(True, "Every chance to ask for those three; only Settings brings them back", "Toda chance de pedir as três; só os Ajustes as trazem de volta",
     "Right: on iOS the first no is final.", "Isso: no iOS o primeiro não é final."),
   C(False, "Only the camera, since it is the most sensitive", "Só a câmera, por ser a mais sensível",
     "Every refused permission is final on iOS.", "Toda permissão recusada é final no iOS."),
   C(False, "One more dialog for each, after explaining", "Mais um diálogo para cada, depois de explicar",
     "That second dialog is Android's.", "Esse segundo diálogo é do Android."),
  ]),
Q(None, None, "numeric", "easy",
  ("On iOS, how many times does the system show the permission dialog for one resource, at most, without the person going to Settings?",
   "No iOS, quantas vezes no máximo o sistema mostra o diálogo de permissão para um recurso, sem a pessoa ir aos Ajustes?"),
  hint=H(12), value=1, tolerance=0),
Q(None, None, "multiple-choice", "medium",
  ("Which of these does Android's documentation ask of an app whose permission was refused? Choose all that apply.",
   "Quais destas a documentação do Android pede de um app cuja permissão foi recusada? Escolha todas as que se aplicam."),
  hint=H(12), choices=[
   C(True, "keep every feature that does not need it working", "manter funcionando todo recurso que não precisa dela", "Right.", "Isso."),
   C(True, "say specifically which feature is missing", "dizer especificamente qual recurso falta", "Right.", "Isso."),
   C(False, "block the screen until the person agrees", "bloquear a tela até a pessoa concordar",
     "It says not to block the interface.", "Ela diz para não bloquear a interface."),
   C(False, "ask again at every launch", "pedir de novo a cada abertura",
     "Persistent nagging is what it calls not respectful.", "Insistir é o que ela chama de desrespeitoso."),
  ]),
Q(None, None, "cloze", "medium",
  ("On Android, the call that tells an app to explain itself before asking a second time is shouldShowRequestPermission___().",
   "No Android, a chamada que diz a um app para se explicar antes de pedir pela segunda vez é shouldShowRequestPermission___()."),
  hint=H(12), blanks=[(["Rationale"], ["Rationale"])]),
Q(None, None, "matching", "medium",
  ("Match each situation to the state the permission is in.", "Associe cada situação ao estado em que a permissão está."),
  hint=H(12), pairs=[(("installed, never asked", "instalado, nunca pedido"), ("not asked", "não perguntada")),
         (("Android, refused once", "Android, recusada uma vez"), ("denied, with one more dialog possible", "negada, com mais um diálogo possível")),
         (("iOS, refused once", "iOS, recusada uma vez"), ("denied for good", "negada de vez")),
         (("turned on in Settings", "ligada nos Ajustes"), ("granted", "concedida"))],
  distractors=[("granted automatically after a week", "concedida sozinha depois de uma semana")]),
]
