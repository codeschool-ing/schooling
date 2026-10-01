---
title: A configuração inteira a partir de um template
version: 1
---

O projeto no `ctl` é um diretório de dados e um diretório de templates:

```
ana@ctl:~$ cd tpl && find data templates -type f | sort
data/core1.yaml
data/edge1.yaml
data/edge2.yaml
templates/frr.j2
templates/iface.j2
```

Cada arquivo de dados é o que torna um roteador diferente. O do edge1:

```yaml
hostname: edge1
loopback: 203.0.113.252
interfaces:
  - name: eth1
    description: uplink to core1
    address: 198.51.100.2/30
    ospf: point-to-point
  - name: eth2
    description: branch LAN
    address: 203.0.113.1/26
    ospf: passive
```

O template é a configuração em execução do FRR com buracos. Duas partes merecem uma leitura atenta.
O `{% if %}` dentro do loop de interfaces transforma um valor, `ospf`, no comando certo para cada
tipo de link; e o bloco `router ospf` percorre as mesmas interfaces uma segunda vez, então uma
declaração network é escrita para toda interface que tem OSPF, e uma interface acrescentada aos
dados aparece nos dois lugares de uma vez:

```conf
frr version 8.4.4
frr defaults traditional
hostname {{ hostname }}
log file /var/log/frr/frr.log informational
service integrated-vtysh-config
!
{% for i in interfaces %}
interface {{ i.name }}
{% if i.description %}
 description {{ i.description }}
{% endif %}
 ip address {{ i.address }}
{% if i.ospf == "point-to-point" %}
 ip ospf network point-to-point
{% elif i.ospf == "passive" %}
 ip ospf passive
{% endif %}
exit
!
{% endfor %}
interface lo
 ip address {{ loopback }}/32
exit
!
router ospf
 ospf router-id {{ loopback }}
 redistribute connected
{% for i in interfaces if i.ospf %}
 network {{ i.address | network }} area 0
{% endfor %}
exit
!
line vty
 exec-timeout 30 0
exit
!
end
```

`network` não é um dos filtros do Jinja2. É uma função no script que renderiza, que transforma
`198.51.100.2/30` em `198.51.100.0/30` com o módulo `ipaddress` do Python. **Um cálculo pertence ao
Python e um filtro é como o template o chama**: a alternativa é um valor `network` em cada arquivo
de dados, escrito à mão ao lado do endereço de que ele deriva, e errado na primeira vez que alguém
renumerar um link.

```schooling-example
{
  "language": "python",
  "file": "render.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\n\nimport yaml\nfrom jinja2 import Environment, FileSystemLoader, StrictUndefined\n\n"
    },
    {
      "code": "def network(address):\n    return str(ipaddress.ip_interface(address).network)\n\n\nenv = Environment(\n    loader=FileSystemLoader(\"templates\"),",
      "note": "**Um filtro é uma função Python.** `198.51.100.2/30 | network` a chama com o endereço e imprime o que ela devolve, a rede em que o endereço está."
    },
    {
      "code": "    trim_blocks=True,\n    lstrip_blocks=True,",
      "note": "**Tags de bloco não deixam linhas em branco.** `trim_blocks` tira a quebra de linha depois de uma tag `{% %}` e `lstrip_blocks`, os espaços antes dela."
    },
    {
      "code": "    undefined=StrictUndefined,",
      "note": "**Um valor que falta é erro, não string vazia.** O padrão do Jinja2 imprime nada para um nome que não conhece, e a configuração sai com um buraco."
    },
    {
      "code": "    keep_trailing_newline=True,\n)\nenv.filters[\"network\"] = network\ntemplate = env.get_template(\"frr.j2\")\n\nout = pathlib.Path(\"configs\")\nout.mkdir(exist_ok=True)",
      "note": "**A última quebra de linha fica.** O Jinja2 tira por padrão uma quebra de linha final do template, e o arquivo renderizado ficaria diferente do roteador por um byte."
    },
    {
      "code": "for path in sorted(pathlib.Path(\"data\").glob(\"*.yaml\")):\n    data = yaml.safe_load(path.read_text())\n    text = template.render(data)\n    (out / f\"{data['hostname']}.conf\").write_text(text)\n    print(f\"{path} -> configs/{data['hostname']}.conf, {len(text.splitlines())} lines\")",
      "note": "**Um template, um arquivo de dados por roteador.** O laço é o programa inteiro: ler o YAML do host, renderizar, gravar."
    }
  ]
}
```

```
ana@ctl:~$ cd tpl && python render.py
data/core1.yaml -> configs/core1.conf, 34 lines
data/edge1.yaml -> configs/edge1.conf, 34 lines
data/edge2.yaml -> configs/edge2.conf, 34 lines
```

A primeira verificação de um template que descreve uma rede existente é se ele a reproduz. A
primeira comparação não reproduziu exatamente:

```
ana@ctl:~$ cd tpl && ssh netops@core1 "show running-config" | tail -n +5 | diff - configs/core1.conf
34c34
< end
---
> end
\ No newline at end of file
```

**Um byte.** O Jinja2 remove uma única quebra de linha final do template a menos que seja instruído
a mantê-la, então o arquivo renderizado terminava em `end` e o do roteador em `end` e uma quebra de
linha. É para isso que serve o `keep_trailing_newline=True` no script acima. Com ele:

```
ana@ctl:~$ cd tpl && python render.py
data/core1.yaml -> configs/core1.conf, 34 lines
data/edge1.yaml -> configs/edge1.conf, 34 lines
data/edge2.yaml -> configs/edge2.conf, 34 lines
ana@ctl:~$ cd tpl && for h in core1 edge1 edge2; do ssh netops@$h "show running-config" | tail -n +5 | diff -q - configs/$h.conf > /dev/null && echo "$h: same"; done
core1: same
edge1: same
edge2: same
```

Três roteadores, três arquivos renderizados, nenhuma diferença. Daqui em diante os dados e o
template são a descrição da rede, e os roteadores são o que eles renderizam.
