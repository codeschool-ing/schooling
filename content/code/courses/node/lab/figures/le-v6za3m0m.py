from fig import Canvas


def flow(T):
    c = Canvas(720, 200, T(
        "A file read as a stream: the readable hands over chunks of 64 KiB, one after another, to the code using them, "
        "with a data event for each, then end when the file is done, or error if something failed. Only one chunk is in "
        "the program's hands at a time.",
        "Um arquivo lido como stream: o readable entrega pedaços de 64 KiB, um depois do outro, ao código que os usa, com "
        "um evento data para cada um, depois end quando o arquivo acaba, ou error se algo falhou. Só um pedaço fica nas "
        "mãos do programa de cada vez."))
    c.rect(20, 50, 130, 80, fill="var(--panel)", stroke="var(--wire)")
    c.text(85, 80, "access.log", mono=True, size=11, fill="var(--paper)")
    c.text(85, 102, T("127 MB on disk", "127 MB no disco"), size=9.5, fill="var(--paper-dim)")
    for i in range(5):
        x = 180 + i * 62
        c.rect(x, 74, 52, 32, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(x + 26, 90, "64 KiB", mono=True, size=9, fill="var(--phosphor)")
    c.line(150, 90, 176, 90, stroke="var(--paper-dim)", arrow=True)
    c.line(490, 90, 528, 90, stroke="var(--paper-dim)", arrow=True)
    c.rect(530, 50, 170, 80, fill="var(--panel)", stroke="var(--wire)")
    c.text(615, 80, T("your code", "o seu código"), size=11, fill="var(--paper)")
    c.text(615, 102, T("one chunk at a time", "um pedaço de cada vez"), size=9.5, fill="var(--paper-dim)")
    c.text(335, 130, "'data'  'data'  'data'  …  'end'", mono=True, size=10, fill="var(--paper-dim)")
    c.text(335, 160, T("or 'error', at any point", "ou 'error', em qualquer ponto"), size=10, fill="var(--amber)")
    c.caption = T("The file is never in memory whole: a chunk is read, used and let go before the next one.",
                  "O arquivo nunca fica inteiro na memória: um pedaço é lido, usado e solto antes do próximo.")
    return c


def pressure(T):
    c = Canvas(720, 230, T(
        "A fast producer writes into a slow consumer's buffer. When the buffer passes its high-water mark, write returns "
        "false; a producer that waits for drain keeps the buffer at that level, while one that ignores it lets the buffer "
        "grow without limit.",
        "Um produtor rápido escreve no buffer de um consumidor lento. Quando o buffer passa da marca d'água, o write devolve "
        "false; um produtor que espera o drain mantém o buffer nesse nível, enquanto um que ignora deixa o buffer crescer sem "
        "limite."))
    c.rect(20, 70, 130, 70, fill="var(--panel)", stroke="var(--wire)")
    c.text(85, 96, T("producer", "produtor"), size=11, fill="var(--paper)")
    c.text(85, 116, T("fast", "rápido"), size=9.5, fill="var(--paper-dim)")
    c.rect(570, 70, 130, 70, fill="var(--panel)", stroke="var(--wire)")
    c.text(635, 96, T("consumer", "consumidor"), size=11, fill="var(--paper)")
    c.text(635, 116, T("slow", "lento"), size=9.5, fill="var(--paper-dim)")
    c.rect(210, 70, 300, 70, fill="var(--ink)", stroke="var(--wire)")
    c.text(360, 60, T("the stream's buffer", "o buffer do stream"), size=10, fill="var(--paper-dim)")
    c.rect(212, 72, 150, 66, fill="var(--phosphor-dim)", stroke="none", rx=2)
    c.line(362, 66, 362, 144, stroke="var(--amber)", dash="3 3")
    c.text(362, 156, "highWaterMark", mono=True, size=9.5, fill="var(--amber)")
    c.line(150, 105, 208, 105, stroke="var(--paper-dim)", arrow=True)
    c.text(179, 92, "write()", mono=True, size=9, fill="var(--paper)")
    c.line(512, 105, 568, 105, stroke="var(--paper-dim)", arrow=True)
    c.path("M360 170 C 360 205, 85 205, 85 142", stroke="var(--amber)")
    c.line(85, 150, 85, 142, stroke="var(--amber)", arrow=True)
    c.text(230, 216, T("past the mark: write() returns false; wait for 'drain'", "passou da marca: write() devolve false; espere o 'drain'"), size=10, fill="var(--amber)")
    c.caption = T("Backpressure is the consumer's buffer saying it is full, and the producer waiting until it is not.",
                  "Contrapressão é o buffer do consumidor dizendo que está cheio, e o produtor esperando até não estar.")
    return c


FIGURES = [("readable-and-writable", flow), ("backpressure", pressure)]
