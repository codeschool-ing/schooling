---
title: "CSV: uma tabela sem os tipos"
version: 1
---

**CSV é o formato que toda ferramenta abre e sobre o qual nem duas ferramentas concordam por
inteiro.** O nome diz valores separados por vírgula, e a imagem que vem junto é a de um arquivo que
se lê quebrando cada linha nas vírgulas. Essa imagem sobrevive até o primeiro campo com uma vírgula
dentro.

Existe uma especificação, a RFC 4180, escrita em 2005 para registrar o que os programas já faziam.
As regras são curtas. Um campo que contém vírgula, aspas duplas ou quebra de linha vai entre aspas
duplas, e uma aspa dupla dentro desse campo é escrita duas vezes. A maioria dos leitores segue essas
regras; muita exportação escrita à mão, não.

## Uma vírgula dentro do campo

Os mecânicos da Roda Livre escrevem uma observação em texto livre em algumas viagens. Aqui estão
três, uma com vírgula e outra com aspas. Salve isto como `formats/comma.py`:

```python
# formats/comma.py
import csv

NOTES = [
    ["ride_id", "station", "minutes", "note"],
    ["R000101", "Praça Tiradentes", 12, "brake loose, seat low"],
    ["R000102", "Rua XV", 7, 'rider said "fine"'],
    ["R000103", "Batel", 31, ""],
]
with open("notes.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f, lineterminator="\n").writerows(NOTES)

print("split on every comma:")
for line in open("notes.csv", encoding="utf-8"):
    print(" ", len(line.rstrip("\n").split(",")), "fields")

print("read with the csv module:")
rows = list(csv.reader(open("notes.csv", encoding="utf-8")))
for row in rows:
    print(" ", len(row), "fields")
print("minutes of R000101:", repr(rows[1][2]))
```

Ele grava o arquivo com o módulo `csv` do Python e depois o lê de volta duas vezes: uma quebrando nas
vírgulas, outra com o módulo. `lineterminator="\n"` termina cada linha do jeito do Linux; sem ele,
o módulo termina as linhas com um retorno de carro e uma quebra de linha, que é o que a RFC 4180
pede.

```
ana@lab:~/roda/formats$ python comma.py
split on every comma:
  4 fields
  5 fields
  4 fields
  4 fields
read with the csv module:
  4 fields
  4 fields
  4 fields
  4 fields
minutes of R000101: '12'
ana@lab:~/roda/formats$ cat notes.csv
ride_id,station,minutes,note
R000101,Praça Tiradentes,12,"brake loose, seat low"
R000102,Rua XV,7,"rider said ""fine"""
R000103,Batel,31,
```

Quebrar nas vírgulas encontra cinco campos na primeira viagem, porque `brake loose, seat low` vira
dois pedaços para quem conta vírgulas. O módulo `csv` encontra quatro em todas as linhas, porque lê
as aspas que o gravador pôs ali. Olhe o próprio arquivo e as regras ficam todas à vista: a
observação com vírgula está entre aspas, e as aspas em volta de `fine` foram dobradas.

## O que o arquivo não diz

**Um arquivo CSV carrega texto e mais nada, então todo tipo é um palpite de quem lê.** A última linha
da execução mostra isso: `minutes` foi gravado como o número 12 e voltou como o texto `'12'`. Se
`12` é número, se `2025-09-14` é data e se `007` mantém os zeros, quem decide é o código que lê o
arquivo, toda vez, e dois leitores podem decidir diferente. A observação vazia em `R000103` é outro
palpite: nada no arquivo diz se o mecânico não escreveu nada ou se a observação está faltando.

Mais duas coisas ficam de fora, e as duas causam falhas de verdade:

- **O delimitador.** Uma planilha configurada em português salva o seu "CSV" com ponto e vírgula,
  porque ali a vírgula é o separador decimal: `4,50` é quatro reais e cinquenta centavos. Um leitor
  que espera vírgulas recebe um campo só por linha.
- **A codificação.** Nada no arquivo diz como os caracteres viraram bytes. Leia o mesmo arquivo como
  Latin-1, uma codificação mais antiga ainda comum em exportações de sistemas Windows, e a primeira
  estação perde a cedilha:

```
ana@lab:~/roda/formats$ python -c "print(open('notes.csv', encoding='latin-1').read().splitlines()[1])"
R000101,PraÃ§a Tiradentes,12,"brake loose, seat low"
```

O `ç` foi gravado como dois bytes em UTF-8, e o Latin-1 lê cada byte como um caractere próprio.
Nenhum erro aparece. O nome simplesmente fica errado, em todas as linhas, dali em diante.

## Para que ele serve

Nada disso faz do CSV um formato ruim. Qualquer um o abre, com qualquer ferramenta, inclusive uma
pessoa com um editor de texto; é o único formato que um parceiro, uma planilha e um sistema de
quarenta anos aceitam ao mesmo tempo. É um formato de linhas, então acrescentar uma linha é barato.
O que ele precisa é de um acordo escrito ao lado: UTF-8, uma linha de cabeçalho, o delimitador, como
se escreve uma data e o que significa um campo vazio. A aula 7 confere um arquivo contra um acordo
assim quando ele chega.
