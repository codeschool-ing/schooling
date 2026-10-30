from fig import Canvas


def timeline(T):
    c = Canvas(720, 230, T(
        "A time line of one component's life. Once, at creation: constructor, then ngOnChanges, ngOnInit, "
        "ngAfterContentInit and ngAfterViewInit, with ngDoCheck and the two Checked hooks in between. Then, on every "
        "later check: ngOnChanges if an input changed, ngDoCheck, ngAfterContentChecked and ngAfterViewChecked. "
        "At the end, once: ngOnDestroy.",
        "Uma linha do tempo da vida de um componente. Uma vez, na criação: constructor, depois ngOnChanges, "
        "ngOnInit, ngAfterContentInit e ngAfterViewInit, com o ngDoCheck e os dois hooks Checked no meio. Depois, a "
        "cada conferência seguinte: ngOnChanges se um input mudou, ngDoCheck, ngAfterContentChecked e "
        "ngAfterViewChecked. No fim, uma vez: ngOnDestroy."))
    c.line(20, 120, 700, 120, stroke="var(--paper-dim)", arrow=True)
    c.text(700, 136, T("time", "tempo"), anchor="end", size=9.5, fill="var(--paper-dim)")
    groups = [
        (20, 300, T("once, when created", "uma vez, na criação"), "var(--phosphor)",
         ["constructor", "ngOnChanges", "ngOnInit", "ngDoCheck", "ngAfterContentInit", "ngAfterContentChecked", "ngAfterViewInit", "ngAfterViewChecked"]),
        (340, 220, T("on every later check", "a cada conferência seguinte"), "var(--amber)",
         ["ngOnChanges*", "ngDoCheck", "ngAfterContentChecked", "ngAfterViewChecked"]),
        (580, 120, T("once, when removed", "uma vez, ao sair"), "var(--phosphor)", ["ngOnDestroy"]),
    ]
    for x, w, title, col, names in groups:
        c.rect(x, 20, w, 88, fill="var(--panel)", stroke=col)
        c.text(x + w / 2, 34, title, size=10, weight="600", fill=col)
        for i, n in enumerate(names):
            col2 = i // 4
            row = i % 4
            cx = x + 10 + col2 * (w / 2)
            c.text(cx, 52 + row * 15, n, mono=True, size=9.5, anchor="start")
        c.line(x + w / 2, 108, x + w / 2, 118, stroke=col)
    c.text(450, 150, T("* only if an input changed", "* só se um input mudou"), size=9.5, fill="var(--amber)")
    c.rect(340, 170, 220, 46, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(450, 186, T("repeats: how often depends on", "se repete: com que frequência depende"), size=9.5, fill="var(--paper-dim)")
    c.text(450, 202, T("OnPush and zone.js (lesson 7)", "do OnPush e do zone.js (aula 7)"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("ngOnInit and the two Init hooks run once; ngDoCheck and the Checked hooks run on every check; ngOnDestroy runs once, at the end.",
                  "O ngOnInit e os dois hooks Init rodam uma vez; o ngDoCheck e os hooks Checked rodam a cada conferência; o ngOnDestroy roda uma vez, no fim.")
    return c


FIGURES = [("the-hooks", timeline)]
