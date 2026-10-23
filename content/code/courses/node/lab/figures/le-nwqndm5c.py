from fig import Canvas


def ten(T):
    c = Canvas(720, 250, T(
        "A bar chart of how long ten one-second requests, sent together, took on each server. Node, Python, Go, Java and "
        "C# each took about one second. PHP's built-in server, with one process, took ten seconds; with ten workers it took "
        "one.",
        "Um gráfico de barras de quanto tempo dez pedidos de um segundo, mandados juntos, levaram em cada servidor. Node, "
        "Python, Go, Java e C# levaram cerca de um segundo cada. O servidor embutido do PHP, com um processo, levou dez "
        "segundos; com dez workers, levou um."))
    rows = [("Node", 1.016), ("Python", 1.015), ("Go", 1.017), ("Java", 1.020), ("C#", 1.019),
            (T("PHP, one process", "PHP, um processo"), 10.017), (T("PHP, ten workers", "PHP, dez workers"), 1.017)]
    sep = T(".", ",")
    x0, scale = 180, 48
    for i, (name, s) in enumerate(rows):
        y = 18 + i * 30
        c.text(x0 - 12, y + 10, name, size=10, anchor="end")
        slow = s > 5
        c.rect(x0, y, s * scale, 20, fill="var(--ink)", stroke="var(--amber)" if slow else "var(--phosphor)", rx=2)
        c.text(x0 + s * scale + 8, y + 10, f"{s:.3f} s".replace(".", sep), size=9.5, anchor="start",
               fill="var(--amber)" if slow else "var(--paper-dim)")
    c.line(x0, 232, x0 + 10 * scale, 232, stroke="var(--wire)")
    for k in range(0, 11, 2):
        c.text(x0 + k * scale, 242, str(k), size=9, fill="var(--paper-dim)")
    c.caption = T("Ten requests that each wait a second: one second wherever the waits overlap, ten where they queue.",
                  "Dez pedidos que esperam um segundo cada: um segundo onde as esperas se sobrepõem, dez onde fazem fila.")
    return c


def models(T):
    c = Canvas(720, 290, T(
        "How each language serves requests that wait. Each small box is a waiting request. Node: one thread, and the "
        "waiting requests set aside, holding no thread. Python: a thread per request, each asleep while it waits. Go, and "
        "Java's virtual threads: many cheap goroutines or virtual threads, parked while they wait, carried by a few real "
        "threads. PHP: a separate process per request, from a pool. C#: a pool of threads, and every await sets its "
        "request aside without a thread.",
        "Como cada linguagem atende pedidos que esperam. Cada caixa pequena é um pedido em espera. Node: uma thread, e os "
        "pedidos em espera postos de lado, sem ocupar thread. Python: uma thread por pedido, cada uma dormindo enquanto "
        "espera. Go, e as virtual threads do Java: muitas goroutines ou virtual threads baratas, estacionadas enquanto "
        "esperam, levadas por poucas threads de verdade. PHP: um processo separado por pedido, de um pool. C#: um pool de "
        "threads, e cada await põe o seu pedido de lado sem thread."))
    lanes = [("Node", T("one thread; a waiting request holds none", "uma thread; um pedido em espera não ocupa nenhuma"), "aside", 1),
             ("Python", T("a thread per request, asleep while it waits", "uma thread por pedido, dormindo enquanto espera"), "inside", 4),
             (T("Go, Java", "Go, Java"), T("goroutines or virtual threads, parked, on a few threads", "goroutines ou virtual threads, estacionadas, em poucas threads"), "parked", 2),
             ("PHP", T("a process per request, from a pool", "um processo por pedido, de um pool"), "proc", 3),
             ("C#", T("a pool of threads; await sets the request aside", "um pool de threads; o await põe o pedido de lado"), "aside", 2)]
    for i, (name, says, kind, n) in enumerate(lanes):
        y = 14 + i * 50
        c.text(20, y + 16, name, size=11, anchor="start", weight="600")
        c.text(20, y + 34, says, size=9.5, anchor="start", fill="var(--paper-dim)")
        x = 400
        if kind in ("inside", "proc"):
            w = 300 / n - 8
            for k in range(n):
                c.rect(x + k * (w + 8), y + 4, w, 34, fill="var(--ink)", stroke="var(--amber)" if kind == "proc" else "var(--phosphor)",
                       dash="4 3" if kind == "proc" else None)
                c.rect(x + k * (w + 8) + w / 2 - 15, y + 12, 30, 18, fill="var(--panel)", stroke="var(--wire)", rx=2)
        else:
            for k in range(n):
                c.rect(x + k * 44, y + 4, 36, 34, fill="var(--ink)", stroke="var(--phosphor)")
            left = x + n * 44 + 10
            for k in range(6 if kind == "parked" else 5):
                c.rect(left + k * 34, y + 12, 26, 18, fill="var(--panel)", stroke="var(--wire)", rx=9 if kind == "parked" else 2)
    c.rect(20, 264, 14, 14, fill="var(--ink)", stroke="var(--phosphor)", rx=2)
    c.text(40, 271, T("a thread", "uma thread"), size=9, anchor="start", fill="var(--paper-dim)")
    c.rect(120, 264, 14, 14, fill="var(--ink)", stroke="var(--amber)", dash="3 2", rx=2)
    c.text(140, 271, T("a process", "um processo"), size=9, anchor="start", fill="var(--paper-dim)")
    c.rect(230, 265, 18, 12, fill="var(--panel)", stroke="var(--wire)", rx=2)
    c.text(254, 271, T("a waiting request", "um pedido em espera"), size=9, anchor="start", fill="var(--paper-dim)")
    c.caption = T("Every model keeps many requests waiting at once; what differs is what each waiting request costs.",
                  "Todo modelo mantém muitos pedidos esperando ao mesmo tempo; o que muda é quanto custa cada pedido em espera.")
    return c


def carried(T):
    c = Canvas(720, 230, T(
        "Two layers. The lower one, which carries over between languages: HTTP, status codes, JSON, configuration from the "
        "environment, signals and graceful shutdown, state outside the process, packages with a lockfile. The upper one, "
        "learnt again for each language: syntax, the framework, its libraries, its tools and its error messages.",
        "Duas camadas. A de baixo, que passa de uma linguagem para outra: HTTP, códigos de status, JSON, configuração pelo "
        "ambiente, sinais e desligamento gracioso, estado fora do processo, pacotes com lockfile. A de cima, aprendida de "
        "novo em cada linguagem: sintaxe, o framework, as bibliotecas, as ferramentas e as mensagens de erro."))
    c.rect(20, 20, 680, 70, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(360, 40, T("learnt again for each language", "aprendido de novo em cada linguagem"), size=11, fill="var(--paper-dim)")
    c.text(360, 66, T("syntax · the framework · its libraries · its tools · its error messages", "sintaxe · o framework · as bibliotecas · as ferramentas · as mensagens de erro"), size=10)
    c.rect(20, 110, 680, 100, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(360, 132, T("carried over, from this course", "levado adiante, deste curso"), size=11, fill="var(--phosphor)")
    c.text(360, 160, T("HTTP · status codes · JSON · configuration from the environment", "HTTP · códigos de status · JSON · configuração pelo ambiente"), size=10)
    c.text(360, 184, T("SIGTERM and a graceful stop · state outside the process · a lockfile", "SIGTERM e uma parada graciosa · estado fora do processo · um lockfile"), size=10)
    c.caption = T("The lower layer is what a server is; the upper layer is how one language spells it.",
                  "A camada de baixo é o que um servidor é; a de cima é como uma linguagem o escreve.")
    return c


FIGURES = [("concurrency-models", ten), ("concurrency-models", models), ("what-transfers", carried)]
