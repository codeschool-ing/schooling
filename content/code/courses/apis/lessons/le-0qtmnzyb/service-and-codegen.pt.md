---
title: O serviço, e o código gerado a partir dele
version: 1
---

**O bloco `service` lista os procedimentos, e um compilador o transforma em código para os dois
lados.** Cada linha `rpc` nomeia um método, a mensagem que ele recebe e a que devolve, com `stream`
na frente de qualquer uma delas quando aquele lado envia mais de uma. Dessas quatro linhas do
`stock.proto` o compilador escreve um **stub** para o cliente, um objeto cujos métodos fazem as
chamadas, e um **servicer** para o servidor, uma classe cujos métodos você preenche.

A imagem errada aqui é a da aula 1: a de que um cliente monta uma requisição, escolhe um caminho e um
método, põe um cabeçalho e interpreta o que volta. No gRPC ninguém escreve nada disso. O cliente
chama `stock.GetStock(request)` e recebe um `StockLevel`, e o caminho, os cabeçalhos e os bytes são
assunto do código gerado. **Os dois lados são gerados de um arquivo só, então não têm como discordar
sobre o número de um campo ou o nome de um método**, a não ser que um deles tenha sido gerado de
outro arquivo.

## Gerando o Python

O `python3-grpc-tools`, da linha de `apt-get` da aula 1, traz uma cópia do `protoc` com o plugin de
gRPC para Python embutido. Em `~/shelf`:

```
ana@api:~/shelf$ python3 -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. stock.proto
/usr/lib/python3/dist-packages/grpc_tools/protoc.py:17: DeprecationWarning: pkg_resources is deprecated as an API. See https://setuptools.pypa.io/en/latest/pkg_resources.html
  import pkg_resources
```

**As duas linhas que ele imprimiu são um aviso sobre o empacotamento da própria ferramenta**, não
sobre o seu arquivo: o `grpc_tools` importa um módulo que o setuptools do Python marcou como de
saída. O comando fez o trabalho dele, e escreveu dois arquivos:

```
ana@api:~/shelf$ ls stock*
stock.proto
stock_client.py
stock_pb2.py
stock_pb2_grpc.py
stock_server.py
ana@api:~/shelf$ wc -l stock_pb2.py stock_pb2_grpc.py
  416 stock_pb2.py
   97 stock_pb2_grpc.py
  513 total
```

O `-I .` diz onde procurar os arquivos `.proto` que este importa; ele não importa nenhum, então o
diretório atual basta. O `--python_out` pede as mensagens, em `stock_pb2.py`, e o `--grpc_python_out`
pede o serviço, em `stock_pb2_grpc.py`. São 513 linhas geradas a partir das 56 do `stock.proto`, e
**você nunca as edita**: quando o `stock.proto` muda, você roda o mesmo comando de novo e elas são
sobrescritas. O arquivo do serviço guarda as três coisas que a próxima seção usa:

```
ana@api:~/shelf$ grep -n '^class\|^def ' stock_pb2_grpc.py
7:class StockStub(object):
39:class StockServicer(object):
72:def add_StockServicer_to_server(servicer, server):
```

| gerado | usado por | o que faz |
|---|---|---|
| `StockStub` | o cliente | um método por `rpc`; chamar um envia a chamada |
| `StockServicer` | o servidor | uma classe para herdar, com um método por `rpc` para preencher |
| `add_StockServicer_to_server` | o servidor | liga a sua classe a um servidor rodando |

## Todas as linguagens a partir de um arquivo

O mesmo `stock.proto` produz as mesmas três coisas nas outras linguagens da trilha de back-end: o
`protoc` tem plugins para Go e Java, e o Node.js lê um `.proto` por um gerador ou direto na
inicialização. Um servidor em Go e um cliente em Java escritos por duas equipes que nunca se viram
concordam em cada byte, porque os dois foram gerados do arquivo que compartilham. **O `.proto` é o
que uma equipe publica**, do jeito que uma equipe REST publica a documentação na aula 6, só que aqui
o compilador confere.

Se os arquivos gerados ficam no repositório ou são produzidos pelo build é escolha de cada equipe, e
as duas coisas são comuns. O que importa é que ninguém os edite à mão, porque a próxima geração apaga
a edição sem dizer nada.
