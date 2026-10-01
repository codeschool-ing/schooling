---
title: Um valor ausente é um erro
version: 1
---

Arquivos de dados são digitados por pessoas, e pessoas erram o nome de chaves. Aqui o `address` de
uma interface está escrito `adress`, e o mesmo template o renderiza com os padrões do Jinja2:

```schooling-example
{
  "language": "python",
  "file": "missing.py",
  "parts": [
    {
      "code": "import sys\n\nimport yaml\nfrom jinja2 import Environment, FileSystemLoader, StrictUndefined, Undefined\n\ndata = yaml.safe_load(open(\"data/edge1.yaml\"))"
    },
    {
      "code": "data[\"interfaces\"][1][\"adress\"] = data[\"interfaces\"][1].pop(\"address\")\n\nstrict = \"--strict\" in sys.argv\nenv = Environment(loader=FileSystemLoader(\"templates\"), trim_blocks=True, lstrip_blocks=True,\n                  undefined=StrictUndefined if strict else Undefined)\nprint(env.get_template(\"iface.j2\").render(data), end=\"\")",
      "note": "**Um erro de digitação nos dados**: a chave de uma interface está escrita `adress`, então `i.address` não nomeia nada."
    }
  ]
}
```

```
ana@ctl:~$ cd tpl && python missing.py
interface eth1
 description uplink to core1
 ip address 198.51.100.2/30
exit
interface eth2
 description branch LAN
 ip address 
exit
```

**Nenhum erro, nenhum aviso, e uma configuração com `ip address` e nada depois.** Esse é o padrão
do Jinja2 de propósito: um nome que ele não encontra é renderizado como string vazia, o que serve a
uma página web com um campo opcional. Para um roteador é o pior resultado possível, porque o arquivo
parece completo. Enviada ao FRR, essa linha é recusada como `% Command incomplete`; enviado a outra
plataforma, um comando incompleto pode significar algo totalmente diferente.

`StrictUndefined` faz de um nome ausente uma exceção:

```
ana@ctl:~$ cd tpl && python missing.py --strict 2>&1 | tail -4
  File "templates/iface.j2", line 6, in top-level template code
    ip address {{ i.address }}
   ^^^^^^^^^^^^^^^^^^^^^^^^^
jinja2.exceptions.UndefinedError: 'dict object' has no attribute 'address'
```

O traceback nomeia o template, a linha, a expressão e a chave que não estava lá, que é toda a
informação necessária para corrigir os dados. **Nada é renderizado, então nada pode ser enviado.**

Onde um valor é de fato opcional, o template tem de dizer isso, e esse é o ponto: `{% if
i.description %}` no template da próxima seção é a decisão de que uma interface pode não ter
descrição, escrita onde quem lê consegue ver. Sem `StrictUndefined`, todo valor é opcional, e
ninguém decidiu isso.
