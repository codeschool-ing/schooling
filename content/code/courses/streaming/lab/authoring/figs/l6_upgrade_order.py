NAME = "l6-upgrade-order"
W, H = 720, 230
LABEL = ("Two deployments over time. Under BACKWARD, the consumers move to version 2 first, so for a while new readers read old version 1 data, which a backward-compatible schema allows; then the producers move. Under FORWARD, the producers move first, so old readers read new version 2 data, which a forward-compatible schema allows; then the consumers move.",
         "Duas implantações ao longo do tempo. Sob BACKWARD, os consumidores passam primeiro para a versão 2, então por um tempo leitores novos leem dados antigos da versão 1, o que um esquema compatível para trás permite; depois passam os produtores. Sob FORWARD, os produtores passam primeiro, então leitores antigos leem dados novos da versão 2, o que um esquema compatível para a frente permite; depois passam os consumidores.")
CAPTION = ("The mode decides which side may run the new version while the other still runs the old one.",
           "O modo decide qual lado pode rodar a versão nova enquanto o outro ainda roda a antiga.")
PT = {"time": "tempo", "producers": "produtores", "consumers": "consumidores",
      "new readers, old data": "leitores novos, dados antigos", "old readers, new data": "leitores antigos, dados novos",
      "BACKWARD": "BACKWARD", "FORWARD": "FORWARD", "v1": "v1", "v2": "v2"}
SAME = ["BACKWARD", "FORWARD", "v1", "v2"]
def draw(s, t):
    x0, x1 = 170, 690
    xa, xb = 330, 520
    for k, (mode, first, second, mid) in enumerate((
            ("BACKWARD", "consumers", "producers", "new readers, old data"),
            ("FORWARD", "producers", "consumers", "old readers, new data"))):
        y = 40 + k * 100
        s.text(20, y + 22, t(mode), size=11, weight=600, anchor="start", fill="var(--amber)")
        for r, who in enumerate((first, second)):
            yy = y + r * 30
            s.text(150, yy + 10, t(who), size=10, anchor="end")
            cut = xa if r == 0 else xb
            s.rect(x0, yy, cut - x0, 20, fill="var(--panel)", stroke="var(--wire)")
            s.text((x0 + cut) / 2, yy + 10, t("v1"), size=10, fill="var(--paper-dim)")
            s.rect(cut, yy, x1 - cut, 20, fill="var(--panel)", stroke="var(--phosphor)")
            s.text((cut + x1) / 2, yy + 10, t("v2"), size=10, fill="var(--phosphor)")
        s.text((xa + xb) / 2, y + 62, t(mid), size=9.5, fill="var(--amber)")
        s.line(xa, y + 54, xb, y + 54, stroke="var(--amber)", sw=1)
    s.line(x0, 222, x1, 222, stroke="var(--paper-dim)", sw=1, arrow=True)
    s.text(x1 - 4, 210, t("time"), size=9.5, fill="var(--paper-dim)", anchor="end")
