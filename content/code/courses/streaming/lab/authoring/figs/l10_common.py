SALES = [("09:00:40", "recife"), ("09:02:10", "natal"), ("09:03:55", "olinda"), ("09:05:00", "recife"),
         ("09:06:20", "natal"), ("09:12:30", "caruaru"), ("09:13:05", "recife"), ("09:08:50", "natal"),
         ("09:14:10", "olinda"), ("09:21:00", "recife")]
def sec(hms):
    h, m, s = map(int, hms.split(":")); return h * 3600 + m * 60 + s
T0, T1, X0, X1 = sec("08:55:00"), sec("09:30:00"), 70, 690
def X(t): return round(X0 + (t - T0) / (T1 - T0) * (X1 - X0), 1)
def axis(s, t, y):
    s.line(X0, y, X1, y, stroke="var(--wire)")
    for m in range(55, 91, 5):
        hh, mm = 8 + m // 60 + (1 if m >= 60 else 0) - (1 if m >= 60 else 0), m % 60
        tt = sec(f"{8 + (m // 60):02d}:{mm:02d}:00")
        s.line(X(tt), y - 3, X(tt), y + 3, stroke="var(--wire)")
        s.text(X(tt), y + 14, f"{8 + m // 60:02d}:{mm:02d}", size=9, fill="var(--paper-dim)", mono=True)
def dots(s, y):
    for i, (w, shop) in enumerate(SALES):
        late = i == 7
        s.circle(X(sec(w)), y, 4, fill="var(--amber)" if late else "var(--phosphor)")
