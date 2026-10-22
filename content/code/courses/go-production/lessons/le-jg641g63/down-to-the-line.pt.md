---
title: Até a linha
version: 1
---

O `-top` nomeia funções. A correção vai ser a mudança de uma linha, então a próxima pergunta é **a
qual linha do `Parse` pertencem os 3,82 segundos**, e depois disso, em que o `strings.Fields` gasta
os 2,53 segundos dele. O `go tool pprof` responde as duas, e também consegue estreitar um relatório
para a parte do programa que interessa, o que importa quando as linhas do runtime começam a abafar
as suas.

## `list`: o código, linha por linha

O `-list` recebe uma expressão regular, acha as funções cujo nome casa e imprime o código delas com
duas colunas na frente, flat e cum de cada linha. Ele lê o arquivo de código pelo caminho guardado
no profile, então funciona na máquina que compilou o binário:

```
ana@vm:~/prof$ go tool pprof -list "tally.Parse" cpu.out | head -21
Total: 6s
ROUTINE ======================== example.com/hits/internal/tally.Parse in /home/ana/prof/internal/tally/tally.go
      20ms      3.82s (flat, cum) 63.67% of Total
      10ms       10ms     26:func Parse(line string) (Entry, error) {
         .      2.53s     27:	f := strings.Fields(line)
         .          .     28:	if len(f) != 5 {
         .          .     29:		return Entry{}, fmt.Errorf("want 5 fields, got %d", len(f))
         .          .     30:	}
         .      670ms     31:	t, err := time.Parse(time.RFC3339, f[0])
         .          .     32:	if err != nil {
         .          .     33:		return Entry{}, err
         .          .     34:	}
         .      140ms     35:	status, err := strconv.Atoi(f[3])
         .          .     36:	if err != nil {
         .          .     37:		return Entry{}, fmt.Errorf("status: %w", err)
         .          .     38:	}
         .      460ms     39:	d, err := time.ParseDuration(f[4])
         .          .     40:	if err != nil {
         .          .     41:		return Entry{}, err
         .          .     42:	}
      10ms       10ms     43:	return Entry{Time: t, Method: f[1], Path: f[2], Status: status, Duration: d}, nil
```

**A linha 27, `strings.Fields`, leva 2,53 dos 3,82 segundos do `Parse`**: dois terços da função numa
chamada só. O horário, linha 31, custa 670 ms; a duração, linha 39, 460 ms; o `strconv.Atoi`, 140
ms. Os pontos são linhas em que nenhuma amostra caiu. O `head -21` corta a listagem no fim do
`Parse`, já que o `-list` imprime algumas linhas depois da função como contexto.

Essa listagem também encerra uma discussão antes de ela começar. O `time.Parse` com layout é a
chamada de que as pessoas desconfiam primeiro num parser de log, porque interpretar datas parece
lento. No Go 1.27, um horário em `time.RFC3339` passa por um caminho escrito para esse layout,
`time.parseRFC3339` no profile, e a linha custa mais ou menos um quarto do que custa o
`strings.Fields`. **O profile já disse onde não gastar a tarde.**

## `peek`: quem chama e quem é chamado

O `-peek` imprime, para cada função que casa, quem a chamou acima da linha e o que ela chamou
abaixo, com o tempo que foi para cada lado:

```
ana@vm:~/prof$ go tool pprof -peek "strings.Fields" cpu.out | sed /^Time:/d
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 6s, 100% of 6s total
----------------------------------------------------------+-------------
      flat  flat%   sum%        cum   cum%   calls calls% + context 	 	 
----------------------------------------------------------+-------------
                                             2.53s   100% |   example.com/hits/internal/tally.Parse
     1.20s 20.00% 20.00%      2.53s 42.17%                | strings.Fields
                                             0.75s 29.64% |   runtime.makeslice
                                             0.33s 13.04% |   runtime.asyncPreempt
                                             0.24s  9.49% |   gcWriteBarrier
                                             0.01s   0.4% |   runtime.gcWriteBarrier2
----------------------------------------------------------+-------------
```

Toda chamada de `strings.Fields` veio de `tally.Parse`. Dos 2,53 segundos de cum dela, **0,75 foram
para `runtime.makeslice`**, que aloca a fatia de campos que ela devolve, e 0,33 para preempção.
Outros 0,24 foram para `gcWriteBarrier`, a contabilidade de que o coletor de lixo precisa quando um
ponteiro é gravado em memória do heap, que é exatamente o que preencher uma fatia de strings
recém-alocada faz. O resto, os 1,20 segundo de flat, é o laço que procura os espaços. A coluna diz
`calls`, mas o que ela guarda é tempo: o tempo gasto em cada função chamada, não uma contagem.

## Estreitando o relatório

O profile de um programa real tem centenas de funções. Quatro opções o reduzem, e duas delas se
confundem fácil:

- **`-focus=REGEXP`** mantém só as amostras cuja pilha contém uma função que casa, então
  `-focus=tally.Parse` mostra o mundo visto de dentro do `Parse`.
- **`-hide=REGEXP`** remove os quadros que casam de cada pilha, mas mantém as amostras; o tempo deles
  é cobrado de quem os chamou.
- **`-ignore=REGEXP`** descarta toda amostra cuja pilha contém uma função que casa.
- **`-nodefraction=F`** esconde as linhas cujo cum fica abaixo dessa fração do total.

`-hide` e `-ignore` com o mesmo padrão dão respostas opostas:

```
ana@vm:~/prof$ go tool pprof -top -hide=runtime cpu.out | sed /^Time:/d | head -14
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Active filters:
   hide=runtime
Showing nodes accounting for 4.92s, 82.00% of 6s total
Dropped 3 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     2.53s 42.17% 42.17%      2.53s 42.17%  strings.Fields
     0.58s  9.67% 51.83%      4.95s 82.50%  example.com/hits/internal/tally.Count
     0.41s  6.83% 58.67%      0.41s  6.83%  bufio.(*Scanner).Text (inline)
     0.40s  6.67% 65.33%      0.45s  7.50%  time.ParseDuration
     0.22s  3.67% 69.00%      0.22s  3.67%  time.parseRFC3339[go.shape.string].func1 (inline)
ana@vm:~/prof$ go tool pprof -top -ignore=runtime cpu.out | sed /^Time:/d | head -12
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Active filters:
   ignore=runtime
Showing nodes accounting for 2.25s, 37.50% of 6s total
Dropped 2 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     1.20s 20.00% 20.00%      1.20s 20.00%  strings.Fields
     0.22s  3.67% 23.67%      2.26s 37.67%  example.com/hits/internal/tally.Count
     0.19s  3.17% 26.83%      0.19s  3.17%  time.parseRFC3339[go.shape.string].func1 (inline)
```

Com o runtime escondido, **`strings.Fields` tem 2,53 segundos de flat, igual ao cum**: a alocação e
os write barriers que ela causou agora são cobrados dela, o que responde direto à pergunta "quanto
custa esta linha do meu código, com tudo". O `Scanner.Text` aparece com 0,41 segundo de flat, que
era o runtime copiando a linha e alocando a string dela. Com o runtime ignorado, em vez disso, toda
amostra que tocou qualquer função `runtime.` some, e **o `tally.Count` cai de 82,50% para 37,67%**:
o relatório passa a descrever outro programa, imaginário, que nunca aloca. O `-ignore` serve para
remover algo de fato alheio, um trabalho em segundo plano dividindo o processo; é a ferramenta
errada para tirar ruído.

O `-nodefraction` é a versão suave, que esconde as linhas pequenas e não mexe em mais nada:

```
ana@vm:~/prof$ go tool pprof -top -nodefraction=0.05 cpu.out | sed /^Time:/d
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 2.70s, 45.00% of 6s total
Dropped 173 nodes (cum <= 0.30s)
      flat  flat%   sum%        cum   cum%
     1.20s 20.00% 20.00%      2.53s 42.17%  strings.Fields
     0.53s  8.83% 28.83%      0.53s  8.83%  runtime.asyncPreempt
     0.31s  5.17% 34.00%      0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
     0.22s  3.67% 37.67%      4.95s 82.50%  example.com/hits/internal/tally.Count
     0.10s  1.67% 39.33%      0.45s  7.50%  time.ParseDuration
     0.10s  1.67% 41.00%      0.59s  9.83%  time.parseRFC3339[go.shape.string]
     0.07s  1.17% 42.17%      0.67s 11.17%  time.Parse
     0.06s  1.00% 43.17%      0.31s  5.17%  runtime.mapaccess2_faststr
     0.03s   0.5% 43.67%      0.51s  8.50%  runtime.bgsweep
     0.03s   0.5% 44.17%      0.75s 12.50%  runtime.makeslice
     0.02s  0.33% 44.50%      3.82s 63.67%  example.com/hits/internal/tally.Parse
     0.02s  0.33% 44.83%      1.05s 17.50%  runtime.mallocgc
     0.01s  0.17% 45.00%      0.30s  5.00%  runtime.unlockWithRank (inline)
         0     0% 45.00%      0.41s  6.83%  bufio.(*Scanner).Text (inline)
         0     0% 45.00%      4.95s 82.50%  example.com/hits/internal/tally_test.BenchmarkCount
         0     0% 45.00%      0.38s  6.33%  runtime.goschedImpl
         0     0% 45.00%      0.35s  5.83%  runtime.gosched_m
         0     0% 45.00%      0.37s  6.17%  runtime.mcall
         0     0% 45.00%      0.41s  6.83%  runtime.slicebytetostring
         0     0% 45.00%      0.51s  8.50%  runtime.systemstack
         0     0% 45.00%      0.30s  5.00%  runtime.unlock (inline)
         0     0% 45.00%      4.95s 82.50%  testing.(*B).run1.func1
         0     0% 45.00%      4.95s 82.50%  testing.(*B).runN
```

173 linhas descartadas, todas com menos de 0,30 segundo de cum, e as 23 que sobram são as que valem
a leitura.

## O grafo de chamadas, se você quiser

O `go tool pprof` também desenha o profile como grafo, uma caixa por função e uma seta por chamada,
com o tamanho do nome acompanhando o flat e a espessura da seta acompanhando o tempo. Ele usa o
`dot` do Graphviz, que o Ubuntu instala com `sudo apt install graphviz`, e grava SVG, PNG ou PDF:

```
ana@vm:~/prof$ go tool pprof -svg -output graph.svg cpu.out
Generating report in graph.svg
ana@vm:~/prof$ stat -c "%s bytes  %n" graph.svg
153168 bytes  graph.svg
```

O arquivo abre em qualquer navegador. Ele mostra os mesmos números do `-peek` para todas as funções
de uma vez, e num programa com uma árvore de chamadas funda e ramificada é o jeito mais rápido de
ver qual caminho leva o tempo. Para o `hits` a forma é simples o bastante para o desenho da próxima
seção dizer mais.