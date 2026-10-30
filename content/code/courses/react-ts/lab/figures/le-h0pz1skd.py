from fig import Fig

r = Fig("what-runs", 720, 300,
        {"en": "What runs when a session is clicked, in each of the four. React: the whole component function runs "
               "again and its result is compared with the last one. Vue: the code in script setup ran once; the "
               "template's render function runs again and is compared. Svelte: the script ran once; only the "
               "compiled updates for the text and attributes that read the state run. Angular: the class was "
               "created once; the template is checked again because a signal it reads changed.",
         "pt": "O que roda quando uma sessão é clicada, em cada um dos quatro. React: a função inteira do "
               "componente roda de novo e o resultado é comparado com o anterior. Vue: o código do script setup "
               "rodou uma vez; a função de renderização do template roda de novo e é comparada. Svelte: o script "
               "rodou uma vez; só rodam as atualizações compiladas do texto e dos atributos que leem o estado. "
               "Angular: a classe foi criada uma vez; o template é conferido de novo porque um signal que ele lê "
               "mudou."},
        {"en": "Only React runs your component's own code again on every change.",
         "pt": "Só o React roda de novo o código do seu componente a cada mudança."})
cols = [("React", {"en": "the whole function", "pt": "a função inteira"}, ["Sessions()"],
         {"en": "compare the result", "pt": "comparar o resultado"}, "amber"),
        ("Vue", {"en": "the template's render", "pt": "o render do template"}, ["render()"],
         {"en": "compare the result", "pt": "comparar o resultado"}, "phosphor"),
        ("Svelte", {"en": "the compiled updates", "pt": "as atualizações compiladas"}, ["{done}", "{s.done}"],
         {"en": "nothing to compare", "pt": "nada a comparar"}, "phosphor"),
        ("Angular", {"en": "the template's check", "pt": "a conferência do template"}, ["done()", "s.done"],
         {"en": "change what differs", "pt": "mudar o que difere"}, "phosphor")]
r.text(14, 62, {"en": "on load", "pt": "na carga"}, tone="dim", size=10.5)
r.text(14, 152, {"en": "per click", "pt": "por clique"}, tone="dim", size=10.5)
for i, (name, what, code, after, tone) in enumerate(cols):
    x = 90 + i * 158
    r.text(x + 70, 24, name, anchor="middle", tone="paper", size=12, weight="600")
    r.box(x, 44, 140, 34, ["Sessions ran"], mono=True, tone="phosphor", size=10)
    r.box(x, 110, 140, 86, code, mono=True, tone=tone, size=10)
    r.text(x + 70, 214, what, anchor="middle", tone=tone, size=10.5)
    r.text(x + 70, 234, after, anchor="middle", tone="dim", size=10)
r.text(90 + 70, 266, {"en": "Sessions ran ×3", "pt": "Sessions ran ×3"}, anchor="middle", tone="amber", size=10.5)
for i in range(1, 4):
    r.text(90 + i * 158 + 70, 266, {"en": "Sessions ran ×1", "pt": "Sessions ran ×1"}, anchor="middle", tone="phosphor", size=10.5)

s = Fig("sizes", 720, 230,
        {"en": "The JavaScript each production build wrote, compressed with gzip -9: Svelte 13,095 bytes, Vue 24,687, "
               "Angular 60,798 and React 67,948, for the same component.",
         "pt": "O JavaScript que cada build de produção escreveu, comprimido com gzip -9: Svelte 13.095 bytes, Vue "
               "24.687, Angular 60.798 e React 67.948, para o mesmo componente."},
        {"en": "For one small component, the size is the framework's own, not your code's.",
         "pt": "Para um componente pequeno, o tamanho é o do framework, não o do seu código."})
data = [("Svelte", 13095), ("Vue", 24687), ("Angular", 60798), ("React", 67948)]
for i, (name, n) in enumerate(data):
    y = 26 + i * 46
    w = round(n / 67948 * 470)
    s.text(96, y + 20, name, anchor="end", tone="paper", size=11)
    s.box(108, y + 4, w, 26, [], tone="phosphor", fill="ink")
    s.text(108 + w + 10, y + 21, {"en": f"{n:,} bytes", "pt": f"{n:,} bytes".replace(",", ".")}, mono=True,
           tone="phosphor", size=10.5)
FIGS = [r, s]
