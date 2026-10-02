---
title: Por que o laptop para de aplicar
version: 1
---

A crença comum é que pipeline de Terraform é coisa de time grande, e que para duas pessoas um
`terraform apply` no laptop basta, desde que o código esteja no git. Todas as aulas deste curso até
aqui aplicaram a partir do laptop da Ana, então vale dizer o que esse arranjo esconde antes de
trocá-lo.

Eis o laptop dela numa tarde qualquer. Ela está testando outra faixa para a sub-rede e ainda não
fez commit de nada:

```
ana@laptop:~/shop$ git status --short
 M main.tf
ana@laptop:~/shop$ git diff --stat
 main.tf | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars | grep -E "# aws|forces replacement|Plan:"
  # aws_subnet.a must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.20.3.0/24" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

**O Terraform faz o plan do diretório, não do commit.** Ele lê os arquivos `.tf` que estão no disco
e não faz ideia do que o git acha deles. Se a Ana tivesse digitado `terraform apply` ali, a sub-rede
teria sido destruída e criada de novo por uma mudança que não existe em commit nenhum, em branch
nenhuma, revisada por ninguém. A próxima pessoa a rodar um plan a partir da `main` veria um plan
para voltar a faixa antiga, e teria de descobrir por quê.

A mesma captura mostra o segundo ponto. O diff tem uma linha. O plan diz que uma sub-rede é
destruída e outra criada, com `# forces replacement` ao lado da linha responsável, como a aula 6
explicou. **O diff diz o que alguém quis; o plan diz o que vai acontecer**, e quem revisa só o
primeiro está aprovando o segundo às cegas. No laptop, o plan passa rolando num terminal e some.

O laptop esconde mais três coisas:

| no laptop | num pipeline |
| --- | --- |
| a versão do Terraform que estiver instalada ali | uma versão, escrita no workflow |
| credenciais que mudam produção, em cada laptop que aplica | credenciais de escrita num só lugar, para um só job |
| nenhum registro do que foi aplicado, de qual commit, por quem | um log por execução, ligado a um commit e a uma aprovação |

Então o arranjo que esta aula monta é simples de enunciar: **um só lugar aplica, e aplica só o que
passou por merge e por revisão**. Pessoas continuam escrevendo a mudança e decidindo se ela é
sensata; o pipeline faz a parte mecânica sempre do mesmo jeito, e deixa o plan onde quem revisa
consegue lê-lo.

## Como esta aula roda um pipeline sem serviço de CI

O laboratório não tem GitHub nem GitLab, e nada aqui alcança os dois. Por isso os arquivos de
workflow desta aula são **ilustrativos**: escritos por inteiro, conferidos como YAML válido e nunca
executados. O que eles chamam é um script de shell, o `ci.sh`, e esse script roda de verdade, cada
vez num clone novo dentro de `~/ci/` que faz o papel do runner. Um repositório bare,
`~/git/shop.git`, faz o papel do remoto, e copiar o `tfplan` de um clone para o seguinte faz o
papel do artefato que um job envia e o próximo baixa. A AWS é o moto, como em todas as aulas, e o
state fica no bucket S3 que a aula 7 criou.
