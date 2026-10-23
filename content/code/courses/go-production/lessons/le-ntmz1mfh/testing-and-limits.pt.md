---
title: Testando a tela, e quando não ter uma
version: 1
---

Um programa de tela cheia parece a coisa mais difícil de testar neste curso: ele precisa de um
terminal, lê teclas uma de cada vez e a saída dele são sequências de escape. **Um programa Bubble
Tea não precisa de nada disso para ser testado, porque a tela é uma função do modelo e o modelo é
uma função das mensagens.** Um teste monta um modelo, entrega mensagens a ele e compara o que o
`View` devolve com a tela esperada. O `internal/tui/tui_test.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/tui_test.go",
  "parts": [
    {
      "code": "package tui\n\nimport (\n\t\"strings\"\n\t\"testing\"\n\n\ttea \"charm.land/bubbletea/v2\"\n)\n\nconst log = \"2026-10-01T09:00:01Z GET / 200 5ms\\n\" +\n\t\"2026-10-01T09:00:02Z GET /login 404 7ms\\n\" +\n\t\"2026-10-01T09:00:03Z POST /login 200 9ms\\n\"\n",
      "note": "**O teste fica no próprio pacote `tui`**, então pode ler os campos não exportados do modelo e chamar direto o comando do `Init`. Três linhas de log, dois caminhos."
    },
    {
      "code": "// send hands the messages to Update one at a time, as the program would.\nfunc send(m Model, msgs ...tea.Msg) Model {\n\tfor _, msg := range msgs {\n\t\tnext, _ := m.Update(msg)\n\t\tm = next.(Model)\n\t}\n\treturn m\n}\n",
      "note": "O `send` é o laço do programa sem o terminal: cada mensagem vai para o `Update`, e o que volta é o modelo que a próxima mensagem encontra."
    },
    {
      "code": "var (\n\tdown  = tea.KeyPressMsg{Code: tea.KeyDown}\n\tj     = tea.KeyPressMsg{Code: 'j', Text: \"j\"}\n\tenter = tea.KeyPressMsg{Code: tea.KeyEnter}\n\tesc   = tea.KeyPressMsg{Code: tea.KeyEscape}\n)\n",
      "note": "Teclas montadas à mão, campo a campo. `Text` é o que uma tecla imprimível digitou; as setas, o Enter e o Esc têm só um `Code`."
    },
    {
      "code": "func TestScreens(t *testing.T) {\n\tm := New(\"test.log\", strings.NewReader(log))\n\tif got := m.View().Content; got != \"counting test.log ...\\n\" {\n\t\tt.Fatalf(\"before the count:\\n%s\", got)\n\t}\n\tm = send(m, m.Init()(), tea.WindowSizeMsg{Width: 26, Height: 10})\n",
      "note": "**`m.Init()()` roda a contagem aqui, de forma síncrona**: a primeira chamada devolve o comando e a segunda o executa. A largura de 26 deixa 10 colunas para uma barra, e o teste pode dizer exatamente quantos `#` espera."
    },
    {
      "code": "\tlist := \"test.log: 2 paths\\n\\n\" +\n\t\t\"> /login                2\\n\" +\n\t\t\"  /                     1\\n\\n\" +\n\t\t\"up/down or j/k: move   enter: statuses   q: quit\\n\"\n\tif got := m.View().Content; got != list {\n\t\tt.Errorf(\"list:\\n%s\\nwant:\\n%s\", got, list)\n\t}\n",
      "note": "A tela inteira, comparada como string. Um teste que só procurasse `/login` em algum ponto do texto passaria com o cursor na linha errada."
    },
    {
      "code": "\tm = send(m, down, j, enter) // two steps down from the top stop at the last row\n\topen := \"requests to /: 1\\n\\n\" +\n\t\t\"  200      1  ##########\\n\\n\" +\n\t\t\"esc: back   q: quit\\n\"\n\tif got := m.View().Content; got != open {\n\t\tt.Errorf(\"open:\\n%s\\nwant:\\n%s\", got, open)\n\t}\n\n\tif m = send(m, esc); m.open || m.cursor != 1 {\n\t\tt.Errorf(\"after esc: open=%t cursor=%d, want false and 1\", m.open, m.cursor)\n\t}\n}\n",
      "note": "Dois passos para baixo numa lista de duas linhas: o segundo é recusado no fim, e o Enter abre `/`. A barra tem dez `#` porque `/` tem um status só, que por isso é o maior."
    },
    {
      "code": "func TestQuit(t *testing.T) {\n\tfor _, k := range []tea.KeyPressMsg{\n\t\t{Code: 'q', Text: \"q\"},\n\t\t{Code: 'c', Mod: tea.ModCtrl},\n\t} {\n\t\t_, cmd := New(\"test.log\", nil).Update(k)\n\t\tif cmd == nil {\n\t\t\tt.Fatalf(\"%s: no command\", k)\n\t\t}\n\t\tif _, ok := cmd().(tea.QuitMsg); !ok {\n\t\t\tt.Errorf(\"%s: command sent %T, want tea.QuitMsg\", k, cmd())\n\t\t}\n\t}\n}\n",
      "note": "O `q` e o Ctrl+C precisam devolver um comando, e esse comando precisa produzir `tea.QuitMsg`. O modelo não precisa de log para isso, então o leitor é `nil`."
    },
    {
      "code": "func TestBadLine(t *testing.T) {\n\tm := New(\"bad.log\", strings.NewReader(log+\"oops\\n\"))\n\tnext, cmd := m.Update(m.Init()())\n\tif err := next.(Model).Err(); err == nil || err.Error() != \"line 4: want 5 fields, got 1\" {\n\t\tt.Errorf(\"error %v, want line 4\", err)\n\t}\n\tif cmd == nil {\n\t\tt.Error(\"a log that cannot be read should quit the program\")\n\t}\n}\n\nfunc TestEmptyLog(t *testing.T) {\n\tm := New(\"empty.log\", strings.NewReader(\"\"))\n\tm = send(m, m.Init()(), enter)\n\tif m.open {\n\t\tt.Error(\"enter opened a row in a log with no rows\")\n\t}\n}",
      "note": "As duas falhas que a seção 04 sabia nomear. Uma linha que não pode ser lida fica guardada no modelo e encerra o programa; um log vazio dá uma lista vazia, em que o Enter não tem o que abrir."
    }
  ]
}
```

```
ana@vm:~/tea-hits$ go test -v ./internal/tui
=== RUN   TestScreens
--- PASS: TestScreens (0.00s)
=== RUN   TestQuit
--- PASS: TestQuit (0.00s)
=== RUN   TestBadLine
--- PASS: TestBadLine (0.00s)
=== RUN   TestEmptyLog
--- PASS: TestEmptyLog (0.00s)
PASS
ok  	example.com/hits/internal/tui	0.003s
ana@vm:~/tea-hits$ go test ./...
ok  	example.com/hits	0.006s
?   	example.com/hits/internal/tally	[no test files]
ok  	example.com/hits/internal/tui	0.008s
?   	example.com/hits/tools/genlog	[no test files]
```

**Quatro testes de um programa de tela cheia rodaram em milissegundos, e nenhum terminal foi
aberto.** É o truque da lição 1, o `run` recebendo os fluxos, em outra forma, e o `go test ./...`
roda o `TestRun` da lição 1 ao lado deles sem mudança. O laço que precisa de terminal é da
biblioteca, e tudo o que decide o que aparece é código comum. As duas falhas de `TestBadLine` e
`TestEmptyLog` são as que vale escrever primeiro, porque nenhuma aparece quando você testa o
programa à mão com um log bom.

O que esses testes não enxergam é o terminal em si. Eles conferem o texto que o `View` devolveu, não
as sequências de escape em que o Bubble Tea o transformou, e entregam as mensagens numa ordem que o
teste escolheu, enquanto um terminal de verdade manda suas respostas e seus tamanhos na ordem dele.
Uma tela como a da seção 02 é como essa metade é conferida: num terminal de verdade, a olho.

## Quando a tela é a ferramenta errada

Um programa de tela cheia é feito para um leitor só: uma pessoa olhando para um terminal. **Todo o
resto é mais bem servido pelo `hits top`**, e o `hits browse` diz isso em vez de tentar:

```
ana@vm:~/tea-hits$ ./hits browse access.log | head -3; echo ${PIPESTATUS[@]}
hits: browse draws on a terminal, and standard output is not one; use hits top
2 0
ana@vm:~/tea-hits$ ./hits browse access.log > /dev/null; echo $?
hits: browse draws on a terminal, and standard output is not one; use hits top
2
ana@vm:~/tea-hits$ stat -c "%F  %n" /dev/null
character special file  /dev/null
ana@vm:~/tea-hits$ ./hits top -n 3 access.log | cat
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
```

A recusa vem antes de o Bubble Tea ser iniciado, e ela é necessária, porque **o próprio Bubble Tea
não recusa**. Quando a saída dele não é um terminal, ele pula a preparação que faria num terminal e
começa assim mesmo. Para ver o que isso custa, apague o primeiro bloco `if` do `browse` e o import
do `golang.org/x/term`, e compile o resultado como `hits-raw`. Depois rode `./hits-raw browse
access.log > screen.out` num terminal e aperte `q`:

```
ana@vm:~/tea-hits$ wc -c screen.out
108 screen.out
ana@vm:~/tea-hits$ grep -c login screen.out
0
ana@vm:~/tea-hits$ od -c screen.out | head -4
0000000 033   [   ?   2   0   2   6   $   p 033   [   ?   2   0   2   7
0000020   $   p 033   [   >   4   m 033   [   ?   1   0   4   9   h 033
0000040   [   ?   2   5   l 033   [   ?   5   W 033   [   ?   2   0   0
0000060   4   h 033   [   >   4   ;   2   m 033   [   >   1   u 033   [
```

Chegaram 108 bytes ao arquivo, e nenhum deles é um caminho. São sequências de escape, as perguntas
que o Bubble Tea faz a um terminal e as chaves que ele liga e desliga na entrada e na saída,
gravadas num arquivo que ninguém nunca vai exibir. Um script lendo essa saída não receberia nem
dados nem erro.

A verificação é `term.IsTerminal`, do `golang.org/x/term`, que pergunta ao sistema operacional se o
descritor é um terminal. Um teste mais curto aparece com frequência em sugestões: `os.Stdout.Stat()`
e uma olhada em `os.ModeCharDevice`. O terceiro comando da sessão mostra por que ele não basta. **O
`/dev/null` também é um dispositivo de caractere**, então `hits browse access.log > /dev/null`
passaria por ele e abriria uma tela que ninguém veria, esperando uma tecla.

Três tipos de leitor ficam do outro lado dessa verificação:

| leitor | o que um programa de tela cheia entrega | o que o `hits top` entrega |
|---|---|---|
| um script, um pipe, um job do cron | sequências de escape, ou um erro quando não há terminal de onde ler teclas | linhas de texto e um código de saída |
| um leitor de tela | uma tela redesenhada no lugar, célula por célula | linhas na ordem em que foram impressas |
| você, dez minutos depois | nada: a tela alternativa é apagada na saída | a tabela, ainda no histórico de rolagem do terminal |

**Um leitor de tela acompanha o texto conforme o programa o escreve**, e um programa de tela cheia
escreve movimentos de cursor e redesenha só as células que mudaram. O que chega ao leitor são
fragmentos sem ordem útil, e o único fato que a tela existe para mostrar, qual linha está escolhida,
é um `>` na primeira coluna. É por isso que o curso mantém o `hits top` e nunca faz do `browse` o
único jeito de ver os dados. Uma tela pode ser um extra para quem ela serve; não deve ser a única
porta.

Os terminais também diferem no que respondem. As duas linhas `ModeReportMsg` da seção 04 foram as
respostas de um terminal, e outro terminal responde diferente ou nem responde. As respostas mudam o
que o Bubble Tea faz em seguida: um `2` para o modo 2026 teria ligado o desenho de quadros inteiros
de uma vez, e o `0` que este terminal mandou o deixou desligado. Nada disso é comportamento que um
teste desta seção tenha visto, e quanto menos respostas dessas um programa exigir, menos surpresas
ele terá na máquina de outra pessoa.

Então a regra que este curso segue: **um comando que produz dados os imprime, e uma tela é
acrescentada para navegar pelo que uma pessoa de outro modo rolaria na mão.** O `hits` tem as duas
coisas, a tela confere se tem um terminal onde desenhar, e tudo o que não for uma pessoa num
terminal recebe a tabela simples e os códigos de saída da lição 1.
