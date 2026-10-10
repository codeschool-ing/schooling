---
title: As ferramentas que fazem isso em escala
version: 1
---

O `provision.sh` tem umas sessenta linhas e monta um tipo de servidor. É o tamanho certo para
aprender a ideia, e é o tamanho a partir do qual escrever o seu próprio deixa de compensar. Em
algum ponto depois de um punhado de máquinas, ou de um segundo tipo de servidor, as conferências
viram a maior parte do código, e o script de cada equipe ganha os mesmos recursos, malfeitos. Duas
ferramentas são o que a maioria das equipes usa no lugar, uma para servidores que você opera e uma
para serviços que outra pessoa opera. Nenhuma das duas roda neste curso; esta seção dá os nomes
para você reconhecer o que está vendo, e a configuração abaixo não foi executada aqui.

## Ansible, para servidores em que você entra

O **Ansible** faz o que o `provision.sh` faz, por SSH, numa lista de máquinas ao mesmo tempo. Cada
passo é uma **task** que chama um **módulo**, e todo módulo é escrito para conferir antes de agir,
então um playbook é idempotente sem ninguém escrever `cmp -s` à mão. A saída dele é a mesma
promessa do script: cada task relata `ok` quando nada precisava ser feito e `changed` quando algo
foi, e uma segunda execução que relata um `changed` é o mesmo aviso de antes.

Os módulos para PostgreSQL ficam numa coleção chamada `community.postgresql`: `postgresql_db`,
`postgresql_user`, `postgresql_pg_hba` e `postgresql_set`, entre outros. Uma task, para dar ideia
do formato:

```yaml
- name: work_mem for the shop's nightly report
  community.postgresql.postgresql_set:
    name: work_mem
    value: 32MB
  become: true
  become_user: postgres
```

**Leia o que um módulo faz antes de confiar um arquivo a ele.** O `postgresql_set` trabalha pelo
`ALTER SYSTEM`, então com ele o arquivo gerenciado é o `postgresql.auto.conf`, e não um arquivo em
`conf.d`. Os dois arranjos são sólidos. Misturá-los não é: se o Ansible é dono do
`postgresql.auto.conf`, uma pessoa rodando `ALTER SYSTEM` à mão está editando o arquivo da
ferramenta, e a próxima execução o toma de volta.

## Terraform, para um serviço gerenciado

Um serviço gerenciado não tem shell nem `conf.d` (lição 3). Os parâmetros dele são um formulário no
console do provedor, e um formulário editado à mão se desvia exatamente como um arquivo editado à
mão. O **Terraform** descreve o próprio serviço como código: a instância, o tamanho, a versão e os
parâmetros, cada um como um recurso num arquivo sob controle de versão. Na AWS, os parâmetros de um
RDS PostgreSQL são um **parameter group**:

```hcl
resource "aws_db_parameter_group" "shop" {
  name   = "shop-pg16"
  family = "postgres16"

  parameter {
    name  = "work_mem"
    value = "32768"
  }
}
```

O valor está em kilobytes, porque é o que o serviço espera; a lista de parâmetros do provedor diz a
unidade de cada um. O Google Cloud SQL chama a mesma coisa de `database_flags` na instância, e o
Azure tem um recurso por parâmetro. O `terraform plan` compara o que os arquivos dizem com o que o
provedor relata, e lista toda diferença antes de mudar qualquer coisa — a versão para serviço
gerenciado do `diff` contra o repositório.

## O que não muda com a ferramenta

Seja o que for que escreve a configuração, os três hábitos desta lição continuam os mesmos. **Uma
fonte**, num repositório, com um motivo em cada mudança. **O servidor feito a partir dela**, por
algo que pode rodar de novo com segurança. **O servidor em execução conferido contra ela**, com o
`pg_settings` para o que está aplicado, o `pg_file_settings` para o que os arquivos dizem e o
`\drds` para o que mora no catálogo — nenhum dos quais sabe ou se importa com qual ferramenta
escreveu.
