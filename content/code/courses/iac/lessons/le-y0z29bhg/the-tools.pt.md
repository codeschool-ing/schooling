---
title: As ferramentas, e qual trabalho cada uma faz
version: 1
---

As ferramentas desta área são mais fáceis de distinguir pelo trabalho que fazem e pelo jeito como
são escritas do que pelo marketing. Esta tabela é o mapa que o curso segue, com a aula em que cada
uma é usada:

| ferramenta | trabalho | escrita em | aulas |
|---|---|---|---|
| **Terraform** | provisionamento, qualquer provedor | HCL, a linguagem de configuração própria dele | 2 a 16 |
| **OpenTofu** | o mesmo, um fork do Terraform | HCL | 17, e 12 por um recurso que falta ao Terraform |
| **CloudFormation** | provisionamento, só AWS | templates em YAML ou JSON | 17 |
| **AWS CDK** | provisionamento, só AWS, gerando CloudFormation | TypeScript, Python, Java, C#, Go | 17 |
| **Pulumi** | provisionamento, qualquer provedor | TypeScript, Python, Go, C#, Java | 17 |
| **Ansible** | gerência de configuração, empurrada por SSH | playbooks em YAML | 18 |
| **Chef**, **Puppet**, **Salt** | gerência de configuração, quase sempre por um agente em cada máquina | Ruby, a linguagem do Puppet, YAML | 19 |
| **Packer** | imagens de máquina | HCL | 20 |
| **Checkov**, **Trivy**, **tfsec** | ler uma descrição atrás do que ela expõe | (elas leem as outras) | 14 |

Duas coisas nessa tabela merecem uma frase cada antes de a aula 2 começar.

**O Terraform fica com a maior parte do curso** porque o modelo dele é a régua dos outros: uma descrição, um provider para cada API, um plano que você lê antes de qualquer coisa
acontecer, e um estado que lembra o que foi feito. CloudFormation, Pulumi e o CDK mudam cada um uma
dessas quatro peças, e a aula 17 fica mais clara com as quatro já na mão. Tudo o que você aprende
sobre planos, estado e módulos vale sem mudança para o OpenTofu, porque ele começou como o mesmo
código.

**Um provider é a parte que conhece uma API.** O Terraform em si não sabe nada de AWS; o provider da
AWS, um programa à parte, sabe transformar `resource "aws_vpc"` nas chamadas certas e ler o
resultado de volta. Há providers para toda nuvem grande, para serviços de DNS, para o GitHub, para
sistemas de monitoramento, e para coisas que nem são serviços, como gerar um nome aleatório ou
escrever um arquivo local. A aula 2 encontra quatro deles.

A tabela não tem linha para "a ferramenta que faz bem os dois trabalhos", de propósito.
Uma configuração que funciona usa uma ferramenta das linhas de provisionamento, uma das linhas de
configuração ou o Packer, e uma fronteira clara entre elas, que era o assunto da seção sobre os dois trabalhos.
