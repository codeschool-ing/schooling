---
title: Go
version: 1
---

**O Go foi feito no Google para servidores e as ferramentas em volta deles**, e boa parte da
infraestrutura que as próximas trilhas deste curso usam é escrita nele: Docker, Kubernetes, Terraform.
Ele compila para um arquivo só, que roda sem mais nada instalado. A instalação é como a do Node na aula
1, a partir de um tarball no site dele:

```sh
# Ubuntu and WSL: the tarball from go.dev, unpacked beside Node
curl -fsSLO https://go.dev/dl/go1.27.3.linux-amd64.tar.gz
mkdir -p ~/.local/go
tar -xzf go1.27.3.linux-amd64.tar.gz -C ~/.local/go --strip-components=1
ln -s ~/.local/go/bin/go ~/.local/bin/
brew install go                   # a Mac, with Homebrew
```

**Nenhum dos dois blocos foi rodado para este curso como está escrito**: a máquina do curso não
alcançava o go.dev, e o Go 1.27.3 dela foi desempacotado da mesma versão servida pelo proxy de módulos
do Go, na mesma pasta. O pacote `golang-go` do próprio Ubuntu também funciona, e é dois anos mais
antigo. A partir daí:

```
ana@dev:~/server/other/go$ go version
go version go1.27.3 linux/amd64
ana@dev:~/server/other/go$ go mod init hello
go: creating new go.mod: module hello
go: to add module requirements and sums:
	go mod tidy
```

O `go mod init` é o `npm init`: ele escreve o `go.mod`, o arquivo que dá nome ao módulo e, mais tarde,
às dependências dele.

```schooling-example
{"language": "go", "file": "main.go", "parts": [
 {"code": "// main.go: the same server in Go, with nothing but the standard library.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"log\"\n\t\"net/http\"\n\t\"os\"\n\t\"time\"\n)", "note": "**Todo arquivo pertence a um pacote, e um programa começa no `main`.** Os imports são todos da biblioteca padrão, que tem um servidor HTTP e JSON prontos para produção."},
 {"code": "func send(w http.ResponseWriter, status int, body any) {\n\tw.Header().Set(\"content-type\", \"application/json\")\n\tw.WriteHeader(status)\n\tjson.NewEncoder(w).Encode(body)\n}", "note": "**Os tipos são escritos**, depois do nome: `status int`. O `any` é qualquer tipo, e é assim que um map e uma struct podem ser mandados."},
 {"code": "func main() {\n\tmux := http.NewServeMux()\n\tmux.HandleFunc(\"GET /hello\", func(w http.ResponseWriter, r *http.Request) {\n\t\tname := r.URL.Query().Get(\"name\")\n\t\tif name == \"\" {\n\t\t\tname = \"world\"\n\t\t}\n\t\tsend(w, http.StatusOK, map[string]string{\"hello\": name})\n\t})", "note": "**`\"GET /hello\"` é um método e um caminho num padrão só**, que o roteador do Go entende desde a 1.22. Um parâmetro de query que falta é uma string vazia, não `undefined`."},
 {"code": "\tmux.HandleFunc(\"GET /slow\", func(w http.ResponseWriter, r *http.Request) {\n\t\ttime.Sleep(time.Second)\n\t\tsend(w, http.StatusOK, map[string]int{\"slept\": 1000})\n\t})\n\tmux.HandleFunc(\"/\", func(w http.ResponseWriter, r *http.Request) {\n\t\tsend(w, http.StatusNotFound, map[string]string{\"error\": \"nothing at \" + r.URL.Path})\n\t})", "note": "**O `time.Sleep` bloqueia só este pedido**: o Go roda cada pedido numa *goroutine*, uma thread tão barata que um servidor mantém uma por conexão."},
 {"code": "\tport := os.Getenv(\"PORT\")\n\tif port == \"\" {\n\t\tport = \"3000\"\n\t}\n\tlog.Println(\"go on :\" + port)\n\tlog.Fatal(http.ListenAndServe(\"127.0.0.1:\"+port, mux))\n}", "note": "**Erros são valores, devolvidos**, não lançados. O `ListenAndServe` só devolve um quando para, e o `log.Fatal` o imprime e sai."}
]}
```

O `go run .` compila e roda num passo só:

```
ana@dev:~/server/other/go$ go run .
2026/10/22 20:11:22 go on :3000
signal: interrupt
^C
```

```
ana@dev:~/server/other/go$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}

ana@dev:~/server/other/go$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at /nope"}
 404
ana@dev:~/server/other/go$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.017s
user	0m0.020s
sys	0m0.036s
```

**As mesmas respostas.** O `Encode` termina o JSON com uma quebra de linha, e por isso há uma linha
vazia depois de cada uma aqui. **Dez pedidos lentos levaram um segundo**, cada um na sua goroutine.

## Um arquivo para o deploy

```
ana@dev:~/server/other/go$ go build -o hello && ls -lh hello && file hello
-rwxr-xr-x 1 ana ana 9.4M Oct 22 20:11 hello
hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=zke-3B9ap-ii_kGjHfvU/jY9QNojl_GW3-QZp088R/VnXH9NUs25NBglEMaOZN/Z98McU8tWfx86XqjRrR8, BuildID[sha1]=f948754fb3b2ac3c37346f35e7343c09c4fd9bb7, with debug_info, not stripped
```

**O `go build` fez um executável só, de uns nove megabytes**, com o runtime e a biblioteca padrão
dentro. Copiado para outra máquina Linux com o mesmo tipo de processador, ele roda sem Go, sem
`node_modules` e sem runtime de versão nenhuma instalado. O `file` diz que ele é *dynamically
linked*: ele usa a biblioteca C do sistema, que todo Linux tem, para resolver nomes de máquinas, e o
`CGO_ENABLED=0 go build` faz um que não precisa nem disso. É essa a propriedade pela qual o Go é
escolhido com mais frequência, e o motivo de tantas ferramentas de linha de comando serem escritas nele.

| o quê | em termos de Node |
|---|---|
| o `net/http` da biblioteca padrão | o `node:http`, mas usado em produção como está |
| `chi`, `gin`, `echo`, quando um roteador não basta | Express |
| `go.mod` e `go.sum` | `package.json` e `package-lock.json` |
| `go get` | `npm install` |
| `go test` | `node --test` |
