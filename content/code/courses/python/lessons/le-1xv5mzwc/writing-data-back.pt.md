---
title: Nunca construa nenhum dos dois formatos à mão
version: 2
---

```python
import csv

with open(path, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "city", "score"])
    writer.writeheader()
    for row in rows:
        writer.writerow(row)
```

O `DictWriter` recebe os nomes dos campos, escreve o cabeçalho, e põe aspas no que precisar. Uma
cidade chamada `Porto, Portugal` sai com aspas corretamente, e você não precisou pensar nisso.

O `writerows(rows)` é o laço numa linha.

## A versão feita à mão, e o que ela custa

```python
f.write(",".join([name, city, str(score)]) + "\n")      # no
```

Isto está correto até um valor conter uma vírgula, uma aspa ou uma quebra de linha — e aí ele produz
um arquivo que parece bom, abre numa planilha, e tem as colunas deslocadas numa linha em onze mil.
Nada levanta erro, nem aqui nem quando ele é lido de volta.

O mesmo argumento vale para o JSON, e com mais força: escapar uma aspa, uma barra invertida e um
caractere de controle corretamente é para o que serve o `json.dumps`.

## Gravar JSON que alguém vai ler

```python
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False, sort_keys=True)
    f.write("\n")
```

`indent=2` para o diff, `ensure_ascii=False` para os acentos, `sort_keys=True` para duas rodadas
produzirem os mesmos bytes. A quebra de linha no fim não é assunto do JSON e é de toda ferramenta de
texto.

## Gravar com segurança

```python
tmp = path.with_suffix(".tmp")
tmp.write_text(text, encoding="utf-8")
tmp.replace(path)          # atomic on the same filesystem
```

Abrir o arquivo de verdade com `"w"` o esvazia antes do primeiro byte ser gravado, então uma queda
no meio deixa você sem o arquivo velho e sem o novo. Gravar ao lado e renomear quer dizer que quem
lê vê um ou o outro e nunca uma metade.

**Isso importa para qualquer coisa que um programa lê ao subir** — um cache, um arquivo de estado,
uma configuração que o processo de outra pessoa está observando.
