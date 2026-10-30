from fig import Fig

f = Fig("dev-and-build", 720, 240,
        {"en": "Two ways the same source reaches a browser. With the development server: each file of src is "
               "translated when the browser asks for it, one request per module, and the dependencies come "
               "pre-bundled from node_modules/.vite/deps. With a build: everything is bundled ahead into a few "
               "files in dist/assets with hashed names, plus index.html and the files from public.",
         "pt": "Dois jeitos de o mesmo código chegar a um navegador. Com o servidor de desenvolvimento: cada arquivo de "
               "src é traduzido quando o navegador o pede, uma requisição por módulo, e as dependências vêm "
               "pré-empacotadas de node_modules/.vite/deps. Com um build: tudo é empacotado antes em poucos arquivos "
               "em dist/assets com nomes com hash, mais o index.html e os arquivos de public."},
        {"en": "Development translates on request; a build bundles ahead.",
         "pt": "O desenvolvimento traduz sob pedido; um build empacota antes."})
f.text(170, 22, "npm run dev", mono=True, anchor="middle", tone="phosphor", size=11)
for i, name in enumerate(["/src/main.tsx", "/src/Root.tsx", "/src/WeekScreen.tsx", "…"]):
    f.box(30, 36 + i * 34, 170, 26, name, mono=True, tone="phosphor", size=9.5)
f.box(30, 176, 170, 40, [".vite/deps/", "react.js · …"], mono=True, tone="wire", text_tone="paper", size=9.5)
f.text(215, 100, {"en": "one request", "pt": "uma requisição"}, tone="dim", size=10)
f.text(215, 116, {"en": "per module", "pt": "por módulo"}, tone="dim", size=10)
f.line(360, 20, 360, 220, tone="wire", dashed=True)
f.text(540, 22, "npm run build", mono=True, anchor="middle", tone="amber", size=11)
f.box(400, 40, 280, 30, "dist/index.html", mono=True, tone="amber", size=10)
f.box(400, 82, 280, 30, "assets/index-R8L4SX4s.js", mono=True, tone="amber", size=10)
f.box(400, 124, 280, 30, "assets/CourseScreen-jvv40fJe.js", mono=True, tone="amber", size=10)
f.box(400, 166, 280, 30, "courses.json · favicon.svg", mono=True, tone="wire", text_tone="paper", size=10)
f.text(540, 214, {"en": "copied from public/, no hash", "pt": "copiados de public/, sem hash"}, anchor="middle", tone="dim", size=10)

FIGS = [f]
