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


def torn(T):
    c = Canvas(720, 230, T(
        "Two ways to replace a file, as timelines with a crash in the middle. writeFile straight onto store.json first "
        "empties it, then writes: a crash in between leaves zero bytes, and both the old and the new data are gone. "
        "Writing to a temporary file beside it and then renaming leaves store.json whole until the rename, which happens "
        "in one step: a crash before it leaves the old file, after it the new one.",
        "Dois jeitos de substituir um arquivo, como linhas do tempo com uma queda no meio. O writeFile direto no store.json "
        "primeiro o esvazia, depois escreve: uma queda no meio deixa zero bytes, e os dados velhos e os novos se perdem. "
        "Escrever num arquivo temporário ao lado e depois renomear deixa o store.json inteiro até o rename, que acontece "
        "num passo só: uma queda antes deixa o arquivo velho, depois, o novo."))
    c.text(20, 26, "writeFile(\"store.json\", …)", mono=True, size=10.5, anchor="start", fill="var(--amber)")
    c.rect(20, 40, 150, 34, fill="var(--panel)", stroke="var(--wire)")
    c.text(95, 57, T("old data", "dados velhos"), size=10)
    c.rect(180, 40, 150, 34, fill="var(--ink)", stroke="var(--amber)", dash="3 3")
    c.text(255, 57, T("emptied: 0 bytes", "esvaziado: 0 bytes"), size=10, fill="var(--amber)")
    c.rect(340, 40, 360, 34, fill="var(--panel)", stroke="var(--wire)")
    c.text(520, 57, T("new bytes, arriving", "bytes novos, chegando"), size=10)
    c.line(300, 30, 300, 86, stroke="var(--amber)", sw=2)
    c.text(300, 98, T("crash here: nothing survives", "queda aqui: nada sobrevive"), size=10, fill="var(--amber)")
    c.text(20, 130, "writeFile(temp) + rename(temp, \"store.json\")", mono=True, size=10.5, anchor="start", fill="var(--phosphor)")
    c.rect(20, 144, 470, 34, fill="var(--panel)", stroke="var(--wire)")
    c.text(255, 161, T("store.json: old data, whole, the whole time", "store.json: dados velhos, inteiros, o tempo todo"), size=10)
    c.rect(500, 144, 200, 34, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(600, 161, T("store.json: new data", "store.json: dados novos"), size=10, fill="var(--phosphor)")
    c.line(495, 136, 495, 190, stroke="var(--phosphor)", sw=2)
    c.text(495, 204, T("rename: one step", "rename: um passo só"), size=10, fill="var(--phosphor)")
    c.text(250, 218, T("crash anywhere: one whole file or the other", "queda em qualquer ponto: um arquivo inteiro ou o outro"), size=10, fill="var(--paper-dim)")
    c.caption = T("Never overwrite what you cannot afford to lose: write beside it, then swap.",
                  "Nunca sobrescreva o que não pode perder: escreva ao lado, depois troque.")
    return c


def bytes_of(T):
    c = Canvas(720, 200, T(
        "The word olá as characters and as bytes. o is the byte 6f and l is 6c, one byte each; á is two bytes, c3 a1, in "
        "UTF-8. So the string has 3 characters and the buffer 4 bytes. Cutting the buffer after 3 bytes splits á in half, "
        "and the half byte c3 decodes as the replacement character.",
        "A palavra olá como caracteres e como bytes. O o é o byte 6f e o l é 6c, um byte cada; o á são dois bytes, c3 a1, "
        "em UTF-8. Então a string tem 3 caracteres e o buffer 4 bytes. Cortar o buffer depois de 3 bytes divide o á ao "
        "meio, e o meio byte c3 vira o caractere de substituição."))
    c.text(20, 40, T("characters: 3", "caracteres: 3"), size=10.5, anchor="start", fill="var(--paper-dim)")
    c.text(20, 100, T("bytes: 4", "bytes: 4"), size=10.5, anchor="start", fill="var(--paper-dim)")
    chars = [("o", 1), ("l", 1), ("á", 2)]
    x = 150
    for ch, n in chars:
        w = 60 * n + 8 * (n - 1)
        c.rect(x, 22, w, 36, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + w / 2, 40, ch, mono=True, size=14)
        x += w + 8
    for i, b in enumerate(["6f", "6c", "c3", "a1"]):
        bx = 150 + i * 68
        c.rect(bx, 82, 60, 36, fill="var(--ink)", stroke="var(--phosphor)" if i < 3 else "var(--wire)")
        c.text(bx + 30, 100, b, mono=True, size=12, fill="var(--phosphor)" if i < 3 else "var(--paper-dim)")
    c.line(354, 72, 354, 128, stroke="var(--amber)", sw=2, dash="4 3")
    c.text(354, 142, "subarray(0, 3)", mono=True, size=10, fill="var(--amber)")
    c.text(500, 100, '→ "ol�"', mono=True, size=13, fill="var(--amber)", anchor="start")
    c.text(360, 178, T("a cut in the middle of a character decodes as a replacement character", "um corte no meio de um caractere vira um caractere de substituição"), size=10, fill="var(--paper-dim)")
    c.caption = T("length counts characters, byteLength counts bytes, and a byte boundary is not a character boundary.",
                  "O length conta caracteres, o byteLength conta bytes, e uma fronteira de byte não é uma fronteira de caractere.")
    return c


FIGURES = [("readable-and-writable", flow), ("backpressure", pressure), ("atomic-writes", torn), ("buffers", bytes_of)]
