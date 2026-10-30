"""Lesson 15: the radio's tail, Android's standby buckets, and a day of wake-ups."""
from fig import Fig

T = {
    "en": dict(
        tail_aria="One small transfer on a typical 3G radio, along a time line in seconds. The transfer takes about one second at full power. The radio then stays at full power for 5 more seconds, then at low power, about half the drain, for 12 seconds, and only then drops to standby. In all, at least 18 seconds of drawing energy for one transfer.",
        transfer="transfer", full=["full power,", "waiting"], low="low power: about half the drain", standby="standby",
        secs="seconds", note="a typical 3G radio, as Android's guide to network access describes it",
        tail_cap="The transfer is the short part. The radio is drawing energy for at least 18 seconds per transfer, whatever the transfer carried.",
        b_aria="Android's App Standby Buckets as a ladder, from fewest restrictions to most. Active: the app is in use or was used very recently; minimal restrictions. Working set: in regular use; mild restrictions. Frequent: used often, not daily; stronger restrictions. Rare: not used often; strict restrictions on jobs, alarms and the network. Restricted: uses a lot of resources, or, from Android 13, not opened for 8 days; jobs once a day in a ten-minute batched session. Apart from the ladder, a never bucket for apps installed and never opened.",
        rows=[("active", "in use, or used very recently", "minimal"),
              ("working set", "in regular use", "mild"),
              ("frequent", "used often, not daily", "stronger"),
              ("rare", "not used often", "strict: jobs, alarms, network"),
              ("restricted", "heavy on resources, or unopened 8 days", "jobs once a day, 10 minutes")],
        h=("bucket", "the app is", "restrictions"),
        never="and a never bucket, for apps installed and never opened: severe",
        more="more restricted ↓",
        b_cap="The system moves an app between buckets as it is used, and each manufacturer may set its own criteria. An app cannot choose its bucket; it can only behave well in all of them.",
        w_aria="Radio wake-ups over one day, from midnight to midnight, for three ways to sync. Polling every minute: 1,440 wake-ups, so close together that they make a solid band all day. Every 15 minutes: 96 thin marks spread across the day. One batched job a day: a single mark at three in the morning, on the charger.",
        r1=["every minute", "1,440"], r2=["every 15 min", "96"], r3=["once a day", "1"],
        charger="on the charger", hour="hour of the day",
        w_cap="The same day, three ways. Each mark is a wake-up with its 18-second tail; at one a minute they merge into a band.",
    ),
    "pt": dict(
        tail_aria="Uma transferência pequena num rádio 3G típico, ao longo de uma linha do tempo em segundos. A transferência leva cerca de um segundo em potência máxima. Depois o rádio fica em potência máxima por mais 5 segundos, então em potência baixa, cerca de metade do consumo, por 12 segundos, e só então cai para o repouso. Ao todo, pelo menos 18 segundos consumindo energia por uma transferência.",
        transfer="transferência", full=["potência", "máxima, à espera"], low="potência baixa: cerca de metade do consumo", standby="repouso",
        secs="segundos", note="um rádio 3G típico, como o guia de acesso à rede do Android o descreve",
        tail_cap="A transferência é a parte curta. O rádio consome energia por pelo menos 18 segundos a cada transferência, carregue ela o que carregar.",
        b_aria="Os App Standby Buckets do Android como uma escada, das menores restrições às maiores. Active: o app está em uso ou foi usado há pouquíssimo tempo; restrições mínimas. Working set: em uso regular; restrições leves. Frequent: usado com frequência, não todo dia; restrições mais fortes. Rare: pouco usado; restrições rígidas em jobs, alarmes e rede. Restricted: consome muitos recursos, ou, a partir do Android 13, não é aberto há 8 dias; jobs uma vez por dia numa sessão agrupada de dez minutos. Fora da escada, um bucket never para apps instalados e nunca abertos.",
        rows=[("active", "em uso, ou usado há pouquíssimo", "mínimas"),
              ("working set", "em uso regular", "leves"),
              ("frequent", "usado com frequência, não todo dia", "mais fortes"),
              ("rare", "pouco usado", "rígidas: jobs, alarmes, rede"),
              ("restricted", "pesado em recursos, ou 8 dias sem abrir", "jobs 1 vez ao dia, 10 minutos")],
        h=("bucket", "o app está", "restrições"),
        never="e um bucket never, para apps instalados e nunca abertos: severas",
        more="mais restrito ↓",
        b_cap="O sistema move um app entre os buckets conforme ele é usado, e cada fabricante pode definir os próprios critérios. Um app não escolhe o seu bucket; só pode se comportar bem em todos eles.",
        w_aria="Despertares do rádio ao longo de um dia, da meia-noite à meia-noite, para três jeitos de sincronizar. Consultar a cada minuto: 1.440 despertares, tão próximos que formam uma faixa contínua o dia todo. A cada 15 minutos: 96 marcas finas espalhadas pelo dia. Um job agrupado por dia: uma única marca às três da manhã, no carregador.",
        r1=["a cada minuto", "1.440"], r2=["a cada 15 min", "96"], r3=["uma vez ao dia", "1"],
        charger="no carregador", hour="hora do dia",
        w_cap="O mesmo dia, de três jeitos. Cada marca é um despertar com a sua cauda de 18 segundos; a um por minuto elas se fundem numa faixa.",
    ),
}


def tail(t):
    f = Fig("l15-tail", 720, 200, t["tail_aria"])
    x0, s = 40, 32  # pixels per second
    f.rect(x0, 60, s * 1, 50, stroke="amber", fill="amber")
    f.box(x0 + s, 60, s * 5, 50, t["full"], stroke="amber")
    f.box(x0 + s * 6, 60, s * 12, 50, [t["low"]], stroke="phosphor")
    f.box(x0 + s * 18, 60, 80, 50, [t["standby"]], stroke="wire", dashed=True, fill="paper-dim")
    f.text(x0 + s / 2, 44, t["transfer"], anchor="start", size=9.5)
    f.arrow([(x0, 130), (x0 + s * 18 + 80, 130)], head=False, color="wire")
    for sec in (0, 1, 6, 18):
        f.arrow([(x0 + s * sec, 126), (x0 + s * sec, 134)], head=False, color="paper-dim")
        f.text(x0 + s * sec, 146, str(sec), mono=True, size=9.5, fill="paper-dim")
    f.text(x0 + s * 18 + 76, 146, t["secs"], anchor="end", size=9, fill="paper-dim")
    f.text(360, 182, t["note"], italic=True, size=9.5, fill="paper-dim")
    return f


def buckets(t):
    f = Fig("l15-buckets", 720, 290, t["b_aria"])
    cols = [(20, 140), (170, 280), (460, 240)]
    for (x, w), head in zip(cols, t["h"]):
        f.text(x + 10, 20, head, anchor="start", bold=True, size=10, fill="paper-dim")
    for i, row in enumerate(t["rows"]):
        y = 34 + i * 40
        stroke = "phosphor" if i == 0 else ("amber" if i >= 3 else "wire")
        for (x, w), cell, mono in zip(cols, row, (True, False, False)):
            f.box(x, y, w, 32, [cell], stroke=stroke, mono=mono, anchor="start")
    f.text(710, 20, t["more"], anchor="end", size=9, fill="paper-dim", italic=True)
    f.text(20, 252, t["never"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    return f


def wakeups(t):
    f = Fig("l15-wakeups", 720, 220, t["w_aria"])
    x0, w = 130, 576  # 24 hours, 24 px an hour
    rows = [(t["r1"], 30), (t["r2"], 90), (t["r3"], 150)]
    for (label, y) in rows:
        f.text(20, y + 9, label[0], anchor="start", size=10)
        f.text(20, y + 24, label[1], anchor="start", size=9.5, fill="paper-dim")
        f.rect(x0, y, w, 34, stroke="wire", fill="panel", rx=2)
    f.rect(x0 + 1, 31, w - 2, 32, stroke="amber", fill="amber", width=0.5, rx=0)
    for k in range(96):
        x = round(x0 + 3 + k * (w - 6) / 96, 1)
        f.arrow([(x, 92), (x, 122)], head=False, color="amber", width=1)
    xc = x0 + 3 * 24
    f.arrow([(xc, 152), (xc, 182)], head=False, color="phosphor", width=2)
    f.text(xc + 8, 167, t["charger"], anchor="start", size=9.5, fill="phosphor")
    for h in (0, 6, 12, 18, 24):
        f.text(x0 + h * 24, 198, f"{h:02d}:00", mono=True, size=9, fill="paper-dim")
    f.text(x0 + w, 214, t["hour"], anchor="end", size=9, fill="paper-dim")
    return f


def figures(lang):
    t = T[lang]
    same = None if lang == "en" else ["bucket"]
    return {
        "l15-tail": tail(t).json(t["tail_cap"]),
        "l15-buckets": buckets(t).json(t["b_cap"], same=same),
        "l15-wakeups": wakeups(t).json(t["w_cap"]),
    }
