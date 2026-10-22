---
title: Um profile a partir de um programa
version: 1
---

Um benchmark mede uma função com a entrada que você escolheu. Às vezes a pergunta é sobre o programa
inteiro com a entrada real: **o lento é um comando que alguém roda, e ele é lento no arquivo dessa
pessoa**. Aí o programa mede a si mesmo. O `runtime/pprof` tem quatro funções que importam para isso,
`StartCPUProfile` e `StopCPUProfile` em volta do trabalho, e `WriteHeapProfile` ou `Lookup` para a
memória, e são elas que o `go test` chama por você quando recebe `-cpuprofile`.

Em vez de acrescentar flags ao próprio `hits`, a medição vai para um segundo programa ao lado do
`genlog`, que conta um arquivo como o `hits count` faz e grava os dois profiles. Em `~/prof`, salve
como `tools/profcount/main.go`:

```schooling-example
{
  "language": "go",
  "file": "tools/profcount/main.go",
  "parts": [
    {
      "code": "// Command profcount counts a log the way hits count does, and writes a CPU\n// profile of the count and a heap profile at the end of it.\npackage main\n\nimport (\n\t\"flag\"\n\t\"fmt\"\n\t\"os\"\n\t\"runtime\"\n\t\"runtime/pprof\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "Um programa próprio em `tools/`, como o `genlog`, para a ferramenta que vai para produção ficar livre de código de profiling. `runtime/pprof` é o pacote que grava profiles; as flags dão nome aos arquivos."
    },
    {
      "code": "func main() {\n\tcpu := flag.String(\"cpuprofile\", \"\", \"write a CPU profile to `file`\")\n\tmem := flag.String(\"memprofile\", \"\", \"write a heap profile to `file`\")\n\tflag.Parse()\n\tif err := run(flag.Arg(0), *cpu, *mem); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"profcount:\", err)\n\t\tos.Exit(1)\n\t}\n}\n",
      "note": "**O `main` só lê as flags e informa um erro.** O trabalho fica em `run`, que retorna em vez de encerrar o processo, e o motivo está na próxima parte."
    },
    {
      "code": "func run(path, cpu, mem string) error {\n\tif cpu != \"\" {\n\t\tf, err := os.Create(cpu)\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t\tdefer f.Close()\n\t\tif err := pprof.StartCPUProfile(f); err != nil {\n\t\t\treturn err\n\t\t}\n\t\tdefer pprof.StopCPUProfile()\n\t}\n",
      "note": "**`StartCPUProfile` liga a amostragem de 100 Hz e vai gravando amostras no arquivo; `StopCPUProfile` a desliga e grava o fim do profile.** Chamadas adiadas rodam da última para a primeira, então o profile é parado antes de o arquivo ser fechado. Um `os.Exit` ou um `log.Fatal` dentro de `run` pularia os dois defers e deixaria um arquivo vazio, e é por isso que `run` devolve os erros ao `main`."
    },
    {
      "code": "\tin, err := os.Open(path)\n\tif err != nil {\n\t\treturn err\n\t}\n\tdefer in.Close()\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\treturn err\n\t}\n\tfmt.Printf(\"%d lines, %d paths\\n\", s.Lines, len(s.ByPath))\n",
      "note": "A parte medida: abrir o arquivo e contá-lo, exatamente como o `hits count` faz. Tudo o que acontece entre `StartCPUProfile` e o retorno de `run` está no profile de CPU."
    },
    {
      "code": "\tif mem != \"\" {\n\t\tf, err := os.Create(mem)\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t\tdefer f.Close()\n\t\truntime.GC()\n\t\treturn pprof.WriteHeapProfile(f)\n\t}\n\treturn nil\n}",
      "note": "**O profile de heap descreve o heap como estava na última coleta de lixo**, então o `runtime.GC()` antes faz ele descrever o agora. O `WriteHeapProfile` grava o profile `heap`; o mesmo arquivo tem as quatro visões da seção 02."
    }
  ]
}
```

O `hits` nunca fica sabendo que foi medido, e o código de medição nunca vai para produção. Quando o
programa a medir é o que vai para produção, as mesmas chamadas entram nele, atrás de uma flag como
`-cpuprofile`; o próprio compilador do Go tem exatamente essa flag, e o `go tool compile -help` a lista
ao lado de `-memprofile`.

## Dois milhões de linhas

O log da seção 03 tinha 4,6 MB. A pergunta real para o `hits` é o log que um servidor movimentado
escreve num dia, e o `genlog` faz um desses com a mesma facilidade:

```
ana@vm:~/prof$ go run ./tools/genlog -n 2000000 > big.log
ana@vm:~/prof$ stat -c "%s bytes  %n" big.log
91465537 bytes  big.log
ana@vm:~/prof$ go build -o profcount ./tools/profcount
ana@vm:~/prof$ ./profcount -cpuprofile count.cpu -memprofile count.mem big.log
2000000 lines, 8 paths
ana@vm:~/prof$ stat -c "%s bytes  %n" count.cpu count.mem
6657 bytes  count.cpu
1355 bytes  count.mem
```

**91.465.537 bytes**, dois milhões de linhas e os oito caminhos da lista do `genlog`. Os profiles são
pequenos, alguns kilobytes cada, porque um profile guarda cada pilha distinta uma vez, com uma
contagem ao lado, e um programa simples assim tem poucas pilhas distintas, não importa quantas vezes
as percorra.

Primeiro o profile de CPU:

```
ana@vm:~/prof$ go tool pprof -top count.cpu | sed /^Time:/d | head -10
File: profcount
Build ID: e7da116405d9a0162329433c437ea1a89bdf4d5d
Type: cpu
Duration: 615.04ms, Total samples = 620ms (100.81%)
Showing nodes accounting for 620ms, 100% of 620ms total
      flat  flat%   sum%        cum   cum%
     120ms 19.35% 19.35%      210ms 33.87%  strings.Fields
      40ms  6.45% 25.81%       40ms  6.45%  runtime.asyncPreempt
      30ms  4.84% 30.65%       30ms  4.84%  runtime.lock2
      30ms  4.84% 35.48%       40ms  6.45%  runtime.unlock2
```

A execução durou 615 milissegundos e o profile tem 62 amostras, poucas demais para ordenar com
confiança qualquer coisa além da primeira linha. Essa linha é a que o benchmark encontrou:
**`strings.Fields`, cerca de um quinto das amostras sozinha e um terço contando o que ela chama**. As
linhas abaixo são pequenas e pertencem ao runtime. `runtime.asyncPreempt` é onde uma amostra cai
quando o runtime acabou de interromper uma goroutine para deixar outra coisa rodar, o coletor de lixo
por exemplo, e `lock2` e `unlock2` são os locks internos dele; numa execução tão curta, três ou quatro
amostras para cada uma é tudo o que são.

## Memória viva e memória toda

O profile de heap é o mais surpreendente dos dois. Aberto como vem, na visão padrão:

```
ana@vm:~/prof$ go tool pprof -top count.mem | sed /^Time:/d | head -9
File: profcount
Build ID: e7da116405d9a0162329433c437ea1a89bdf4d5d
Type: inuse_space
Showing nodes accounting for 2210.27kB, 100% of 2210.27kB total
      flat  flat%   sum%        cum   cum%
 1184.27kB 53.58% 53.58%  1184.27kB 53.58%  runtime/pprof.StartCPUProfile
    1026kB 46.42%   100%     1026kB 46.42%  runtime.mallocgc
         0     0%   100%  1184.27kB 53.58%  main.main
         0     0%   100%  1184.27kB 53.58%  main.run
```

**2,2 MB vivos, e nada disso pertence ao `tally`.** Mais da metade é o buffer do próprio profiler de
CPU, alocado por `StartCPUProfile`, e o resto é do runtime. Quando o profile de heap foi gravado,
depois do `runtime.GC()`, tudo o que o `Count` tinha feito era lixo e já tinha sido coletado, e os dois
mapas pequenos, de oito caminhos e dez status, são pouco demais para serem escolhidos por uma amostra
a cada 512 KB. O `inuse_space` responde "o que está segurando memória agora", e para o `hits` a
resposta é nada.

A outra pergunta é "o que foi alocado pelo caminho":

```
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_space count.mem | sed /^Time:/d | head -8
File: profcount
Build ID: e7da116405d9a0162329433c437ea1a89bdf4d5d
Type: alloc_space
Showing nodes accounting for 253.02MB, 99.15% of 255.18MB total
Dropped 15 nodes (cum <= 1.28MB)
      flat  flat%   sum%        cum   cum%
  143.51MB 56.24% 56.24%   143.51MB 56.24%  strings.Fields
  109.51MB 42.91% 99.15%   109.51MB 42.91%  bufio.(*Scanner).Text (inline)
```

**255,18 MB alocados para contar um arquivo de 91 MB**, tudo pelas mesmas duas funções que o
benchmark apontou, e tudo virando lixo em instantes. Isso dá uns 133 bytes por linha, que é também o
resultado dos 13.323.728 bytes para 100.000 linhas da seção 03. Dois profiles de programas diferentes,
com entradas diferentes, concordam no byte por linha, e esse é o tipo de conferência que vale fazer
antes de acreditar em qualquer um deles. Uma contagem que aloca quase três vezes o tamanho da entrada
e não guarda nada é a segunda descoberta desta lição, e a lição 13 remove a maior parte disso.
