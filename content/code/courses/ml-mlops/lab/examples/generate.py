FILE = __file__.replace('/examples/', '/programs/')
LANGUAGE = "python"
NAME = "generate.py"
PARTS = [
 ('"""generate.py', "The docstring says how to run it. With no argument it stops on 28 February 2026, the night this course begins on; `--until` lets lesson 10 read the same history further on.",
  "A docstring diz como rodar. Sem argumento ele para em 28 de fevereiro de 2026, a noite em que este curso começa; `--until` deixa a lição 10 ler a mesma história mais adiante."),
 ("FIRST, LAST", "The shops are the ones from `pipelines-etl`. The two dates at the end are things that will happen to the shop after February. Nothing in the first nine lessons depends on them, and lesson 10 is about noticing them from the data alone.",
  "As lojas são as de `pipelines-etl`. As duas datas no fim são coisas que vão acontecer com a loja depois de fevereiro. Nada nas nove primeiras lições depende delas, e a lição 10 é sobre percebê-las só pelos dados."),
 ("args = argparse", "**One seed, `2026`, draws everything.** Change it and you get a different shop, with every number in the course different from yours.",
  "**Uma semente, `2026`, sorteia tudo.** Mude-a e você terá outra loja, com todos os números do curso diferentes dos seus."),
 ("# 80 titles", "Eighty books, ten in each of eight categories, so that lesson 2 has something to recommend.",
  "Oitenta livros, dez em cada uma de oito categorias, para a lição 2 ter o que recomendar."),
 ("members, purchases, lines = []", "Each member gets a join date, the channel they signed up on, an age band and a home shop. The app only exists from September 2025, so nobody before that joined on it.",
  "Cada membro recebe uma data de adesão, o canal pelo qual se cadastrou, uma faixa de idade e uma loja de referência. O aplicativo só existe a partir de setembro de 2025, então ninguém antes disso aderiu por ele."),
 ("    rate = rng.gamma", "Two hidden numbers decide a member's life: how often they visit, and how long they stay before they leave for good. Young members and app members leave sooner. **No column in the database records either number**, which is the situation every real model is in: it sees what people did, never why.",
  "Dois números escondidos decidem a vida de um membro: com que frequência ele visita e quanto tempo fica antes de ir embora de vez. Membros jovens e do aplicativo saem antes. **Nenhuma coluna do banco registra nenhum dos dois**, que é a situação de todo modelo real: ele vê o que as pessoas fizeram, nunca o porquê."),
 ("    day = max(joined, FIRST)", "Then the visits, one at a time, until the member leaves or the history ends. Each visit is in a shop or online, and holds one or more books, mostly from the member's two favourite categories.",
  "Depois as visitas, uma de cada vez, até o membro sair ou a história acabar. Cada visita é numa loja ou online, e tem um ou mais livros, na maioria das duas categorias favoritas do membro."),
 ("db = sqlite3.connect", "The tables are rewritten every time, so running it twice is safe. The two indexes are what make lesson 1's query take a second instead of minutes.",
  "As tabelas são reescritas toda vez, então rodar duas vezes é seguro. Os dois índices são o que faz a consulta da lição 1 levar um segundo em vez de minutos."),
 ("kept = {p[0]", "**Only what happened by `--until` is written.** The whole two years are always drawn, so the first months come out identical whatever the date, and a later run only adds to them.",
  "**Só o que aconteceu até `--until` é escrito.** Os dois anos inteiros são sempre sorteados, então os primeiros meses saem idênticos qualquer que seja a data, e uma rodada posterior só acrescenta a eles."),
]
