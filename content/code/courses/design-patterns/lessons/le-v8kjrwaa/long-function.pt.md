---
title: "Função longa: extraia até cada pedaço dizer uma coisa"
version: 1
---

**Uma função longa raramente é um problema de tamanho.** Quarenta linhas que fazem uma coisa em
ordem estão bem. O problema é uma função que faz vários trabalhos, de modo que entender qualquer um
deles exige ler todos, e mudar um põe os outros em risco. `report` faz pelo menos quatro: calcula
uma data de vencimento, conta dias de atraso, escolhe um rótulo para o tipo de item e formata uma
linha de texto. Cada um é uma pergunta que alguém vai fazer sozinha: *quando vence este filme?* não
tem nada a ver com a pontuação de uma linha.

O movimento é **extrair função** (*extract function*): pegue um trecho que faz um trabalho, dê a ele
um nome que diga qual é o trabalho, e chame-o de onde o trecho estava. O critério de Fowler para
extrair não é tamanho, é intenção. Se você precisa ler um bloco para saber para que ele serve, ele
deveria ser uma função cujo nome diga isso.

## Três extrações

Cada uma das três abaixo foi um movimento separado, e os testes rodaram depois de cada uma. O
arquivo mostrado é o de depois da terceira:

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]", "note": "Os dados não mudam. A refatoração muda o código que os lê, e quem chama continua passando as mesmas tuplas."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on", "note": "A primeira cadeia de `if`, tirada inteira. Ela recebe os dois valores que lê em vez da linha toda, então a assinatura diz do que ela depende."},
 {"code": "\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"", "note": "A segunda cadeia. A variável local se chamava `what`; o nome da função diz o que `what` era."},
 {"code": "\n\ndef days_late(row, today):\n    end = row[6] or today\n    return (end - due_date(row[4], row[5])).days", "note": "Quatro linhas de `if l[6]: ... else: ...` viraram `row[6] or today`. Isso é seguro aqui porque uma data nunca é falsa; para um valor que pudesse ser zero ou vazio, mudaria o comportamento."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = 0\n    for l in loans:\n        d = days_late(l, today)\n        if d > 0:\n            f = d * 50\n            total = total + f\n            out.append(l[0] + \" <\" + l[2] + \">: \" + label(l[4]) + \" '\" + l[3] + \"', \" + str(d) + \" days late, R$ \"\n                       + str(f // 100) + \",\" + str(f % 100).zfill(2))\n    out.append(\"total: R$ \" + str(total // 100) + \",\" + str(total % 100).zfill(2))\n    return \"\\n\".join(out)", "note": "O que sobrou se lê como o trabalho do próprio relatório: para cada empréstimo atrasado, acrescente uma linha e uma multa. A montagem das strings continua feia; isso é a próxima seção."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

O comando abaixo é o mesmo teste rodado sem `-v`, um ponto por teste. Daqui em diante a lição usa
vários jeitos equivalentes de rodar os mesmos dois testes; todos rodam `test_report.py`.

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest test_report.py
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## Dar nome é a refatoração

A extração em si é mecânica, e a maioria dos editores a faz com um comando. A decisão que importa é
o nome. **Um bom nome dispensa ler o corpo**: quem lê `report` agora vê `days_late(l, today)` e
segue em frente, e esse é o ganho inteiro. Um nome como `helper1` ou `process_part` mantém a
estrutura e perde o benefício.

Dois sinais de que um bloco quer ser uma função com nome:

- um comentário em cima explicando o que ele faz. `# work out when it is due` é o nome `due_date`,
  escrito no lugar errado;
- uma linha em branco separando-o dos vizinhos, que é o autor admitindo que é um passo à parte.

## Toda linguagem tem este movimento

| linguagem | no que um auxiliar extraído costuma virar |
|---|---|
| Python | uma função de módulo; com sublinhado na frente se for privada do módulo |
| Java | um método `private`, ou `private static` se não usa campos |
| Go | uma função não exportada, em minúscula, no mesmo pacote |
| TypeScript | uma função do módulo que não é exportada |

As IDEs das quatro extraem uma função e descobrem os parâmetros. O que nenhuma consegue é dizer se o
resultado tem um só trabalho e um nome honesto; essa parte é sua.

`days_late` ainda acessa `row[6]` e `row[4]` pela posição, e nada diz a quem lê o que é a posição 4.
Esse cheiro também tem nome, e a seção sobre obsessão por primitivos trata dele.
