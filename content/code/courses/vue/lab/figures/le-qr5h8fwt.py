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


def two_halves(T):
    c = Canvas(720, 235, T(
        "The two halves of a scoped style, side by side. On the left, the footer's HTML as the page has it: the "
        "footer element carries data-v-6704560a, AppFooter's own attribute, and a second one, data-v-7a7a37b1, "
        "which is App.vue's, because the root element of a child also gets its parent's attribute; the paragraph "
        "inside carries data-v-6704560a only. On the right, the style block as Vite sends it: the rule written "
        "for p has become p[data-v-6704560a], with colour #666 and font size 0.875rem. Below, the browser "
        "applies the rule only where both match.",
        "As duas metades de um estilo scoped, lado a lado. À esquerda, o HTML do footer como a página o tem: o "
        "elemento footer carrega data-v-6704560a, o atributo do próprio AppFooter, e um segundo, data-v-7a7a37b1, "
        "que é o do App.vue, porque o elemento raiz de um filho também recebe o atributo do pai; o parágrafo de "
        "dentro carrega só data-v-6704560a. À direita, o bloco de estilo como o Vite o envia: a regra escrita "
        "para p virou p[data-v-6704560a], com cor #666 e tamanho de fonte 0.875rem. Embaixo, o navegador aplica "
        "a regra só onde os dois casam."))
    c.text(180, 20, T("the HTML: an attribute on every element", "o HTML: um atributo em cada elemento"), size=10.5,
           fill="var(--paper-dim)")
    c.rect(30, 36, 300, 124, fill="var(--ink)", stroke="var(--wire)")
    rows = [(0, "<footer data-v-6704560a", "var(--phosphor)"), (8, "data-v-7a7a37b1>", "var(--paper-dim)"),
            (2, "<p data-v-6704560a>", "var(--phosphor)"), (0, "</footer>", "var(--paper)")]
    for i, (ind, s, f) in enumerate(rows):
        c.text(46 + ind * 6.3, 56 + i * 20, s, mono=True, size=10.5, anchor="start", fill=f)
    c.text(180, 145, T("the second one is App.vue's, on the child's root", "o segundo é o do App.vue, na raiz do filho"),
           size=9.5, fill="var(--paper-dim)")
    c.text(540, 20, T("the stylesheet: a selector rewritten", "a folha de estilo: um seletor reescrito"), size=10.5,
           fill="var(--paper-dim)")
    c.rect(390, 36, 300, 124, fill="var(--ink)", stroke="var(--wire)")
    c.text(406, 56, "p {", mono=True, size=10.5, anchor="start", fill="var(--paper-dim)")
    c.text(674, 56, T("as written", "como foi escrito"), size=9.5, anchor="end", fill="var(--paper-dim)")
    c.text(406, 80, "p[data-v-6704560a] {", mono=True, size=10.5, anchor="start", fill="var(--phosphor)")
    c.text(674, 80, T("as Vite sends it", "como o Vite envia"), size=9.5, anchor="end", fill="var(--phosphor)")
    c.text(419, 100, "color: #666;", mono=True, size=10.5, anchor="start")
    c.text(419, 120, "font-size: 0.875rem;", mono=True, size=10.5, anchor="start")
    c.text(406, 140, "}", mono=True, size=10.5, anchor="start")
    c.line(180, 162, 290, 188, stroke="var(--phosphor)", arrow=True)
    c.line(540, 162, 430, 188, stroke="var(--phosphor)", arrow=True)
    c.rect(200, 190, 320, 34, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(360, 207, T("the browser applies the rule where both match", "o navegador aplica a regra onde os dois casam"),
           size=10.5, fill="var(--phosphor)")
    c.caption = T("The compiler marks the elements and rewrites the selector; the browser runs ordinary CSS.",
                  "O compilador marca os elementos e reescreve o seletor; o navegador roda CSS comum.")
    return c


FIGURES = [("anatomy", compile_path), ("scoped-style", two_halves)]
