---
title: Regras em Sigma
version: 1
---

Uma detecção escrita na linguagem de consulta de um SIEM fica presa a ele. O **Sigma** é um formato aberto
para escrever a detecção uma vez, em YAML, e convertê-la para a linguagem que o SIEM falar; o conversor é
o `sigma-cli`, com um plugin por destino. Instale-o, com o plugin do SQLite, num ambiente virtual só dele:

```
ana@soc:~/week$ python3 -m venv ~/sigma && ~/sigma/bin/pip install -q sigma-cli==3.1.0 pySigma-backend-sqlite==2.0.0
ana@soc:~/week$ ~/sigma/bin/sigma list targets
+------------+-----------------------+------------------------------+--------+
| Identifier | Target Query Language | Processing Pipeline Required | Plugin |
+------------+-----------------------+------------------------------+--------+
| sqlite     | SQLite backend        | No                           | sqlite |
+------------+-----------------------+------------------------------+--------+
```

A regra mais simples é uma condição sobre um evento. Salve isto como `failures.yml`:

```yaml
title: SSH login failure
name: ssh_login_failure
id: 3f1d2c6a-8b7e-4e0f-9a52-6c1b0e7d4a10
status: test
description: One failed SSH login, for a known or an unknown account.
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: failure
  condition: selection
level: low
```

`logsource` diz de que tipo de log a regra trata; `detection` nomeia uma seleção de valores de campo e uma
`condition` sobre as seleções; `level` diz quanta atenção um resultado merece. O `id` é um UUID, para que
uma regra possa ser renomeada e continuar rastreável. Converta-a:

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite failures.yml
Parsing Sigma rules
SELECT * FROM logs WHERE product='sshd' AND `action`='failure'
```

Esse é todo o sentido do Sigma, visível numa linha: o YAML virou uma cláusula `WHERE` sobre a tabela que
o `load.py` montou, com os nomes de campo que ele escolheu. Aqui os campos batem porque a tabela foi
desenhada para isso. Num SIEM de verdade os nomes diferem (`src_ip` num produto, `source.ip` em outro), e
os **processing pipelines** do Sigma os traduzem durante a conversão. **Uma regra só é tão portável quanto
o mapeamento dos nomes de campo dela**: o motivo mais comum de uma regra baixada não casar com nada é ela
pedir um campo que o seu SIEM chama de outra coisa.

Um login falho é um evento, não um alerta. Nesta semana ele casa com 150 linhas, e ninguém quer 150
alertas. O que torna uma falha interessante é a companhia dela, e é disso que trata a próxima seção.
