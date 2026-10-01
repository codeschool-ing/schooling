---
title: Conferindo um arquivo antes de confiar nele
version: 1
---

Um arquivo com erro de sintaxe falha alto e na hora. **Os arquivos perigosos são os que passam
pelo parser e significam outra coisa que não a que o autor quis dizer.** As surpresas do YAML
foram um tipo. Uma chave duplicada é outro, num inventário em que alguém copiou `edge1` para fazer
`edge2` e esqueceu de renomear:

```yaml
routers:
  core1:
    address: 192.0.2.11
    site: core
  edge1:
    address: 192.0.2.12
    site: branch-1
  edge1:
    address: 192.0.2.13
    site: branch-2
```

```
ana@ctl:~$ python -c 'import yaml; print(yaml.safe_load(open("inventory.yaml")))'
{'routers': {'core1': {'address': '192.0.2.11', 'site': 'core'}, 'edge1': {'address': '192.0.2.13', 'site': 'branch-2'}}}
ana@ctl:~$ yamllint inventory.yaml; echo "exit status $?"
inventory.yaml
  1:1       warning  missing document start "---"  (document-start)
  8:3       error    duplication of key "edge1" in mapping  (key-duplicates)

exit status 1
```

O PyYAML leu sem dizer uma palavra, e **o segundo `edge1` substituiu o primeiro**: o resultado tem
um `edge1` no endereço do `edge2` e nenhum `edge2`. Um script que percorresse esse inventário
configuraria o roteador errado com o nome certo. O `yamllint` recusa o arquivo, com a linha e a
regra, e também avisa da falta do `---` que abre um documento YAML, que é uma regra de estilo e
pode ser desligada. **Rodar um linter em todo arquivo YAML antes que um script o leia** pega essa
classe inteira de erro, e a aula 14 faz disso o primeiro passo do pipeline.

Os outros dois formatos têm seus próprios verificadores. Uma vírgula no final, válida em Python e
inválida em JSON:

```
ana@ctl:~$ printf '{"name": "eth1", "mtu": 1500,}\n' > bad.json; python -m json.tool bad.json; echo "exit status $?"
Expecting property name enclosed in double quotes: line 1 column 30 (char 29)
exit status 1
```

E um elemento XML fechado na ordem errada:

```
ana@ctl:~$ printf '<interface><name>eth1</interface>\n' > bad.xml; xmllint --noout bad.xml; echo "exit status $?"
bad.xml:1: parser error : Opening and ending tag mismatch: name line 1 and interface
<interface><name>eth1</interface>
                                 ^
bad.xml:2: parser error : Premature end of data in tag interface line 1

^
exit status 1
```

Cada ferramenta dá a linha, a coluna e um status de saída diferente de zero, que é tudo de que um
pipeline precisa. **Bem formado é a primeira verificação, válido é a segunda**: `json.tool` e
`xmllint --noout` dizem que a sintaxe está certa, e um modelo, pelo `yanglint` como na aula 5, diz
que o conteúdo está.
