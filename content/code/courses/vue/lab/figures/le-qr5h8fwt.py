from fig import Canvas


def compile_path(T):
    c = Canvas(720, 230, T(
        "The journey of App.vue. On your machine, the Vue plugin inside Vite compiles the file into a JavaScript "
        "module whose template has become a render function. In the browser, running that function produces "
        "virtual nodes, plain objects that describe elements, and Vue's runtime builds the real DOM elements "
        "from them.",
        "O caminho do App.vue. Na sua máquina, o plugin do Vue dentro do Vite compila o arquivo num módulo "
        "JavaScript em que o template virou uma função de renderização. No navegador, rodar essa função produz "
        "nós virtuais, objetos simples que descrevem elementos, e o runtime do Vue constrói os elementos reais "
        "do DOM a partir deles."))
    c.rect(10, 10, 330, 210, fill="none", stroke="var(--wire)", dash="4 3")
    c.text(20, 26, T("your machine: the dev server", "a sua máquina: o servidor de desenvolvimento"), anchor="start", size=10.5, fill="var(--paper-dim)")
    c.rect(380, 10, 330, 210, fill="none", stroke="var(--wire)", dash="4 3")
    c.text(390, 26, T("the browser", "o navegador"), anchor="start", size=10.5, fill="var(--paper-dim)")
    # the file
    c.rect(30, 50, 120, 150, fill="var(--panel)", stroke="var(--wire)")
    c.text(90, 66, "App.vue", mono=True, size=11, weight="600")
    for i, s in enumerate(["<script setup>", "<template>", "<style scoped>"]):
        c.rect(40, 84 + i * 36, 100, 26, fill="var(--ink)", stroke="var(--phosphor-dim)")
        c.text(90, 97 + i * 36, s, mono=True, size=9.5, fill="var(--phosphor)")
    c.line(152, 125, 192, 125, stroke="var(--amber)", arrow=True)
    c.text(172, 112, T("compiles", "compila"), size=9.5, fill="var(--amber)")
    c.rect(196, 50, 128, 150, fill="var(--panel)", stroke="var(--wire)")
    c.text(260, 66, T("a JS module", "um módulo JS"), size=10.5, weight="600")
    c.text(260, 97, "_sfc_main", mono=True, size=9.5, fill="var(--phosphor)")
    c.text(260, 133, "_sfc_render()", mono=True, size=9.5, fill="var(--phosphor)")
    c.text(260, 169, "p[data-v-…]", mono=True, size=9.5, fill="var(--phosphor)")
    c.line(326, 125, 396, 125, stroke="var(--amber)", arrow=True)
    c.text(361, 112, "HTTP", mono=True, size=9.5, fill="var(--amber)")
    c.rect(400, 50, 140, 150, fill="var(--panel)", stroke="var(--wire)")
    c.text(470, 66, T("virtual nodes", "nós virtuais"), size=10.5, weight="600")
    for i, s in enumerate(['{ type: "h1" }', '{ type: "p" }', '{ type: "a" }']):
        c.text(470, 97 + i * 36, s, mono=True, size=9.5, fill="var(--phosphor)")
    c.line(542, 125, 572, 125, stroke="var(--amber)", arrow=True)
    c.rect(576, 50, 124, 150, fill="var(--panel)", stroke="var(--wire)")
    c.text(638, 66, T("the DOM", "o DOM"), size=10.5, weight="600")
    for i, s in enumerate(["<h1>", "<p>", "<a>"]):
        c.text(638, 97 + i * 36, s, mono=True, size=9.5, fill="var(--phosphor)")
    c.caption = T("The template never reaches the browser as markup. It arrives as a function, and the page is built "
                  "by running it.",
                  "O template nunca chega ao navegador como marcação. Ele chega como uma função, e a página é "
                  "construída rodando essa função.")
    return c


FIGURES = [("anatomy", compile_path)]
