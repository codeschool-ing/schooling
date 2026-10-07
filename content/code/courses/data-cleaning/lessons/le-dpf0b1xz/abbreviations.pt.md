---
title: Abreviações, e o passo que precisa de uma lista
version: 1
---

**Depois de aparar, normalizar, reparar, pôr em minúsculas e tirar acentos, as cidades estão em onze
grafias, e nenhuma regra geral ajuda mais.** A cascata:

```
ana@lab:~/clean$ python cascade.py
as exported         28 distinct
spaces trimmed      25 distinct
Unicode to NFC      23 distinct
mojibake repaired   21 distinct
lower case          12 distinct
accents removed     11 distinct
['b. horizonte', 'belo horizonte', 'bh', 'campinas', 'curitiba', 'curitiba - pr', 'rio', 'rio de janeiro', 'rj', 's. paulo', 'sao paulo']
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l06-cascade\" aria-label=\"Um gráfico de barras de quantos valores distintos a coluna de cidade tem depois de cada passo da limpeza: como exportado 28, espaços aparados 25, Unicode em NFC 23, mojibake reparado 21, minúsculas 12, sem acentos 11, abreviações mapeadas 5. A maior queda isolada é a das minúsculas.\"><text x=\"190.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">como exportado</text><rect x=\"200.0\" y=\"30.0\" width=\"420.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">28</text><text x=\"190.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espaços aparados</text><rect x=\"200.0\" y=\"70.0\" width=\"375.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"581.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">25</text><text x=\"190.0\" y=\"122.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Unicode em NFC</text><rect x=\"200.0\" y=\"110.0\" width=\"345.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"551.0\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">23</text><text x=\"190.0\" y=\"162.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mojibake reparado</text><rect x=\"200.0\" y=\"150.0\" width=\"315.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"521.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">21</text><text x=\"190.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">minúsculas</text><rect x=\"200.0\" y=\"190.0\" width=\"180.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"190.0\" y=\"242.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sem acentos</text><rect x=\"200.0\" y=\"230.0\" width=\"165.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"371.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11</text><text x=\"190.0\" y=\"282.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">abreviações mapeadas</text><rect x=\"200.0\" y=\"270.0\" width=\"75.0\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"281.0\" y=\"282.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text></svg>", "caption": "Vinte e oito grafias, cinco cidades. Os passos são baratos e gerais; só o último precisa de uma lista que alguém escreveu."}
```

O que sobra é conhecimento, não mecânica. `bh` é Belo Horizonte porque no Brasil se diz assim; `rj` é
o estado do Rio de Janeiro usado como se fosse a cidade; `rio` é curto; `curitiba - pr` tem o estado
colado; `s. paulo` e `b. horizonte` foram abreviados à mão. **Nenhuma função sabe que `bh` quer dizer
Belo Horizonte.** Alguém precisa escrever:

```
ana@lab:~/clean$ cat abbreviations.csv
spelling,city
s. paulo,São Paulo
sao paulo,São Paulo
campinas,Campinas
rio de janeiro,Rio de Janeiro
rio,Rio de Janeiro
rj,Rio de Janeiro
belo horizonte,Belo Horizonte
b. horizonte,Belo Horizonte
bh,Belo Horizonte
curitiba,Curitiba
curitiba - pr,Curitiba
```

Um arquivo de onze linhas: toda grafia que chega a esta etapa, e a cidade que ela quer dizer. Aplicado
às chaves limpas:

```
ana@lab:~/clean$ python -c "import pandas as pd; from cascade import values; m = pd.read_csv('abbreviations.csv'); out = values.map(dict(zip(m['spelling'], m['city']))); print(out.value_counts(dropna=False).to_string())"
city
São Paulo         935
Rio de Janeiro    487
Belo Horizonte    337
Curitiba          318
Campinas          299
```

Cinco cidades, todo cliente contado: nenhuma grafia ficou fora da lista. **Essa última checagem é o
que torna um mapeamento confiável**: uma grafia que não está na lista deve sair como vazio, e contar
os vazios mostra se a lista está completa. Aqui não há nenhum. No mês que vem, um cliente vai digitar
`Sampa`, e a contagem vai dizer.

A lista também faz algo que os passos anteriores não conseguiam: dá a cada cidade **a sua forma
correta de exibição**, `São Paulo` com acento e maiúsculas, escrita uma vez por uma pessoa em vez de
reconstruída por uma regra. A aula 8 generaliza isso nas tabelas de mapeamento que padronizam
categorias, e a aula 14 liga cada cidade ao seu código oficial do IBGE, que é o que uma junção com
qualquer dado de fora precisa.
