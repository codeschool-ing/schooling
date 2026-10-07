---
title: Bloqueio: não comparar tudo com tudo
version: 1
---

**Comparar cada registro com todos os outros cresce com o quadrado do arquivo.** 2.376 clientes dão
2.821.500 pares, e um milhão de clientes dariam cerca de quinhentos bilhões. Dar nota a todo par é
desperdício neste tamanho e impossível no próximo.

O **bloqueio** compara só registros que já compartilham algo barato de checar: um CEP, um ano de
nascimento, as primeiras letras de um sobrenome. Ana bloqueia pela última palavra do nome simples, o
sobrenome:

```schooling-example
{
  "language": "python",
  "file": "match.py",
  "parts": [
    {
      "code": "import itertools\n\nimport pandas as pd\nfrom rapidfuzz import fuzz\n\nfrom keys import customers\n\n"
    },
    {
      "code": "customers[\"block\"] = customers[\"name_key\"].str.split().str[-1]\n",
      "note": "**O bloco é o sobrenome**: a última palavra do nome simples."
    },
    {
      "code": "pairs = []\nfor _, group in customers.groupby(\"block\"):\n    for a, b in itertools.combinations(group.to_dict(\"records\"), 2):\n        pairs.append({\n",
      "note": "Todo par dentro de cada bloco, e só dentro dele."
    },
    {
      "code": "            \"a\": a[\"customer_id\"], \"b\": b[\"customer_id\"],\n"
    },
    {
      "code": "            \"name\": fuzz.token_sort_ratio(a[\"name_key\"], b[\"name_key\"]),\n",
      "note": "Quão parecidos são os dois nomes, com as palavras ordenadas antes."
    },
    {
      "code": "            \"email\": pd.notna(a[\"email_key\"]) and a[\"email_key\"] == b[\"email_key\"],\n",
      "note": "Se compartilham um e-mail. Dois vazios não são uma correspondência: `pd.notna` garante que um endereço existe."
    },
    {
      "code": "            \"cep\": a[\"cep_key\"] == b[\"cep_key\"],\n",
      "note": "Se compartilham um CEP, já na forma simples."
    },
    {
      "code": "        })\npairs = pd.DataFrame(pairs)\n\n"
    },
    {
      "code": "if __name__ == \"__main__\":\n    n = len(customers)\n    print(f\"{n} customers: {n * (n - 1) // 2} possible pairs, {len(pairs)} compared\")\n",
      "note": "Quantos pares eram possíveis, e quantos foram comparados."
    }
  ]
}
```

```
ana@lab:~/clean$ python match.py
2376 customers: 2821500 possible pairs, 46299 compared
```

46.299 comparações em vez de 2.821.500: menos de 2% do trabalho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l05-blocking\" aria-label=\"Dois quadrados em escala de área. O grande é todo par possível dos 2376 clientes, 2.821.500. O pequeno no canto é o dos 46.299 pares que compartilham sobrenome, os únicos comparados: 1,6% do trabalho.\"><rect x=\"60.0\" y=\"40.0\" width=\"260.0\" height=\"260.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60.0\" y=\"266.7\" width=\"33.3\" height=\"33.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">todo par: 2.821.500</text><text x=\"390.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">comparados cada um com cada um</text><text x=\"390.0\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">mesmo sobrenome: 46.299</text><text x=\"390.0\" y=\"265.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">75 blocos, um por sobrenome</text></svg>", "caption": "Bloquear compara só registros que já compartilham alguma coisa. O preço é todo par real que não compartilha."}
```

**O preço é todo par real que não cai no mesmo bloco.** Uma pessoa cujo sobrenome foi digitado
errado num dos dois registros cai num bloco diferente, e nunca é comparada consigo mesma. A nota da
próxima seção conta seis duplicados reais perdidos exatamente assim: `Babrosa` por `Barbosa`,
`Ferreria` por `Ferreira`, e mais quatro.

Dois hábitos reduzem esse preço:

- **bloquear por algo que raramente está errado.** Um sobrenome é digitado por uma pessoa; um CEP
  muitas vezes é escolhido numa lista. A melhor chave é o campo em que as origens mais concordam;
- **bloquear mais de uma vez, por chaves diferentes, e juntar os candidatos.** Um par perdido no
  bloco de sobrenome em geral compartilha um CEP ou um e-mail, e uma segunda passada por esses
  campos o pega. Cada passada é barata; caro é comparar tudo.
