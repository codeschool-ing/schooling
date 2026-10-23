from fig import Canvas


def pieces(T):
    c = Canvas(720, 330, T(
        "Node in layers. At the top, your JavaScript and Node's library run on V8, on the main thread. "
        "Below them the C++ bindings, then libuv with its event loop on the same main thread and a thread pool "
        "of four. At the bottom, the operating system, which watches sockets and timers for the loop and does "
        "file reads for the pool.",
        "O Node em camadas. No alto, o seu JavaScript e a biblioteca do Node rodam no V8, na thread principal. "
        "Abaixo deles os bindings em C++, depois a libuv com o event loop na mesma thread principal e um pool "
        "de quatro threads. Embaixo, o sistema operacional, que vigia sockets e timers para o loop e faz as "
        "leituras de arquivo para o pool."))
    c.rect(20, 14, 680, 56, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(360, 32, T("your JavaScript", "o seu JavaScript"), size=12, weight="600", fill="var(--phosphor)")
    c.text(360, 52, "node:http   node:fs   node:crypto   …", mono=True, size=10.5, fill="var(--paper-dim)")
    c.rect(20, 82, 330, 50, fill="var(--panel)", stroke="var(--wire)")
    c.text(185, 100, "V8", mono=True, size=12, fill="var(--paper)")
    c.text(185, 118, T("compiles and runs it; owns the heap", "compila e roda; é dono do heap"), size=10, fill="var(--paper-dim)")
    c.rect(370, 82, 330, 50, fill="var(--panel)", stroke="var(--wire)")
    c.text(535, 100, T("bindings (C++)", "bindings (C++)"), size=12, fill="var(--paper)")
    c.text(535, 118, T("where a call stops being JavaScript", "onde a chamada deixa de ser JavaScript"), size=10, fill="var(--paper-dim)")
    c.rect(20, 144, 680, 92, fill="var(--panel)", stroke="var(--wire)")
    c.text(36, 160, "libuv", mono=True, size=12, anchor="start", fill="var(--paper)")
    c.rect(40, 174, 300, 50, fill="var(--ink)", stroke="var(--amber)")
    c.text(190, 192, T("the event loop", "o event loop"), size=11.5, weight="600", fill="var(--amber)")
    c.text(190, 210, T("on the main thread, with V8", "na thread principal, com o V8"), size=10, fill="var(--paper-dim)")
    c.rect(380, 174, 300, 50, fill="var(--ink)", stroke="var(--wire)")
    c.text(530, 192, T("the thread pool", "o pool de threads"), size=11.5, weight="600", fill="var(--paper)")
    for i in range(4):
        c.rect(452 + i * 40, 202, 30, 14, fill="var(--panel)", stroke="var(--wire)", rx=2)
    c.rect(20, 254, 680, 60, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(360, 272, T("the operating system", "o sistema operacional"), size=12, fill="var(--paper)")
    c.text(190, 296, T("watches sockets and timers (epoll)", "vigia sockets e timers (epoll)"), size=10, fill="var(--paper-dim)")
    c.text(530, 296, T("reads files, resolves names", "lê arquivos, resolve nomes"), size=10, fill="var(--paper-dim)")
    c.line(190, 236, 190, 252, stroke="var(--amber)", arrow=True)
    c.line(530, 236, 530, 252, stroke="var(--wire)", arrow=True)
    c.caption = T("Your code and the loop share one thread. The pool's four threads never run JavaScript.",
                  "O seu código e o loop dividem uma thread. As quatro threads do pool nunca rodam JavaScript.")
    return c


def phases(T):
    c = Canvas(720, 300, T(
        "The event loop as a circuit of four phases in order: timers, poll, check and close, and back to timers. "
        "Between every callback in any phase, the nextTick queue and then the promise microtasks are emptied. "
        "The loop sleeps in the poll phase when nothing is due.",
        "O event loop como um circuito de quatro fases em ordem: timers, poll, check e close, e de volta aos timers. "
        "Entre cada callback, em qualquer fase, a fila do nextTick e depois as microtasks das promises são esvaziadas. "
        "O loop dorme na fase poll quando nada está para vencer."))
    boxes = [("timers", "setTimeout, setInterval", 40), ("poll", T("sockets, files, connections", "sockets, arquivos, conexões"), 210),
             ("check", "setImmediate", 380), ("close", T("'close' events", "eventos 'close'"), 550)]
    for name, sub, x in boxes:
        stroke = "var(--amber)" if name == "poll" else "var(--wire)"
        c.rect(x, 60, 130, 64, fill="var(--panel)", stroke=stroke)
        c.text(x + 65, 82, name, mono=True, size=12, fill="var(--paper)")
        if name == "timers":
            c.text(x + 65, 100, "setTimeout", mono=True, size=9.5, fill="var(--paper-dim)")
            c.text(x + 65, 114, "setInterval", mono=True, size=9.5, fill="var(--paper-dim)")
        else:
            c.text(x + 65, 104, sub, mono=name == "check", size=9.5, fill="var(--paper-dim)")
    for x in (170, 340, 510):
        c.line(x + 2, 92, x + 38, 92, stroke="var(--paper-dim)", arrow=True)
    c.path("M615 124 L615 160 L105 160 L105 128", stroke="var(--paper-dim)")
    c.line(105, 140, 105, 127, stroke="var(--paper-dim)", arrow=True)
    c.text(360, 174, T("and round again", "e de novo"), size=10, fill="var(--paper-dim)")
    c.text(275, 40, T("sleeps here when nothing is due", "dorme aqui quando nada vence"), size=10, fill="var(--amber)")
    c.rect(40, 200, 640, 80, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(360, 220, T("between every single callback, in every phase", "entre cada callback, em toda fase"), size=11.5, weight="600", fill="var(--phosphor)")
    c.rect(120, 236, 220, 30, fill="var(--panel)", stroke="var(--wire)")
    c.text(230, 251, T("1. the nextTick queue", "1. a fila do nextTick"), size=10.5, fill="var(--paper)")
    c.rect(380, 236, 220, 30, fill="var(--panel)", stroke="var(--wire)")
    c.text(490, 251, T("2. promise microtasks", "2. microtasks das promises"), size=10.5, fill="var(--paper)")
    c.line(342, 251, 378, 251, stroke="var(--paper-dim)", arrow=True)
    c.caption = T("Each phase empties its own queue. The two small queues are emptied after every callback, in any phase.",
                  "Cada fase esvazia a própria fila. As duas filas pequenas são esvaziadas depois de cada callback, em qualquer fase.")
    return c


FIGURES = [("the-pieces", pieces), ("phases", phases)]
