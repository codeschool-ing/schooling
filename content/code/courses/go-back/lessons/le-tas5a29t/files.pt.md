---
title: Arquivos de configuração, e quando você precisa de um
version: 1
---

Flags e variáveis são planas: um nome e uma string. As sete configurações do boxoffice cabem nisso com
folga. Um arquivo de configuração se justifica quando as configurações deixam de ser planas: uma lista de
sites autorizados, um timeout por rota, um bloco de configurações por cliente. Escrever isso como
`BOXOFFICE_ROUTE_3_TIMEOUT` é onde as variáveis deixam de ajudar.

Quando esse dia chegar, a biblioteca padrão já lê um formato: **o `encoding/json` decodifica um arquivo na
mesma struct `config`** que a seção 07 preenche a partir das flags, com o `DisallowUnknownFields` da aula 3
recusando uma chave escrita errado em vez de ignorá-la. YAML e TOML são mais confortáveis de ler à mão e
aceitam comentários, e cada um precisa de uma biblioteca.

## A biblioteca que faz tudo

**Viper** é a biblioteca de configuração mais conhecida do Go: lê JSON, YAML, TOML e outros formatos,
mistura tudo com variáveis e flags, e consegue vigiar um arquivo por mudanças. É uma dependência grande para
um trabalho pequeno, e o custo dá para medir. Aqui está um programa vazio que só a importa, comparado com o
`knobs`:

```
ana@vm:~/vipertry$ go mod init example.com/vipertry 2>/dev/null; go get github.com/spf13/viper@v1.21.0 2>&1 | grep -c "^go: added"
13
ana@vm:~/vipertry$ go list -m all | wc -l; go build -o vipertry . && ls -l vipertry ~/knobs/knobs
27
-rwxr-xr-x 1 ana ana 2501577 Oct 22 19:43 /home/ana/knobs/knobs
-rwxr-xr-x 1 ana ana 6312912 Oct 22 19:43 vipertry
```

Acrescentar o Viper acrescentou 13 módulos ao projeto, e o grafo de módulos dele tem 27. O programa que não
faz nada com ele tem 6,3 MB, contra 2,5 MB do `knobs`, que analisa flags e lê uma variável. Cada um desses
módulos é código que você entrega, atualiza e em que confia. **Para uma ferramenta de linha de comando com
dezenas de configurações em vários formatos, pode ser um preço justo; para um servidor com sete
configurações, `flag` e `os.Getenv` fazem o mesmo trabalho em sessenta linhas que você consegue ler.**

## Arquivos `.env`

Um arquivo `.env` é uma lista de linhas `NOME=valor` guardada ao lado do código, uma conveniência de
desenvolvimento para ninguém digitar as mesmas variáveis em todo terminal. Dois hábitos o mantêm inofensivo.
**Ele nunca vai para um commit**, porque mais cedo ou mais tarde guarda um segredo: vai no `.gitignore`, e
um `.env.example` com os nomes e sem os valores é commitado no lugar dele. **E o programa não o lê.** O
shell o carrega no ambiente, e o programa lê o ambiente como sempre:

```sh
set -a; . ./.env; set +a
./boxoffice
```

`set -a` exporta toda variável que o arquivo define, e `set +a` desliga isso de novo. Existem bibliotecas
que carregam o `.env` de dentro do programa, e elas criam um segundo caminho para a configuração chegar que
só funciona nas máquinas de quem desenvolve. Produção não tem `.env`; plataformas de containers e o systemd
recebem variáveis, ou um arquivo delas, do jeito deles, que a aula 16 usa.
