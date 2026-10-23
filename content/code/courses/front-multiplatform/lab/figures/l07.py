"""Lesson 7: the annotated App.tsx, and the layers figure."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent / "l07-App.tsx").read_text().rstrip("\n")
chunks = SRC.split("\n\n")
NOTES = [
 ("React Native's components come from `react-native`, not from the DOM, and the planner's rules and data from the two files copied from `~/planner`. Importing JSON works as it does with Vite.",
  "Os componentes do React Native vêm de `react-native`, não do DOM, e as regras e os dados do planner dos dois arquivos copiados de `~/planner`. Importar JSON funciona como no Vite."),
 ("On a phone there is no address bar, so `location` does not exist; the check keeps the `?today=` of lesson 1 working in the browser and falls back to the real date everywhere else.",
  "Num celular não há barra de endereço, então `location` não existe; o teste mantém o `?today=` da aula 1 funcionando no navegador e cai na data real em qualquer outro lugar."),
 ("The component. Two pieces of state, the plan and the open course, and the week's total worked out from them on every draw by `weekTotal`, unchanged. Pressing a course opens or closes it; pressing **Mark done** replaces the plan with the one `markDone` returns. `role` tells assistive technology what each element is, as `<h1>` and `<button>` did on the web.",
  "O componente. Dois estados, o plano e o curso aberto, e o total da semana calculado a partir deles a cada desenho pelo `weekTotal`, sem mudança. Apertar um curso o abre ou fecha; apertar **Mark done** troca o plano pelo que o `markDone` devolve. O `role` diz à tecnologia assistiva o que cada elemento é, como `<h1>` e `<button>` faziam na web."),
 ("Styles are JavaScript objects, with names that look like CSS in camelCase and numbers without units. Lesson 8 is about what is and is not there.",
  "Os estilos são objetos JavaScript, com nomes que parecem CSS em camelCase e números sem unidade. A aula 8 é sobre o que existe e o que não existe ali."),
]
assert len(chunks) == len(NOTES), (len(chunks), len(NOTES))
parts = [(c + ("\n" if i < len(chunks) - 1 else ""), en, pt) for i, (c, (en, pt)) in enumerate(zip(chunks, NOTES))]
EXAMPLES = {"the-rules-come-along": [{"language": "typescript", "file": "App.tsx", "parts": parts}]}

T = {
 "en": dict(aria="The layers of a React Native app on a phone. Your components and planner.ts are JavaScript, run by the Hermes engine. React works out what the screen should be. The renderer, Fabric, with the Yoga layout engine, creates and lays out native views. Those are the platform's own controls: a TextView or a UILabel for Text, a native view for Pressable. JSI joins the JavaScript to the native side. There is no WebView anywhere.",
   js="JavaScript, in Hermes", comp=["your components,", "and src/planner.ts"], react=["React: what the", "screen should be"], fabric=["Fabric and Yoga:", "views and layout"],
   native="the platform's own views", nat=["<Text> → TextView,", "UILabel"], nat2=["<Pressable> → a", "native touch view"], jsi="JSI", none="no WebView, no HTML, no CSS",
   cap="Your code still runs as JavaScript. What reaches the screen is a description, turned into the views a Kotlin or Swift app would have."),
 "pt": dict(aria="As camadas de um app React Native num celular. Os seus componentes e o planner.ts são JavaScript, rodado pelo motor Hermes. O React calcula o que a tela deve ser. O renderizador, o Fabric, com o motor de layout Yoga, cria e posiciona views nativas. Essas são os controles da própria plataforma: uma TextView ou um UILabel para Text, uma view nativa para Pressable. A JSI liga o JavaScript ao lado nativo. Não há WebView em lugar nenhum.",
   js="JavaScript, no Hermes", comp=["os seus componentes,", "e o src/planner.ts"], react=["React: o que a", "tela deve ser"], fabric=["Fabric e Yoga:", "views e layout"],
   native="as views da própria plataforma", nat=["<Text> → TextView,", "UILabel"], nat2=["<Pressable> → uma", "view nativa de toque"], jsi="JSI", none="sem WebView, sem HTML, sem CSS",
   cap="O seu código continua rodando como JavaScript. O que chega à tela é uma descrição, transformada nas views que um app Kotlin ou Swift teria."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l07-layers", 720, 230, t["aria"])
    f.rect(20, 20, 300, 170, stroke="phosphor", dashed=True, fill="ink")
    f.text(34, 36, t["js"], anchor="start", size=9.5, fill="phosphor", italic=True)
    f.box(40, 52, 260, 46, t["comp"], stroke="wire", size=9.5)
    f.box(40, 120, 260, 46, t["react"], stroke="wire", size=9.5)
    f.arrow([(170, 98), (170, 120)])
    f.box(360, 82, 140, 50, t["fabric"], stroke="amber", size=9.5)
    f.arrow([(300, 143), (360, 115)])
    f.text(330, 98, t["jsi"], size=9, fill="amber", bold=True)
    f.text(610, 36, t["native"], size=9.5, fill="paper-dim", italic=True)
    f.box(530, 52, 160, 46, t["nat"], stroke="phosphor", size=9.5, mono=True)
    f.box(530, 120, 160, 46, t["nat2"], stroke="phosphor", size=9.5)
    f.arrow([(500, 100), (530, 75)])
    f.arrow([(500, 115), (530, 143)])
    f.text(360, 214, t["none"], size=9.5, fill="paper-dim", italic=True)
    same = None if lang == "en" else ["JSI"]
    return {"l07-layers": f.json(t["cap"], same=same)}
