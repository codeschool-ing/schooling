---
title: O macOS, e os três lado a lado
version: 1
---

**O macOS usa os dois modelos.** Por baixo ele é Unix: todo arquivo tem um dono, um grupo e as nove
letras da seção 01, e o `ls -l` do Terminal as mostra exatamente como no Linux. **Por cima, ele aceita
ACLs** no estilo do Windows, que o *Obter Informações > Compartilhamento e Permissões* do Finder edita
quando você acrescenta uma pessoa pelo nome.

```sh
ls -le ~/Shared                       # -e adds the ACL entries under each line
chmod +a "bruno allow read" plan.txt  # add an entry, as on Windows
```

**Nenhum dos dois foi rodado para esta aula.** O `ls -le` lista as entradas de ACL embaixo de cada
arquivo que tem alguma; a maioria dos arquivos não tem nenhuma.

## Um terceiro tipo de permissão

Um Mac acrescenta algo que os outros não têm da mesma forma: **permissões de privacidade**. Mesmo com
todas as permissões Unix num arquivo, um app não consegue ler a pasta Documentos, a câmera ou o disco
inteiro até a pessoa permitir em *Ajustes do Sistema > Privacidade e Segurança*. Um programa de backup
que "não enxerga alguns arquivos" num Mac em geral precisa de **Acesso Total ao Disco** ali, diga o que
disser o `ls -l`.

## Lado a lado

| | Linux | Windows | macOS |
|---|---|---|---|
| modelo básico | dono, grupo, outros | lista de controle de acesso | dono, grupo, outros |
| listas de entradas nomeadas | opcional (ACLs) | sempre | opcional (ACLs) |
| uma regra de negação | não | sim | sim, nas ACLs |
| herdado da pasta | quase nada: a umask decide | sim | o grupo da pasta, e as entradas de ACL |
| para vê-las | `ls -l` | aba *Segurança*, `icacls` | `ls -le`, *Obter Informações* |
| quem pode mudar donos | root | administradores | root |

O hábito que vale nos três: **dê permissão a grupos, não a pessoas**. Um grupo com o nome de uma função,
*accounts*, sobrevive ao dia em que alguém muda de função; uma permissão dada a uma pessoa tem de ser
achada e removida à mão.
