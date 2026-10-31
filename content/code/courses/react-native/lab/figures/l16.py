"""Lesson 16: the two roads a notification takes."""
from fig import Fig

T = {
 "en": dict(aria="Two roads to the same notification. A local notification: the app schedules it on the phone, and the phone's system shows it at the time, with no network. A push notification: the app sends its token to its server; the server sends a message to Expo's push service or straight to the platform service, APNs for iOS and FCM for Android, which delivers it to the phone, whose system shows it.",
   local="local", push="push", app="the app", sys="the phone's system", shown="notification shown", server="your server", expo="Expo push service", apns="APNs / FCM",
   sched="schedules", token="token", optional="optional", cap="A local notification never leaves the phone; a push always passes through Apple's or Google's service."),
 "pt": dict(aria="Dois caminhos até a mesma notificação. Uma notificação local: o app a agenda no celular, e o sistema do celular a mostra na hora, sem rede. Uma notificação push: o app manda o token ao servidor dele; o servidor manda uma mensagem ao serviço de push do Expo ou direto ao serviço da plataforma, APNs para iOS e FCM para Android, que a entrega ao celular, cujo sistema a mostra.",
   local="local", push="push", app="o app", sys="o sistema do celular", shown="notificação na tela", server="o seu servidor", expo="push do Expo", apns="APNs / FCM",
   sched="agenda", token="token", optional="opcional", cap="Uma notificação local nunca sai do celular; um push sempre passa pelo serviço da Apple ou do Google."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l16-roads", 720, 250, t["aria"])
    f.text(20, 50, t["local"], anchor="start", size=10, bold=True, fill="phosphor")
    f.box(80, 32, 110, 36, [t["app"]], stroke="phosphor")
    f.box(300, 32, 150, 36, [t["sys"]])
    f.box(560, 32, 140, 36, [t["shown"]], stroke="phosphor")
    f.arrow([(190, 50), (300, 50)])
    f.text(245, 42, t["sched"], size=9, fill="paper-dim", italic=True)
    f.arrow([(450, 50), (560, 50)])
    f.text(20, 160, t["push"], anchor="start", size=10, bold=True, fill="amber")
    f.box(80, 142, 110, 36, [t["app"]], stroke="amber")
    f.box(80, 200, 110, 36, [t["server"]], stroke="amber")
    f.arrow([(135, 178), (135, 200)])
    f.text(150, 190, t["token"], anchor="start", size=9, fill="paper-dim", italic=True)
    f.box(240, 200, 130, 36, [t["expo"]], dashed=True)
    f.text(305, 246, t["optional"], size=8.5, fill="paper-dim", italic=True)
    f.box(410, 200, 110, 36, [t["apns"]], mono=True, size=9.5, stroke="amber")
    f.arrow([(190, 218), (240, 218)])
    f.arrow([(370, 218), (410, 218)])
    f.arrow([(465, 200), (390, 68)])
    same = ["local", "push", "token"] if lang == "pt" else None
    return {"l16-roads": f.json(caption=t["cap"], same=same)}
