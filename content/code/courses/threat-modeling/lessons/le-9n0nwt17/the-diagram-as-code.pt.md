---
title: O diagrama como código
version: 1
---

Um diagrama feito numa ferramenta de desenho é uma figura: não dá para compará-lo linha a linha com
a versão do mês passado, não dá para um programa conferi-lo, e ele se afasta do sistema sem
ninguém perceber. **Escrever o mesmo diagrama como código** resolve os dois primeiros problemas e
torna o terceiro visível, porque uma mudança no sistema pode chegar no mesmo pull request que a
mudança no modelo dele. A aula 15 se apoia nisso. Esta seção escreve o diagrama de nível 1 do
portal com o **pytm**, a biblioteca da OWASP instalada na aula 1.

### O modelo

Crie `model.py` em `~/tm/portal-model`. Ele é o desenho das seções anteriores, elemento por
elemento:

```schooling-example
{"language": "python", "file": "model.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The data flow diagram of Vereda's patient portal, written as code.\"\"\"\nfrom pytm import TM, Actor, Boundary, Dataflow, Datastore, ExternalEntity, Process, Server\n\ntm = TM(\"Vereda patient portal\")\ntm.description = \"Booking, records and reminders for a chain of physiotherapy clinics.\"\ntm.isOrdered = True\n", "note": "O modelo é um arquivo Python comum. `TM` é o próprio modelo; nome e descrição são o que um relatório imprimiria no topo."}, {"code": "# Trust boundaries: where the level of trust changes.\ninternet = Boundary(\"Internet\")\ncloud = Boundary(\"Vereda cloud\")\nprivate = Boundary(\"Private network\")\nprivate.inBoundary = cloud\nclinic = Boundary(\"Clinic network\")\nvendors = Boundary(\"Vendors\")\n", "note": "Uma `Boundary` por zona de confiança. A rede privada fica dentro da nuvem, o que o pytm diz com `inBoundary`, do mesmo jeito que posiciona todo elemento."}, {"code": "# External entities: people and systems outside Vereda's control.\npatient = Actor(\"Patient\")\npatient.inBoundary = internet\npatient.protocol = \"HTTPS\"\nstaff = Actor(\"Clinic staff\")\nstaff.inBoundary = clinic\nsms = ExternalEntity(\"SMS provider\")\nsms.inBoundary = vendors\nsms.protocol = \"HTTPS\"\npayments = ExternalEntity(\"Payment gateway\")\npayments.inBoundary = vendors\npayments.protocol = \"HTTPS\"\n", "note": "As quatro entidades externas. Pessoas são `Actor`, sistemas de outras empresas são `ExternalEntity`. `protocol` é o que os fluxos que chegam ao elemento usam."}, {"code": "# Processes: code Vereda runs.\nportal = Server(\"Portal\")\nportal.inBoundary = cloud\nportal.protocol = \"HTTPS\"\nportal.usesSessionTokens = True\nconsole = Server(\"Staff console\")\nconsole.inBoundary = cloud\nconsole.protocol = \"HTTPS\"\nconsole.usesSessionTokens = True\nworker = Process(\"Reminder worker\")\nworker.inBoundary = private\n", "note": "Os três processos. O portal e o console atendem pedidos e guardam sessões, então são `Server`; o worker só roda num horário."}, {"code": "# Data stores.\ndb = Datastore(\"Records database\")\ndb.inBoundary = private\ndb.storesPII = True\ndb.storesSensitiveData = True\ndb.isSQL = True\ndb.protocol = \"PostgreSQL\"\nfiles = Datastore(\"Exam files\")\nfiles.inBoundary = private\nfiles.storesPII = True\nfiles.storesSensitiveData = True\nfiles.protocol = \"HTTPS\"\n", "note": "Os dois repositórios, os dois na rede privada, os dois com dados pessoais e sensíveis. Essas marcações são fatos com que o pytm vai raciocinar na aula 3."}, {"code": "# Data flows, in the order a booking happens. A flow takes its protocol\n# from the element it arrives at.\nDataflow(patient, portal, \"Sign in and book\")\nDataflow(portal, patient, \"Pages and booking status\")\nDataflow(patient, portal, \"Upload exam PDF\")\nDataflow(portal, files, \"Store exam PDF\")\nDataflow(portal, db, \"Read and write bookings\")\nDataflow(portal, payments, \"Charge for a session\")\nDataflow(payments, portal, \"Payment webhook\")\nDataflow(staff, console, \"Manage the agenda\")\nDataflow(console, db, \"Read and write records\")\nDataflow(console, files, \"Open exam PDF\")\nDataflow(worker, db, \"Read tomorrow's bookings\")\nDataflow(worker, sms, \"Send reminder\")\n", "note": "Os doze fluxos da figura, na ordem dela: origem, destino e o rótulo que nomeia o dado."}, {"code": "if __name__ == \"__main__\":\n    tm.process()", "note": "`process()` lê a linha de comando: `--json`, `--dfd`, `--report` e as demais."}]}
```

Três detalhes são do pytm, e não da notação. Uma entidade externa que é uma pessoa é um `Actor`;
uma que é um sistema é um `ExternalEntity`. Um processo que atende pedidos é um `Server`, o que
deixa o pytm fazer perguntas sobre sessões; um que não atende é um `Process`. E
`tm.isOrdered = True` mantém os fluxos numerados na ordem em que foram escritos, e é por isso que
os números na figura e na saída abaixo são os mesmos.

### Quais fluxos cruzam uma fronteira

O pytm consegue escrever tudo o que sabe sobre o modelo como JSON. Um programa curto ao lado,
`flows.py`, lê esse arquivo e marca cada fluxo cujas duas pontas estão em fronteiras diferentes:

```schooling-example
{"language": "python", "file": "flows.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"List the data flows of a pytm model, and mark the ones that cross a trust boundary.\"\"\"\nimport json\nimport sys\n\nmodel = json.load(open(sys.argv[1]))", "note": "O JSON do pytm lista cada elemento com a fronteira em que está, e cada fluxo com os nomes das duas pontas."}, {"code": "where = {e[\"name\"]: e[\"inBoundary\"] or \"(none)\" for e in model[\"elements\"]}\n", "note": "Um dicionário do nome do elemento para a fronteira dele. Um elemento fora de todas as fronteiras recebe `(none)`."}, {"code": "crossing = 0\nfor f in model[\"flows\"]:\n    a, b = where[f[\"source\"]], where[f[\"sink\"]]\n    mark = \"x\" if a != b else \" \"\n    crossing += a != b\n    print(f\"{f['order']:2} {mark} {f['name']:26} {a} -> {b}\")\nprint(f\"\\n{crossing} of {len(model['flows'])} flows cross a trust boundary\")", "note": "Um fluxo cruza quando as pontas estão em fronteiras diferentes. Fronteiras aninhadas contam como diferentes: a nuvem e a rede privada dentro dela são duas zonas."}]}
```

Rode o modelo com `--json`, que não imprime nada e escreve o arquivo, e depois o programa:

```
(.venv) ana@vm:~/tm/portal-model$ ls -A
.git
.gitignore
flows.py
model.py
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 flows.py model.json
 1 x Sign in and book           Internet -> Vereda cloud
 2 x Pages and booking status   Vereda cloud -> Internet
 3 x Upload exam PDF            Internet -> Vereda cloud
 4 x Store exam PDF             Vereda cloud -> Private network
 5 x Read and write bookings    Vereda cloud -> Private network
 6 x Charge for a session       Vereda cloud -> Vendors
 7 x Payment webhook            Vendors -> Vereda cloud
 8 x Manage the agenda          Clinic network -> Vereda cloud
 9 x Read and write records     Vereda cloud -> Private network
10 x Open exam PDF              Vereda cloud -> Private network
11   Read tomorrow's bookings   Private network -> Private network
12 x Send reminder              Private network -> Vendors

11 of 12 flows cross a trust boundary
```

É a contagem que a figura de duas seções atrás mostrava a olho, agora calculada a partir do
modelo. Na próxima vez que alguém acrescentar um fluxo, o programa conta também, e ninguém precisa
lembrar de redesenhar uma figura antes.

O pytm também consegue imprimir o diagrama na linguagem do Graphviz, com `python3 model.py --dfd`,
para virar imagem. Fazer a imagem precisa do próprio Graphviz, que este ambiente não instala, então
esse passo não foi rodado aqui.

### Faça o commit

O `.gitignore` mantém `model.json` e o cache do Python fora do repositório, já que os dois são
produzidos a partir dos arquivos que estão nele:

```
(.venv) ana@vm:~/tm/portal-model$ git status --short
?? .gitignore
?? flows.py
?? model.py
(.venv) ana@vm:~/tm/portal-model$ git add .gitignore model.py flows.py
(.venv) ana@vm:~/tm/portal-model$ git commit -m 'Draw the portal as a data flow diagram'
[main (root-commit) 0cc253e] Draw the portal as a data flow diagram
 3 files changed, 88 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 flows.py
 create mode 100644 model.py
```

O `.gitignore` tem duas linhas, `__pycache__/` e `model.json`. Se o seu commit mostrar outro hash,
é o esperado: um hash cobre o autor e o horário, e os seus não são os da ana.

### Código também não é o modelo

O arquivo só é um modelo enquanto bate com o sistema. O pytm não tem como saber que o console
responde pela internet a menos que alguém escreva isso; ele acredita na fronteira que recebeu,
exatamente como o desenho acreditava. A vantagem do código não é ser mais verdadeiro. É que uma
diferença entre o modelo e o sistema pode aparecer num diff, ser revisada e discutida, que é o
hábito que a aula 15 monta.
