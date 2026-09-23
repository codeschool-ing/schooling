---
title: O `raise`, e a mensagem que alguém vai ler
version: 2
---

```python
if port < 1 or port > 65535:
    raise ValueError(f"port out of range: {port}")
```

O `raise` cria a falha e a entrega para cima. Duas coisas são sua escolha: a classe e a mensagem.

## Escolher a classe

| quando | classe |
| --- | --- |
| o valor está errado | `ValueError` |
| o tipo está errado | `TypeError` |
| falta uma chave | `KeyError` |
| o arquivo não está lá | `FileNotFoundError` |
| você ainda não escreveu | `NotImplementedError` |
| nada acima serve, e quem chama talvez queira capturar a SUA falha | uma classe sua |

**Não levante `Exception("deu algo errado")`.** Quem chama só consegue capturar isso capturando
tudo, que é a situação que esta aula inteira tenta evitar.

## A mensagem

Ela é lida por uma pessoa, às três da manhã, num log. Então ela nomeia o valor:

```python
raise ValueError("invalid config")                       # useless
raise ValueError(f"{path}: port must be a number, not {raw!r}")   # actionable
```

**Qual arquivo, qual campo, o que estava lá, e o que era esperado.** O `!r` mantém as aspas, então
uma string vazia e uma string de espaços dão para distinguir — que é exatamente o caso que você vai
estar encarando.

## `raise … from e`

```python
try:
    port = int(raw)
except ValueError as e:
    raise ConfigError(f"{path}: bad port {raw!r}") from e
```

É assim que se traduz uma falha de baixo nível numa que significa algo para quem chamou, sem perder
o que de fato aconteceu. O traceback então imprime as duas, com **"The above exception was the
direct cause of the following exception"** entre elas.

Sem o `from`, o Python ainda as encadeia — como "During handling of the above exception, another
exception occurred", que se lê como um acidente. O `from e` diz que foi deliberado, e o `from None`
esconde a original inteira, o que de vez em quando está certo e em geral é uma perda.

## `raise` sem nada

```python
except OSError:
    log.warning("retrying")
    raise                     # the same exception, same traceback
```

Um `raise` pelado dentro de um tratamento relevanta o que você capturou. É assim que se faz algo de
passagem sem engolir a falha — e ele mantém o traceback original, que um `raise e` truncaria.
