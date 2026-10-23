---
title: Segurando um pacote de propósito
version: 1
---

**Às vezes uma atualização não pode ser instalada numa máquina ainda.** A aula 16 chamou isso de
exceção: a atualização quebra algo de que o escritório depende, o fornecedor está trabalhando nisso, e
a máquina tem de ficar na versão antiga até lá. A palavra do apt para isso é **hold**:

```
root@web:~# apt-mark hold jatoba-health; apt-mark showhold
jatoba-health set on hold.
jatoba-health
root@web:~# apt-get -s upgrade 2>&1 | grep -A1 "kept back"
The following packages have been kept back:
  jatoba-health
root@web:~# unattended-upgrade --dry-run --debug 2>&1 | grep -E "^(Packages that will be upgraded|No packages found)"
No packages found that can be upgraded unattended and no pending auto-removals
```

O `apt-mark hold` marca o pacote, e o `showhold` lista o que está segurado. Um upgrade simulado agora o
mantém para trás, e as atualizações automáticas o deixam em paz: o pacote que a simulação da seção
anterior teria atualizado agora nem é candidato. Um hold é respeitado por todo comando do apt que
atualiza, e é isso que o torna a ferramenta certa e também o que o torna perigoso.

## Um hold é invisível a não ser que alguém olhe

Nada reclama de um pacote segurado. Ele não expira, não aparece no e-mail da manhã, e seis meses
depois ninguém lembra por que está ali. **Um hold é a exceção da aula 16 sem o registro**, a não ser
que o registro seja guardado em outro lugar:

| campo | para este hold |
|---|---|
| máquina e pacote | `web`, `jatoba-health` segurado em `1.0` |
| motivo | a `1.1` quebra o job de monitoramento que lê a saída dele; chamado aberto com o fornecedor |
| controle compensatório | o job de monitoramento confere o portal direto até a correção |
| dono | a pessoa responsável pelo `web`, pelo nome |
| validade | uma data; nela o hold é tirado ou a exceção é renovada pelo mesmo dono |

A checagem que mantém os holds honestos é barata: `apt-mark showhold` em cada máquina, comparado com a
lista de exceções. Qualquer coisa segurada sem exceção é um achado, e o inventário da aula 18 é onde
essa comparação é feita de uma vez para o escritório inteiro.

## Segurar não é o único jeito

Um hold congela um pacote no que estiver instalado. O apt também tem **pinning**, um arquivo em
`/etc/apt/preferences.d/` que define prioridades por pacote ou por origem, que pode dizer "nunca acima
de 1.0" ou "prefira o espelho interno". O pinning é mais preciso e mais fácil de esquecer, e para o caso
desta seção, um pacote numa máquina por algumas semanas, um hold com um registro ao lado basta.
