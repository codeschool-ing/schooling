---
title: Espaços: o defeito que ninguém vê
version: 1
---

**Um espaço no fim de um valor é invisível em toda tela e diferente em toda comparação.**
`'São Paulo'` e `'São Paulo '` aparecem iguais, ficam lado a lado na ordenação e se agrupam
separados. É o defeito mais barato de corrigir do curso e o mais comum de passar batido, porque
ninguém procura o que não consegue ver.

Contar é o único jeito de achá-lo:

```schooling-example
{
  "language": "python",
  "file": "cities.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "customers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n",
      "note": "O arquivo de clientes como texto, sem os duplicados exatos, para cada cliente contar uma vez."
    },
    {
      "code": "city = customers[\"city\"]\n",
      "note": "A coluna em que esta aula trabalha, importada por todo comando seguinte."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from cities import city; print(city.nunique(), (city != city.str.strip()).sum(), city.str.strip().nunique())"
28 60 25
```

28 cidades distintas; 60 valores diferem de si mesmos com as pontas aparadas; 25 distintas depois
de aparar. **Três das 28 grafias só existiam por causa de um espaço no fim.** A aula 1 encontrou
uma delas, a linha de 25 clientes em São Paulo com onze bytes.

Imprimir os valores com o `ascii()` do Python, que escreve todo caractere invisível ou fora do ASCII
como um escape, mostra o que cada São Paulo é de verdade:

```
ana@lab:~/clean$ python -c "from cities import city; print(sorted({ascii(v) for v in city if 'Paulo' in v and 'Ã' not in v}))"
["'S. Paulo'", "'S\\xe3o Paulo '", "'S\\xe3o Paulo'", "'Sa\\u0303o Paulo '", "'Sa\\u0303o Paulo'", "'Sao Paulo'"]
```

`'S\xe3o Paulo '` finalmente mostra o seu espaço. O `̃` em duas delas é o assunto da próxima
seção.

## Aparar, depois reduzir

Os espaços erram em três lugares, e um passo padrão corrige os três:

- **nas pontas**, de um campo de formulário que guardou o que o cursor deixou: `strip()`, `trim()`
  em SQL;
- **no meio**, como dois espaços onde se queria um, que a aula 5 achou em nomes como
  `Mariana  Souza`: trocar toda sequência de espaços por um só;
- **como caracteres que não são o espaço comum**: uma tabulação, uma quebra de linha, ou o espaço
  inseparável que um texto copiado de uma página web traz junto. O `\s` de uma expressão regular casa
  com todos eles, e é por isso que a redução o usa em vez de um espaço literal.

No pandas: `.str.strip().str.replace(r"\s+", " ", regex=True)`. **Este passo é seguro em qualquer
coluna de texto** — nenhuma cidade, nome ou endereço deveria começar ou terminar com espaço — e ele
pertence ao início de toda limpeza de texto, antes de qualquer comparação.
