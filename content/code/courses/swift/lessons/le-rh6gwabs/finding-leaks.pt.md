---
title: Achando um ciclo que você não viu sendo escrito
version: 1
---

O vazamento da seção 03 não imprimiu nada. Um ciclo é a ausência de uma linha, e ausências são
difíceis de notar lendo saída. **Por isso as ferramentas de vazamento funcionam todas do mesmo jeito:
olham o que ainda está na memória e perguntam o que o segura.** Num Mac essas ferramentas estão no
Xcode; no Linux, o compilador traz uma própria.

## Num Mac: o grafo de memória e o Instruments

Esta parte não foi rodada para este curso, porque o Xcode só existe para macOS. Ela é descrita a
partir da documentação da Apple para o Xcode.

- **O depurador de grafo de memória.** Enquanto um app roda pelo Xcode, o botão chamado *Debug Memory
  Graph* o pausa e lista todo objeto vivo naquele momento, agrupado por classe. Selecionar um desenha
  as referências que o seguram, e um ciclo aparece desenhado como um laço. Objetos que o Xcode
  consegue provar que vazaram ganham um sinal de alerta roxo.
- **O Instruments, com o modelo Leaks.** O Instruments grava o app enquanto você o usa, e o
  instrumento Leaks confere a memória de tempos em tempos e lista as alocações para as quais nada
  alcançável aponta, com um desenho do ciclo e o código que alocou cada objeto.

O `ios-apps` usa os dois num app de verdade. O que eles mostram é a mesma coisa que esta aula
mostra com o `deinit`: quais objetos estão vivos e não deveriam estar.

## No Linux: a verificação de vazamento do address sanitizer

O compilador consegue gerar um programa com o **AddressSanitizer**, um conjunto de verificações que
ele insere no código de máquina. No Linux ele inclui o **LeakSanitizer**, que roda quando o programa
termina e relata todo bloco de memória para o qual nada alcançável aponta. Um ciclo é exatamente
isso: dois objetos alcançáveis só um pelo outro. O programa da seção 03, sem mudança nenhuma,
compilado com `-sanitize=address`:

```
ana@vm:~/sw/l11$ swiftc -sanitize=address Cycle.swift -o cycle-asan 2>&1 | grep -c "warning: Cannot export"
141
ana@vm:~/sw/l11$ ./cycle-asan 2>&1 | swift demangle --simplified | grep -E "leak of|SUMMARY|__allocating_init"
Indirect leak of 40 byte(s) in 1 object(s) allocated from:
    #3 0x56408b09cddb in Course.__allocating_init(name:) crtstuff.c
Indirect leak of 40 byte(s) in 1 object(s) allocated from:
Indirect leak of 32 byte(s) in 1 object(s) allocated from:
    #3 0x56408b09d327 in StudySession.__allocating_init(minutes:) crtstuff.c
SUMMARY: AddressSanitizer: 112 byte(s) leaked in 3 allocation(s).
```

O build imprime 141 linhas de avisos do linker sobre símbolos que ele não consegue exportar, e o
`grep -c` as conta em vez de mostrá-las; elas são sobre o código do próprio sanitizer e o programa é
gerado corretamente. A execução termina então com um relatório. Os nomes saem **mutilados**
(*mangled*), a codificação que o compilador faz de um nome Swift num símbolo, então o
`swift demangle --simplified` os devolve a Swift, e o `grep` guarda as linhas que valem a leitura:

- **três alocações vazadas, 112 bytes.** Uma é um `Course`, outra é uma `StudySession`, e a terceira
  é o armazenamento do array `sessions` que o `append` criou;
- **onde cada uma foi feita**, em `plan()`, por `Course.__allocating_init(name:)` e
  `StudySession.__allocating_init(minutes:)`, que é aquilo em que `Course(name:)` e
  `StudySession(minutes:)` se compilam;
- **"Indirect" em todas**, que é a palavra do LeakSanitizer para memória segurada só por outra memória
  vazada: a assinatura de um ciclo.

A mesma verificação no programa da seção 04, em que a referência de volta é `weak`:

```
ana@vm:~/sw/l11$ swiftc -sanitize=address Weak.swift -o weak-asan 2>/dev/null
ana@vm:~/sw/l11$ ./weak-asan 2>&1 | grep -c "leak of"
0
```

Nenhum relatório de vazamento, então o `grep -c` conta zero linhas de um. **Um build com sanitizer é
mais lento e maior**, então é um build para investigar, não para distribuir.

Uma coisa que o sanitizer faz e que você precisa saber antes de confiar na saída dele: as linhas de
`print` do próprio programa não apareceram na primeira execução. O LeakSanitizer encerra o processo do
jeito dele depois do relatório, e o que ainda estava no buffer de saída se perde, e é por isso que
essas execuções foram filtradas só para o relatório.

## O hábito que acha a maioria deles

Nenhuma das ferramentas substitui a mais barata: **um `deinit` que imprime, em toda classe de que você
suspeita.** Rode o fluxo que deveria encerrar a vida de um objeto, sair de uma tela num app, retornar
de `plan()` aqui, e procure a linha. Uma linha de `deinit` faltando é um ciclo até prova em contrário,
e o lugar de procurar é cada propriedade guardada e cada closure guardada daquela classe.
