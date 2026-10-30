"""Lesson 13: the camera's three answers, and the photo component annotated."""
import pathlib
from fig import Fig

T = {
 "en": dict(aria="A flow chart. The person presses Take a photo, and the app asks for the camera. If it is granted, the system camera opens. If it is refused and canAskAgain is true, the app explains what is lost and offers to choose a photo instead; it may ask again next time. If it is refused and canAskAgain is false, the app explains and offers a button that opens Settings.",
   press="Take a photo", ask="requestCameraPermissionsAsync()", yes="granted", no="refused", again="canAskAgain", camera="the system camera opens",
   explain="explain what is lost,", explain2="offer the library", settings="explain, and offer", settings2="Open Settings", t="true", f="false",
   cap="One request, three outcomes. Only the person can undo a final refusal, so the app's last move is to show them where."),
 "pt": dict(aria="Um fluxograma. A pessoa aperta Take a photo, e o app pede a câmera. Se ela é concedida, a câmera do sistema abre. Se é recusada e canAskAgain é true, o app explica o que se perde e oferece escolher uma foto; pode pedir de novo na próxima vez. Se é recusada e canAskAgain é false, o app explica e oferece um botão que abre os Ajustes.",
   press="Take a photo", ask="requestCameraPermissionsAsync()", yes="concedida", no="recusada", again="canAskAgain", camera="a câmera do sistema abre",
   explain="explicar o que se perde,", explain2="oferecer a galeria", settings="explicar, e oferecer", settings2="Open Settings", t="true", f="false",
   cap="Um pedido, três desfechos. Só a pessoa desfaz uma recusa definitiva, então o último passo do app é mostrar onde."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l13-ask", 720, 270, t["aria"])
    f.box(20, 30, 130, 36, [t["press"]], stroke="phosphor")
    f.box(200, 30, 230, 36, [t["ask"]], mono=True, stroke="amber", size=9.5)
    f.arrow([(150, 48), (200, 48)])
    f.box(500, 30, 200, 36, [t["camera"]], stroke="phosphor")
    f.arrow([(430, 48), (500, 48)])
    f.text(465, 40, t["yes"], size=9, fill="phosphor", italic=True)
    f.box(240, 120, 150, 36, [t["again"]], mono=True, size=9.5)
    f.arrow([(315, 66), (315, 120)])
    f.text(335, 94, t["no"], size=9, fill="amber", italic=True, anchor="start")
    f.box(60, 200, 210, 44, [t["explain"], t["explain2"]])
    f.box(400, 200, 210, 44, [t["settings"], t["settings2"]], stroke="amber")
    f.arrow([(270, 156), (165, 200)])
    f.arrow([(360, 156), (505, 200)])
    f.text(196, 172, t["t"], mono=True, size=9, fill="paper-dim")
    f.text(452, 172, t["f"], mono=True, size=9, fill="paper-dim")
    same = None if lang == "en" else ["Take a photo", "Open Settings"]
    return {"l13-ask": f.json(caption=t["cap"], same=same)}


SRC = (pathlib.Path(__file__).parent.parent / "src" / "l13" / "NotesPhoto.tsx").read_text().rstrip("\n").split("\n")
blocks, cur = [], []
for line in SRC:
    if line == "" and cur:
        blocks.append(cur); cur = []
    else:
        cur.append(line)
blocks.append(cur)
NOTES = [
 ("The picker library, imported whole as `ImagePicker` so every call says where it comes from, and `keepPhoto`, which the section on files writes.",
  "A biblioteca do seletor, importada inteira como `ImagePicker` para cada chamada dizer de onde vem, e o `keepPhoto`, que a seção sobre arquivos escreve."),
 ("**The same options for both ways in**: images only, and a JPEG quality of 0.7, from 0 to 1, which keeps a photo of a page legible at a fraction of the size. The camera's state has a name for each answer that matters.",
  "**As mesmas opções para os dois caminhos**: só imagens, e qualidade JPEG de 0,7, de 0 a 1, que mantém legível a foto de uma página com uma fração do tamanho. O estado da câmera tem um nome para cada resposta que importa."),
 ("One photo per course, kept in state for now: lesson 14 is where it survives a restart.",
  "Uma foto por curso, guardada em estado por enquanto: a aula 14 é onde ela sobrevive a reiniciar o app."),
 ("**Both pickers answer the same way**: `canceled`, and when it is false, `assets`, one per photo. A cancelled picker leaves everything as it was.",
  "**Os dois seletores respondem do mesmo jeito**: `canceled` e, quando ele é falso, `assets`, um por foto. Um seletor cancelado deixa tudo como estava."),
 ("Choosing asks for nothing, for the reason the first section gave: the system's picker hands over only what the person picked.",
  "Escolher não pede nada, pelo motivo que a primeira seção deu: o seletor do sistema entrega só o que a pessoa escolheu."),
 ("**Taking a photo asks first, every time.** Once the answer is a yes or a final no, the request returns it at once, with no dialog. A refusal ends here, with the state saying which kind.",
  "**Tirar uma foto pede antes, toda vez.** Quando a resposta é um sim ou um não definitivo, o pedido a devolve na hora, sem diálogo. Uma recusa termina aqui, com o estado dizendo de que tipo."),
 ("Two buttons, and a sentence for each refusal. Each is a `role=\"alert\"`, announced when it appears, and says what the person can do. Only the final refusal offers Settings, through `Linking.openSettings()`, which opens the app's own page there.",
  "Dois botões, e uma frase para cada recusa. Cada uma é um `role=\"alert\"`, anunciado quando aparece, e diz o que a pessoa pode fazer. Só a recusa definitiva oferece os Ajustes, pelo `Linking.openSettings()`, que abre a página do próprio app lá."),
 ("The photo fills the width, in a 4:3 frame, and `contain` shows all of it whatever its shape.",
  "A foto ocupa a largura, num quadro de 4:3, e o `contain` a mostra inteira, seja qual for o formato."),
]
assert len(blocks) == len(NOTES), len(blocks)
parts = [("\n".join(b) + ("\n" if i < len(blocks) - 1 else ""), en, pt) for i, (b, (en, pt)) in enumerate(zip(blocks, NOTES))]
EXAMPLES = {"picker": [{"language": "tsx", "file": "src/NotesPhoto.tsx", "parts": parts}]}
