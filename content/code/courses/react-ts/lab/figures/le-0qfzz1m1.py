from fig import Fig

k = Fig("key-identity", 720, 250,
        {"en": "The session list before and after reversing. With index keys, row 0 before is matched to row 0 after, "
               "so the note typed beside Monday stays in the first row, now Wednesday's. With id keys, s1 is matched "
               "to s1 wherever it moved, so the note travels with Monday's session to the second row.",
         "pt": "A lista de sessões antes e depois de inverter. Com keys de índice, a linha 0 de antes casa com a linha "
               "0 de depois, então a nota digitada ao lado da segunda-feira fica na primeira linha, agora a da "
               "quarta. Com keys de id, s1 casa com s1 onde quer que tenha ido, então a nota viaja com a sessão de "
               "segunda para a segunda linha."},
        {"en": "React matches the rows of two renders by key. An index matches positions; an id matches items.",
         "pt": "O React casa as linhas de duas renderizações pela key. Um índice casa posições; um id casa itens."})
for col, (title, keys_after, tone) in enumerate([
        ({"en": "key = index", "pt": "key = índice"}, ["0", "1"], "amber"),
        ({"en": "key = s.id", "pt": "key = s.id"}, ["s2", "s1"], "phosphor")]):
    x0 = 20 + col * 360
    k.text(x0 + 160, 20, title, anchor="middle", tone=tone, size=11.5)
    k.text(x0 + 60, 44, {"en": "before", "pt": "antes"}, anchor="middle", tone="dim", size=10)
    k.text(x0 + 260, 44, {"en": "after reversing", "pt": "depois de inverter"}, anchor="middle", tone="dim", size=10)
    before = [("0" if col == 0 else "s1", "Mon 19 Oct", "read chapter 3"), ("1" if col == 0 else "s2", "Wed 21 Oct", "")]
    after_dates = ["Wed 21 Oct", "Mon 19 Oct"]
    after_notes = ["read chapter 3", ""] if col == 0 else ["", "read chapter 3"]
    for i, (key, date, note) in enumerate(before):
        y = 60 + i * 80
        k.box(x0, y, 130, 60, [f"key {key}", date, note or "—"], mono=True, tone="wire", text_tone="paper", size=9.5)
        y2 = 60 + i * 80
        k.box(x0 + 190, y2, 130, 60, [f"key {keys_after[i]}", after_dates[i], after_notes[i] or "—"], mono=True,
              tone=tone if after_notes[i] else "wire", text_tone="paper", size=9.5)
    if col == 0:
        k.arrow(x0 + 132, 90, x0 + 188, 90, tone=tone)
        k.arrow(x0 + 132, 170, x0 + 188, 170, tone=tone)
    else:
        k.arrow(x0 + 132, 90, x0 + 188, 170, tone=tone)
        k.arrow(x0 + 132, 170, x0 + 188, 90, tone=tone)
k.text(180, 236, {"en": "the note stayed in row 0, now Wednesday's", "pt": "a nota ficou na linha 0, agora da quarta"},
       anchor="middle", tone="amber", size=10.5)
k.text(540, 236, {"en": "the note moved with Monday's session", "pt": "a nota foi junto com a sessão de segunda"},
       anchor="middle", tone="phosphor", size=10.5)

FIGS = [k]
