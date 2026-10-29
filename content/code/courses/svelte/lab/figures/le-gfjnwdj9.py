from fig import Canvas


def prg(T):
    c = Canvas(720, 300, T(
        "Post/Redirect/Get, as three exchanges between the browser on the left and the server on the right. First the "
        "browser sends POST /courses/guitar with date and minutes; the server runs the action, which saves the session, "
        "and answers 303 See Other with a Location header naming /courses/guitar. Then the browser sends GET "
        "/courses/guitar; the server runs the load functions, which read the file again, and answers 200 with the page. "
        "What the browser now shows is the answer to a GET, so reloading it only reads the page again.",
        "Post/Redirect/Get, como três trocas entre o navegador à esquerda e o servidor à direita. Primeiro o navegador "
        "envia POST /courses/guitar com date e minutes; o servidor roda a action, que salva a sessão, e responde 303 See "
        "Other com um cabeçalho Location que aponta para /courses/guitar. Depois o navegador envia GET /courses/guitar; o "
        "servidor roda as funções load, que leem o arquivo de novo, e responde 200 com a página. O que o navegador mostra "
        "agora é a resposta a um GET, então recarregar só lê a página de novo."))
    c.text(90, 20, T("browser", "navegador"), size=11, weight="600", fill="var(--phosphor)")
    c.text(630, 20, T("server", "servidor"), size=11, weight="600", fill="var(--amber)")
    c.line(90, 32, 90, 262, stroke="var(--wire)", dash="3 4")
    c.line(630, 32, 630, 262, stroke="var(--wire)", dash="3 4")
    c.line(92, 60, 520, 60, stroke="var(--phosphor)", arrow=True)
    c.text(300, 50, "POST /courses/guitar  date=2026-10-21&minutes=30", mono=True, size=9.5)
    c.rect(522, 42, 190, 40, fill="var(--panel)", stroke="var(--amber)")
    c.text(617, 56, T("the action saves", "a action salva"), size=9.5)
    c.text(617, 71, "addSession(…)", mono=True, size=9, fill="var(--paper-dim)")
    c.line(520, 110, 94, 110, stroke="var(--amber)", arrow=True)
    c.text(300, 100, "303 See Other   Location: /courses/guitar", mono=True, size=9.5)
    c.line(92, 160, 520, 160, stroke="var(--phosphor)", arrow=True)
    c.text(300, 150, "GET /courses/guitar", mono=True, size=9.5)
    c.rect(522, 142, 190, 40, fill="var(--panel)", stroke="var(--amber)")
    c.text(617, 156, T("the load functions read", "as funções load leem"), size=9.5)
    c.text(617, 171, "readPlanner()", mono=True, size=9, fill="var(--paper-dim)")
    c.line(520, 210, 94, 210, stroke="var(--amber)", arrow=True)
    c.text(300, 200, T("200, the page with the new session", "200, a página com a sessão nova"), size=9.5)
    c.text(360, 284, T("reloading now repeats the GET, which only reads",
                       "recarregar agora repete o GET, que só lê"), size=10, fill="var(--paper-dim)")
    c.caption = T("A form that worked is answered with a redirect, so the page on the screen is the answer to a GET.",
                  "Um formulário que deu certo é respondido com um redirecionamento, então a página na tela é a resposta a um GET.")
    return c


def both(T):
    c = Canvas(720, 330, T(
        "The same form sent two ways. Left, with JavaScript off: the browser sends the form with POST, the action "
        "answers 303, the browser asks for the whole page with GET, and the server renders it. Right, with "
        "use:enhance: the browser's script stops the submission and sends the same fields with fetch; the action "
        "answers with JSON saying redirect; the script asks for __data.json, the load functions' data and not a page, "
        "and updates the page already on the screen. The action and the load functions are the same code in both.",
        "O mesmo formulário enviado de dois jeitos. À esquerda, com JavaScript desligado: o navegador envia o "
        "formulário com POST, a action responde 303, o navegador pede a página inteira com GET, e o servidor a "
        "renderiza. À direita, com use:enhance: o script do navegador interrompe o envio e manda os mesmos campos com "
        "fetch; a action responde com JSON dizendo redirect; o script pede __data.json, os dados das funções load e "
        "não uma página, e atualiza a página que já está na tela. A action e as funções load são o mesmo código nos "
        "dois."))
    for col, (title, steps) in enumerate([
        (T("JavaScript off", "JavaScript desligado"), [
            ("POST", T("the browser sends the form", "o navegador envia o formulário")),
            ("303", T("the action saves and redirects", "a action salva e redireciona")),
            ("GET", T("the browser asks for the page", "o navegador pede a página")),
            ("HTML", T("a whole new page", "uma página nova inteira"))]),
        (T("use:enhance", "use:enhance"), [
            ("fetch POST", T("the same fields, from a script", "os mesmos campos, de um script")),
            ("JSON", T("the same action, its answer as data", "a mesma action, a resposta como dados")),
            ("__data.json", T("the load functions run again", "as funções load rodam de novo")),
            ("DOM", T("the page already on the screen", "a página que já está na tela"))])]):
        x0 = 20 + col * 360
        c.text(x0 + 160, 20, title, size=11, weight="600", mono=(col == 1),
               fill="var(--amber)" if col == 0 else "var(--phosphor)")
        for k, (tag, what) in enumerate(steps):
            y = 40 + k * 64
            c.rect(x0, y, 320, 46, fill="var(--panel)", stroke="var(--amber)" if col == 0 else "var(--phosphor)")
            c.text(x0 + 14, y + 23, tag, mono=True, size=10, anchor="start",
                   fill="var(--amber)" if col == 0 else "var(--phosphor)")
            c.text(x0 + 120, y + 23, what, size=10, anchor="start")
            if k < 3:
                c.line(x0 + 160, y + 46, x0 + 160, y + 62, stroke="var(--paper-dim)", arrow=True)
    c.text(360, 312, T("the action and the load functions are the same code on both sides",
                       "a action e as funções load são o mesmo código dos dois lados"), size=10, fill="var(--paper-dim)")
    c.caption = T("use:enhance changes how the form travels and what comes back, not what the server does with it.",
                  "O use:enhance muda como o formulário viaja e o que volta, não o que o servidor faz com ele.")
    return c


FIGURES = [("default-action", prg), ("use-enhance", both)]
