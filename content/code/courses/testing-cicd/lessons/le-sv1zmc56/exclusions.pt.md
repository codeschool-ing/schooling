---
title: O que deixar fora da conta
version: 1
---

Algum código não vale testar na suíte, e contá-lo como faltando só acrescenta ruído à lista que
alguém precisa conferir. As ferramentas de cobertura deixam excluí-lo. Usada com parcimônia, a
exclusão mantém o relatório honesto; usada de forma larga, é o jogo do limite da seção 06 jogado com
configuração.

`app.py` está em 76%, e parte do que falta é o ponto de entrada do programa:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q > /dev/null; coverage report -m --include=shipquote/app.py
Name               Stmts   Miss Branch BrPart  Cover   Missing
--------------------------------------------------------------
shipquote/app.py      54     12      8      3    76%   20-21, 23, 31, 36-38, 60-63, 67
--------------------------------------------------------------
TOTAL                 54     12      8      3    76%
ana@laptop:~/shipquote$ sed -n 58,67p shipquote/app.py

def main():
    port = int(os.environ.get("SHIPQUOTE_PORT", "8080"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"shipquote {VERSION} listening on 127.0.0.1:{port}", file=sys.stderr)
    server.serve_forever()


if __name__ == "__main__":
    main()
ana@laptop:~/shipquote$ git diff pyproject.toml | tail -4
 
 [tool.coverage.report]
 show_missing = true
+exclude_also = ["if __name__ == .__main__.:"]
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/app.py
Name               Stmts   Miss Branch BrPart  Cover   Missing
--------------------------------------------------------------
shipquote/app.py      52     11      6      2    78%   20-21, 23, 31, 36-38, 60-63
--------------------------------------------------------------
TOTAL                 52     11      6      2    78%
```

As linhas 60 a 63 são `main()`, que lê a porta e sobe um servidor para sempre, e a linha 67 é a
guarda `if __name__ == "__main__":` que a chama quando o arquivo roda como programa. Os testes sobem o
servidor do jeito deles, numa thread, então essas linhas nunca rodam na suíte.

O projeto acrescenta uma linha de configuração, `exclude_also`, uma lista de padrões cujas linhas e
blocos correspondentes saem da conta. O padrão aqui casa com a guarda, então a linha 67 some do
relatório e o arquivo vai para 78%. **`main()` continua contada**, e essa é uma decisão que vale
explicar.

## O que merece exclusão

| excluir | não excluir |
|---|---|
| a guarda `if __name__ == "__main__":` | a função que ela chama |
| código só para verificadores de tipo, sob `if TYPE_CHECKING:` | tratamento de erro que você ainda não testou |
| um `assert False` marcando um ramo que não pode acontecer | um ramo que você acredita que não acontece |
| auxiliares de depuração que nunca rodam em produção | um módulo inteiro "porque é difícil de testar" |

`main()` lê `SHIPQUOTE_PORT` do ambiente e monta o servidor, e as duas coisas podem estar erradas:
um erro de digitação no nome da variável, um servidor ligado no endereço errado. Vale conferir, e a
verificação que vai cobri-las é o smoke test da aula 7, que sobe o programa implantado e pergunta
`/health`. Excluir `main()` a esconderia do único relatório que mostra que ela ainda não é conferida
em lugar nenhum.

O marcador `# pragma: no cover` numa linha exclui essa linha, ou o bloco que ela abre, do mesmo
jeito. **Toda exclusão deveria dizer por quê**, num comentário ao lado, porque quem lê o relatório não
vê o que não está mais nele.
