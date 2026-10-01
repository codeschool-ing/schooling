---
title: YAML, e os valores que não são o que parecem
version: 1
---

YAML é o formato que as pessoas escrevem, porque se lê com quase nenhuma pontuação: indentação é
estrutura, `-` começa um item de lista, `key: value` é um mapeamento. **O preço é que o YAML
adivinha o tipo de todo valor sem aspas**, e na versão do YAML que o PyYAML lê, a 1.1, ele adivinha
mais do que qualquer um espera. Seis valores que uma pessoa quis dizer como texto:

```yaml
country: NO
enable_ntp: on
file_mode: 0755
version: 1.10
port_range: 22:22
vlan_name: 010
```

```schooling-example
{
  "language": "python",
  "file": "surprises.py",
  "parts": [
    {
      "code": "import yaml\n"
    },
    {
      "code": "for key, value in yaml.safe_load(open(\"surprises.yaml\")).items():\n    print(f\"{key:11} {type(value).__name__:5} {value!r}\")",
      "note": "**Seis valores que uma pessoa quis como texto.** O PyYAML lê YAML 1.1, e em YAML 1.1 cada um deles parece outra coisa."
    }
  ]
}
```

```
ana@ctl:~$ python surprises.py
country     bool  False
enable_ntp  bool  True
file_mode   int   493
version     float 1.1
port_range  int   1342
vlan_name   int   8
```

Cada um é um erro real com um custo real num inventário de rede:

| escreveu | quis dizer | recebeu | por quê |
|---|---|---|---|
| `NO` | o código de país da Noruega | `False` | `yes`, `no`, `on`, `off` são booleanos no YAML 1.1 |
| `on` | o texto "on" | `True` | a mesma regra |
| `0755` | um modo de arquivo, como texto | `493` | um zero à esquerda o torna octal |
| `1.10` | uma versão de software | `1.1` | é um float, e o zero no final não significa nada para um float |
| `22:22` | uma faixa de portas | `1342` | números com dois-pontos são base 60, para horas como `1:30:00` |
| `010` | o nome de uma VLAN | `8` | octal de novo |

**A correção são as aspas.** Um valor entre aspas é sempre uma string, e nada nele é adivinhado:

```
ana@ctl:~$ sed -E 's/: (.*)$/: "\1"/' surprises.yaml > quoted.yaml; cat quoted.yaml
country: "NO"
enable_ntp: "on"
file_mode: "0755"
version: "1.10"
port_range: "22:22"
vlan_name: "010"
ana@ctl:~$ python -c 'import yaml; print(yaml.safe_load(open("quoted.yaml")))'
{'country': 'NO', 'enable_ntp': 'on', 'file_mode': '0755', 'version': '1.10', 'port_range': '22:22', 'vlan_name': '010'}
```

A regra que evita os seis: **ponha aspas em todo valor que não seja um número ou um booleano que
você quis como tal**, e trate versões, códigos, modos e qualquer coisa com zeros à esquerda como
texto. O YAML 1.2 abandonou a maioria desses palpites, mas o PyYAML e boa parte das ferramentas em
torno do Ansible ainda leem 1.1.

**E sempre `safe_load`, nunca `load`.** O YAML completo pode descrever objetos Python, inclusive
uma chamada de função, e `yaml.load` com `yaml.UnsafeLoader` vai construí-los. `safe_load` recusa:

```
ana@ctl:~$ python -c 'import yaml; yaml.safe_load("!!python/object/apply:os.system [echo hello]")' 2>&1 | grep Error
    raise ConstructorError(None, None,
yaml.constructor.ConstructorError: could not determine a constructor for the tag 'tag:yaml.org,2002:python/object/apply:os.system'
```

Essa tag pede que `os.system("echo hello")` seja executado enquanto o arquivo é lido. `safe_load`
não o construiria; num arquivo do repositório de outra pessoa, essa recusa é a diferença entre ler
dados e rodar o código dela.
