---
title: Trabalhando no laboratório, aula após aula
version: 1
---

**As quatro variáveis `AWS_` são o truque inteiro**, as quatro que o `env` listou no fim da seção
anterior, e são o motivo de os arquivos do Terraform destas aulas parecerem exatamente os de uma
conta real. `AWS_ENDPOINT_URL` manda toda chamada que o AWS CLI e o provider da AWS fazem para o moto,
e não para a Amazon. O par de chaves é a palavra `test`, que o moto aceita e a AWS recusaria; então um
deslize que mande uma chamada para a AWS de verdade falha, em vez de fazer alguma coisa. A região é
São Paulo. A conta como a qual o moto responde, `123456789012`, é a de exemplo que a própria AWS usa
na documentação, e ela aparece em nomes de buckets em aulas posteriores.

## Um laboratório novo a cada aula

**Cada aula foi gravada com um moto vazio e um diretório pessoal vazio**, e as transcrições dela só
batem se a sua começar do mesmo jeito. O moto esquece tudo quando para, então esvaziá-lo é apertar
Ctrl+C no terminal dele e iniciá-lo de novo. Os arquivos são tarefa deste script curto; salve-o como
`fresh-lesson.sh`:

```sh
#!/bin/sh
# ~/fresh-lesson.sh: move aside what the last lesson left in your home
# directory, so the next one starts as empty as it was recorded.
set -e
cd ~
aside=lessons-done/$(date +%Y%m%d-%H%M%S)
mkdir -p "$aside"
for f in *; do
  case $f in
    iac-venv|lessons-done|setup-iac.sh|iac-env.sh|fresh-lesson.sh) ;;
    *) mv "$f" "$aside/" ;;
  esac
done
echo "moved aside: $(ls "$aside" | tr '\n' ' ')"
```

Ele move em vez de apagar, porque os arquivos da aula anterior são seus e talvez você queira lê-los de
novo. Então o começo de toda aula são os mesmos dois passos:

```
ana@laptop:~$ sh ~/fresh-lesson.sh
moved aside: lookup shop shop-tf 
ana@laptop:~$ ls
fresh-lesson.sh  iac-env.sh  iac-venv  lessons-done  setup-iac.sh
```

Numa máquina virtual há um segundo jeito: tire um snapshot logo depois de montar o laboratório e volte
a ele no começo de cada aula. Uma aula que precisa de algo que uma anterior criou diz isso e dá os
comandos que o criam de novo.

**Três hábitos que as transcrições dão por certos:**

- **`terraform init` em todo diretório novo**, antes do primeiro `plan`. As aulas o mostram quando
  ele diz algo que vale ler, e não toda vez.
- **As aulas que mostram `git diff` guardam a configuração no Git**, e fazem commit onde o texto diz
  que a Ana fez. Diga ao Git o seu nome uma vez, com `git config --global user.name "Seu Nome"` e o
  mesmo com `user.email`, ou o primeiro commit é recusado; e `git config --global init.defaultBranch main`,
  o nome de ramo que as transcrições mostram, onde o Git do Ubuntu diria `master`.
- **Os ids são diferentes a cada execução.** A AWS inventa ids `vpc-…` e `sg-…`, e o moto também,
  então os seus nunca vão bater com a página; todo o resto deve bater.

## Onde a sua tela difere da página, e por quê

As aulas foram gravadas numa máquina **sem acesso à internet**, e quatro coisas na página vêm disso e
não do Terraform:

- **Os providers vieram de uma cópia local.** Foram baixados do site de releases da HashiCorp,
  conferidos contra os checksums que ela publica e servidos a partir de um diretório. Onde o
  `terraform init` imprime `(unauthenticated)`, o seu imprime que o provider é assinado pela
  HashiCorp, e o arquivo de lock que ele escreve tem mais linhas do que a página mostra. A aula 2
  mostra esse arquivo.
- **Duas transcrições mostram o Terraform Registry sem responder**, nas aulas 10 e 17. O seu vai
  baixar o que elas não conseguiram.
- **Dois scanners imprimem uma reclamação sobre a rede** na aula 14, e os seus não vão imprimir.
- **Algumas ferramentas foram compiladas a partir do código-fonte**, porque os downloads delas ficam
  num site que a máquina de gravação não alcançava. Você instala os programas publicados, e cada aula
  que precisa de um diz como.

As outras ferramentas chegam na aula que as usa primeiro, e cada uma dessas aulas começa dizendo como
instalá-las:

| aula | ferramentas |
|---|---|
| 11 | Terragrunt |
| 12 | OpenTofu |
| 14 | Checkov, Trivy, tfsec |
| 17 | Node.js e o AWS CDK |
| 18 | Docker e Ansible |
| 19 | Puppet e Salt |
| 20 | Packer e o plugin Docker dele |

**E quando você passar para uma conta real**, as configurações funcionam como estão, com duas
exceções. As imagens de máquina de exemplo do moto têm ids que a AWS não tem, e um nome de bucket na
AWS precisa ser único entre todas as contas do mundo; as aulas apontam as duas onde aparecem.
Rode `unset AWS_ENDPOINT_URL`, configure credenciais reais com `aws configure` e lembre que, a partir
daí, todo `apply` cria algo que custa dinheiro até um `destroy` removê-lo.
