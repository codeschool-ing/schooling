"""Lesson 13's figures. The rows drawn are the lesson's own files, read by
pqfiles, so a figure cannot disagree with the text the student saved."""
from fig import Svg
from pqfiles import WEB, files, web_orders


def split(t):
    line = files()["freight-2026-q3.csv"].split("\n")[1]
    s = Svg(760, 228, "l13-split", t(
        f"One line of the courier's file, {line}, split two ways. Split at the semicolons it gives four "
        "cells: the order, the date, the weight and the freight. Split at the commas it gives three "
        "fragments, because the commas are the decimal marks inside the numbers.",
        f"Uma linha do arquivo da transportadora, {line}, dividida de dois jeitos. Dividida nos pontos e "
        "vírgulas, dá quatro células: o pedido, a data, o peso e o frete. Dividida nas vírgulas, dá três "
        "pedaços, porque as vírgulas são as marcas decimais dentro dos números."))
    s.sans(30, 20, t("one line of freight-2026-q3.csv", "uma linha de freight-2026-q3.csv"), size=12, weight="600")
    s.rect(30, 34, 700, 30, fill="var(--scan)")
    s.mono(42, 49.5, line, size=13)
    # Split at ;
    s.sans(30, 92, t("split at the semicolons: what the file means",
                     "dividida nos pontos e vírgulas: o que o arquivo quer dizer"),
           size=11.5, fill="var(--phosphor)", weight="600")
    parts = line.split(";")
    s.grid(30, 106, [120, 150, 110, 110], [parts], rowh=28, header=False, size=12,
           colours={(0, i): "var(--phosphor)" for i in range(4)})
    s.sans(530, 120, t("4 fields, as the header says", "4 campos, como o cabeçalho diz"), size=11,
           fill="var(--paper-dim)")
    # Split at ,
    s.sans(30, 170, t("split at the commas: what an English-language Excel does on a double-click",
                      "dividida nas vírgulas: o que um Excel em inglês faz num clique duplo"),
           size=11.5, fill="var(--amber)", weight="600")
    frags = line.split(",")
    s.grid(30, 184, [190, 90, 60], [frags], rowh=28, header=False, size=12,
           colours={(0, i): "var(--amber)" for i in range(3)})
    s.sans(400, 198, t("3 fragments; the numbers are cut in half", "3 pedaços; os números cortados ao meio"),
           size=11, fill="var(--paper-dim)")
    cap = t("The delimiter decides where a value ends. Split at the character the file was written with, "
            "the line is four fields; split at the comma, the decimal marks become boundaries and the "
            "numbers are cut in two.",
            "O delimitador decide onde um valor termina. Dividida no caractere com que o arquivo foi "
            "escrito, a linha tem quatro campos; dividida na vírgula, as marcas decimais viram fronteiras "
            "e os números são cortados em dois.")
    return s, cap


def folder(t):
    rows = web_orders()
    per = {n: [r for r in rows if r["Source.Name"] == n] for n in WEB}
    s = Svg(760, 360, "l13-folder", t(
        f"Three files in the web folder, holding {', '.join(str(len(per[n])) for n in WEB)} orders, are "
        f"combined into one query of {len(rows)} rows. Each file's header line is used once, for the "
        "column names, and a first column, Source.Name, records which file each row came from.",
        f"Três arquivos na pasta web, com {', '.join(str(len(per[n])) for n in WEB)} pedidos, são "
        f"combinados numa consulta de {len(rows)} linhas. A linha de cabeçalho de cada arquivo é usada "
        "uma vez, para os nomes das colunas, e uma primeira coluna, Source.Name, registra de que arquivo "
        "veio cada linha."))
    s.sans(30, 20, t("the web folder", "a pasta web"), size=12, weight="600")
    y = 40
    for n in WEB:
        s.rect(30, y, 190, 92, fill="var(--panel)", rx=4)
        s.path(f"M190 {y} L220 {y + 30}", stroke="var(--wire)")
        s.mono(42, y + 16, n, size=11.5, weight="600")
        s.mono(42, y + 36, "Order,Date,SKU,…", size=10, fill="var(--paper-dim)")
        first = per[n][0]
        s.mono(42, y + 54, f"{first['Order']},{first['Date'].isoformat()},…", size=10)
        s.mono(42, y + 70, "…", size=10)
        s.sans(42, y + 84, t(f"{len(per[n])} orders", f"{len(per[n])} pedidos"), size=10.5,
               fill="var(--phosphor)")
        y += 110
    s.arrow(232, 186, 290, 186)
    s.sans(261, 168, t("Combine", "Combinar"), size=11, anchor="middle", fill="var(--amber)", weight="600")
    s.sans(300, 20, t("one query, WebOrders", "uma consulta, WebOrders"), size=12, weight="600")
    head = ["Source.Name", "Order", "Date", "SKU", "Qty"]
    body = [head]
    marks = {}
    for n in WEB:
        for r in per[n][:2]:
            body.append([n, r["Order"], r["Date"].isoformat(), r["SKU"], str(r["Qty"])])
        body.append(["…", "…", "…", "…", "…"])
    for i in range(1, len(body)):
        marks[(i, 0)] = "var(--amber)"
    s.grid(300, 40, [130, 62, 92, 66, 40], body, rowh=24, colours=marks, size=10.5, anchors={4: "end"})
    s.sans(300, 40 + len(body) * 24 + 20, t(f"{len(rows)} rows: {' + '.join(str(len(per[n])) for n in WEB)}",
                                         f"{len(rows)} linhas: {' + '.join(str(len(per[n])) for n in WEB)}"),
           size=11, fill="var(--phosphor)")
    s.sans(300, 40 + len(body) * 24 + 38, t("Source.Name says which file each row came from",
                                         "Source.Name diz de que arquivo veio cada linha"),
           size=11, fill="var(--amber)")
    cap = t("From Folder applies the same steps to every file and stacks the results. Saving a fourth file "
            "in the folder and refreshing adds its rows; nothing in the query changes.",
            "De Pasta aplica as mesmas etapas a cada arquivo e empilha os resultados. Salvar um quarto "
            "arquivo na pasta e atualizar acrescenta as linhas dele; nada na consulta muda.")
    return s, cap


FIGS = {"l13-split": split, "l13-folder": folder}
