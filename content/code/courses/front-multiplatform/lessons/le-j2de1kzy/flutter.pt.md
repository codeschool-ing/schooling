---
title: Flutter, que pinta os próprios pixels
version: 1
---

**O Flutter é o kit do Google para apps em celulares, desktops e na web, a partir de uma base de código em
Dart**, uma linguagem que o Google faz para ele. É a mais diferente das ferramentas deste curso, e o
planner mostra isso de dois jeitos: as regras têm que ser escritas de novo, porque nada de TypeScript roda
nele, e a tela é pixels, não elementos.

## Instalando

O Flutter é uma pasta, como o Node. As linhas que o instalaram onde este curso foi gravado, na versão
atual no dia:

```sh
curl -fsSLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.8-stable.tar.xz
tar -xJf flutter_linux_3.47.8-stable.tar.xz -C ~/.local
```

e depois `~/.local/flutter/bin` no `PATH`, acrescentado no `~/.profile` assim:
`export PATH="$HOME/.local/flutter/bin:$PATH"`. O download tem cerca de 1,6 GB e a pasta descompactada 2,5
GB. **No Windows e no macOS, o flutter.dev tem um instalador**; construir para Android exige o SDK do
Android da aula 3, e para iOS um Mac com Xcode, então este curso constrói só para a web.

```
ana@dev:~$ flutter --version
Flutter 3.47.8 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 737ba8f885 (19 hours ago) • 2026-10-22 21:37:31 -0700
Engine • hash dfd2e6cb7d319db05e3bf1503f3e2ac60f6288a2 (revision cf636b1dfb) (24 hours ago) • 2026-10-23 02:13:38.000Z
Tools • Dart 3.13.7 • DevTools 2.60.0
```

## O planner em Dart

```
ana@dev:~$ flutter create --platforms web --empty --project-name planner_flutter planner_flutter
Creating project planner_flutter...
Resolving dependencies in `planner_flutter`...
Downloading packages...
Got dependencies in `planner_flutter`.
Wrote 18 files.

All done!
You can find general documentation for Flutter at: https://docs.flutter.dev/
Detailed API documentation is available at: https://api.flutter.dev/
If you prefer video documentation, consider: https://www.youtube.com/c/flutterdev

In order to run your empty application, type:

  $ cd planner_flutter
  $ flutter run

Your empty application code is in planner_flutter/lib/main.dart.
```

Troque o `lib/main.dart` pela tela do planner. **A primeira metade é o `planner.ts` escrito de novo em
Dart**, à mão, porque não há como importar TypeScript; a segunda metade é a tela, feita dos *widgets* do
Flutter, a palavra dele para componentes:

```
// lib/main.dart: the planner's screen in Flutter, its rules written again in Dart.
import 'package:flutter/material.dart';

class Session {
  Session(this.id, this.course, this.date, this.minutes, this.done);
  final String id, course, date;
  final int minutes;
  bool done;
}

const courses = {'spanish': 'Spanish A2', 'statistics': 'Statistics', 'guitar': 'Guitar'};
final sessions = [
  Session('s1', 'spanish', '2026-10-19', 30, true),
  Session('s2', 'statistics', '2026-10-20', 45, true),
  Session('s3', 'guitar', '2026-10-21', 20, false),
  Session('s4', 'spanish', '2026-10-22', 30, false),
  Session('s5', 'statistics', '2026-10-26', 60, false),
  Session('s6', 'guitar', '2026-10-28', 20, false),
];

String mondayOf(String date) {
  final d = DateTime.parse('${date}T12:00:00Z');
  return d.subtract(Duration(days: d.weekday - 1)).toIso8601String().substring(0, 10);
}

(int, int) weekTotal(List<Session> all, String monday) {
  final end = DateTime.parse('${monday}T12:00:00Z').add(const Duration(days: 7));
  final last = end.toIso8601String().substring(0, 10);
  final week = all.where((s) => s.date.compareTo(monday) >= 0 && s.date.compareTo(last) < 0);
  final done = week.where((s) => s.done).fold(0, (n, s) => n + s.minutes);
  return (done, week.fold(0, (n, s) => n + s.minutes));
}

// The transcripts open the web build with ?today=2026-10-21, as lesson 1 does.
final today = Uri.base.queryParameters['today'] ?? DateTime.now().toIso8601String().substring(0, 10);

void main() => runApp(const MaterialApp(title: 'Study planner', home: Planner()));

class Planner extends StatefulWidget {
  const Planner({super.key});
  @override
  State<Planner> createState() => _PlannerState();
}

class _PlannerState extends State<Planner> {
  String? open;

  @override
  Widget build(BuildContext context) {
    final (done, planned) = weekTotal(sessions, mondayOf(today));
    return Scaffold(
      appBar: AppBar(title: const Text('Study planner')),
      body: ListView(children: [
        ListTile(title: Text('This week: $done of $planned minutes done')),
        for (final MapEntry(key: id, value: name) in courses.entries) ...[
          ListTile(title: Text(name), onTap: () => setState(() => open = open == id ? null : id)),
          if (open == id)
            for (final s in sessions.where((s) => s.course == id))
              ListTile(
                title: Text('${s.date}, ${s.minutes} min'),
                trailing: s.done
                    ? const Text('done')
                    : TextButton(onPressed: () => setState(() => s.done = true), child: const Text('Mark done')),
              ),
        ],
      ]),
    );
  }
}
```

Os widgets se aninham como os componentes do React, e o `setState` pede ao Flutter que desenhe de novo,
como o `useState` faz no React. `ListTile`, `TextButton` e `AppBar` são widgets do Material Design, o
visual do Google, desenhados pelo Flutter em toda plataforma; os widgets `Cupertino` do Flutter desenham o
visual do iOS.

```
ana@dev:~$ cd planner_flutter
ana@dev:~/planner_flutter$ flutter analyze
Analyzing planner_flutter...                                    
No issues found! (ran in 7.4s)
ana@dev:~/planner_flutter$ flutter build web --no-web-resources-cdn
Compiling lib/main.dart for the Web...                          
Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm
Use --no-wasm-dry-run to disable these warnings.
Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons). This usually means you are referring to font families in an IconData class but not including them in the assets section of your pubspec.yaml, are missing the package that would include them, or are missing "uses-material-design: true".
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 7736 bytes (99.5% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Compiling lib/main.dart for the Web...                             32.1s
✓ Built build/web
ana@dev:~/planner_flutter$ du -sh build/web
40M	build/web
```

O `--no-web-resources-cdn` faz o build levar uma cópia própria do motor de desenho, o CanvasKit, em vez de
carregá-lo dos servidores do Google quando a página abre; a máquina de gravação não alcançava esses
servidores, e um app que deve funcionar sem rede precisa da mesma opção. **O build tem 40 MB**, que é o
motor, contra os poucos kilobytes do planner.

## O que um leitor de tela vê

```
ana@dev:~/planner$ node look.mjs 'http://localhost:4174/?today=2026-10-21' --wait 4000 2>&1 | grep -v '^console'
- button "Enable accessibility"
ana@dev:~/planner$ node look.mjs 'http://localhost:4174/?today=2026-10-21' --wait 4000 --eval 'document.querySelector("flt-semantics-placeholder").click()' --wait 1500 --click 'Spanish A2' --wait 500 --click 'Mark done' --wait 500 2>&1 | grep -v '^console'
document.querySelector("flt-semantics-placeholder").click() = undefined
- heading "Study planner" [level=2]
- group:
  - text: "This week: 105 of 125 minutes done"
  - button "Spanish A2"
  - text: 2026-10-19, 30 min done 2026-10-22, 30 min done
  - button "Statistics"
  - button "Guitar"
```

**A primeira execução mostra um elemento, um botão chamado "Enable accessibility", e mais nada**: nem a
semana, nem os cursos. O Flutter os pintou num canvas, e um canvas é uma imagem só para o navegador. O
botão é a porta de entrada do Flutter: ativá-lo, como faria quem usa leitor de tela, liga a **árvore de
semântica** do Flutter, uma estrutura escondida que ele constrói ao lado dos pixels para dizer à
tecnologia assistiva o que está ali. Com ela ligada, a segunda execução lê o planner, abre Spanish A2 e
marca uma sessão como feita, e a semana diz 105 de 125, o mesmo número de toda outra versão do planner, a
partir de regras escritas duas vezes.

Num celular, o Flutter entrega a árvore de semântica ao TalkBack e ao VoiceOver sem esse botão, então um
app Flutter pode ser tão acessível quanto um nativo; é uma promessa que o Flutter cumpre com trabalho
próprio, onde o React Native a recebe dos controles da plataforma.
