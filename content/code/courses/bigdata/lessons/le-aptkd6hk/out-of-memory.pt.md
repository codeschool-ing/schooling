---
title: Um programa que fica sem memória
version: 1
---

**A pergunta é simples: quantos visitantes diferentes olharam cada livro em 2025?** O time de
marketing quer os três primeiros. A primeira resposta da Ana é o programa que qualquer pessoa
escreveria, e é um bom programa. Salve-o como `~/big/visitors.py`:

```schooling-example
{
  "language": "python",
  "file": "visitors.py",
  "parts": [
    {
      "code": "\"\"\"How many different visitors looked at each book in 2025? The top three.\"\"\"\nimport csv\nimport glob\nimport gzip\nimport resource\n\n"
    },
    {
      "code": "seen = {}\nfor path in sorted(glob.glob(\"data/raw/clicks/day=*/*.csv.gz\")):\n    with gzip.open(path, \"rt\") as f:\n        for row in csv.DictReader(f):\n            if row[\"book_id\"]:\n                seen.setdefault(row[\"book_id\"], set()).add(row[\"visitor_id\"])\n\n",
      "note": "**O método inteiro é este dicionário**: para cada livro, o conjunto de visitantes que olharam para ele. Um conjunto guarda cada visitante uma vez só, que é o que *diferentes* quer dizer."
    },
    {
      "code": "top = sorted(seen.items(), key=lambda kv: len(kv[1]), reverse=True)[:3]\nfor book, visitors in top:\n    print(f\"book {book}: {len(visitors):,} visitors\")\n",
      "note": "Só depois de ler todos os arquivos os conjuntos podem ser contados. Até lá, tudo fica na memória."
    },
    {
      "code": "peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss\nprint(f\"peak memory: {peak / 1024:,.0f} MB\")\n",
      "note": "O `ru_maxrss` é o máximo de memória que o processo ocupou em algum momento, em kilobytes no Linux."
    }
  ]
}
```

Na máquina do laboratório ele funciona:

```
ana@lab:~/big$ time python3 visitors.py
book 1: 936,076 visitors
book 2: 335,986 visitors
book 3: 244,287 visitors
peak memory: 2,338 MB

real	1m8.529s
user	1m6.386s
sys	0m1.485s
```

**Pouco mais de um minuto, e 2,3 GB de memória no pico.** Os dados têm 243 MB compactados e o
programa precisou de dez vezes isso, porque uma string Python e uma entrada de conjunto custam
dezenas de bytes cada, e há milhões delas. Essa proporção é normal, e é a primeira coisa a medir
antes de decidir que uma máquina é grande o bastante.

Agora dê ao programa uma máquina com 1 GB sobrando. O `ulimit -v` limita quanta memória um processo
pode pedir, e dentro dos parênteses o limite vale para aquele comando e não para o seu shell:

```
ana@lab:~/big$ (ulimit -v 1000000; time python3 visitors.py)
Traceback (most recent call last):
  File "/home/ana/big/visitors.py", line 12, in <module>
    seen.setdefault(row["book_id"], set()).add(row["visitor_id"])
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^
MemoryError

real	0m26.030s
user	0m25.123s
sys	0m0.696s
```

**Vinte e seis segundos de trabalho, e depois nada.** Nenhum resultado para os livros já contados,
nenhuma resposta parcial, nenhum aviso um minuto antes. É assim que acabar a memória se parece toda
vez: o consumo do programa cresce com os dados, e no dia em que os dados passam da máquina, o
programa para na linha que pediu um byte a mais.

Duas coisas valem ver aqui. **A falha não é um bug**: o programa está correto, e numa máquina maior
dá a resposta certa. E **a solução não é um dicionário melhor.** Todo programa que precisa segurar
todos os visitantes de uma vez tem a mesma parede em algum lugar; uma estrutura de dados mais
esperta muda a parede de lugar e não a remove. A próxima seção a remove.
