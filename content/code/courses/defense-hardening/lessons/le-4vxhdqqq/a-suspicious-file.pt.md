---
title: Um arquivo suspeito, escrito por você
version: 1
---

**Para ver uma sandbox trabalhar, você precisa de um programa que tente coisas que uma sandbox deveria
barrar.** Arquivos maliciosos de verdade são o jeito errado de conseguir um: são perigosos de
guardar, ilegais de repassar em muitos lugares, e nenhuma aula precisa de um. Este foi escrito para a
aula e não faz nada de nocivo. Ele faz o papel de um script que um cliente mandou ao escritório,
dizendo formatar um relatório. Salve-o no `web` como `relatorio.sh`:

```schooling-example
{"language": "sh", "file": "relatorio.sh", "parts": [{"code": "#!/bin/bash\n# relatorio.sh: says it formats a client's report. Written for this lesson; it harms nothing.\necho \"formatting the report...\"\nls \"$HOME/.ssh\" 2>&1 | head -3\necho \"checked\" 2>&1 > /etc/relatorio-was-here || echo \"could not write to /etc\"\ncurl -s -m 3 http://192.168.60.66:8443/hello || echo \"could not reach 192.168.60.66\"\necho \"done\"", "note": "Três coisas de que um formatador de relatório nunca precisa, cada uma inofensiva aqui: listar os nomes dos arquivos do seu diretório SSH, deixar um arquivo em `/etc` e abrir uma conexão com outra máquina. Cada linha imprime o que aconteceu, para você ver qual delas o isolamento permitiu."}]}
```

Ele lista só os **nomes** do seu diretório SSH, nunca o conteúdo, grava a palavra `checked` e pede ao
`trap` uma página que não existe. Cada uma dessas coisas representa algo que um formatador de
relatório não tem motivo para fazer: procurar chaves, mudar o sistema, falar com uma máquina em outro
lugar.

**Não o rode fora de uma sandbox**, mesmo sabendo que é inofensivo. Esse é o hábito que a aula está
criando: um script desconhecido é aberto primeiro dentro das paredes, toda vez, porque a única vez que
importa é a vez em que você tinha certeza de que não importava.

O que as paredes devem proteger é fácil de dizer no `web`. A sua conta tem um diretório SSH, e o
`/etc` não tem nenhum arquivo chamado `relatorio-was-here`:

```
ana@web:~$ ls ~/.ssh; ls /etc/relatorio-was-here 2>&1
authorized_keys
config
id_ed25519
id_ed25519.pub
ls: cannot access '/etc/relatorio-was-here': No such file or directory
```

Quatro arquivos, o seu par de chaves entre eles: o que o `build` fez para que todas as máquinas
confiem em você. Os nomes deles são exatamente o que o script de um invasor procura primeiro. A
próxima seção roda o script dentro de paredes e compara.
