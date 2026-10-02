---
title: Salvar um plano, e aplicar exatamente esse plano
version: 1
---

Todo plano deste curso que não foi salvo terminou com a mesma nota, e vale levá-la ao pé da letra:
sem `-out`, o Terraform "can't guarantee to take exactly these actions", não garante executar
exatamente essas ações se você rodar o `apply` agora. **O plano que você lê e o plano que o `apply`
executa são dois cálculos diferentes.** O `terraform apply` sem argumento planeja de novo do zero,
e qualquer coisa que tenha mudado no meio, o apply de um colega, uma edição manual no console, a
mudança de outro branch, muda o que ele faz. A pergunta que ele faz mostra o plano novo, mas o que
você revisou foi o antigo.

O `-out` grava o plano num arquivo:

```
ana@laptop:~/shop$ terraform plan -out=tfplan | tail -n 6
─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
```

O `terraform show` imprime um plano salvo de novo, no mesmo formato do `terraform plan`, e é assim
que um revisor o lê sem rodar um plano próprio:

```
ana@laptop:~/shop$ terraform show tfplan | tail -n 3
    }

Plan: 4 to add, 1 to change, 2 to destroy.
```

O arquivo é um zip, e o conteúdo dele diz para que serve:

```
ana@laptop:~/shop$ unzip -l tfplan
Archive:  tfplan
  Length      Date    Time    Name
---------  ---------- -----   ----
    13818  2026-10-02 07:26   tfplan
    16522  2026-10-02 07:26   tfstate
    15677  2026-10-02 07:26   tfstate-prev
     1846  2026-10-02 07:26   tfconfig/m-/main.tf
      199  2026-10-02 07:26   tfconfig/m-/versions.tf
       41  2026-10-02 07:26   tfconfig/modules.json
      459  2026-10-02 07:26   .terraform.lock.hcl
---------                     -------
    48562                     7 files
```

Além do plano propriamente dito, estão ali o estado sobre o qual ele foi calculado, o estado como
estava antes do refresh, uma cópia da configuração e o lock file. **Um plano salvo é um retrato de
tudo o que o decidiu**, e é por isso que ele pode ser aplicado mais tarde em outra máquina, e por
isso que deve ser tratado como o estado: qualquer segredo que esteja no estado está aqui também. O
`.gitignore` da Ana deixa `tfplan*` fora do git por esse motivo.

## Um plano que ficou desatualizado

A Ana salva o plano no branch dela, `change`, para um colega revisar. Enquanto ele espera, surge
algo urgente: a VPC precisa de uma tag `Owner` hoje. Ela faz essa mudança num branch só dela,
`hotfix`, e aplica na hora:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 5c3e89a..22dfa0d 100644
--- a/main.tf
+++ b/main.tf
@@ -4,7 +4,7 @@ provider "aws" {
 
 resource "aws_vpc" "shop" {
   cidr_block = "10.20.0.0/16"
-  tags       = { Name = "shop" }
+  tags       = { Name = "shop", Owner = "ana" }
 }
 
 resource "aws_subnet" "a" {
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 3
aws_vpc.shop: Modifications complete after 0s [id=vpc-bf1e4c53969619f51]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

Na manhã seguinte a revisão está feita, e ela volta ao `change` para aplicar o plano aprovado:

```
ana@laptop:~/shop$ git log --format=%s -1
shop: public subnet, new image, assets bucket
ana@laptop:~/shop$ terraform apply tfplan
╷
│ Error: Saved plan is stale
│ 
│ The given plan file can no longer be applied because the state was changed
│ by another operation after the plan was created.
╵
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois branches e um arquivo de estado. No branch change, a Ana salva um plan, que registra o estado sobre o qual foi calculado, e o plan vai para revisão. Enquanto isso um hotfix em outro branch é aplicado e grava o arquivo de estado. Quando a Ana aplica o plan salvo, a cópia do estado dentro dele e o arquivo já não batem, e o Terraform o recusa como stale.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"st-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">terraform plan -out=tfplan</text><text x=\"120.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guarda uma cópia do estado</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">em revisão</text><rect x=\"500\" y=\"30\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">terraform apply tfplan</text><text x=\"600.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado: o plan está stale</text><path d=\"M222 60 L266 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-wire)\"></path><path d=\"M452 60 L496 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-wire)\"></path><text x=\"20.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">terraform.tfstate</text><path d=\"M140 135 L700 135\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120 92 L120 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"130.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">lido</text><path d=\"M360 186 L360 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"370.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">gravado</text><path d=\"M600 128 L600 94\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"610.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">comparado</text><rect x=\"260\" y=\"188\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um hotfix, em outro branch</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">terraform apply</text><text x=\"600.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">os dois já não batem</text></svg>", "caption": "Um plan salvo carrega o estado sobre o qual foi calculado. Qualquer apply no meio o deixa stale, e o Terraform o recusa em vez de adivinhar."}
```

A recusa vem do estado que o plano carrega. O Terraform aumenta o `serial` de um arquivo de estado
toda vez que grava uma mudança nele, e a cópia dentro do `tfplan` é mais velha que o arquivo no
disco:

```
ana@laptop:~/shop$ unzip -p tfplan tfstate | jq .serial
9
ana@laptop:~/shop$ jq .serial terraform.tfstate
11
```

**O Terraform não aplica um plano calculado sobre um estado que já não existe**, porque não tem como
saber se o plano ainda quer dizer o que o revisor leu. Aqui o plano antigo é anterior à tag
`Owner`; aplicado mesmo assim, teria sido a revisão de uma mudança e o apply de outra. A saída é a
honesta: atualizar o branch, planejar de novo e mandar o plano novo para revisão de novo.

```
ana@laptop:~/shop$ git log --format=%s -2
shop: public subnet, new image, assets bucket
tag the VPC with its owner
ana@laptop:~/shop$ terraform plan -out=tfplan | tail -n 6
─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
```

## Aplicando

Um plano salvo é aplicado pelo nome, e **o `apply` não faz a pergunta**. A revisão foi a pergunta,
então ele vai direto ao trabalho:

```
ana@laptop:~/shop$ terraform apply tfplan
random_password.db: Creating...
random_password.db: Creation complete after 0s [id=none]
aws_subnet.b: Destroying... [id=subnet-47480a1b8bee893f8]
aws_instance.web: Destroying... [id=i-43f242be6e5a6202f]
aws_s3_bucket.assets: Creating...
aws_subnet.b: Destruction complete after 0s
aws_s3_bucket.assets: Creation complete after 0s [id=shop-assets-f49cbf8abcb1f97a65245f1ee3]
data.aws_iam_policy_document.assets_read: Reading...
data.aws_iam_policy_document.assets_read: Read complete after 0s [id=2811800691]
aws_iam_role_policy.web_assets: Creating...
aws_iam_role_policy.web_assets: Creation complete after 0s [id=web:assets-read]
aws_instance.web: Still destroying... [id=i-43f242be6e5a6202f, 00m10s elapsed]
aws_instance.web: Destruction complete after 10s
aws_subnet.a: Modifying... [id=subnet-d072b899e3e7150dc]
aws_subnet.a: Modifications complete after 0s [id=subnet-d072b899e3e7150dc]
aws_instance.web: Creating...
aws_instance.web: Still creating... [00m10s elapsed]
aws_instance.web: Creation complete after 10s [id=i-b00516cf21bf483a2]

Apply complete! Resources: 4 added, 1 changed, 2 destroyed.
```

As contagens da última linha são as que o revisor viu, e é exatamente em torno disso que a aula 15
monta um pipeline: planejar uma vez, revisar esse arquivo, aplicar esse arquivo.
