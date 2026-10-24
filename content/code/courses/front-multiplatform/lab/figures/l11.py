"""Lesson 11: Electron's two processes."""
from fig import Fig

T = {
 "en": dict(aria="Electron's two processes. The main process is Node.js: it creates the window, serves the site under app://planner/, and answers export-plan by writing a file in the app's data folder. The renderer process is a Chromium page with the planner in it and no Node.js. The preload script runs in the renderer, in a world of its own, and puts window.desktop.exportPlan on the page. A press calls it, IPC carries the call to the main process with invoke and handle, and the file's path comes back as the result of a Promise.",
   main="the main process: Node.js", m1=["creates the window,", "serves app://planner/"], m2=["ipcMain.handle(", "\"export-plan\")"], m3=["writes the file in", "~/.config/planner"],
   rend="a renderer: a Chromium page", r1=["the planner,", "with no Node.js"], pre=["the preload: puts", "window.desktop on it"],
   ipc="IPC: invoke and handle", back="the file's path, as a Promise",
   cap="The page asks; only the main process acts. The preload is the one door, and it opens onto one function."),
 "pt": dict(aria="Os dois processos do Electron. O processo principal é Node.js: ele cria a janela, serve o site em app://planner/, e responde ao export-plan escrevendo um arquivo na pasta de dados do app. O processo renderizador é uma página do Chromium com o planner dentro e sem Node.js. O script de preload roda no renderizador, num mundo próprio, e põe window.desktop.exportPlan na página. Um toque o chama, o IPC leva a chamada ao processo principal com invoke e handle, e o caminho do arquivo volta como resultado de uma Promise.",
   main="o processo principal: Node.js", m1=["cria a janela,", "serve app://planner/"], m2=["ipcMain.handle(", "\"export-plan\")"], m3=["escreve o arquivo em", "~/.config/planner"],
   rend="um renderizador: uma página do Chromium", r1=["o planner,", "sem Node.js"], pre=["o preload: põe", "window.desktop nela"],
   ipc="IPC: invoke e handle", back="o caminho do arquivo, como Promise",
   cap="A página pede; só o processo principal age. O preload é a única porta, e ela abre para uma função."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l11-processes", 720, 250, t["aria"])
    f.rect(20, 20, 300, 210, stroke="amber", dashed=True, fill="ink")
    f.text(34, 36, t["main"], anchor="start", size=9.5, fill="amber", italic=True)
    f.box(40, 52, 260, 44, t["m1"], stroke="wire", size=9.5)
    f.box(40, 110, 260, 44, t["m2"], stroke="amber", size=9.5, mono=True)
    f.box(40, 168, 260, 44, t["m3"], stroke="wire", size=9.5)
    f.arrow([(170, 154), (170, 168)])
    f.rect(400, 20, 300, 210, stroke="phosphor", dashed=True, fill="ink")
    f.text(414, 36, t["rend"], anchor="start", size=9.5, fill="phosphor", italic=True)
    f.box(420, 52, 260, 44, t["r1"], stroke="wire", size=9.5)
    f.box(420, 130, 260, 50, t["pre"], stroke="phosphor", size=9.5)
    f.arrow([(420, 145), (300, 128)], color="amber")
    f.text(360, 122, t["ipc"], size=8.5, fill="amber")
    f.arrow([(300, 140), (420, 165)], color="paper-dim", dashed=True)
    f.text(360, 172, t["back"], size=8.5, fill="paper-dim", italic=True)
    return {"l11-processes": f.json(t["cap"], same=None if lang == "en" else ["~/.config/planner"])}
