---
title: Três formas de descrever o mesmo bucket
version: 1
---

**O bucket de assets da loja pode ser descrito de três formas, e o bucket é idêntico nas três.** O que
difere é quem age, quando, onde fica o registro do que existe, e o que acontece com uma mudança feita à
mão. Nenhuma das três é a certa em geral; cada uma serve a um time que já trabalha de certo jeito.

| | Terraform, rodado por você (lições 5 e 6) | Infrastructure Manager | Config Connector |
|---|---|---|---|
| a linguagem | HCL | HCL | YAML do Kubernetes |
| quem roda | uma pessoa ou uma esteira | o Google, como conta de serviço | um controlador num cluster do GKE |
| o registro do que existe | um arquivo de estado num bucket que você gerencia | um estado que o Google guarda por deployment | os objetos no cluster |
| a prévia | `terraform plan` | uma prévia guardada | o diff do YAML |
| uma mudança feita à mão | fica até o próximo plano mostrá-la | fica até a próxima revisão | é desfeita |
| quanto custa rodar | os minutos da esteira | a cobrança do Google pelas execuções (não citada neste curso) | o cluster, o tempo todo |
| outras nuvens | a mesma ferramenta, outros providers | só Google | só Google |

Leia ao longo de uma linha em vez de descer uma coluna. As duas últimas linhas costumam ser onde os times
decidem: um time que também roda AWS ou Azure fica com o Terraform porque é a única ferramenta que fala
as três, e um time cujo mundo inteiro é GKE ganha mais com o Config Connector do que com uma segunda
ferramenta e um segundo fluxo de revisão.

## A escolha da loja

A loja fica com o Terraform, rodado pela própria esteira, por três razões que vêm de lições anteriores e não
de preferência. O build dela já roda no Cloud Build (lição 1), então um passo de Terraform não custa nada
novo para operar. O estado dela está protegido por versionamento e trava (lição 6), e ela ensaiou a
restauração. E ela roda no Cloud Run, não no GKE, então o Config Connector significaria rodar um cluster só
para guardar descrições de buckets.

**O Infrastructure Manager é o passo que ela daria em seguida**, quando a conta de serviço da esteira ficar
ampla demais para ser confortável: levar o apply para um deployment com uma conta própria e estreita tira
da esteira a necessidade de ter permissões de infraestrutura, e a configuração não muda.

## O que não fazer

Não descreva um recurso em duas delas ao mesmo tempo. Um bucket no Terraform e no Config Connector é um
bucket com dois donos: o controlador desfaz as mudanças do Terraform, o próximo plano propõe desfazer as do
controlador, e cada apply parece ter funcionado. Escolha um dono por recurso, e quando um recurso muda de
um para o outro, tire-o do primeiro (`terraform state rm`, ou a anotação `abandon`) antes de o segundo
adotá-lo.
