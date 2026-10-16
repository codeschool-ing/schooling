NAME = "l15-visibility"
W, H = 720, 220
LABEL = ("The visibility timeout of an SQS queue over six seconds. At 0 seconds worker A receives web-0001 and the message becomes invisible for 5 seconds. Worker B asks at once and gets nothing. Worker A crashes and never deletes it. At 5 seconds the message is visible again; at 6 seconds worker B receives it, with a receive count of 2, and deletes it.",
         "O visibility timeout de uma fila SQS ao longo de seis segundos. Em 0 segundo o worker A recebe o web-0001 e a mensagem fica invisível por 5 segundos. O worker B pede na hora e não recebe nada. O worker A cai e nunca a apaga. Aos 5 segundos a mensagem volta a ficar visível; aos 6 segundos o worker B a recebe, com contagem de recebimentos 2, e a apaga.")
CAPTION = ("SQS has no connection to watch, so a received message is hidden for a fixed time, and an undeleted one comes back when the time runs out.",
           "O SQS não tem conexão para observar, então uma mensagem recebida fica escondida por um tempo fixo, e uma que não foi apagada volta quando o tempo acaba.")
PT = {"worker A": "worker A", "worker B": "worker B", "invisible: visibility timeout 5 s": "invisível: visibility timeout de 5 s",
      "receives": "recebe", "crashes, no delete": "cai, sem apagar", "asks: 0 messages": "pede: 0 mensagens",
      "receives, count 2": "recebe, contagem 2", "deletes": "apaga", "seconds": "segundos", "visible again": "visível de novo"}
SAME = ["worker A", "worker B"]


def draw(s, t):
    x0, sc = 120, 90  # px per second
    def X(sec): return x0 + sec * sc
    s.line(X(0), 185, X(6.4), 185, stroke="var(--wire)")
    for i in range(7):
        s.line(X(i), 181, X(i), 189, stroke="var(--wire)")
        s.text(X(i), 200, str(i), size=9, fill="var(--paper-dim)")
    s.text(20, 200, t("seconds"), size=9, fill="var(--paper-dim)", anchor="start")
    s.rect(X(0), 92, 5 * sc, 26, fill="var(--panel)", stroke="var(--amber)", dash="4 3")
    s.text(X(2.5), 105, t("invisible: visibility timeout 5 s"), size=9.5, fill="var(--amber)")
    s.text(X(5) + 6, 105, t("visible again"), size=9, fill="var(--phosphor)", anchor="start")
    s.text(20, 55, t("worker A"), size=10.5, weight=600, anchor="start")
    s.text(20, 150, t("worker B"), size=10.5, weight=600, anchor="start")
    s.circle(X(0), 55, 5, fill="var(--phosphor)")
    s.text(X(0) + 10, 45, t("receives"), size=9, anchor="start")
    s.circle(X(1.5), 55, 5, fill="var(--amber)")
    s.text(X(1.5) + 10, 45, t("crashes, no delete"), size=9, fill="var(--amber)", anchor="start")
    s.line(X(0), 55, X(1.5), 55, stroke="var(--phosphor)")
    s.circle(X(0.05), 150, 5, fill="none", stroke="var(--paper-dim)")
    s.text(X(0) + 10, 162, t("asks: 0 messages"), size=9, fill="var(--paper-dim)", anchor="start")
    s.circle(X(6), 150, 5, fill="var(--phosphor)")
    s.text(X(6) - 10, 140, t("receives, count 2"), size=9, anchor="end")
    s.text(X(6) - 10, 162, t("deletes"), size=9, fill="var(--paper-dim)", anchor="end")
