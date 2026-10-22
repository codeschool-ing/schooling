---
title: Servir um site de dentro do binário
version: 1
---

O uso mais comum de um `embed.FS` é o que esta própria plataforma faz: um servidor web que leva as
próprias páginas, scripts e folhas de estilo, para que implantá-lo seja copiar um arquivo.
**`http.FileServerFS` serve qualquer `fs.FS`, e `fs.Sub` transforma um subdiretório de um num
sistema de arquivos próprio.** Salvo como `serve/main.go`:

```go
// Command serve answers HTTP requests from files built into it.
package main

import (
	"embed"
	"io/fs"
	"log"
	"net/http"
)

//go:embed static
var files embed.FS

func main() {
	root, err := fs.Sub(files, "static")
	if err != nil {
		log.Fatal(err)
	}
	http.Handle("/", http.FileServerFS(root))
	log.Fatal(http.ListenAndServe("127.0.0.1:8024", nil))
}
```

`fs.Sub(files, "static")` é o motivo de a requisição para `/` achar `index.html` em vez de precisar
de `/static/index.html`. O servidor escuta só em `127.0.0.1`, então nada fora desta máquina o
alcança. O mesmo diretório `static` é copiado ao lado dele e o programa compilado:

```
ana@vm:~/embedding$ cp -r site/static serve/
ana@vm:~/embedding$ go build -o bin/serve ./serve
ana@vm:~/embedding$ ls -l bin/serve
-rwxr-xr-x 1 ana ana 8844359 Oct 16 19:54 bin/serve
```

Quase nove milhões de bytes: o servidor HTTP é a maior parte, e os quatro arquivos, algumas dezenas de
bytes. Iniciado em segundo plano, ele responde a partir do que foi embutido:

```
ana@vm:~/embedding$ curl -s http://127.0.0.1:8024/
<h1>Orders</h1>
ana@vm:~/embedding$ curl -s -o /dev/null -w "%{http_code} %{content_type}\n" http://127.0.0.1:8024/style.css
200 text/css; charset=utf-8
ana@vm:~/embedding$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8024/_notes.txt
404
ana@vm:~/embedding$ rm -r serve/static
ana@vm:~/embedding$ curl -s http://127.0.0.1:8024/
<h1>Orders</h1>
```

A página voltou, a folha de estilo chegou com o tipo de conteúdo certo, que o `FileServerFS`
deduziu da extensão, e `_notes.txt` deu 404, porque o padrão simples nunca o embutiu. **Depois o
diretório `static` foi apagado, e o servidor continuou servindo a página**, porque nunca lê esse
diretório: ele existia para o build e para nada depois.

## Para que embutir não serve

Os arquivos ficam fixos na compilação, o que é a questão e também o limite. Conteúdo que muda sem
uma nova versão, o upload de um usuário, uma configuração que muda entre ambientes, fica em disco
ou num banco de dados, lido na execução. E um arquivo embutido custa o seu tamanho no binário e na
memória: algumas folhas de estilo não custam nada, enquanto um gigabyte de vídeo seria um gigabyte
em cada cópia do programa.
