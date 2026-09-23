---
title: `requirements.txt`, e por que o `pip freeze` não escreve um
version: 2
---

```sh
# requirements.txt
requests==2.31.0
```

```sh
python -m pip install -r requirements.txt
```

Um arquivo de texto nomeando do que o projeto precisa, um por linha, com os mesmos
especificadores da linha de comando. Comentários começam com `#`, e `-r outro.txt` inclui outro
arquivo.

## O que o `pip freeze` dá no lugar

```sh
$ python -m pip freeze
certifi==2026.7.22
charset-normalizer==3.5.1
idna==3.20
requests==2.31.0
urllib3==2.8.0
```

**Cinco linhas, e o projeto pediu uma delas.** O `freeze` imprime o que está instalado, fixado
exatamente, em ordem alfabética, sem distinção entre o que você escolheu e o que veio junto.

Essa saída é útil e não é um arquivo de requisitos, por três razões:

- **Nada diz quais pacotes são seus.** Daqui a um ano, ninguém consegue dizer se o `idna` é
  dependência do projeto ou sobra de algo desinstalado.
- **Remover um pacote deixa as dependências dele para trás**, e o `freeze` segue imprimindo-as,
  então o arquivo cresce e nunca encolhe.
- **Ele fixa coisas sobre as quais você não tem opinião.** Uma correção de segurança no `urllib3`
  passa a precisar de uma edição no seu arquivo de requisitos.

## `freeze > requirements.txt` é como isso dá errado

É a primeira coisa que todo mundo faz, funciona, e o que ela produz é um arquivo que ninguém lê
seis meses depois. A lista cresce toda vez que alguém acrescenta uma biblioteca, nunca encolhe, e
no dia em que uma fixação transitiva trava uma atualização, descobrir qual linha pode ser apagada
leva uma tarde.

## Escreva à mão

```sh
# requirements.txt — what this project asks for
requests==2.31.0        # HTTP; pinned, 2.32 changed the retry behaviour
pandas~=2.2.0           # tables; patch releases are fine
```

Uma linha por dependência direta, com a versão contra a qual você de fato testou, e um comentário
onde a fixação não é óbvia. É um arquivo curto, ele continua curto, e ele diz alguma coisa.

## Dois arquivos, quando há ferramentas de desenvolvimento

```sh
# requirements.txt
requests==2.31.0

# requirements-dev.txt
-r requirements.txt
pytest==9.0.2
ruff==0.15.8
```

O `pytest` não é algo de que a aplicação precisa para rodar, e instalá-lo em produção manda um
framework de testes para um servidor. O `-r` na primeira linha faz do arquivo de desenvolvimento o
conjunto inteiro.
