---
title: Forçar e depois contar o que se perdeu
version: 1
---

A conversão óbvia falha na hora:

```
ana@lab:~/clean$ python -c "from raw_customers import customers as c; c['birth_year'].astype(int)" 2>&1 | tail -1
ValueError: cannot convert float NaN to integer
```

**Essa falha é a honesta.** A coluna tem vazios, um inteiro simples não tem como guardar um vazio,
e o pandas se recusa em vez de inventar um número. O passo seguinte de costume é o que a
documentação sugere: `pd.to_numeric` com `errors="coerce"`, que transforma em `NaN` tudo o que não
consegue ler e segue em frente.

```
ana@lab:~/clean$ python -c "import pandas as pd; from raw_customers import customers as c; n = pd.to_numeric(c['birth_year'], errors='coerce'); print(c['birth_year'].isna().sum(), n.isna().sum()); print(n.head(3).to_string())"
332 332
0    1986.0
1    1982.0
2    1953.0
```

Aqui não fez mal nenhum. A coluna tinha 332 vazios antes e 332 depois, então todo valor que estava
escrito virou número. **As duas contagens são a verificação inteira**, e só são baratas porque a
comparação foi feita. Veja a mesma chamada sobre quatro preços escritos do jeito que os arquivos
desta empresa escrevem:

```
ana@lab:~/clean$ python -c "import pandas as pd; s = pd.Series(['12.90', '1.234,56', 'R$ 5,00', '7']); print(pd.to_numeric(s, errors='coerce').to_string())"
0    12.9
1     NaN
2     NaN
3     7.0
```

Dois dos quatro valores sumiram. `1.234,56` tem separador de milhar e vírgula decimal brasileiros,
e `R$ 5,00` carrega o símbolo da moeda; nenhum dos dois é número para o pandas, então ambos viraram
`NaN`, e um `NaN` é idêntico a um preço que ninguém registrou. Uma soma sobre essa coluna sai
errada, uma média sai errada, e **nada na tela avisa**. A aula 7 mostrou como ler os dois; o perigo é uma coluna que chega a
este passo sem ter passado por lá.

`errors="coerce"` continua sendo a ferramenta certa. O que falta é a contagem ao lado, toda vez,
escrita uma vez só para não ser esquecida:

```schooling-example
{
  "language": "python",
  "file": "convert.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n\n"
    },
    {
      "code": "def to_number(values, name):\n    \"\"\"Convert text to numbers and refuse to lose anything quietly.\"\"\"\n",
      "note": "Uma coluna de texto, e o nome dela para a mensagem de erro."
    },
    {
      "code": "    numbers = pd.to_numeric(values, errors=\"coerce\")\n",
      "note": "Converte, transformando em `NaN` o que não puder ser lido."
    },
    {
      "code": "    lost = values.notna() & numbers.isna()\n",
      "note": "**Perdido** quer dizer presente antes e vazio depois. Um vazio que já era vazio não entra na conta."
    },
    {
      "code": "    if lost.any():\n        examples = sorted(values[lost].unique())[:5]\n        raise ValueError(f\"{name}: {lost.sum()} values are not numbers, e.g. {examples}\")\n",
      "note": "Qualquer perda para aqui, dizendo quantos e mostrando até cinco dos valores."
    },
    {
      "code": "    return numbers\n",
      "note": "Senão, os números, com vazios só onde já havia vazios."
    }
  ]
}
```

A regra cabe em uma linha: **um valor que existia antes e está vazio depois foi perdido**, e uma
perda interrompe a conversão. A mensagem diz quantos e mostra alguns, porque a primeira coisa que
qualquer pessoa faz com esse erro é olhar os valores:

```
ana@lab:~/clean$ python -c "import pandas as pd; from convert import to_number; to_number(pd.Series(['12.90', '1.234,56', None]), 'price')" 2>&1 | tail -1
ValueError: price: 1 values are not numbers, e.g. ['1.234,56']
ana@lab:~/clean$ python -c "import pandas as pd; from convert import to_number; print(to_number(pd.Series(['12.90', '7', None]), 'price').to_string())"
0    12.9
1     7.0
2     NaN
```

A segunda chamada passa porque nada se perdeu. O vazio na terceira posição já era vazio antes da
conversão, então continua vazio e não entra na conta. Essa distinção é o ponto: dado faltante é
assunto da aula 3 e é mantido, enquanto um valor destruído pela conversão é assunto desta aula, e é
recusado.
