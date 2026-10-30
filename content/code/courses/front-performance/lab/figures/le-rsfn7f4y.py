from fig import Canvas


def push(T):
    c = Canvas(720, 230, T(
        "The journey of a push message, left to right. The page subscribes at the browser's push service and gives the "
        "subscription to the planner's server. Later the server sends a message to the push service, signed with its "
        "VAPID key. The push service delivers it to the browser, which wakes the service worker, and the worker shows "
        "the notification. The page does not need to be open.",
        "O caminho de uma mensagem push, da esquerda para a direita. A página se inscreve no serviço de push do "
        "navegador e entrega a inscrição ao servidor do planner. Depois o servidor manda uma mensagem ao serviço de "
        "push, assinada com a sua chave VAPID. O serviço de push a entrega ao navegador, que acorda o service worker, "
        "e o worker mostra a notificação. A página não precisa estar aberta."))
    boxes = [(20, T("planner's server", "servidor do planner")), (200, T("push service", "serviço de push")),
             (380, T("the browser", "o navegador")), (560, T("service worker", "service worker"))]
    for x, label in boxes:
        c.rect(x, 80, 140, 50, fill="var(--panel)", stroke="var(--wire)", sw=1.4)
        c.text(x + 70, 105, label, size=10.5)
    c.line(162, 96, 198, 96, stroke="var(--amber)", arrow=True)
    c.text(180, 70, T("2. send, signed", "2. manda, assinada"), size=9.5, fill="var(--amber)")
    c.line(342, 96, 378, 96, stroke="var(--amber)", arrow=True)
    c.text(360, 70, T("3. deliver", "3. entrega"), size=9.5, fill="var(--amber)")
    c.line(522, 96, 558, 96, stroke="var(--amber)", arrow=True)
    c.text(540, 70, T("4. wake", "4. acorda"), size=9.5, fill="var(--amber)")
    c.path("M450 132 V 170 H 90 V 132", stroke="var(--phosphor)", dash="4 3")
    c.text(270, 186, T("1. the page subscribes, and the server keeps the subscription",
                       "1. a página se inscreve, e o servidor guarda a inscrição"), size=10, fill="var(--phosphor)")
    c.text(630, 150, T("notification", "notificação"), size=10, fill="var(--paper)")
    c.caption = T("Only the last box runs code you wrote in the visitor's browser.",
                  "Só a última caixa roda, no navegador do visitante, código que você escreveu.")
    return c


FIGURES = [
    ("push", push),
]
