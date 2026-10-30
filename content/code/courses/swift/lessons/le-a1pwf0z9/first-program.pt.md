---
title: O primeiro programa, rodado de dois jeitos
version: 1
---

Um programa Swift é um arquivo de texto terminado em `.swift`. Crie um diretório para esta aula,
`~/sw/l01`, abra um arquivo chamado `Hello.swift` em qualquer editor de texto e digite estas quatro
linhas:

```swift
// Hello.swift
let course = "Swift"
let minutes = 45
print("Studied \(course) for \(minutes) minutes")
```

A primeira linha é um comentário, e o compilador a ignora. Todo programa deste curso começa com um
comentário que dá o nome do arquivo, para você sempre saber como chamar o arquivo que está
digitando. As duas linhas seguintes dão dois nomes a dois valores, e a seção 05 é sobre a palavra
`let`. A última imprime uma frase, e o `\(…)` dentro das aspas é **interpolação de string**: o Swift
avalia o que está entre os parênteses e põe o resultado no texto.

Não há função `main`, nem classe, nem import. Um arquivo de instruções é um programa inteiro, e as
instruções rodam de cima para baixo. Isso é uma propriedade de um arquivo rodado sozinho; os pacotes
da aula 19 põem a mesma regra num único arquivo, `main.swift`, e em nenhum outro.

## Dois comandos, um compilador

```
ana@vm:~/sw/l01$ swift Hello.swift
Studied Swift for 45 minutes
ana@vm:~/sw/l01$ swiftc Hello.swift -o hello
ana@vm:~/sw/l01$ ./hello
Studied Swift for 45 minutes
ana@vm:~/sw/l01$ ls -l Hello.swift hello
-rw-r--r-- 1 ana ana   103 Oct 30 14:52 Hello.swift
-rwxr-xr-x 1 ana ana 16968 Oct 30 14:52 hello
ana@vm:~/sw/l01$ file hello
hello: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=11a55221dc1c195d3e9b99c0e54ed521cddaf428, not stripped
```

**`swift Hello.swift` compila o arquivo na memória e o roda na hora**, sem imprimir mais nada. É o
jeito mais rápido de experimentar algo, e a maioria dos programas deste curso roda assim.

**`swiftc Hello.swift -o hello` o compila para um arquivo** e não roda nada. O `-o` dá nome ao
resultado; sem ele o arquivo se chamaria `Hello`, como o fonte. O `./hello` então o roda, como
qualquer outro programa da máquina. Os dois comandos usam o mesmo compilador e produzem o mesmo
código de máquina, e a diferença é só se sobra um arquivo.

As duas linhas do `ls` merecem uma olhada. Quatro linhas de fonte viraram um programa de cerca de
17 KB, e o `file` diz de que tipo: um **executável ELF para x86-64**, o formato nativo do Linux nesse
processador. O Swift não roda numa máquina virtual como o Java e o Kotlin. O compilador, construído
sobre o LLVM, transforma o fonte em instruções para o processador à sua frente, e o mesmo
`Hello.swift` compilado no processador de um iPhone vira um programa ARM.

O executável é pequeno porque não está sozinho. Ele é "dynamically linked", então pega emprestados o
runtime e a biblioteca padrão do Swift do diretório `usr/lib/swift/linux` do toolchain toda vez que
inicia. Copie o `hello` para uma máquina sem o toolchain e ele não inicia, que é o problema que a
aula 20 resolve com um build estático.

## O que digitar, toda vez

Daqui em diante todo programa chega do mesmo jeito: um bloco cuja primeira linha dá o nome do
arquivo, e então um bloco de terminal mostrando o comando e o que voltou. **Digite o programa você
mesmo em vez de colar**, nas primeiras aulas; muito do que o Swift ensina no começo é a reação do
compilador a um erro de digitação, e você verá mais delas digitando.

O prompt no começo de cada comando, `ana@vm:~/sw/l01$`, é o da Ana: o nome de usuário dela, o nome da
máquina e o diretório em que ela está. O seu mostrará os seus, e a parte depois do `$` é o que você
digita.
