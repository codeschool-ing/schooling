---
title: A cada push
version: 1
---

Testes que só rodam quando você lembra são testes que param de rodar. A saída é o site de hospedagem
rodá-los a cada push e a cada pull request, o que no GitHub é um arquivo de workflow:

```yaml
name: tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: python3 -m unittest -v
```

Salvo como `.github/workflows/tests.yml`, ele baixa o código, instala o Python 3.12 e roda o mesmo comando
de antes. **Ele não foi rodado neste curso**: o laboratório não tem GitHub, e o histórico do loanbook não o
inclui. É o arquivo que você acrescentaria na primeira semana, e o equivalente do GitLab, `.gitlab-ci.yml`,
tem os mesmos três passos.

Num portfólio ele se paga de três jeitos. **Todo commit ganha um sinal verde ou um X vermelho** ao lado, no
site, que é o *nenhum commit quebra o build* da aula 9 mostrado em vez de afirmado. **Um pull request não
pode ser mesclado por acidente no vermelho**, se você ligar essa proteção. E **quem avalia vê sem rodar
nada**: o sinal verde é evidência exatamente no sentido da aula 1.

Mantenha pequeno assim. Um workflow com dez jobs para um projeto com sete testes é o teatro da aula 8 em
outro arquivo.
