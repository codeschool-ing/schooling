"""Lesson 17 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-zajskzvj"

f = Fig("l17-push", 720, 330,
        "Three columns, from left to right: the planner on the phone, Apple's Push Notification service, and the planner's server. Time runs downwards. First the app asks APNs to register and receives a device token. Second the app sends that token to the planner's server, which stores it with the account. Later, when a session is added on another device, the server sends a payload with the token to APNs, and APNs delivers it to the phone, which shows it.",
        "Três colunas, da esquerda para a direita: o planner no telefone, o serviço de notificações push da Apple, e o servidor do planner. O tempo corre para baixo. Primeiro o app pede registro ao APNs e recebe um token do aparelho. Depois o app envia esse token ao servidor do planner, que o guarda com a conta. Mais tarde, quando uma sessão é acrescentada em outro aparelho, o servidor envia ao APNs um payload com o token, e o APNs o entrega ao telefone, que o mostra.")
cols = [(110, "the planner, on the phone", "o planner, no telefone"), (360, "APNs", "APNs"), (610, "the planner's server", "o servidor do planner")]
for x, en, pt in cols:
    f.box(x - 95, 16, 190, 34, stroke="wire")
    f.text(x, 33, en, pt, size=11, fill="paper", weight="600")
    f.line(x, 52, x, 312, color="wire", dashed=True, arrow=False, sw=1)
f.line(114, 82, 356, 82, color="phosphor")
f.text(235, 72, "registerForRemoteNotifications()", mono=True, size=10, fill="phosphor")
f.line(356, 118, 114, 118, color="phosphor")
f.text(235, 108, "device token", "token do aparelho", size=10, fill="phosphor")
f.line(114, 160, 606, 160, color="amber")
f.text(360, 150, "the token, sent once per launch and stored with the account", "o token, enviado a cada abertura e guardado com a conta", size=10, fill="amber")
f.text(610, 196, "later: a session added elsewhere", "depois: uma sessão acrescentada em outro lugar", size=10, fill="paper-dim")
f.line(606, 236, 364, 236, color="amber")
f.text(485, 226, "payload + token", "payload + token", size=10, fill="amber")
f.line(356, 276, 114, 276, color="amber")
f.text(235, 266, "the notification", "a notificação", size=10, fill="amber")
f.write(lesson(L, "remote"),
        "The token goes from the phone to the server, again at every launch; every notification then goes from the server to APNs, and from APNs to the phone.",
        "O token vai do telefone ao servidor, de novo a cada abertura; toda notificação vai então do servidor ao APNs, e do APNs ao telefone.")
