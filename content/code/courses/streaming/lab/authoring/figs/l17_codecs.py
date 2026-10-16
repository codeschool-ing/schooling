NAME = "l17-codecs"
W, H = 720, 200
LABEL = ("A bar chart of bytes on disk per sale for the same 100 000 sales stored four ways: uncompressed 135.3, lz4 31.5, zstd 16.9, gzip 14.5.",
         "Um gráfico de barras de bytes em disco por venda para as mesmas 100 000 vendas guardadas de quatro jeitos: sem compressão 135,3, lz4 31,5, zstd 16,9, gzip 14,5.")
CAPTION = ("Bytes on disk per sale, measured: the same sales take an eighth of the space with zstd, and a little less with gzip.",
           "Bytes em disco por venda, medidos: as mesmas vendas ocupam um oitavo do espaço com zstd, e um pouco menos com gzip.")
PT = {"uncompressed": "sem compressão", "lz4": "lz4", "zstd": "zstd", "gzip": "gzip",
      "135.3": "135,3", "31.5": "31,5", "16.9": "16,9", "14.5": "14,5", "bytes per sale": "bytes por venda"}
SAME = []
def draw(s, t):
    rows = [("uncompressed", 135.3), ("lz4", 31.5), ("zstd", 16.9), ("gzip", 14.5)]
    x0, scale = 150, 3.6
    for i, (n, v) in enumerate(rows):
        y = 30 + i * 38
        s.text(x0 - 12, y + 12, t(n), size=10.5, anchor="end", mono=(n != "uncompressed"))
        s.rect(x0, y, v * scale, 24, fill="var(--phosphor-dim)" if i else "var(--panel)", stroke="var(--phosphor)", rx=2)
        s.text(x0 + v * scale + 8, y + 12, t(f"{v}"), size=10, anchor="start", mono=True)
    s.text(x0, 190, t("bytes per sale"), size=9.5, fill="var(--paper-dim)", anchor="start")
