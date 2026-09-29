---
title: Menor privilégio, e como o acesso cresce
version: 1
---

**Menor privilégio** quer dizer que cada identidade pode fazer o que o trabalho dela precisa e nada ao
lado disso. É um princípio com que todo mundo concorda. O difícil é a ordem em que as pessoas
trabalham: o comum é começar amplo para as coisas funcionarem, com a intenção de apertar depois. O
depois raramente chega, porque uma política que permite demais não produz erro, nem chamado, nem
reclamação. O único momento em que alguém percebe é o dia em que outra pessoa a usa.

Então a ordem é a inversa. Comece do nada, que a negação implícita já dá, e acrescente as ações que
o trabalho mostrar que precisa. Um pedido recusado durante o desenvolvimento é barato: ele diz a
ação que queria, e acrescentá-la é uma linha.

## Uma política para ler com desconfiança

Esta é uma política escrita para um job noturno cuja tarefa inteira é enviar um arquivo de backup
para um bucket. Ela funciona; o job nunca falhou.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
```

Tudo o que há de errado nela está visível em quatro linhas:

- `"Action": "s3:*"` permite toda operação do S3, não só enviar: apagar objetos, apagar buckets e
  reescrever a política de um bucket para que qualquer pessoa na internet possa lê-lo.
- `"Resource": "*"` aplica isso a todo bucket da conta, não ao dos backups. Os relatórios, os uploads
  dos clientes e os logs estão todos no alcance.
- `"Action": "iam:*"` é a pior linha, e nem é sobre armazenamento. **Uma identidade que pode mudar o
  IAM pode dar qualquer coisa a si mesma**: pode anexar uma política de administrador à própria role
  ou criar um usuário novo com chaves. `iam:*` é acesso de administrador com outro nome.
- Não há condição em lugar nenhum, então nada disso depende de onde o pedido vem nem de quando.

O que o job precisa é uma ação, sobre um prefixo, de um bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::example-backups/nightly/*"
    }
  ]
}
```

Se as credenciais desse job vazarem, quem estiver com elas pode gravar arquivos abaixo de `nightly/`
num bucket. Continua sendo um problema, e um bem menor que o da primeira política.

## O que procurar

Ao ler a política de outra pessoa, as linhas em que parar são poucas:

- um `*` sozinho em `Action` ou em `Resource`;
- um serviço inteiro, `s3:*` ou `ec2:*`, onde o trabalho faz uma coisa só nele;
- qualquer coisa em `iam:` dada a uma identidade cujo trabalho não é gerenciar identidades;
- um curinga no meio de um nome, como `s3:Get*`. Parece estreito, porque soa como "só leitura". Ele
  também casa com `s3:GetBucketPolicy` e com toda outra ação `Get` que o S3 tem, inclusive as que o
  provedor acrescentar no ano que vem: um curinga casa com ações que não existiam quando foi escrito.

## Acesso que cresceu e nunca foi removido

A maior parte do acesso em excesso não foi escrita de uma vez. Ela se acumulou. Alguém passou do
time de pagamentos para o de relatórios e ficou com os dois grupos. Um incidente às duas da manhã
precisou de uma permissão ampla por uma hora, e a permissão continua lá dois anos depois. Um serviço
foi aposentado e a role dele manteve todas as permissões, esperando alguém achar as credenciais.

**Nada expira a menos que alguém faça expirar**, então a resposta é um hábito: uma revisão, com data
na agenda. Os provedores ajudam com as evidências. A AWS mostra, para cada identidade, quando cada
serviço foi usado por ela pela última vez, e uma permissão sem uso há meses é uma pergunta a fazer ao
dono. Alguns provedores vão além e conseguem rascunhar uma política mais estreita a partir das
chamadas que uma identidade de fato fez. Seja como for, a revisão é uma pessoa decidindo, e a seção
de auditoria no fim desta aula diz o que ela examina.
