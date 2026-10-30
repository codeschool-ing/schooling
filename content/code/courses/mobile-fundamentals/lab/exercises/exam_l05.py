"""The course exam, lesson 5: saving and restoring state."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "medium",
  ("A notes app keeps the note being edited only in a ViewModel. The user rotates the phone, then later leaves the app for an hour while playing a game. What survives each event?",
   "Um app de notas guarda a nota em edição só num ViewModel. O usuário gira o celular, e depois sai do app por uma hora jogando um jogo. O que sobrevive a cada evento?"),
  hint=H(5), choices=[
   C(False, "Both: a ViewModel is kept by the system", "Os dois: um ViewModel é guardado pelo sistema",
     "A ViewModel is kept in the process, and the process can be killed.", "Um ViewModel fica no processo, e o processo pode ser morto."),
   C(True, "The rotation, yes; a kill during the hour, no", "A rotação, sim; uma morte durante a hora, não",
     "Right: ViewModels are destroyed in a system-initiated process death.", "Isso: ViewModels são destruídos numa morte de processo iniciada pelo sistema."),
   C(False, "Neither: a rotation clears every ViewModel", "Nenhum: uma rotação apaga todo ViewModel", "Surviving the rotation is what a ViewModel is for.", "Sobreviver à rotação é para isso que serve um ViewModel."),
   C(False, "The hour, yes; the rotation, no", "A hora, sim; a rotação, não", "That reverses the table.", "Isso inverte a tabela."),
  ]),
Q(None, None, "matching", "medium",
  ("Match each piece of a shopping app's screen to where it belongs.", "Associe cada pedaço da tela de um app de compras ao lugar a que pertence."),
  hint=H(5), pairs=[(("the items in the user's basket", "os itens na cesta do usuário"), ("persistent storage", "armazenamento persistente")),
                    (("the id of the product being viewed", "o id do produto sendo visto"), ("saved state", "estado salvo")),
                    (("the basket's total price", "o preço total da cesta"), ("recomputed from the data", "recalculado a partir dos dados"))],
  distractors=[("a copy of the whole catalogue in saved state", "uma cópia do catálogo inteiro no estado salvo")]),
Q(None, None, "numeric", "easy",
  ("Android's guide gives the Binder transaction buffer, shared by the whole process, a size of how many megabytes?",
   "O guia do Android dá ao buffer de transações do Binder, compartilhado pelo processo inteiro, um tamanho de quantos megabytes?"),
  hint=H(5), value=1, tolerance=0),
Q(None, None, "quiz", "hard",
  ("A React Native app writes its half-filled form to its own storage on every trip to the background and reads it at launch. A user submits the form, closes the app, and opens it a week later. What has the developer forgotten if the old form reappears?",
   "Um app React Native grava o formulário pela metade no próprio armazenamento a cada ida ao segundo plano e o lê ao abrir. Um usuário envia o formulário, fecha o app e o abre uma semana depois. O que quem desenvolve esqueceu se o formulário antigo reaparecer?"),
  hint=H(5), choices=[
   C(False, "To ask for the storage permission", "Pedir a permissão de armazenamento", "An app's own storage needs no permission.", "O armazenamento do próprio app não precisa de permissão."),
   C(False, "To use @SceneStorage instead", "Usar @SceneStorage no lugar", "That is SwiftUI's, not React Native's.", "Esse é do SwiftUI, não do React Native."),
   C(True, "To clear the saved draft when the form is submitted", "Apagar o rascunho salvo quando o formulário é enviado",
     "Right: storage the app writes itself survives everything until the app removes it.", "Isso: um armazenamento que o próprio app grava sobrevive a tudo até o app removê-lo."),
   C(False, "To save on the way to the background", "Salvar no caminho para o segundo plano", "It does; the problem is that it never forgets.", "Ele salva; o problema é que nunca esquece."),
  ]),
Q(None, None, "cloze", "medium",
  ("On Android 7.0 and later, saved state larger than the Binder buffer allows makes the system throw a ___.",
   "No Android 7.0 em diante, um estado salvo maior do que o buffer do Binder permite faz o sistema lançar uma ___."),
  hint=H(5), blanks=[(["TransactionTooLargeException"], ["TransactionTooLargeException"])], ignore_case=True),
]
