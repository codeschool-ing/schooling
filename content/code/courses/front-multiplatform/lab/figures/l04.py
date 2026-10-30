"""Lesson 4: the annotated src/device.ts, and the permission figure."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent / "l04-device.ts").read_text().rstrip("\n")
chunks = SRC.split("\n\n")
NOTES = [
 ("One import per plugin, each from its own package, and the planner's types. Nothing here touches the DOM; `view.ts` still draws everything.",
  "Um import por plugin, cada um do seu pacote, e os tipos do planner. Nada aqui toca o DOM; o `view.ts` continua desenhando tudo."),
 ("**Preferences** keeps small strings under a key. The plan is turned into JSON on the way in and back on the way out, and a key that was never set comes back as `null`.",
  "O **Preferences** guarda textos pequenos sob uma chave. O plano vira JSON na entrada e volta na saída, e uma chave que nunca foi gravada volta como `null`."),
 ("", ""),
 ("**Filesystem** writes the plan into the app's own data folder, and reads it back to prove the file is there. `Directory.Data` is private to the app and needs no permission.",
  "O **Filesystem** escreve o plano na pasta de dados do próprio app, e o lê de volta para provar que o arquivo está lá. `Directory.Data` é privada do app e não exige permissão."),
 ("**LocalNotifications** asks first, and gives up with the answer if it was not a yes. Then it schedules one notification at eight in the morning of the session's day, with the session's number as its id.",
  "O **LocalNotifications** pergunta primeiro, e desiste com a resposta se ela não foi sim. Depois agenda uma notificação às oito da manhã do dia da sessão, com o número da sessão como id."),
 ("**Geolocation** asks the device where it is. The permission question happens inside this call, the first time.",
  "O **Geolocation** pergunta ao aparelho onde ele está. A pergunta de permissão acontece dentro desta chamada, na primeira vez."),
 ("**Camera** opens the camera, or on the web a file picker. `webPath` is an address the page can load, and the function reports the picture's type and size.",
  "A **Camera** abre a câmera, ou na web um seletor de arquivo. `webPath` é um endereço que a página consegue carregar, e a função informa o tipo e o tamanho da imagem."),
]
assert len(chunks) == len(NOTES), (len(chunks), len(NOTES))
parts = []
for i, (c, (en, pt)) in enumerate(zip(chunks, NOTES)):
    parts.append((c + ("\n" if i < len(chunks) - 1 else ""), en, pt))
EXAMPLES = {"the-new-code": [{"language": "typescript", "file": "src/device.ts", "parts": parts}]}

T = {
 "en": dict(aria="What happens the first time the planner asks for the location. The call goes to the plugin, which checks the permission. If it was never asked, the system shows its dialog with the sentence from Info.plist or the system's own text on Android. A yes is remembered and the position comes back; a no is remembered too, and later calls fail at once without asking again, until the person changes it in the system settings.",
   a=["your code calls", "getCurrentPosition()"], b=["the plugin checks", "the permission"], c=["never asked:", "the system asks"],
   yes=["granted: the position", "comes back"], no=["denied: the call fails,", "and fails again later"], again="only the system's settings undo a no",
   cap="The dialog is the system's, shown once. What your app controls is when it asks, and what it does with a no."),
 "pt": dict(aria="O que acontece na primeira vez que o planner pede a localização. A chamada vai ao plugin, que confere a permissão. Se ela nunca foi pedida, o sistema mostra o diálogo dele, com a frase do Info.plist ou o texto do próprio sistema no Android. Um sim fica guardado e a posição volta; um não também fica guardado, e as chamadas seguintes falham na hora sem perguntar de novo, até a pessoa mudar isso nas configurações do sistema.",
   a=["o seu código chama", "getCurrentPosition()"], b=["o plugin confere", "a permissão"], c=["nunca pedida:", "o sistema pergunta"],
   yes=["concedida: a posição", "volta"], no=["negada: a chamada falha,", "e falha de novo depois"], again="só os ajustes do sistema desfazem um não",
   cap="O diálogo é do sistema, mostrado uma vez. O que o seu app controla é quando pergunta, e o que faz com um não."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l04-permission", 720, 200, t["aria"])
    f.box(20, 70, 150, 50, t["a"], stroke="wire", size=9.5)
    f.box(200, 70, 150, 50, t["b"], stroke="phosphor", size=9.5)
    f.box(380, 70, 140, 50, t["c"], stroke="amber", size=9.5)
    f.box(550, 20, 150, 50, t["yes"], stroke="phosphor", size=9.5)
    f.box(550, 120, 150, 50, t["no"], stroke="amber", size=9.5)
    f.arrow([(170, 95), (200, 95)])
    f.arrow([(350, 95), (380, 95)])
    f.arrow([(520, 85), (550, 50)])
    f.arrow([(520, 105), (550, 140)])
    f.text(625, 188, t["again"], size=8.5, fill="paper-dim", italic=True)
    return {"l04-permission": f.json(t["cap"], same=None if lang == "en" else ["getCurrentPosition()"])}
