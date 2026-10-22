---
title: O preço de uma dependência
version: 1
---

O custo de um framework não é o tamanho do download. **É tudo o que vem junto com deixar o código
de outra pessoa decidir a forma do seu serviço**, pago aos poucos enquanto o serviço viver. A aula
4 mediu a primeira parte disso.

## Módulos de que você agora cuida

O Gin trouxe 55 módulos para o grafo de módulos, o Fiber 25, o Beego 102. Cada um é código que roda
dentro do seu processo com todas as permissões dele. **Quando um deles tem uma vulnerabilidade
conhecida, o seu serviço tem também**, chame você a função vulnerável ou não, até alguém conferir e
atualizar. O Go tem uma ferramenta que lê o grafo de módulos contra uma base de vulnerabilidades
conhecidas e aponta só as que o seu código alcança; a aula 9 do `go-production` a ensina, e num
serviço com cem módulos isso é tarefa semanal, não curiosidade.

Cada módulo também tem uma licença, um mantenedor que talvez pare, e a própria ideia de quando
quebrar compatibilidade. **O `gorilla/mux`, por anos o roteador padrão do mundo Go, foi arquivado
em dezembro de 2022**, e todo projeto que o usava teve de decidir entre esperar e migrar, até novos
mantenedores o assumirem em 2023.

## Uma versão maior é cada handler

Num framework, **a assinatura do handler pertence ao framework**. O programa Echo da aula 4 foi
escrito para a v5, em que um handler recebe `*echo.Context`. Eis o mesmo arquivo sem nenhuma
mudança além do import, compilado contra a v4, a versão maior que o Echo lançou por anos antes da
v5:

```
ana@vm:~/fw/echo4$ sed -i "s#labstack/echo/v5#labstack/echo/v4#g" main.go && grep echo/v4 main.go
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
ana@vm:~/fw/echo4$ go mod tidy
go: finding module for package github.com/labstack/echo/v4/middleware
go: finding module for package github.com/labstack/echo/v4
go: downloading github.com/labstack/echo/v4 v4.16.0
go: found github.com/labstack/echo/v4 in github.com/labstack/echo/v4 v4.16.0
go: found github.com/labstack/echo/v4/middleware in github.com/labstack/echo/v4 v4.16.0
go: downloading golang.org/x/crypto v0.53.0
go: downloading github.com/labstack/gommon v0.5.0
go: downloading golang.org/x/net v0.56.0
go: downloading github.com/valyala/fasttemplate v1.2.2
go: downloading github.com/mattn/go-colorable v0.1.15
go: downloading github.com/mattn/go-isatty v0.0.22
go: downloading golang.org/x/sys v0.46.0
ana@vm:~/fw/echo4$ go build -o server .
# example.com/fw/echo4
./main.go:33:23: cannot use func(c *echo.Context) error {…} (value of type func(c *echo.Context) error) as echo.HandlerFunc value in argument to e.GET
./main.go:34:29: c.Param undefined (type *echo.Context is pointer to interface, not interface)
./main.go:44:12: c.JSON undefined (type *echo.Context is pointer to interface, not interface)
./main.go:46:32: cannot use func(c *echo.Context) error {…} (value of type func(c *echo.Context) error) as echo.HandlerFunc value in argument to e.POST
./main.go:47:27: c.Param undefined (type *echo.Context is pointer to interface, not interface)
./main.go:49:15: c.Bind undefined (type *echo.Context is pointer to interface, not interface)
./main.go:65:12: c.JSON undefined (type *echo.Context is pointer to interface, not interface)
```

**Sete erros, um para cada lugar em que o arquivo toca o contexto**, e num serviço real seria um
para cada handler e cada middleware. Na v4, `echo.Context` é uma interface e o handler a recebe por
valor; na v5 é uma struct e o handler recebe um ponteiro. Levar um serviço de uma para a outra é
mexer em toda rota que ele tem. É uma mudança mecânica e um framework tem direito de fazê-la, que é
para isso que existe uma versão maior, e é exatamente o tipo de trabalho que **um handler escrito
como `func(w http.ResponseWriter, r *http.Request)` nunca teve de fazer desde o Go 1**.

## Uma coisa maior para publicar

O binário da versão Gin da aula 4 tinha 31,6 MB contra 9,8 MB da biblioteca padrão, para as mesmas
duas rotas. **Tamanho sozinho raramente importa num servidor**, e importa um pouco mais na imagem de
container que a aula 16 monta, que toda implantação baixa, e no tempo de compilar e de escanear. É
o menor desses custos, e o mais fácil de medir.

## E uma segunda coisa para aprender

Todo desenvolvedor que entra na equipe tem de aprender Go, e depois o framework: o contexto dele,
as regras de binding, o tratador de erros, os padrões. **Um desenvolvedor Go que nunca viu o
boxoffice consegue ler cada linha dele no primeiro dia**, porque ele não usa nada que não esteja na
documentação da biblioteca padrão. Isso não vale para um serviço Gin ou Beego, por mais limpo que
seja.
