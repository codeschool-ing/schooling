NAME = "l16-reset"
W, H = 720, 220
LABEL = ("Two partitions drawn along a clock, each message placed at the time it was written. A vertical line marks the datetime given to the reset. In each partition, the group's new position is the first message written at or after that line, so the two partitions move to different offsets that belong to the same moment.",
         "Duas partições desenhadas ao longo de um relógio, cada mensagem posta na hora em que foi escrita. Uma linha vertical marca o datetime dado ao reset. Em cada partição, a nova posição do grupo é a primeira mensagem escrita naquele instante ou depois, então as duas partições vão para offsets diferentes que pertencem ao mesmo momento.")
CAPTION = ("A reset by datetime picks an offset per partition; the offsets differ, the moment is the same.",
           "Um reset por datetime escolhe um offset por partição; os offsets diferem, o momento é o mesmo.")
PT = {"partition 0": "partição 0", "partition 1": "partição 1", "--to-datetime": "--to-datetime",
      "new position: offset 4": "nova posição: offset 4", "new position: offset 9": "nova posição: offset 9",
      "record timestamp": "timestamp do registro"}
SAME = []
def draw(s, t):
    x0, x1 = 120, 680
    rows = ((70, "partition 0", [0.03, 0.12, 0.2, 0.33, 0.52, 0.6, 0.71, 0.85, 0.95]),
            (150, "partition 1", [0.02, 0.07, 0.11, 0.16, 0.22, 0.27, 0.31, 0.38, 0.44, 0.5, 0.55, 0.62, 0.66, 0.73, 0.79, 0.84, 0.9, 0.96]))
    cut = 0.48
    xc = x0 + cut * (x1 - x0)
    for y, name, ts in rows:
        s.text(20, y, t(name), size=11, weight=600, anchor="start")
        s.line(x0, y, x1, y, stroke="var(--wire)")
        first = None
        for i, f in enumerate(ts):
            x = x0 + f * (x1 - x0)
            after = f >= cut
            if after and first is None: first = (i, x)
            s.circle(x, y, 5, fill="var(--phosphor)" if after else "var(--paper-dim)")
        i, x = first
        s.circle(x, y, 9, fill="none", stroke="var(--amber)", sw=1.5)
        s.text(x + 14, y - 18, t(f"new position: offset {i}"), size=9.5, fill="var(--amber)", anchor="start")
    s.line(xc, 30, xc, 185, stroke="var(--amber)", sw=1.5, dash="5 4")
    s.text(xc, 22, t("--to-datetime"), size=10, mono=True, fill="var(--amber)")
    s.path(f"M {x0} 200 L {x1} 200", arrow=True)
    s.text(x1, 212, t("record timestamp"), size=9.5, fill="var(--paper-dim)", anchor="end")
