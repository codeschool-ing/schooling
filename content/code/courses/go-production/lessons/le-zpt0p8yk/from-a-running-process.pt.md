---
title: Um profile a partir de um processo em execução
version: 1
---

Os programas que mais precisam de um profile são os que você não pode parar para acrescentar flags:
**um serviço que está rodando há uma semana e começou a usar mais memória, ou mais processador, do que
usava na segunda-feira**. Reiniciá-lo com o profiling ligado joga fora justamente o estado que você
queria olhar. O `net/http/pprof` é a resposta da biblioteca padrão. Um programa que o importa serve
cada profile da seção 02 por HTTP, sob demanda, enquanto continua trabalhando, e o `go tool pprof`
consegue ler um profile direto do endereço.

Este curso não pressupõe que você tenha escrito um servidor web, e esta seção não precisa de um além
de poucas linhas. O `net/http` sabe escutar num endereço de rede e responder pedidos; **um handler é
uma função que responde um pedido, e um mux é a tabela que diz qual handler responde qual caminho**.
`http.ListenAndServe(addr, nil)` escuta em `addr` e usa o mux padrão do pacote,
`http.DefaultServeMux`. Esse é todo o código de servidor abaixo.

## Um serviço com um defeito

O `profserve` faz o papel de um serviço. Ele conta o log grande da seção 04 sem parar, como um
servidor atende um pedido atrás do outro, e dá um prazo a cada contagem. Em `~/prof`, salve como
`tools/profserve/main.go`:

```schooling-example
{
  "language": "go",
  "file": "tools/profserve/main.go",
  "parts": [
    {
      "code": "// Command profserve counts a log again and again, the way a service that\n// runs for weeks does its work, and serves its own profiles on localhost.\npackage main\n\nimport (\n\t\"errors\"\n\t\"flag\"\n\t\"log\"\n\t\"net/http\"\n\t_ \"net/http/pprof\"\n\t\"os\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "**Importar `net/http/pprof` pelo efeito colateral registra handlers em `/debug/pprof/`** no `http.DefaultServeMux`, a tabela de rotas padrão do servidor. O nome em branco `_` diz que o programa não usa mais nada do pacote."
    },
    {
      "code": "func main() {\n\taddr := flag.String(\"pprof\", \"127.0.0.1:6060\", \"where to serve the profiles\")\n\ttimeout := flag.Duration(\"timeout\", 2*time.Second, \"how long one count may take\")\n\tflag.Parse()\n\tlog.SetFlags(0)\n\tif flag.NArg() != 1 {\n\t\tlog.Fatal(\"usage: profserve [-pprof addr] [-timeout d] file\")\n\t}\n",
      "note": "Duas flags: onde servir os profiles, e quanto tempo uma contagem pode levar. **O endereço padrão é `127.0.0.1`**, a interface de loopback da própria máquina, que nada na rede alcança."
    },
    {
      "code": "\tgo func() {\n\t\tlog.Println(http.ListenAndServe(*addr, nil))\n\t}()\n",
      "note": "`http.ListenAndServe` com handler `nil` serve o `DefaultServeMux`, onde o import pôs os profiles. Ele não retorna enquanto o servidor roda, então ganha uma goroutine própria e o trabalho de verdade do programa segue no `main`."
    },
    {
      "code": "\tfor round := 1; ; round++ {\n\t\ts, err := countBefore(flag.Arg(0), *timeout)\n\t\tif err != nil {\n\t\t\tlog.Printf(\"round %d: %v\", round, err)\n\t\t\tcontinue\n\t\t}\n\t\tlog.Printf(\"round %d: %d lines\", round, s.Lines)\n\t}\n}\n",
      "note": "O trabalho: contar o arquivo, informar e recomeçar, para sempre. Um serviço atendendo pedidos tem esta cara para um profiler: o mesmo código rodando de novo e de novo, enquanto alguém estiver olhando."
    },
    {
      "code": "type result struct {\n\ts   tally.Summary\n\terr error\n}\n\n// countBefore counts the file at path, and gives up after d.\nfunc countBefore(path string, d time.Duration) (tally.Summary, error) {\n\tdone := make(chan result)\n\tgo func() {\n\t\ts, err := countFile(path)\n\t\tdone <- result{s, err}\n\t}()\n\tselect {\n\tcase r := <-done:\n\t\treturn r.s, r.err\n\tcase <-time.After(d):\n\t\treturn tally.Summary{}, errors.New(\"timed out\")\n\t}\n}\n",
      "note": "**O defeito está aqui.** A contagem roda numa goroutine para que o `select` possa parar de esperar depois de `d`. Quando o timer ganha, `countBefore` retorna e não sobra ninguém para receber de `done`: a goroutine termina de contar, chega em `done <- result{s, err}` e espera ali para sempre."
    },
    {
      "code": "func countFile(path string) (tally.Summary, error) {\n\tf, err := os.Open(path)\n\tif err != nil {\n\t\treturn tally.Summary{}, err\n\t}\n\tdefer f.Close()\n\treturn tally.Count(f)\n}",
      "note": "Abrir e contar, fechando o arquivo aconteça o que acontecer."
    }
  ]
}
```

**`127.0.0.1` é o endereço de loopback**: um servidor escutando ali aceita conexões de programas na
mesma máquina e de nenhum outro lugar. Dois terminais, então. No primeiro, Ana inicia o serviço com um
prazo menor do que uma contagem de 91 MB leva nesta máquina, que é a situação em que o defeito
aparece:

```
ana@vm:~/prof$ ./profserve -timeout 500ms big.log
round 1: timed out
round 2: timed out
round 3: timed out
round 4: timed out
round 5: timed out
round 6: timed out
```

Toda rodada desiste depois de meio segundo, o programa passa para a próxima, e nada na saída parece
errado. O resto desta seção acontece no segundo terminal.

## O que ele serve

`/debug/pprof/` é uma página HTML que lista os profiles com uma contagem ao lado de cada um. O `curl`
a busca, e o `grep` e o `sed` reduzem a tabela às linhas:

```
ana@vm:~/prof$ curl -s http://127.0.0.1:6060/debug/pprof/ | grep "<tr>" | sed "s/<[^>]*>/ /g"
  9   allocs   
  0   block   
  0   cmdline   
  11   goroutine   
  0   goroutineleak   
  9   heap   
  0   mutex   
  0   profile   
  0   symbol   
  10   threadcreate   
  0   trace   
```

**São os profiles da seção 02, com os mesmos nomes**, mais quatro que o pacote acrescenta: `profile`
é o profile de CPU, `trace` é o trace de execução da lição 14, e `cmdline` e `symbol` são auxiliares
das ferramentas. As contagens são o que cada profile tem neste momento. `block` e `mutex` estão em 0,
como a seção 02 disse que estariam num programa que nunca chamou `SetBlockProfileRate` nem
`SetMutexProfileFraction`. `goroutine` diz 11, três segundos depois do início; guarde esse número.

## Um profile de CPU pela rede

O profile de CPU é tirado a pedido: `?seconds=5` pede ao processo que se amostre por cinco segundos
e mande o resultado. O `go tool pprof` aceita o endereço em qualquer lugar onde aceita um arquivo:

```
ana@vm:~/prof$ go tool pprof -top "http://127.0.0.1:6060/debug/pprof/profile?seconds=5" | sed /^Time:/d | head -12
Fetching profile over HTTP from http://127.0.0.1:6060/debug/pprof/profile?seconds=5
Saved profile in /home/ana/pprof/pprof.profserve.samples.cpu.001.pb.gz
File: profserve
Build ID: 5f0f43423e37f4038fb1f9893cbbd59c5978ff16
Type: cpu
Duration: 5s, Total samples = 7.52s (150.30%)
Showing nodes accounting for 6.85s, 91.09% of 7.52s total
Dropped 118 nodes (cum <= 0.04s)
      flat  flat%   sum%        cum   cum%
     1.21s 16.09% 16.09%      2.76s 36.70%  strings.Fields
     0.72s  9.57% 25.66%      0.72s  9.57%  runtime.asyncPreempt
     0.28s  3.72% 29.39%      0.31s  4.12%  runtime.lock2
     0.23s  3.06% 32.45%      0.29s  3.86%  runtime.unlock2
     0.22s  2.93% 35.37%      0.22s  2.93%  internal/runtime/syscall/linux.Syscall6
```

O comando esperou cinco segundos pelo profile, depois **guardou uma cópia em `~/pprof`**, para poder
ser lida de novo depois que o processo sumir, e imprimiu o relatório. 7,52 segundos de amostras em 5
segundos de relógio significam um processador e meio ocupado em média: as contagens se sobrepõem,
porque cada rodada começa uma nova antes de a anterior terminar. E a primeira linha é a que as seções
03 e 04 encontraram, `strings.Fields`, com 36,70% contando o que ela chama. **Três jeitos de tirar um
profile, de três programas diferentes, concordam sobre para onde vai o tempo**, e é isso que faz a
descoberta valer uma ação na lição 13.

## As goroutines

O profile de goroutines com `?debug=1` é texto em vez do formato binário: cada pilha distinta uma vez,
com o número de goroutines paradas nela. Treze segundos depois:

```
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=1" | head -10
goroutine profile: total 37
30 @ 0x48c1ea 0x418d1c 0x418917 0x682af2 0x4930c1
#	0x682af1	main.countBefore.func1+0x51	/home/ana/prof/tools/profserve/main.go:50

1 @ 0x448bf1 0x48afbd 0x666211 0x665ee5 0x662e49 0x67cd94 0x67d7dc 0x643329 0x644eaf 0x64b12e 0x64199c 0x4930c1
#	0x666210	runtime/pprof.writeRuntimeProfile+0xb0	/usr/local/go/src/runtime/pprof/pprof.go:848
#	0x665ee4	runtime/pprof.writeGoroutine+0x44	/usr/local/go/src/runtime/pprof/pprof.go:781
#	0x662e48	runtime/pprof.(*Profile).WriteTo+0x148	/usr/local/go/src/runtime/pprof/pprof.go:405
#	0x67cd93	net/http/pprof.handler.ServeHTTP+0x553	/usr/local/go/src/net/http/pprof/pprof.go:272
#	0x67d7db	net/http/pprof.Index+0xdb		/usr/local/go/src/net/http/pprof/pprof.go:391
```

**37 goroutines, e 30 delas exatamente na mesma linha**, `main.go:50`, que é `done <- result{s, err}`
em `countBefore`. O segundo registro é a goroutine respondendo este próprio pedido. O `?debug=2`
imprime cada goroutine separadamente, no formato de um panic, com o estado em que cada uma espera, e o
estado confirma:

```
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=2" | grep -A2 "chan send" | head -3
goroutine 9 [chan send]:
main.countBefore.func1()
	/home/ana/prof/tools/profserve/main.go:50 +0x52
```

**`chan send`: uma goroutine tentando entregar o resultado a um receptor que já foi embora.** Cada
rodada que estourou o prazo deixou uma para trás, e cada uma segura a pilha de uma goroutine e o
resumo que calculou, enquanto o processo viver. A contagem foi de 11 para 37 em treze segundos e não
desce. Num serviço que roda por uma semana, esse é o crescimento de memória que alguém acaba notando,
sem erro nenhum nos logs.

O `goroutineleak` diz a mesma coisa sem precisar do raciocínio:

```
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutineleak?debug=1" | head -3
goroutineleak profile: total 30
30 @ 0x48c1ea 0x418d1c 0x418917 0x682af2 0x4930c1
#	0x682af1	main.countBefore.func1+0x51	/home/ana/prof/tools/profserve/main.go:50
```

Para montá-lo, o runtime roda uma coleta de lixo que também pergunta, para cada goroutine bloqueada,
se alguma goroutine que ainda possa rodar alcança o canal ou o lock em que ela está bloqueada. O canal
`done` não é referenciado por nada além da goroutine esperando nele, então ninguém jamais vai receber
dele, e **essas 30 goroutines são informadas como vazadas, e não apenas esperando**. A verificação
tem um limite que vale conhecer: uma goroutine bloqueada num canal para o qual algo alcançável ainda
aponta, uma variável global por exemplo, não é informada, porque o runtime não consegue saber que
ninguém vai usá-lo.

## A correção

A goroutine precisa de um lugar para deixar o resultado que não dependa de um receptor. **Um canal
com buffer de um aceita um envio sem esperar**, então a goroutine sempre consegue terminar, e o canal
vira lixo quando os dois lados acabam com ele. Uma edição, o serviço parado no primeiro terminal,
recompilado e iniciado de novo com o mesmo comando:

```
ana@vm:~/prof$ sed -i 's/done := make(chan result)/done := make(chan result, 1)/' tools/profserve/main.go
ana@vm:~/prof$ go build -o profserve ./tools/profserve
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutineleak?debug=1" | head -3
goroutineleak profile: total 0
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=1" | head -1
goroutine profile: total 15
```

**Nenhuma goroutine vazada depois de doze segundos.** As 15 goroutines são as do próprio servidor e as
contagens ainda em andamento: cada rodada continua estourando o prazo e começando uma nova contagem,
mas agora toda contagem termina, envia para o buffer e retorna.

## Fora da rede

Os handlers que o `net/http/pprof` registra não têm autenticação, e o que servem não é inofensivo. O
profile de goroutines mostra os caminhos do código e a forma do programa, e o `cmdline` mostra a
linha de comando com os segredos que tiverem sido passados nela. Um pedido de `profile?seconds=60` ou de
um trace mantém um processador ocupado pelo tempo que quem pede quiser. **Um endpoint desses nunca
pode ser alcançável pela internet.** Três hábitos garantem isso:

- **Escute em `127.0.0.1`**, como o `profserve`, e chegue até ele de outro lugar por um túnel SSH como
  `ssh -L 6060:127.0.0.1:6060 server`, que faz a porta remota aparecer na sua máquina.
- **Sirva numa porta própria, nunca na pública.** O import registra os handlers no
  `http.DefaultServeMux`. Um programa que também serve o tráfego público pelo `DefaultServeMux`, que é
  o que `http.ListenAndServe(":8080", nil)` faz, acabou de publicar o `/debug/pprof/` para todo mundo
  que alcança a porta 8080. O formato seguro mantém os dois separados: o servidor público num mux
  próprio, criado com `http.NewServeMux()`, e o mux padrão, com os profiles, num endereço de loopback.
- **Faça do endereço uma flag**, como o `-pprof` aqui, para que um operador possa movê-lo para uma
  porta que só a rede interna alcança sem recompilar o programa.
