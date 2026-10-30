"""The course exam, lesson 4: the app lifecycle."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "medium",
  ("An app is suspended and the system needs its memory. Which code of the app runs before the process is gone?",
   "Um app está suspenso e o sistema precisa da memória dele. Que código do app roda antes de o processo sumir?"),
  hint=H(4), choices=[
   C(False, "onDestroy on Android, applicationWillTerminate on iOS", "onDestroy no Android, applicationWillTerminate no iOS",
     "Neither is called for a suspended app that the system terminates.", "Nenhum dos dois é chamado para um app suspenso que o sistema encerra."),
   C(True, "None", "Nenhum", "Right: suspended means no code runs, and the kill is silent.", "Isso: suspenso quer dizer que nenhum código roda, e a morte é silenciosa."),
   C(False, "A cleanup function the app registered at launch", "Uma função de limpeza que o app registrou ao abrir", "Nothing registered in a frozen process gets to run.", "Nada registrado num processo congelado chega a rodar."),
   C(False, "onPause, once more", "onPause, mais uma vez", "onPause already ran when the app left the foreground.", "onPause já rodou quando o app saiu do primeiro plano."),
  ]),
Q(None, None, "matching", "medium",
  ("Match each React Native AppState value to the state of the shared model.", "Associe cada valor do AppState do React Native ao estado do modelo compartilhado."),
  hint=H(4), pairs=[(("active", "active"), ("in front, receiving touches", "na frente, recebendo toques")),
                    (("inactive", "inactive"), ("interrupted while visible, on iOS", "interrompido e visível, no iOS")),
                    (("background", "background"), ("not visible", "não visível"))],
  distractors=[("killed, reported just before the process ends", "morto, informado logo antes de o processo acabar")]),
Q(None, None, "quiz", "hard",
  ("A user is writing in a form when a full-screen call arrives; she answers, talks for two minutes on a phone with plenty of free memory, and comes back. What does the app most likely see on Android?",
   "Uma usuária está escrevendo num formulário quando chega uma ligação em tela cheia; ela atende, fala dois minutos num celular com bastante memória livre, e volta. O que o app mais provavelmente vê no Android?"),
  hint=H(4), choices=[
   C(False, "onDestroy, then onCreate with an empty form", "onDestroy, depois onCreate com o formulário vazio",
     "Nothing destroyed the Activity; it was only stopped.", "Nada destruiu a Activity; ela só foi parada."),
   C(True, "onPause and onStop, then onRestart, onStart and onResume, with the form intact", "onPause e onStop, depois onRestart, onStart e onResume, com o formulário intacto",
     "Right: the process stayed alive throughout.", "Isso: o processo ficou vivo o tempo todo."),
   C(False, "No callbacks at all, because calls are handled by the system", "Nenhum callback, porque ligações são tratadas pelo sistema",
     "The call's screen covers the app, and Android says so.", "A tela da ligação cobre o app, e o Android avisa."),
   C(False, "Only onPause, because a call never stops an Activity", "Só onPause, porque uma ligação nunca para uma Activity",
     "A full-screen call makes the Activity invisible, which is onStop.", "Uma ligação em tela cheia deixa a Activity invisível, o que é onStop."),
  ]),
Q(None, None, "cloze", "easy",
  ("On iOS, a scene that is visible but interrupted, for example by a system alert, is in the ___ phase.",
   "No iOS, uma cena visível mas interrompida, por exemplo por um alerta do sistema, está na fase ___."),
  hint=H(4), blanks=[(["inactive", ".inactive"], ["inactive", ".inactive", "inativa"])], ignore_case=True),
Q(None, None, "numeric", "easy",
  ("How many callbacks does Android call on an Activity that comes back to the foreground from the stopped state?",
   "Quantos callbacks o Android chama numa Activity que volta ao primeiro plano a partir do estado parado?"),
  hint=H(4), value=3, tolerance=0),
]
