---
title: De onde vêm as linhas em branco
version: 2
---

Um roteador não se importa com uma linha em branco na configuração; um diff se importa. A aula 11
compara a configuração que um roteador está rodando com a que o template renderizou, e toda linha
em branco ou indentação perdida é uma diferença que não significa nada e esconde a que significa.

Um template menor mostra de onde elas vêm. Ele escreve um bloco de interface por interface, e o seu
`{% if %}` está indentado, como as pessoas costumam indentar a lógica que escrevem:

```conf
{% for i in interfaces %}
interface {{ i.name }}
  {% if i.description %}
 description {{ i.description }}
  {% endif %}
 ip address {{ i.address }}
exit
{% endfor %}
```

Salvo como `templates/iface.j2`, ele é renderizado para o edge1 pelo `spacing.py`, que liga as duas
opções de espaço em branco do Jinja2 quando recebe `--trim`:

```python
import sys

import yaml
from jinja2 import Environment, FileSystemLoader

data = yaml.safe_load(open("data/edge1.yaml"))
trim = "--trim" in sys.argv
env = Environment(loader=FileSystemLoader("templates"), trim_blocks=trim, lstrip_blocks=trim)
print(env.get_template("iface.j2").render(data), end="")
```

Renderizado com os padrões do Jinja2:

```
ana@ctl:~$ cd tpl && python spacing.py

interface eth1
  
 description uplink to core1
  
 ip address 198.51.100.2/30
exit

interface eth2
  
 description branch LAN
  
 ip address 203.0.113.1/26
exit
```

**Toda tag deixou algo para trás.** A quebra de linha depois de `{% for %}` pertence ao corpo do
loop, então é impressa uma vez por interface: a linha em branco acima de cada `interface`. Os dois
espaços antes de `{% if %}` e de `{% endif %}` foram copiados, e também a quebra de linha depois de
cada um deles, que é a linha com dois espaços sob `interface eth1`. O Jinja2 remove a tag e mantém
tudo em volta dela, porque é isso que uma linguagem de template para qualquer tipo de texto
precisa fazer.

Duas opções mudam isso para o ambiente inteiro. **`trim_blocks` descarta a primeira quebra de linha
depois de uma tag de bloco, e `lstrip_blocks` descarta os espaços e tabs antes dela** na sua linha:

```
ana@ctl:~$ cd tpl && python spacing.py --trim
interface eth1
 description uplink to core1
 ip address 198.51.100.2/30
exit
interface eth2
 description branch LAN
 ip address 203.0.113.1/26
exit
```

Agora as tags somem com as suas linhas, e a saída é o texto entre elas. Ligue as duas opções em
todo template de configuração; a alternativa é `{%-` e `-%}` em cada tag, que apara à mão e é a
primeira coisa esquecida na próxima edição.

Que o separador `!` entre os blocos de interface falte aqui é escolha do template, não das opções:
o `iface.j2` nunca escreveu um. O template completo da seção depois da próxima escreve.
