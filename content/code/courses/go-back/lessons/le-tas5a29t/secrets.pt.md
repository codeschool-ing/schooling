---
title: Segredos não são flags
version: 1
---

Um token, uma senha ou uma URL de banco com senha dentro também são configuração, e variam entre ambientes
como o resto. **De onde vêm importa mais do que para qualquer outra coisa**, por causa de quem mais na
máquina consegue ler cada fonte. Inicie o `knobs` com um token no ambiente e uma senha como argumento, e
olhe para ele de outro terminal enquanto roda, primeiro como o usuário `nobody`, que não tem nada a ver com
isso:

```
ana@vm:~/knobs$ sudo -u nobody ps -o user=,args= -C knobs
ana      ./knobs -wait 3s -addr localhost:8080 hunter2
```

**Todo usuário da máquina lê a linha de comando de todo processo**, pelo `ps` ou pelo `/proc`. Uma flag como
`-token=…` fica publicada para todos eles enquanto o processo roda, e ainda vai parar no histórico do
shell. Por isso segredos nunca vêm de flags, e o boxoffice não declara flag para nenhum.

```
ana@vm:~/knobs$ sudo -u nobody cat /proc/$(pgrep -x knobs)/environ
cat: /proc/26459/environ: Permission denied
```

**O ambiente é privado do dono do processo e do root**, então o `nobody` é recusado. A própria Ana consegue
lê-lo:

```
ana@vm:~/knobs$ tr '\0' '\n' < /proc/$(pgrep -x knobs)/environ | grep TOKEN
BOXOFFICE_MANAGER_TOKEN=3f9c1e7a2b8d4f60
```

Isso é melhor que uma flag e ainda não é à prova de vazamento. Uma variável exportada chega a todo programa
que o dono inicia, como a seção 04 mostrou, inclusive os que não têm uso para ela; uma página de depuração
ou um relatório de falha que imprime o ambiente imprime o segredo; e os tokens que você exporta desde a
aula 2, guardados no `~/.profile` ao lado do `DATABASE_URL` da aula 6, estão em todo terminal que você abre.

## Um arquivo só dele

O passo seguinte é um arquivo que guarda só o segredo, legível só pelo dono, com a variável guardando o
caminho do arquivo em vez do segredo. A convenção é uma variável com `_FILE` no fim do nome: a imagem
oficial de container do PostgreSQL lê `POSTGRES_PASSWORD_FILE`, por exemplo. Ela combina com o jeito como
as plataformas entregam segredos: o Docker e o Kubernetes conseguem montar segredos num container como
arquivos, e só os processos que abrem o arquivo os veem.

O boxoffice lê `BOXOFFICE_MANAGER_TOKEN`, `BOXOFFICE_DOOR_TOKEN` e `DATABASE_URL` da variável ou do arquivo
que o `…_FILE` indica. A seção 08 tira os tokens do `~/.profile` e os põe em arquivos.

## O que não fazer com um

- **Nunca faça commit de um.** Um segredo num repositório fica no histórico depois de apagado, e em todo
  clone. Arquivos que guardam segredos, como os `.env`, vão no `.gitignore`.
- **Nunca registre um no log.** A seção 07 dá ao boxoffice um tipo cuja saída no log é `[hidden]`, a mesma
  ideia do `email` da aula 12.
- **Deixe-os fáceis de trocar.** Um token lido de um arquivo na inicialização é trocado escrevendo o arquivo
  e reiniciando, coisa que ninguém precisa adiar.

O seu `DATABASE_URL` local conecta por um socket sem senha, e é por isso que a aula 6 pôde colocá-lo no
`~/.profile`. Uma URL de banco de produção leva senha e ganha um arquivo.
