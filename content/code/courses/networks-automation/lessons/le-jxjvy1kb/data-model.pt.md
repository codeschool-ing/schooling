---
title: Um modelo para os dados
version: 1
---

A primeira verificação é a mais barata: os dados têm ao menos a forma certa? O `StrictUndefined`
da aula 10 pegou uma chave ausente, mas só na hora de renderizar, só a primeira, e só uma chave
ausente. Um **modelo** diz como os dados de todo roteador têm de ser, na forma de tipos:

```schooling-example
{
  "language": "python",
  "file": "model.py",
  "parts": [
    {
      "code": "from ipaddress import IPv4Address, IPv4Interface\nfrom typing import Literal\n\nfrom pydantic import BaseModel, ConfigDict\n\n"
    },
    {
      "code": "class Interface(BaseModel):\n    model_config = ConfigDict(extra=\"forbid\")\n    name: str\n    description: str = \"\"\n    address: IPv4Interface\n    ospf: Literal[\"point-to-point\", \"passive\"] | None = None\n\n\nclass Router(BaseModel):\n    model_config = ConfigDict(extra=\"forbid\")\n    hostname: str\n    loopback: IPv4Address\n    interfaces: list[Interface]",
      "note": "**A forma dos dados de um roteador, escrita como tipos.** Um endereço tem que ser lido como endereço, `ospf` tem que ser uma de duas palavras, e `extra=\"forbid\"` recusa uma chave que o modelo não nomeia, que é como um erro como `adress` é pego."
    }
  ]
}
```

O `pydantic` lê um dicionário para dentro do modelo e recusa tudo o que não se encaixa. Um script
pequeno o roda em cada arquivo:

```schooling-example
{
  "language": "python",
  "file": "validate.py",
  "parts": [
    {
      "code": "import pathlib\nimport sys\n\nimport yaml\nfrom pydantic import ValidationError\n\nfrom model import Router\n\nfailed = False\nfor path in sorted(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else \"data\").glob(\"*.yaml\")):\n    try:\n        Router.model_validate(yaml.safe_load(path.read_text()))\n        print(f\"{path}: ok\")"
    },
    {
      "code": "    except ValidationError as e:\n        failed = True\n        print(f\"{path}: {e.error_count()} error(s)\")\n        for err in e.errors():\n            print(\"   \", \".\".join(str(p) for p in err[\"loc\"]), \"-\", err[\"msg\"])\nsys.exit(1 if failed else 0)",
      "note": "**Todo problema do arquivo, não só o primeiro.** O pydantic junta todos, cada um com o caminho até o valor e o que estava errado nele."
    }
  ]
}
```

```
ana@ctl:~$ cd net && python validate.py
data/core1.yaml: ok
data/edge1.yaml: ok
data/edge2.yaml: ok
```

O arquivo de um roteador novo com três erros, colocado num diretório só dele:

```
ana@ctl:~$ cd net && mkdir -p new && cp edge3.yaml new/ && python validate.py new; echo "exit status $?"
new/edge3.yaml: 4 error(s)
    interfaces.0.address - Field required
    interfaces.0.adress - Extra inputs are not permitted
    interfaces.1.address - Input is not a valid IPv4 interface
    interfaces.1.ospf - Input should be 'point-to-point' or 'passive'
exit status 1
```

**Quatro erros, cada um com o caminho até o valor**: `interfaces.0.adress` é a chave escrita
errado, o que também deixa `address` faltando; `interfaces.1.address` tem `300` onde deveria haver
um octeto; e `interfaces.1.ospf` diz quais duas palavras teria aceitado. O template nunca rodou, e
o status de saída é 1.

São três tipos de erro pegos por uma declaração só, e nenhum deles precisou de um roteador. Eles
teriam chegado a um por três caminhos diferentes: um `KeyError`, uma configuração que o FRR recusa,
e uma interface sem OSPF e sem erro nenhum.

Abaixo do modelo há o próprio YAML. O `yamllint` verifica a sintaxe e o layout dos arquivos:

```
ana@ctl:~$ cd net && yamllint -d relaxed data/
```

**Ele não imprimiu nada, que é o jeito dele de passar**; o status de saída, 0, é o que um pipeline
lê.
