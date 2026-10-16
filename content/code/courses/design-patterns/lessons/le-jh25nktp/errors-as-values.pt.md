---
title: "Erros como valores: um Result em vez de uma exceção"
version: 1
---

**Uma exceção é um efeito colateral de um tipo fácil de esquecer: uma função que lança tem um segundo
jeito de retornar, e nada na assinatura diz isso.** `date.fromisoformat(text)` devolve um `date`,
diz o tipo dela, e às vezes também salta para fora de quem chamou e sobe a pilha. Muitas vezes isso
é exatamente o certo. Encaixa mal quando a falha é um resultado esperado, como uma linha de arquivo
que alguém digitou errado, porque aí quem chama precisa lembrar de um `try` que o tipo nunca pediu.

A resposta funcional é devolver a falha como valor. O resultado de uma função é *ok, com um valor* ou
*um erro, com um motivo*, e quem chama precisa olhar qual recebeu antes de usar. Rust chama o tipo
de `Result`, Haskell de `Either`, e Go devolve `value, err` em quase toda função que pode falhar.

## Carregando empréstimos de texto

A biblioteca importa empréstimos de linhas de texto, título, data e tipo separados por ponto e
vírgula. Algumas linhas estão erradas de jeitos diferentes, e a importação deve relatar toda linha
ruim em vez de parar na primeira:

```schooling-example
{"language": "python", "file": "result.py", "parts": [
 {"code": "# result.py\nfrom dataclasses import dataclass\nfrom datetime import date\n\nLOAN_DAYS = {\"book\": 14, \"film\": 7}", "note": "A duração do empréstimo por tipo, como tabela: o ponto da lição 14 sobre dados que diferem só em valores."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Ok:\n    value: tuple[str, date, int]\n\n\n@dataclass(frozen=True)\nclass Err:\n    error: str", "note": "O tipo Result inteiro: duas classes pequenas e congeladas. O Python não tem um embutido, e isto é tudo o que ele precisa ser."},
 {"code": "\n\ndef parse_loan(line: str) -> Ok | Err:\n    fields = line.split(\";\")\n    if len(fields) != 3:\n        return Err(f\"expected 3 fields, got {len(fields)}: {line!r}\")\n    title, lent, kind = fields\n    try:\n        lent_on = date.fromisoformat(lent)\n    except ValueError as err:\n        return Err(f\"{lent!r} is not a date: {err}\")\n    if kind not in LOAN_DAYS:\n        return Err(f\"unknown kind {kind!r} for {title!r}\")\n    return Ok((title, lent_on, LOAN_DAYS[kind]))", "note": "A assinatura diz os dois resultados: `Ok | Err`. A única exceção que a biblioteca padrão lança é capturada onde acontece e transformada em valor."},
 {"code": "\n\nLINES = [\"Dom Casmurro;2026-03-02;book\",\n         \"Central do Brasil;2026-03-09;film\",\n         \"Iracema;2026-02-30;book\",\n         \"Vidas Secas;2026-03-10;magazine\",\n         \"Cidade de Deus 2026-03-01 film\"]", "note": "Duas linhas boas e três ruins, cada ruim de um jeito: 30 de fevereiro, um tipo que a biblioteca não empresta, e espaços onde deviam estar os pontos e vírgulas."},
 {"code": "\n\nif __name__ == \"__main__\":\n    results = [parse_loan(line) for line in LINES]\n    for result in results:\n        match result:\n            case Ok((title, lent_on, days)):\n                print(f\"ok     {title}: {days} days from {lent_on}\")\n            case Err(message):\n                print(f\"error  {message}\")\n    loaded = [r.value for r in results if isinstance(r, Ok)]\n    print(f\"{len(loaded)} of {len(results)} lines loaded\")", "note": "`match` (Python 3.10 em diante) desmonta o resultado pela forma. Toda linha é analisada, os erros são dados para imprimir, e nada interrompe o laço."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 result.py
ok     Dom Casmurro: 14 days from 2026-03-02
ok     Central do Brasil: 7 days from 2026-03-09
error  '2026-02-30' is not a date: day is out of range for month
error  unknown kind 'magazine' for 'Vidas Secas'
error  expected 3 fields, got 1: 'Cidade de Deus 2026-03-01 film'
2 of 5 lines loaded
```

Toda linha recebeu uma resposta. Uma versão de `parse_loan` que lançasse exceção numa linha ruim
pararia a importação em *Iracema*, a menos que cada chamada fosse embrulhada num `try` próprio, e o
relatório de que três linhas em cinco estavam erradas nunca seria impresso.

## O que o verificador de tipos acrescenta

Em tempo de execução, `Ok | Err` é uma promessa num comentário. Com um verificador de tipos como o
mypy, vira uma conferência: `parse_loan(line).value` é recusado, porque um `Err` não tem `value`,
até o código estreitar o resultado com `isinstance` ou `match`. **O caso de falha vira algo que o
código precisa tratar antes de passar na verificação, não algo que um revisor precisa lembrar de
perguntar.** O Go tem uma versão mais fraca disso por convenção e linters: um `err` não usado é
apontado, embora nada impeça um `if err != nil` de ser escrito errado.

## Quando lançar mesmo assim

O Python é construído em torno de exceções, e brigar com isso em todo lugar piora o código. Uma
divisão razoável:

| situação | em Python |
|---|---|
| entrada que vem errada com frequência e precisa ser relatada em lote: importações, validação de formulário | devolver um valor de resultado |
| uma falha com a qual quem chama pode fazer algo sensato, caso a caso | qualquer um; um resultado a torna visível |
| um bug ou um estado impossível: número negativo de dias, configuração faltando | lançar, e deixar quebrar com barulho |
| uma falha no fundo da E/S que só o nível mais alto sabe tratar: uma conexão perdida | lançar; devolvê-la por dez camadas é ruído |

O teste é se quem chama deve tratar a falha como parte do trabalho comum. Se sim, ponha no tipo de
retorno, onde quem chama não tem como deixar passar. Se não, uma exceção a leva até quem consegue
lidar com ela, que é para isso que exceções existem.
