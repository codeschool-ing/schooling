---
title: JUnit XML, o formato em que os resultados viajam
version: 1
---

O nome engana duas vezes. JUnit é um framework de teste unitário para Java, então JUnit XML parece
algo que só programadores Java produzem, e só para testes unitários. **JUnit XML é o mais perto que
o teste tem de uma língua comum para resultados: quase todo executor de testes consegue escrevê-lo,
e quase todo servidor de integração contínua e ferramenta de relatório consegue lê-lo.** Ele
começou como o arquivo que as execuções do JUnit deixavam nos builds Java, outras ferramentas o
copiaram para se ligar aos mesmos leitores, e ele se espalhou daí. Ninguém nunca o publicou como
padrão, então as ferramentas divergem nas bordas; o núcleo abaixo é o que elas têm em comum.

## A forma do arquivo

Um arquivo guarda uma **testsuite**, ou várias dentro de um elemento **testsuites**. A suíte diz
quantos casos tem e quantos deles não passaram. Cada **testcase** nomeia um caso, e o que fica
dentro dele é o resultado:

| dentro do testcase | o resultado |
|---|---|
| nada | passou |
| `failure` | rodou e a verificação não se confirmou; a mensagem diz o que se viu |
| `error` | não conseguiu rodar até o fim, porque algo inesperado quebrou |
| `skipped` | não foi executado |

Um caso também traz um `classname`, que agrupa os casos como uma suíte faz numa ferramenta de
casos, e a maioria dos executores acrescenta um `time` em segundos a cada caso e suíte.

## A sua execução manual, como JUnit XML

Nada no formato exige um teste automatizado. A coluna 1.1 do `cases.csv` que você salvou na aula 18
é uma execução com um resultado por caso, que é tudo o que o formato guarda. O programa abaixo lê
uma coluna de execução e a escreve como JUnit XML. Crie um arquivo novo no seu diretório
`boxoffice`, cole o programa nele e salve. Salve como `to_junit.py`, exatamente esse nome:

```python
"""to_junit.py: one run of the case spreadsheet, written as a JUnit XML file.

    python3 to_junit.py cases.csv 1.1 > results-1.1.xml
"""
import csv
import sys
import xml.etree.ElementTree as ET

path, run = sys.argv[1], sys.argv[2]
with open(path, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

suite = ET.Element("testsuite", name=f"boxoffice {run}")
failures = skipped = 0
for row in rows:
    case = ET.SubElement(suite, "testcase", classname=row["requirement"],
                         name=f"{row['id']} {row['title']}")
    result = row[run]
    if result.startswith("failed"):
        failures += 1
        ET.SubElement(case, "failure", message=result.removeprefix("failed: "))
    elif result != "passed":
        skipped += 1
        ET.SubElement(case, "skipped", message="not run")
suite.set("tests", str(len(rows)))
suite.set("failures", str(failures))
suite.set("skipped", str(skipped))

ET.indent(suite)
print('<?xml version="1.0" encoding="UTF-8"?>')
print(ET.tostring(suite, encoding="unicode"))
```

Ele usa só a biblioteca padrão do Python, como o boxoffice. Rode-o no diretório `boxoffice`, com a
execução que você quer como segunda palavra, e mande o que ele imprime para um arquivo:

```
ana@laptop:~/boxoffice$ python3 to_junit.py cases.csv 1.1 > results-1.1.xml
ana@laptop:~/boxoffice$ cat results-1.1.xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="boxoffice 1.1" tests="17" failures="7" skipped="0">
  <testcase classname="R1" name="TC-01 Shows are listed" />
  <testcase classname="R2" name="TC-02 Sign up" />
  <testcase classname="R2" name="TC-03 E-mail already used" />
  <testcase classname="R4" name="TC-04 Book one ticket" />
  <testcase classname="R4" name="TC-05 Book six tickets" />
  <testcase classname="R4" name="TC-06 Seven tickets refused" />
  <testcase classname="R4" name="TC-07 Seats go down" />
  <testcase classname="R5" name="TC-08 Member discount" />
  <testcase classname="R5" name="TC-09 Largest discount only" />
  <testcase classname="R5" name="TC-10 Student pays half">
    <failure message="10% off, R$ 144,00" />
  </testcase>
  <testcase classname="R7" name="TC-11 Quantity in words">
    <failure message="error 500, a traceback" />
  </testcase>
  <testcase classname="R6" name="TC-12 Pay an order" />
  <testcase classname="R6" name="TC-13 No refund after use">
    <failure message="refunded" />
  </testcase>
  <testcase classname="R6" name="TC-14 Message for a refused move">
    <failure message="says cannot be useed" />
  </testcase>
  <testcase classname="R6" name="TC-15 No refund once started">
    <failure message="refunded" />
  </testcase>
  <testcase classname="R8" name="TC-16 Shows on a phone">
    <failure message="scrolls sideways" />
  </testcase>
  <testcase classname="R9" name="TC-17 Every field labelled">
    <failure message="Tickets has no label" />
  </testcase>
</testsuite>
```

O `>` funciona do mesmo jeito num terminal no Linux, no Mac e no Windows; no Windows sem WSL, abra
o `results-1.1.xml` no seu editor ou no navegador em vez de usar o `cat`.

## Lendo o arquivo

A primeira linha de dentro resume a execução inteira: **17 testes, 7 falhas, 0 pulados.** Cada caso
que passou é uma linha só, sem nada dentro, e é por isso que um arquivo de milhares de casos
aprovados continua fácil de varrer atrás dos poucos que não passaram. Cada falha traz a mensagem da célula da
planilha, o que se viu no lugar do resultado esperado. E o requisito foi para o `classname`, então
um leitor que agrupa por classe, como a maioria faz, mostra os resultados por requisito: quatro do
R6, três do R5, um do R9.

A coluna da 1.0 passa pelo mesmo programa:

```
ana@laptop:~/boxoffice$ python3 to_junit.py cases.csv 1.0 > results-1.0.xml
ana@laptop:~/boxoffice$ head -n 2 results-1.0.xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="boxoffice 1.0" tests="17" failures="5" skipped="3">
```

Três casos não rodaram na 1.0, porque ainda não existiam, e saíram como `skipped`. Essa é uma
**decisão que este programa tomou**, e vale vê-la como tal. Uma ferramenta de casos tem pelo menos
quatro resultados, e o formato tem quatro desfechos que não se alinham com eles: bloqueado não tem
elemento próprio, e vira `skipped` no conversor de um time e `error` no de outro. Quem converte
resultados manuais escreve o mapeamento, ou dois relatórios da mesma execução discordam sobre
quantos casos foram testados.

## Quem lê

Ninguém lê este arquivo por prazer. Ele é a passagem de bastão entre o que rodou os testes e o que
os mostra, que, para suítes automatizadas, costuma ser a página de resultados de um servidor de
integração contínua ou uma ferramenta de relatório como a da seção 03 desta aula. O valor dele é
ser chato e compartilhado: uma execução registrada assim pode ser lida por ferramentas que não
sabem nada do boxoffice, do Python ou da planilha de onde ela veio.
