---
title: O `with`, e o arquivo que ninguém fechou
version: 1
---

```python
with open("linhas.csv", encoding="utf-8") as f:
    texto = f.read()
# fechado aqui, tenha acontecido o que tiver acontecido lá dentro
```

O `open` dá um objeto de arquivo. O `with` o devolve quando o bloco termina — no sucesso, num
`return`, e numa exceção. É o `try`/`finally` da aula 8, escrito por você já pronto.

## Os modos

| modo | quer dizer |
| --- | --- |
| `"r"` | ler texto — o padrão |
| `"w"` | gravar texto, ESVAZIANDO o arquivo antes |
| `"a"` | acrescentar ao fim |
| `"x"` | criar, e falhar se já existir |
| `"rb"` `"wb"` | o mesmo, em bytes |

**O `"w"` esvazia o arquivo no momento em que ele é aberto**, antes de um único byte ser gravado.
Um script que abre para gravar e então levanta erro apagou o dado que ele ia substituir — que é
por que o `"x"` existe, e por que gravar num temporário e renomear é a versão cuidadosa.

## Por que `with` em vez de `close`

```python
f = open(caminho)
processar(f)        # levanta erro
f.close()           # nunca roda
```

O arquivo fica aberto até o processo terminar — ou, num programa de longa duração, até acabarem os
descritores. No Windows um arquivo aberto não dá para renomear nem apagar, então a falha chega em
outro lugar completamente.

**Não existe caso em que o `with` seja a escolha errada para um arquivo.** Se você precisa do
descritor além de um bloco, você tem uma função que deveria recebê-lo por argumento.

## Vários de uma vez

```python
with open(orig, encoding="utf-8") as a, open(dest, "w", encoding="utf-8") as b:
    b.write(a.read())
```

Um `with`, dois arquivos, os dois fechados. A forma entre parênteses ocupando várias linhas também
existe, e qualquer uma das duas é melhor que aninhar.

## O que é um objeto de arquivo

Ele é um ITERADOR de linhas — que é a seção depois da próxima, e a razão de `for linha in f:` ser a
forma que escala.
