from fig import Fig

rt = Fig("routes", 720, 240,
         {"en": "The route tree. The route at slash draws Root, with an ErrorBoundary, RouteError. Inside Root's Outlet "
                "go its children: the index route, WeekScreen, for slash itself, and courses slash colon courseId, whose "
                "loader, courseLoader, runs first and whose component, CourseScreen, is loaded lazily. Below, three "
                "addresses and what each draws: slash draws Root and WeekScreen; slash courses slash spanish draws Root "
                "and CourseScreen; slash courses slash latin draws RouteError.",
          "pt": "A árvore de rotas. A rota em barra desenha o Root, com um ErrorBoundary, RouteError. No Outlet do Root vão "
                "os filhos: a rota índice, WeekScreen, para a própria barra, e courses barra dois-pontos courseId, cujo "
                "loader, courseLoader, roda primeiro e cujo componente, CourseScreen, é carregado sob demanda. Embaixo, "
                "três endereços e o que cada um desenha: barra desenha Root e WeekScreen; barra courses barra spanish "
                "desenha Root e CourseScreen; barra courses barra latin desenha RouteError."},
         {"en": "The address picks a branch; the loader can refuse it before anything is drawn.",
          "pt": "O endereço escolhe um ramo; o loader pode recusá-lo antes de qualquer coisa ser desenhada."})
rt.box(250, 14, 220, 44, ["path: '/'", "Root · ErrorBoundary"], mono=True, tone="phosphor", size=10)
rt.box(60, 100, 220, 44, ["index", "WeekScreen"], mono=True, tone="phosphor", size=10)
rt.box(400, 100, 280, 44, ["courses/:courseId", "courseLoader → lazy CourseScreen"], mono=True, tone="amber", size=10)
rt.line(360, 58, 170, 100)
rt.line(360, 58, 540, 100)
rt.text(360, 86, "<Outlet />", mono=True, tone="dim", anchor="middle", size=9.5)
rows = [("/", {"en": "Root + WeekScreen", "pt": "Root + WeekScreen"}, "phosphor"),
        ("/courses/spanish", {"en": "Root + CourseScreen", "pt": "Root + CourseScreen"}, "phosphor"),
        ("/courses/latin", {"en": "the loader throws 404 → RouteError", "pt": "o loader lança 404 → RouteError"}, "amber")]
for i, (addr, what, tone) in enumerate(rows):
    y = 172 + i * 22
    rt.text(60, y, addr, mono=True, tone="paper", size=10)
    rt.text(240, y, "→", tone="dim", size=10)
    rt.text(270, y, what, tone=tone, size=10.5)

FIGS = [rt]
