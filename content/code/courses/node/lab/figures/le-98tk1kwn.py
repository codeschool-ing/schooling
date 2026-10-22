from fig import Canvas


def shutdown(T):
    c = Canvas(720, 220, T(
        "A timeline of a graceful shutdown. SIGTERM arrives; the server stops accepting connections at once; a request "
        "that was already open keeps running until it answers; when nothing is left the process exits with 0. A deadline "
        "ten seconds after the signal would force the exit if a request never ended.",
        "Uma linha do tempo de um desligamento gracioso. O SIGTERM chega; o servidor para de aceitar conexões na hora; um "
        "pedido que já estava aberto continua até responder; quando nada sobra o processo sai com 0. Um prazo de dez "
        "segundos depois do sinal forçaria a saída se um pedido nunca terminasse."))
    c.line(40, 150, 690, 150, stroke="var(--paper-dim)", arrow=True)
    c.text(690, 168, T("time", "tempo"), anchor="end", size=9.5, fill="var(--paper-dim)")
    c.line(200, 40, 200, 160, stroke="var(--amber)", dash="4 3")
    c.text(200, 30, "SIGTERM", mono=True, size=10, fill="var(--amber)")
    c.rect(40, 60, 160, 30, fill="var(--panel)", stroke="var(--wire)")
    c.text(120, 75, T("accepting connections", "aceitando conexões"), size=10, fill="var(--paper)")
    c.rect(200, 60, 210, 30, fill="var(--ink)", stroke="var(--wire)", dash="3 3")
    c.text(305, 75, T("closed to new ones: curl gets 7", "fechado a novas: o curl ganha 7"), size=10, fill="var(--paper-dim)")
    c.rect(120, 105, 290, 30, fill="var(--ink)", stroke="var(--phosphor)", sw=1.6)
    c.text(265, 120, T("/slow, open before the signal, finishes", "/slow, aberto antes do sinal, termina"), size=10, fill="var(--paper)")
    c.line(410, 40, 410, 160, stroke="var(--phosphor)")
    c.text(410, 30, T("loop empty: exit 0", "loop vazio: sai com 0"), size=10, fill="var(--phosphor)")
    c.line(620, 40, 620, 160, stroke="var(--paper-dim)", dash="2 4")
    c.text(620, 30, T("10 s: exit 1 anyway", "10 s: sai com 1 mesmo assim"), size=10, fill="var(--paper-dim)")
    c.text(620, 190, T("only if something hangs", "só se algo travar"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("Stop taking work, finish the work already taken, and let the loop end on its own.",
                  "Parar de aceitar trabalho, terminar o que já foi aceito, e deixar o loop acabar sozinho.")
    return c


def shell(T):
    c = Canvas(720, 230, T(
        "The same file name given two ways. exec hands one string to a shell, which splits it at the semicolon into two "
        "commands, wc and echo. execFile hands wc a list of arguments, so the whole name, semicolon included, arrives as one "
        "argument and no shell reads it.",
        "O mesmo nome de arquivo entregue de dois jeitos. O exec entrega uma string a um shell, que a divide no ponto e "
        "vírgula em dois comandos, wc e echo. O execFile entrega ao wc uma lista de argumentos, então o nome inteiro, ponto e "
        "vírgula incluído, chega como um argumento só e nenhum shell o lê."))
    c.text(20, 30, "exec(`wc -w ${name}`)", mono=True, size=10.5, fill="var(--amber)", anchor="start")
    c.rect(20, 45, 120, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(80, 65, "Node", mono=True, size=10.5)
    c.line(140, 65, 198, 65, stroke="var(--paper-dim)", arrow=True)
    c.rect(200, 45, 120, 40, fill="var(--ink)", stroke="var(--amber)")
    c.text(260, 65, "/bin/sh", mono=True, size=10.5, fill="var(--amber)")
    c.line(320, 58, 400, 50, stroke="var(--paper-dim)", arrow=True)
    c.line(320, 72, 400, 88, stroke="var(--paper-dim)", arrow=True)
    c.rect(402, 35, 300, 28, fill="var(--panel)", stroke="var(--wire)")
    c.text(552, 49, "wc -w notes.txt", mono=True, size=10)
    c.rect(402, 75, 300, 28, fill="var(--panel)", stroke="var(--amber)")
    c.text(552, 89, "echo the shell ran this too", mono=True, size=10, fill="var(--amber)")
    c.text(20, 140, 'execFile("wc", ["-w", name])', mono=True, size=10.5, fill="var(--phosphor)", anchor="start")
    c.rect(20, 155, 120, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(80, 175, "Node", mono=True, size=10.5)
    c.line(140, 175, 400, 175, stroke="var(--paper-dim)", arrow=True)
    c.text(270, 165, T("no shell in between", "nenhum shell no meio"), size=9.5, fill="var(--paper-dim)")
    c.rect(402, 155, 300, 40, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(552, 168, "wc -w", mono=True, size=10)
    c.text(552, 184, '"notes.txt; echo the shell ran this too"', mono=True, size=8.5, fill="var(--phosphor)")
    c.caption = T("A shell reads a string as commands; a list of arguments is only ever arguments.",
                  "Um shell lê uma string como comandos; uma lista de argumentos é sempre só argumentos.")
    return c


def procs(T):
    c = Canvas(720, 240, T(
        "Two ways to run JavaScript on more than one processor. On the left, two processes started with fork: each has its "
        "own Node, its own memory and its own event loop, joined by a channel that carries messages. On the right, one "
        "process with a main thread and two worker threads: each thread has its own heap and loop, inside one Node, and a "
        "SharedArrayBuffer can be seen by all of them.",
        "Dois jeitos de rodar JavaScript em mais de um processador. À esquerda, dois processos iniciados com fork: cada um "
        "tem o seu Node, a sua memória e o seu event loop, ligados por um canal que leva mensagens. À direita, um processo "
        "com uma thread principal e duas worker threads: cada thread tem o seu heap e o seu loop, dentro de um Node só, e um "
        "SharedArrayBuffer pode ser visto por todas."))
    c.text(175, 22, T("fork: two processes", "fork: dois processos"), size=11, weight="600")
    for i, (x, name) in enumerate(((25, "parent.js"), (205, "child.js"))):
        c.rect(x, 40, 145, 150, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + 72, 58, name, mono=True, size=10)
        c.text(x + 72, 80, T("its own Node", "o seu próprio Node"), size=9.5, fill="var(--paper-dim)")
        c.rect(x + 15, 95, 115, 34, fill="var(--ink)", stroke="var(--wire)")
        c.text(x + 72, 112, T("heap", "heap"), size=9.5)
        c.rect(x + 15, 140, 115, 34, fill="var(--ink)", stroke="var(--wire)")
        c.text(x + 72, 157, T("event loop", "event loop"), size=9.5)
    c.line(172, 210, 203, 210, stroke="var(--phosphor)", arrow=True)
    c.line(205, 220, 172, 220, stroke="var(--phosphor)", arrow=True)
    c.text(188, 233, T("messages, copied", "mensagens, copiadas"), size=9, fill="var(--phosphor)")
    c.text(540, 22, T("worker_threads: one process", "worker_threads: um processo"), size=11, weight="600")
    c.rect(390, 40, 310, 150, fill="var(--panel)", stroke="var(--wire)")
    c.text(545, 58, T("one Node", "um Node só"), size=9.5, fill="var(--paper-dim)")
    for i, name in enumerate((T("main", "principal"), "worker 1", "worker 2")):
        x = 402 + i * 100
        c.rect(x, 70, 88, 80, fill="var(--ink)", stroke="var(--wire)")
        c.text(x + 44, 88, name, size=9.5)
        c.text(x + 44, 108, T("its heap", "o seu heap"), size=9, fill="var(--paper-dim)")
        c.text(x + 44, 126, T("its loop", "o seu loop"), size=9, fill="var(--paper-dim)")
    c.rect(402, 158, 288, 24, fill="var(--ink)", stroke="var(--phosphor)", dash="3 3")
    c.text(546, 170, "SharedArrayBuffer", mono=True, size=9.5)
    c.caption = T("A child process shares nothing; a worker thread shares the process, and only the memory it is given.",
                  "Um processo filho não divide nada; uma worker thread divide o processo, e só a memória que recebe.")
    return c


def three(T):
    c = Canvas(720, 230, T(
        "Three ways data reaches a worker. Copied: the main thread keeps its data and the worker gets a separate copy. "
        "Transferred: the bytes move to the worker and the main thread is left with an empty buffer. Shared: one block of "
        "memory that both threads read and write at the same time.",
        "Três jeitos de os dados chegarem a uma worker. Copiados: a thread principal fica com os dados e a worker recebe uma "
        "cópia separada. Transferidos: os bytes vão para a worker e a thread principal fica com um buffer vazio. "
        "Compartilhados: um bloco de memória que as duas threads leem e escrevem ao mesmo tempo."))
    rows = [(T("copied", "copiado"), "postMessage(x)", T("both have it, twice", "os dois têm, duas vezes"), "copy"),
            (T("transferred", "transferido"), "postMessage(x, [x.buffer])", T("the worker has it; ours is empty", "a worker tem; o nosso fica vazio"), "move"),
            (T("shared", "compartilhado"), "SharedArrayBuffer", T("both at once: use Atomics", "os dois juntos: use Atomics"), "share")]
    for i, (name, code, says, kind) in enumerate(rows):
        y = 20 + i * 70
        c.text(20, y + 25, name, size=11, anchor="start", weight="600")
        c.text(20, y + 45, code, mono=True, size=9, anchor="start", fill="var(--paper-dim)")
        c.rect(200, y + 10, 120, 40, fill="var(--panel)", stroke="var(--wire)")
        c.text(240, y + 30, T("main", "principal"), size=9.5)
        c.rect(420, y + 10, 110, 40, fill="var(--panel)", stroke="var(--wire)")
        c.text(455, y + 30, "worker", size=9.5)
        if kind == "copy":
            c.rect(284, y + 18, 28, 24, fill="var(--phosphor-dim)", stroke="var(--phosphor)", rx=2)
            c.rect(494, y + 18, 28, 24, fill="var(--phosphor-dim)", stroke="var(--phosphor)", rx=2)
            c.line(320, y + 30, 418, y + 30, stroke="var(--paper-dim)", arrow=True)
        elif kind == "move":
            c.rect(284, y + 18, 28, 24, fill="none", stroke="var(--paper-dim)", dash="3 3", rx=2)
            c.rect(494, y + 18, 28, 24, fill="var(--phosphor-dim)", stroke="var(--phosphor)", rx=2)
            c.line(320, y + 30, 418, y + 30, stroke="var(--paper-dim)", arrow=True)
        else:
            c.rect(332, y + 16, 76, 28, fill="var(--ink)", stroke="var(--amber)", rx=2)
            c.text(370, y + 30, T("one block", "um bloco"), size=9, fill="var(--amber)")
            c.line(320, y + 30, 332, y + 30, stroke="var(--amber)")
            c.line(408, y + 30, 420, y + 30, stroke="var(--amber)")
        c.text(545, y + 30, says, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.caption = T("A copy costs time, a transfer costs the sender its copy, and sharing costs care.",
                  "Uma cópia custa tempo, uma transferência custa ao remetente a sua cópia, e compartilhar custa cuidado.")
    return c


def pool(T):
    c = Canvas(720, 210, T(
        "A pool of four workers. Jobs arrive on the left and wait in a queue; each free worker takes the next job, and "
        "when it answers it is free again. A worker that throws is replaced by a new one.",
        "Um pool de quatro workers. Os jobs chegam pela esquerda e esperam numa fila; cada worker livre pega o próximo job, "
        "e quando responde fica livre de novo. Uma worker que lança um erro é substituída por uma nova."))
    c.text(40, 30, "pool.run(job)", mono=True, size=10, anchor="start", fill="var(--paper)")
    c.line(80, 40, 80, 68, stroke="var(--paper-dim)", arrow=True)
    c.rect(40, 70, 230, 60, fill="var(--panel)", stroke="var(--wire)")
    c.text(200, 58, T("queue", "fila"), size=10, fill="var(--paper-dim)")
    for i in range(5):
        c.rect(52 + i * 42, 84, 34, 32, fill="var(--ink)", stroke="var(--wire)")
        c.text(69 + i * 42, 100, "job", mono=True, size=8.5, fill="var(--paper-dim)")
    c.line(270, 100, 360, 100, stroke="var(--paper-dim)", arrow=True)
    c.text(315, 88, T("next free", "próxima livre"), size=9, fill="var(--paper-dim)")
    for i in range(4):
        y = 20 + i * 44
        busy = i < 3
        c.rect(362, y, 150, 34, fill="var(--ink)" if busy else "var(--panel)", stroke="var(--phosphor)" if busy else "var(--wire)")
        c.text(437, y + 17, T("worker: busy", "worker: ocupada") if busy else T("worker: free", "worker: livre"), size=9.5)
    c.line(512, 37, 580, 37, stroke="var(--phosphor)", arrow=True)
    c.text(586, 37, T("answer: resolve", "resposta: resolve"), size=9.5, anchor="start", fill="var(--phosphor)")
    c.line(512, 81, 580, 81, stroke="var(--amber)", arrow=True)
    c.text(586, 81, T("throws: reject,", "lança: reject,"), size=9.5, anchor="start", fill="var(--amber)")
    c.text(586, 97, T("and a new worker", "e uma worker nova"), size=9.5, anchor="start", fill="var(--amber)")
    c.caption = T("A fixed number of threads, started once; the queue is what absorbs the load.",
                  "Um número fixo de threads, iniciadas uma vez; é a fila que absorve a carga.")
    return c


def clus(T):
    c = Canvas(720, 230, T(
        "The cluster module. Connections arrive at port 3000, which the primary process holds. The primary hands each new "
        "connection to the next of four worker processes in turn; each worker is a full copy of the program with its own "
        "memory and event loop. When a worker dies the primary starts another.",
        "O módulo cluster. As conexões chegam na porta 3000, que o processo primário segura. O primário entrega cada conexão "
        "nova à próxima de quatro workers, em rodízio; cada worker é uma cópia inteira do programa, com a sua memória e o "
        "seu event loop. Quando uma worker morre o primário inicia outra."))
    c.text(70, 80, T("connections", "conexões"), size=10, fill="var(--paper-dim)")
    for i in range(3):
        c.line(20, 100 + i * 14, 128, 112, stroke="var(--paper-dim)")
    c.line(128, 112, 168, 112, stroke="var(--paper-dim)", arrow=True)
    c.rect(170, 72, 160, 80, fill="var(--ink)", stroke="var(--amber)")
    c.text(250, 96, T("primary", "primário"), size=11, fill="var(--amber)")
    c.text(250, 116, ":3000", mono=True, size=10)
    c.text(250, 136, T("serves nothing itself", "não atende nada"), size=9, fill="var(--paper-dim)")
    for i in range(4):
        y = 14 + i * 52
        c.line(330, 112, 438, y + 20, stroke="var(--phosphor)", arrow=True)
        c.rect(440, y, 200, 40, fill="var(--panel)", stroke="var(--wire)")
        c.text(540, y + 13, T(f"worker {i + 1}", f"worker {i + 1}"), size=10)
        c.text(540, y + 28, T("its own memory and loop", "a sua memória e o seu loop"), size=9, fill="var(--paper-dim)")
    c.text(250, 190, T("in turn, on Linux", "em rodízio, no Linux"), size=9.5, fill="var(--phosphor)")
    c.text(250, 210, T("a worker dies: fork another", "uma worker morre: fork de outra"), size=9.5, fill="var(--amber)")
    c.caption = T("One port, one primary, a copy of the whole server per processor.",
                  "Uma porta, um primário, uma cópia do servidor inteiro por processador.")
    return c


def apart(T):
    c = Canvas(720, 240, T(
        "Why the links service breaks in a cluster. Four workers each hold their own Map of links. A link created on worker "
        "4 exists only in worker 4's Map, so the other three answer 404 for it. Each worker writes its whole Map over the "
        "same file, so the file holds whatever the last writer knew.",
        "Por que o serviço links quebra num cluster. Quatro workers guardam cada uma o seu Map de links. Um link criado na "
        "worker 4 só existe no Map da worker 4, então as outras três respondem 404 para ele. Cada worker grava o seu Map "
        "inteiro por cima do mesmo arquivo, então o arquivo guarda o que a última a escrever sabia."))
    for i in range(4):
        x = 20 + i * 172
        has = i == 3
        c.rect(x, 30, 160, 100, fill="var(--panel)", stroke="var(--phosphor)" if has else "var(--wire)")
        c.text(x + 80, 48, f"worker {i + 1}", size=10)
        c.text(x + 80, 72, "Map", mono=True, size=10, fill="var(--paper-dim)")
        c.text(x + 80, 96, T("the new link", "o link novo") if has else T("(empty)", "(vazio)"), size=9.5,
               fill="var(--phosphor)" if has else "var(--paper-dim)")
        c.text(x + 80, 116, "302" if has else "404", mono=True, size=10, fill="var(--phosphor)" if has else "var(--amber)")
        c.line(x + 80, 130, 360, 180, stroke="var(--amber)" if i == 2 else "var(--wire)", dash=None if i == 2 else "3 3")
    c.rect(260, 182, 200, 40, fill="var(--ink)", stroke="var(--amber)")
    c.text(360, 197, "demo/cluster.json", mono=True, size=10)
    c.text(360, 212, T("whatever the last save held", "o que o último save tinha"), size=9, fill="var(--amber)")
    c.caption = T("State in a variable is state per worker: the workers disagree, and the file keeps the last word.",
                  "Estado numa variável é estado por worker: as workers discordam, e o arquivo fica com a última palavra.")
    return c


def choose(T):
    c = Canvas(720, 250, T(
        "A decision tree. Is the slow part waiting on something outside? Then one process is enough. Is it another "
        "program? Use execFile or spawn. Is it a calculation? Use a worker thread, or a pool for many. Does the whole "
        "server need every processor? Use cluster or several copies, but only if nothing is kept in memory between "
        "requests.",
        "Uma árvore de decisão. A parte lenta está esperando algo de fora? Então um processo basta. É outro programa? Use "
        "execFile ou spawn. É um cálculo? Use uma worker thread, ou um pool para muitos. O servidor inteiro precisa de todos "
        "os processadores? Use cluster ou várias cópias, mas só se nada ficar na memória entre pedidos."))
    q = [(T("waiting on the disk, network, a database?", "esperando o disco, a rede, um banco?"), T("one process is enough", "um processo basta")),
         (T("another program to run?", "outro programa para rodar?"), "execFile / spawn"),
         (T("a calculation that blocks the loop?", "um cálculo que bloqueia o loop?"), T("a worker, or a pool", "uma worker, ou um pool")),
         (T("the whole server on every processor?", "o servidor inteiro em todo processador?"), T("cluster, if no state in memory", "cluster, se não houver estado na memória"))]
    for i, (ask, ans) in enumerate(q):
        y = 18 + i * 56
        c.rect(20, y, 320, 40, fill="var(--panel)", stroke="var(--wire)")
        c.text(180, y + 20, ask, size=10)
        c.line(340, y + 20, 418, y + 20, stroke="var(--phosphor)", arrow=True)
        c.text(379, y + 12, T("yes", "sim"), size=9, fill="var(--phosphor)")
        c.rect(420, y, 280, 40, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(560, y + 20, ans, size=10, mono=(i == 1), fill="var(--phosphor)")
        if i < 3:
            c.line(60, y + 40, 60, y + 54, stroke="var(--paper-dim)", arrow=True)
            c.text(70, y + 48, T("no", "não"), size=9, anchor="start", fill="var(--paper-dim)")
    c.caption = T("Ask in this order, and stop at the first yes: each answer down the list costs more than the one above.",
                  "Pergunte nesta ordem, e pare no primeiro sim: cada resposta mais abaixo custa mais que a de cima.")
    return c


FIGURES = [("graceful-shutdown", shutdown), ("child-processes", shell), ("talking-to-a-child", procs),
           ("sharing-memory", three), ("a-worker-pool", pool), ("cluster", clus),
           ("what-cluster-does-not-share", apart), ("choosing", choose)]
