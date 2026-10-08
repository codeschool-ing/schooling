---
title: Padrões: a forma de cada valor
version: 1
---

**Um perfil de padrões troca todo dígito por `9` e toda letra por `a`, e conta o que sobra.**
`01310-100` vira `99999-999`, `2025-03-14` vira `9999-99-99`, `Pix` vira `aaa`. Milhares de valores
distintos se reduzem a um punhado de formas, e uma coluna que deveria ter uma forma e tem quatro diz
isso em quatro linhas. É a técnica mais produtiva desta aula, e cabe numa função:

```schooling-example
{
  "language": "python",
  "file": "patterns.py",
  "parts": [
    {
      "code": "import sys\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def pattern(values):\n    return (values.str.replace(r\"[0-9]\", \"9\", regex=True)\n                  .str.replace(r\"[^\\W\\d_]\", \"a\", regex=True))\n\n\n",
      "note": "**Todo dígito vira `9` e toda letra vira `a`**, letras acentuadas inclusive: `[^\\W\\d_]` é uma letra de qualquer alfabeto. Pontuação e espaços ficam como estão, porque são eles que distinguem os formatos."
    },
    {
      "code": "path, column = sys.argv[1], sys.argv[2]\ndf = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[\"\"])\n",
      "note": "A mesma leitura do `profile.py`: texto, e só um vazio como faltante."
    },
    {
      "code": "if len(sys.argv) > 3:\n    print(pd.crosstab(pattern(df[column]), df[sys.argv[3]]))\n",
      "note": "Com um terceiro argumento, uma tabela do padrão contra outra coluna, que é como se rastreia um formato até o sistema que o escreveu."
    },
    {
      "code": "else:\n    print(pattern(df[column]).value_counts(dropna=False).to_string())\n",
      "note": "Sem ele, cada padrão e quantos valores o têm."
    }
  ]
}
```

O CEP, a data de cadastro e o ano de nascimento:

```
ana@lab:~/clean$ python patterns.py raw/customers.csv cep
cep
99999-999    1322
99999999      803
9999999       288
ana@lab:~/clean$ python patterns.py raw/customers.csv signed_up
signed_up
99/99/9999    1369
9999-99-99    1044
ana@lab:~/clean$ python patterns.py raw/customers.csv birth_year
birth_year
9999    1969
NaN      338
99       106
```

**`cep` tem três formas.** Os Correios escrevem um CEP como cinco dígitos, um hífen e três dígitos.
803 valores perderam o hífen e 288 têm só sete dígitos, coisa que nenhum CEP tem: falta um dígito, e
só pode ser um zero à esquerda, porque os CEPs da região de São Paulo começam com `0`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l02-cep-profile\" aria-label=\"Um cartão de perfil da coluna cep do customers.csv: 2413 preenchidos, nenhum vazio, 2360 distintos, de 7 a 9 caracteres. Ao lado, os três padrões: 1322 valores escritos como os Correios escrevem, 803 sem o hífen e 288 sem o hífen e com um zero à esquerda perdido.\"><rect x=\"20.0\" y=\"30.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">cep, perfilado</text><text x=\"36.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">preenchidos</text><text x=\"204.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2413</text><text x=\"36.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vazios</text><text x=\"204.0\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"36.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">distintos</text><text x=\"204.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2360</text><text x=\"36.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tamanho</text><text x=\"204.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7–9</text><text x=\"250.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">padrão</text><text x=\"250.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">99999-999</text><rect x=\"345.0\" y=\"70.0\" width=\"200.0\" height=\"20.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"551.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1322</text><text x=\"345.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">como os Correios escrevem</text><text x=\"250.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">99999999</text><rect x=\"345.0\" y=\"114.0\" width=\"121.5\" height=\"20.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"472.5\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">803</text><text x=\"345.0\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem o hífen</text><text x=\"250.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">9999999</text><rect x=\"345.0\" y=\"158.0\" width=\"43.6\" height=\"20.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"394.6\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">288</text><text x=\"345.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem o hífen e sem um zero à esquerda</text></svg>", "caption": "O perfil diz que os tamanhos discordam; os padrões dizem como. Só a primeira barra é um CEP que uma tabela de consulta reconheceria como está."}
```

**`signed_up` tem duas formas, e essa é a armadilha.** `9999-99-99` é o formato ISO e só pode
querer dizer uma coisa. `99/99/9999` cobre tanto `14/03/2025` quanto `03/14/2025`, então o perfil de
padrões informa dois formatos onde a aula 1 achou três. Um padrão vê forma e não significado; para o
significado, separe as formas pela origem dos valores:

```
ana@lab:~/clean$ python patterns.py raw/customers.csv signed_up signup_channel
signup_channel  app  import-2023  site  store
signed_up                                    
99/99/9999      730           21     0    618
9999-99-99        0           24  1020      0
ana@lab:~/clean$ python patterns.py raw/customers.csv cep signup_channel
signup_channel  app  import-2023  site  store
cep                                          
99999-999         0           28  1020    274
9999999         285            3     0      0
99999999        445           14     0    344
```

Agora as origens aparecem. O site escreve datas ISO e CEPs com hífen. As lojas escrevem
`99/99/9999` — dia primeiro, como a aula 1 descobriu — e CEPs com e sem hífen, do jeito que a pessoa
no balcão digitou. **O aplicativo também escreve `99/99/9999`, com o mês primeiro, e produziu 285
dos 288 CEPs de sete dígitos**: ele guarda o CEP como número, então `01310100` virou `1310100`. A
migração de 2023 contribui com um pouco de tudo, porque foi uma cópia dos registros dos três
sistemas naquele momento.

**`birth_year` tem `9999`, `99` e vazio**, sem mais nada escondido: os anos de dois dígitos que a
aula 1 encontrou e os 338 vazios. Os 1900 não aparecem aqui, porque `1900` tem exatamente a forma de
um ano bom. **Um perfil de padrões acha valores inválidos, nunca os inexatos**, que é a distinção da
aula 1, medida.

## Para que servem os padrões

Cada forma é uma regra esperando para ser escrita. `99999-999` é o CEP válido, então a regra de
limpeza da coluna é: tirar o hífen, completar com zeros à esquerda até oito dígitos, pôr o hífen de
volta. A aula 7 a escreve. Sem o perfil, a regra óbvia — tirar o hífen — teria deixado 288 códigos de
sete dígitos que não batem com nada em nenhuma tabela de endereços, e uma junção com uma delas os
perderia sem um aviso.
