---
title: "errors.Is: esse erro está em algum lugar da cadeia?"
version: 1
---

A lição 32 conferiu todo erro com `err != nil`, e para essa pergunta o `!=` está exatamente certo. O hábito
que vem daí é comparar com um erro em particular do mesmo jeito: `err == fs.ErrNotExist`, "é um
arquivo que falta?". **Depois de um embrulho essa comparação dá falso, seja o que for que estiver
dentro.** Aqui está um `main` para o programa da seção 02, com `readConfig` e `start` sem mudança,
fazendo a pergunta de quatro jeitos:

```go
func main() {
	err := start()
	fmt.Println("==           ", err == fs.ErrNotExist)
	fmt.Println("errors.Is    ", errors.Is(err, fs.ErrNotExist))
	fmt.Println("os.IsNotExist", os.IsNotExist(err))
	fmt.Println("permission   ", errors.Is(err, fs.ErrPermission))

	if errors.Is(err, fs.ErrNotExist) {
		fmt.Println("no settings.json: starting with the defaults")
	}
}
```

```
ana@vm:~/is-as-is$ go run .
==            false
errors.Is     true
os.IsNotExist false
permission    false
no settings.json: starting with the defaults
```

O `==` compara o valor que recebe, e o valor que `start` devolveu é o `*fmt.wrapError` mais externo
da figura da seção 02. Esse valor não é `fs.ErrNotExist` e nunca vai ser, por mais camadas abaixo
que esteja o arquivo que falta. **`errors.Is(err, target)` faz a mesma pergunta a cada elo da
cadeia**, começando pelo próprio `err`, e responde `true` assim que um elo casa. A última linha é a
forma que isso toma em código de verdade: um desvio que faz algo sensato com uma falha em
particular, aqui começar com as configurações padrão, e deixa passar todos os outros erros.

A quarta linha importa tanto quanto a segunda. `errors.Is` não responde "há um erro"; responde
"*este* erro está aí dentro", e um arquivo que falta não é um problema de permissão.

## A função mais antiga, que não desembrulha

`os.IsNotExist` respondeu `false` para a mesma cadeia. Ela é mais antiga que o embrulho, e a
própria documentação diz isso:

```
ana@vm:~/is-as-is$ go doc os.IsNotExist
package os // import "os"

func IsNotExist(err error) bool
    IsNotExist returns a boolean indicating whether its argument is known
    to report that a file or directory does not exist. It is satisfied by
    ErrNotExist as well as some syscall errors.

    This function predates errors.Is. It only supports errors returned by the os
    package. New code should use errors.Is(err, fs.ErrNotExist).

```

Você ainda vai encontrar `os.IsNotExist`, `os.IsExist` e `os.IsPermission` em código mais antigo.
Elas funcionam com um erro que veio direto do pacote `os` e falham em silêncio com o mesmo erro
depois de um `%w`, o tipo de bug que aparece no dia em que alguém acrescenta contexto a uma
mensagem. A variável também se escreve de dois jeitos, e os dois são uma coisa só: `os.ErrNotExist`
é `fs.ErrNotExist` com outro nome.

```
ana@vm:~/is-as-is$ go doc os.ErrNotExist | grep NotExist
	ErrNotExist   = fs.ErrNotExist   // "file does not exist"
```

## O que "casar" quer dizer

Olhe aquele comentário, `"file does not exist"`, e depois a cadeia da seção 02, cujo último elo
dizia `no such file or directory`. **A cadeia nunca conteve `fs.ErrNotExist`.** O último elo dela
era um `syscall.Errno`, e este programa o examina direto:

```go
func main() {
	_, err := os.ReadFile("settings.json")
	inner := errors.Unwrap(err)
	fmt.Println(inner == fs.ErrNotExist)
	fmt.Println(inner == syscall.ENOENT)
	fmt.Println(syscall.ENOENT.Is(fs.ErrNotExist))
}
```

```
ana@vm:~/is-as-errno$ go run .
false
true
true
```

O elo é `syscall.ENOENT`, o código do sistema para arquivo que falta, e ele não é igual a
`fs.ErrNotExist`. O que ele tem é um método `Is(error) bool`, e esse método diz sim quando
perguntado sobre `fs.ErrNotExist`. **`errors.Is` conta um elo como casado se ele for igual ao alvo
ou se o próprio método `Is` do elo disser que sim.** É assim que uma pergunta portável, "é um
arquivo que falta", recebe um sim da resposta numérica do sistema operacional lá embaixo. Os seus
próprios tipos de erro também podem ter um método `Is`, embora a maioria nunca precise.

## `%v` corta a cadeia

A cadeia da seção 02 existe porque todas as camadas usaram `%w`. Troque uma delas por `%v`, o verbo
que a lição 33 usou para acrescentar palavras sem embrulhar, e rode o mesmo laço e a mesma
pergunta:

```go
		return nil, fmt.Errorf("read config: %v", err)
```

```
ana@vm:~/is-as-cut$ go run .
start server: read config: open settings.json: no such file or directory
*fmt.wrapError       start server: read config: open settings.json: no such file or directory
*errors.errorString  read config: open settings.json: no such file or directory
false
```

A primeira linha é, palavra por palavra, o que a seção 02 imprimiu. Embaixo dela, a cadeia tem dois
elos: `readConfig` agora devolve um `*errors.errorString`, o tipo que `errors.New` cria, guardando
uma cópia do texto e mais nada. O `*fs.PathError` e o `syscall.Errno` sumiram, então `errors.Is`
responde `false`, e o programa acima não começaria mais com as configurações padrão. **Nada na
mensagem impressa diz que a cadeia foi cortada**; só o código que inspeciona o erro descobre, e
descobre tomando o desvio errado.
