---
title: JSON e Python
version: 1
---

O JSON tem seis tipos de valor, e o módulo `json` do Python mapeia cada um para um tipo Python:

```schooling-example
{
  "language": "python",
  "file": "types.py",
  "parts": [
    {
      "code": "import json\n"
    },
    {
      "code": "text = '{\"name\": \"eth1\", \"mtu\": 1500, \"enabled\": true, \"speed\": null, \"load\": 0.25, \"addresses\": [\"198.51.100.2/30\"]}'\ndata = json.loads(text)\nfor key, value in data.items():\n    print(f\"{key:10} {type(value).__name__:6} {value!r}\")\n",
      "note": "**No que o `json.loads` transforma cada valor JSON.** Um objeto vira `dict`, um array vira `list`, `true` vira `True` e `null` vira `None`. Um número com ponto vira `float`."
    },
    {
      "code": "print(json.dumps(data, sort_keys=True, indent=2))",
      "note": "**E de volta.** `sort_keys` e `indent` não mudam os dados, só o layout, e é isso que torna dois arquivos comparáveis linha a linha."
    }
  ]
}
```

```
ana@ctl:~$ python types.py
name       str    'eth1'
mtu        int    1500
enabled    bool   True
speed      NoneType None
load       float  0.25
addresses  list   ['198.51.100.2/30']
{
  "addresses": [
    "198.51.100.2/30"
  ],
  "enabled": true,
  "load": 0.25,
  "mtu": 1500,
  "name": "eth1",
  "speed": null
}
```

O mapeamento é simples e tem três pontas que vale conhecer.

- **Um número com ponto decimal vira um `float`**, e um float não guarda todo decimal com
  exatidão. Um contador ou uma banda que chega como `0.1` não é bem 0,1 depois do parse, o que não
  importa para exibir e importa para testes de igualdade.
- **O JSON não tem inteiros de tamanho limitado, e muitos parsers têm.** O JavaScript perde
  precisão acima de 2 elevado a 53, então a RFC 7951 escreve os tipos de 64 bits do YANG,
  `counter64` entre eles, **como strings** em JSON: `"in-octets": "123456789012"`. Um script que lê
  contadores via RESTCONF tem de convertê-los ele mesmo com `int()`. O `json` do Python não tem
  esse limite, e é por isso que o target gNMI da aula 4 podia mandar inteiros e o `pygnmi` os lia
  como vinham.
- **As chaves são sempre strings**, e **a ordem das chaves não tem significado**. `sort_keys=True`
  as escreve em ordem alfabética, e é isso que torna dois arquivos JSON comparáveis com um diff
  linha a linha.

`json.dumps` com `indent` é a outra metade: dos dados de volta para o texto. **O que um programa
escreve deve ser estável**: os mesmos dados escritos duas vezes devem dar os mesmos bytes. Chaves
ordenadas e uma indentação fixa garantem isso, e um backup ou uma configuração renderizada que muda
de layout a cada execução transforma todo diff em ruído.
