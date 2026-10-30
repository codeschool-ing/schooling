"""Lesson 1: the threads, the bridge, and JSI."""
from fig import Fig

T = {
 "en": dict(
   t_aria="Three places work happens in a React Native app. On the JavaScript thread, Hermes runs your components and React, which renders elements. Yoga, in C++, computes the layout. On the main thread, the native views are mounted and drawn, and touches arrive; a touch travels to the JavaScript thread as an event, and the answer comes back as views.",
   js="JavaScript thread", js1=["Hermes runs your", "components and React"], render="1 · render",
   cpp="C++, shared", yoga=["Yoga: flexbox", "to sizes and positions"], layout="2 · layout",
   main="main thread", views=["native views:", "TextView, UILabel"], mount="3 · mount",
   touch="a touch arrives here", event="event", t_cap="Your code runs on the JavaScript thread. Only the main thread may touch a view, so the result is handed to it.",
   b_aria="The old architecture. The JavaScript side puts messages in a queue, such as create view 42 or set its text. The queue is serialised to JSON and crosses the bridge in a batch. The native side parses it and acts. Answers come back the same way, later, so every call is asynchronous and every value is copied.",
   bjs="JavaScript side", bq="a queue of messages", bridge="the bridge", bjson="JSON, in batches", bnat="native side", bparse=["parse, then", "create the views"],
   back="answers come back the same way, frames later", b_cap="Before 2024: nothing was shared, everything was a message, and every answer was a callback.",
   j_aria="The new architecture. JavaScript holds references to C++ objects through JSI and calls them directly, in the same call. Fabric keeps the tree of views in C++ and mounts native views on the main thread. TurboModules are native modules created the first time they are called. Codegen writes the C++ glue at build time from a typed TypeScript spec.",
   jjs="JavaScript, in Hermes", jcall="module.getString()", jsi="JSI", jdirect="a direct call, same thread",
   fabric=["Fabric: the tree", "of views, in C++"], turbo=["TurboModule:", "created on first use"],
   native=["Kotlin or Swift"], nviews=["native views,", "on the main thread"], codegen=["Codegen: C++ glue", "from a TypeScript spec"], build="written at build time",
   j_cap="Since 0.76 by default, and since 0.82 always: references instead of messages."),
 "pt": dict(
   t_aria="Três lugares onde o trabalho acontece num app React Native. Na thread de JavaScript, o Hermes roda os seus componentes e o React, que renderiza os elementos. O Yoga, em C++, calcula o layout. Na thread principal, as views nativas são montadas e desenhadas, e os toques chegam; um toque viaja até a thread de JavaScript como evento, e a resposta volta como views.",
   js="thread de JavaScript", js1=["o Hermes roda os seus", "componentes e o React"], render="1 · render",
   cpp="C++, compartilhado", yoga=["Yoga: flexbox em", "tamanhos e posições"], layout="2 · layout",
   main="thread principal", views=["views nativas:", "TextView, UILabel"], mount="3 · montagem",
   touch="um toque chega aqui", event="evento", t_cap="O seu código roda na thread de JavaScript. Só a thread principal pode mexer numa view, então o resultado é entregue a ela.",
   b_aria="A arquitetura antiga. O lado JavaScript põe mensagens numa fila, como criar a view 42 ou definir o texto dela. A fila é serializada em JSON e atravessa a ponte em lote. O lado nativo a interpreta e age. As respostas voltam do mesmo jeito, depois, então toda chamada é assíncrona e todo valor é copiado.",
   bjs="lado JavaScript", bq="uma fila de mensagens", bridge="a ponte", bjson="JSON, em lotes", bnat="lado nativo", bparse=["interpreta e", "cria as views"],
   back="as respostas voltam do mesmo jeito, quadros depois", b_cap="Antes de 2024: nada era compartilhado, tudo era mensagem, e toda resposta era um callback.",
   j_aria="A nova arquitetura. O JavaScript guarda referências a objetos C++ pela JSI e os chama diretamente, na mesma chamada. O Fabric mantém a árvore de views em C++ e monta as views nativas na thread principal. Os TurboModules são módulos nativos criados na primeira vez que são chamados. O Codegen escreve a cola em C++ na hora do build, a partir de uma spec em TypeScript tipada.",
   jjs="JavaScript, no Hermes", jcall="module.getString()", jsi="JSI", jdirect="chamada direta, mesma thread",
   fabric=["Fabric: a árvore", "de views, em C++"], turbo=["TurboModule:", "criado no primeiro uso"],
   native=["Kotlin ou Swift"], nviews=["views nativas, na", "thread principal"], codegen=["Codegen: cola em C++", "a partir de uma spec"], build="escrita na hora do build",
   j_cap="Desde a 0.76 por padrão, e desde a 0.82 sempre: referências em vez de mensagens."),
}


def figures(lang):
    t = T[lang]
    out = {}

    f = Fig("l01-threads", 720, 215, t["t_aria"])
    for x, title, color in ((20, t["js"], "phosphor"), (260, t["cpp"], "amber"), (500, t["main"], "phosphor")):
        f.text(x + 100, 38, title, size=10, fill=color, bold=True)
    f.box(40, 60, 160, 50, t["js1"], size=9.5)
    f.text(120, 128, t["render"], size=9.5, fill="paper-dim", italic=True)
    f.box(280, 60, 160, 50, t["yoga"], size=9.5)
    f.text(360, 128, t["layout"], size=9.5, fill="paper-dim", italic=True)
    f.box(520, 60, 160, 50, t["views"], size=9.5, mono=False)
    f.text(600, 128, t["mount"], size=9.5, fill="paper-dim", italic=True)
    f.arrow([(200, 85), (280, 85)])
    f.arrow([(440, 85), (520, 85)])
    f.text(600, 168, t["touch"], size=9.5, fill="paper-dim", italic=True)
    f.arrow([(560, 182), (560, 196), (120, 196), (120, 150)], dashed=True)
    f.text(340, 188, t["event"], size=9, fill="paper-dim")
    out["l01-threads"] = f.json(caption=t["t_cap"], same=None if lang == "en" else ["1 · render", "2 · layout", "TextView, UILabel"])

    f = Fig("l01-bridge", 720, 220, t["b_aria"])
    f.text(130, 38, t["bjs"], size=10, fill="phosphor", bold=True)
    f.text(130, 62, t["bq"], size=9.5, fill="paper-dim", italic=True)
    f.box(40, 76, 180, 26, ['{"op":"create","tag":42}'], mono=True, size=9)
    f.box(40, 108, 180, 26, ['{"op":"set","text":"Hi"}'], mono=True, size=9)
    f.box(40, 140, 180, 22, ["…"], mono=True, size=9)
    f.rect(270, 70, 180, 60, stroke="amber", fill="panel")
    f.text(360, 92, t["bridge"], size=10.5, fill="amber", bold=True)
    f.text(360, 112, t["bjson"], size=9.5, fill="paper")
    f.arrow([(220, 100), (270, 100)])
    f.arrow([(450, 100), (500, 100)])
    f.text(590, 38, t["bnat"], size=10, fill="phosphor", bold=True)
    f.box(510, 76, 170, 50, t["bparse"], size=9.5)
    f.arrow([(590, 170), (590, 196), (130, 196), (130, 170)], dashed=True)
    f.text(360, 208, t["back"], size=9.5, fill="paper-dim", italic=True)
    out["l01-bridge"] = f.json(caption=t["b_cap"])

    f = Fig("l01-jsi", 720, 270, t["j_aria"])
    f.text(120, 38, t["jjs"], size=10, fill="phosphor", bold=True)
    f.box(40, 60, 160, 34, [t["jcall"]], mono=True, size=9.5)
    f.text(120, 116, t["jdirect"], size=9, fill="paper-dim", italic=True)
    f.rect(250, 55, 50, 44, stroke="amber", fill="panel")
    f.text(275, 77, t["jsi"], size=11, fill="amber", bold=True)
    f.arrow([(200, 77), (250, 77)], both=True)
    f.box(330, 30, 170, 46, t["turbo"], stroke="phosphor", size=9.5)
    f.box(330, 96, 170, 46, t["fabric"], stroke="phosphor", size=9.5)
    f.arrow([(300, 70), (330, 53)])
    f.arrow([(300, 85), (330, 119)])
    f.box(530, 30, 170, 46, t["native"], size=9.5)
    f.box(530, 96, 170, 46, t["nviews"], size=9.5)
    f.arrow([(500, 53), (530, 53)])
    f.arrow([(500, 119), (530, 119)])
    f.box(250, 186, 250, 46, t["codegen"], stroke="amber", dashed=True, size=9.5)
    f.text(375, 250, t["build"], size=9, fill="paper-dim", italic=True)
    f.arrow([(375, 186), (375, 145)], dashed=True)
    out["l01-jsi"] = f.json(caption=t["j_cap"], same=None if lang == "en" else ["JSI", "TurboModule:"])
    return out
