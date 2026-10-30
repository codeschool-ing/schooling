"""Exam questions for lesson 6: the main thread, jank, and the frame budget."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q("@", "", "numeric", "easy",
  ("A display refreshes 90 times a second. How many milliseconds is the budget for one frame? Give two decimal places.",
   "Uma tela se atualiza 90 vezes por segundo. Quantos milissegundos é o orçamento de um quadro? Responda com duas casas decimais."),
  hint=H(6), value=11.11, tolerance=0.01, unit=("ms", "ms")),
Q("@", "", "quiz", "medium",
  ("An Android app sorts 50,000 items inside the click handler of a button, and the list behind it stutters. Which change fixes the stutter rather than hiding it?",
   "Um app Android ordena 50 mil itens dentro do tratador de clique de um botão, e a lista atrás dele dá trancos. Qual mudança corrige os trancos em vez de escondê-los?"),
  hint=H(6), choices=[
   C(False, "Run the sort twice as fast by using a phone with more cores", "Rodar a ordenação no dobro da velocidade com um celular de mais núcleos",
     "Extra cores do nothing for work that stays on the main thread.", "Núcleos a mais não fazem nada por um trabalho que continua na thread principal."),
   C(True, "Sort off the main thread, show on it", "Ordenar fora da thread principal e mostrar nela",
     "Right: off the main thread, and back to it for the screen.", "Isso: fora da thread principal, e de volta a ela para a tela."),
   C(False, "Turn on StrictMode in the release build", "Ligar o StrictMode no build de produção",
     "StrictMode reports disk and network on the main thread; it moves nothing.", "O StrictMode aponta disco e rede na thread principal; ele não muda nada de lugar."),
   C(False, "Sort on a worker thread and set the list from that thread", "Ordenar numa thread de trabalho e definir a lista a partir dela",
     "Touching the UI toolkit from another thread breaks Android's second rule.", "Mexer no kit de interface a partir de outra thread quebra a segunda regra do Android."),
  ]),
Q("@", "", "quiz", "medium",
  ("A frame's work takes 18 ms on a 60 Hz screen. What happens to that frame?",
   "O trabalho de um quadro leva 18 ms numa tela de 60 Hz. O que acontece com esse quadro?"),
  hint=H(6), choices=[
   C(False, "It is shown 1.33 ms late", "Ele é mostrado 1,33 ms atrasado",
     "A frame that misses its slot is not shown late.", "Um quadro que perde o espaço não aparece atrasado."),
   C(False, "The app is closed by the system", "O app é fechado pelo sistema",
     "That needs seconds, not 18 ms.", "Isso exige segundos, não 18 ms."),
   C(True, "It is dropped; the old picture stays", "É descartado; a imagem antiga fica",
     "Right: overrunning the slot by any amount loses the frame.", "Isso: passar do espaço por qualquer margem perde o quadro."),
   C(False, "Nothing visible; 18 ms is inside the budget", "Nada visível; 18 ms cabe no orçamento",
     "The budget at 60 Hz is 16.67 ms.", "O orçamento a 60 Hz é de 16,67 ms."),
  ]),
Q("@", "", "cloze", "medium",
  ("A crash report from an iOS app terminated by the watchdog for an unresponsive main thread carries the code ___.",
   "Um relatório de falha de um app iOS encerrado pelo watchdog por uma thread principal sem resposta traz o código ___."),
  hint=H(6), blanks=[(["0x8badf00d"], ["0x8badf00d"])], ignore_case=True),
Q("@", "", "quiz", "hard",
  ("In a React Native app, a fetch returns a 5 MB JSON response and the screen freezes for a moment when it arrives, although the request itself was asynchronous. Where is the time going?",
   "Num app React Native, um fetch devolve uma resposta JSON de 5 MB e a tela congela por um instante quando ela chega, embora o pedido em si fosse assíncrono. Para onde vai o tempo?"),
  hint=H(6), choices=[
   C(True, "Parsing the JSON, which runs to the end on the JavaScript thread", "Na interpretação do JSON, que roda até o fim na thread de JavaScript",
     "Right: the wait was off the thread, the parse is on it.", "Isso: a espera foi fora da thread, a interpretação é nela."),
   C(False, "The network wait, which holds the JavaScript thread", "Na espera da rede, que segura a thread de JavaScript",
     "fetch does not hold the thread while it waits.", "O fetch não segura a thread enquanto espera."),
   C(False, "The native main thread drawing the JSON", "Na thread principal nativa desenhando o JSON",
     "Nothing draws JSON; the parse is JavaScript work.", "Nada desenha JSON; a interpretação é trabalho de JavaScript."),
   C(False, "The watchdog pausing the app to inspect the data", "No watchdog pausando o app para inspecionar os dados",
     "The watchdog terminates unresponsive apps; it does not inspect data.", "O watchdog encerra apps sem resposta; ele não inspeciona dados."),
  ]),
]
