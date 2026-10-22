---
title: Um arquivo, copiado para dentro quando o programa é compilado
version: 1
---

A lição 1 de `go` mostrou o que é um programa Go no fim: um arquivo para copiar, sem nada para
instalar ao lado. Um programa que lê um template, uma página ou uma configuração padrão do disco
quebra essa promessa, porque agora o arquivo também precisa viajar e ser achado na execução.
**`//go:embed` copia um arquivo para dentro do binário quando ele é compilado**, e o programa o lê de
uma variável.

Todo programa desta lição mora num diretório próprio dentro de `~/embedding`, um módulo só para
todos. O primeiro imprime um número de versão e o tamanho de um pequeno banner, os dois vindos de
arquivos ao lado dele, salvo como `version/main.go`:

```schooling-example
{"language": "go", "file": "version/main.go", "parts": [{"code": "// Command version prints a file that was copied into it when it was built.\npackage main\n\nimport (\n\t_ \"embed\"\n\t\"fmt\"\n\t\"strings\"\n)\n\n", "note": "**O pacote `embed` precisa ser importado**, mesmo quando nada no arquivo o cita. O `_` em branco diz que a importação está ali pelo efeito no build."}, {"code": "//go:embed version.txt\nvar version string\n\n", "note": "**`//go:embed` é uma diretiva para o comando go, escrita como comentário sem espaço depois de `//`**, na linha logo acima de uma variável de pacote. O arquivo é nomeado em relação ao diretório do arquivo-fonte. Uma `string` recebe o conteúdo como texto."}, {"code": "//go:embed logo.txt\nvar logo []byte\n\n", "note": "Um `[]byte` o recebe como bytes. A terceira escolha, `embed.FS`, é da próxima seção."}, {"code": "func main() {\n\tfmt.Println(\"version\", strings.TrimSpace(version))\n\tfmt.Println(len(logo), \"bytes of logo\")\n}\n", "note": "Daqui em diante as variáveis são valores comuns, e nada lê o disco."}]}
```

Os arquivos de dados são digitados em vez de mostrados, uma linha cada. O primeiro build só tem um
dos dois:

```
ana@vm:~/embedding$ printf "1.4.2\n" > version/version.txt
ana@vm:~/embedding$ go build -o bin/version ./version
version/main.go:13:12: pattern logo.txt: no matching files found
ana@vm:~/embedding$ printf "[ go ]\n" > version/logo.txt
ana@vm:~/embedding$ go build -o bin/version ./version
ana@vm:~/embedding$ bin/version
version 1.4.2
7 bytes of logo
ana@vm:~/embedding$ printf "1.5.0\n" > version/version.txt
ana@vm:~/embedding$ bin/version
version 1.4.2
7 bytes of logo
ana@vm:~/embedding$ go build -o bin/version ./version
ana@vm:~/embedding$ bin/version
version 1.5.0
7 bytes of logo
```

**Um arquivo que não está lá é um erro de build**, que cita o padrão que não casou com nada, então
um binário nunca sai sem um arquivo que embute. Depois que o banner existiu, o programa compilou e
rodou. Aí o arquivo de versão mudou e o mesmo binário rodou de novo: ainda disse `1.4.2`, porque o
conteúdo foi copiado na compilação e o arquivo em disco não é mais consultado. Só um build novo
pegou o `1.5.0`. Esse é o comportamento inteiro, e vale lembrar dele no dia em que uma mudança num
arquivo embutido parecer não ter efeito.

## A importação não é opcional

A mesma diretiva num arquivo que não importa `embed`, salvo como `noimport/main.go`:

```go
package main

import "fmt"

//go:embed version.txt
var version string

func main() { fmt.Print(version) }
```

```
ana@vm:~/embedding$ go build -o bin/noimport ./noimport
# example.com/embedding/noimport
noimport/main.go:5:3: go:embed requires import "embed" (or import _ "embed", if package is not used)
```

A mensagem dá as duas formas do conserto. É uma recusa e não um nada silencioso, o que importa: uma
diretiva é um comentário, e sem essa conferência uma diretiva com erro de digitação ou sem a
importação deixaria uma string vazia onde o arquivo devia estar.
