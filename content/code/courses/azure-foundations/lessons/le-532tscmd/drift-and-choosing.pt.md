---
title: Drift, e a escolha de uma porta
version: 1
---

**Declarar a infraestrutura só ajuda enquanto o arquivo e o Azure concordam. No dia em que alguém muda um
recurso por outra porta, eles param de concordar, e essa diferença tem nome: drift.** Nada no Azure
impede isso. Um colega abre uma porta no portal às duas da manhã para parar uma pane, e o arquivo no
repositório continua dizendo que a porta está fechada.

## Como cada ferramenta enxerga o drift

As duas ferramentas acham o drift em lugares diferentes, porque lembram de coisas diferentes:

- **O Terraform guarda um arquivo de estado**, o seu próprio registro de cada recurso que criou e dos
  valores que viu por último. O `terraform plan` atualiza esse registro a partir do Azure, compara os
  três, arquivo, estado e realidade, e propõe devolver a realidade ao que o arquivo diz. Uma mudança
  feita no portal aparece como algo que o Terraform vai desfazer.
- **O Bicep não guarda estado.** A memória dele é a do Resource Manager: o que existe agora. O `what-if`
  compara o template com o que está lá, e uma propriedade mudada no portal aparece como uma que a
  implantação vai modificar de volta.

**De um jeito ou de outro, aplicar o arquivo de novo desfaz a mudança feita à mão**, o que está certo se a
mudança foi um erro e é uma pane se ela foi o conserto. Então uma mudança feita por outra porta numa
emergência precisa ser escrita no arquivo no mesmo dia, e isso é uma regra sobre pessoas, não sobre
ferramentas.

**Nada disso foi executado**: drift precisa de um recurso que exista, e de uma porta que o tenha mudado.

## O que uma implantação faz com o que ela não cita

Uma implantação Bicep ou ARM num grupo de recursos roda num de dois **modos**, e a diferença é o que
acontece com os recursos que o template não cita:

| modo | recursos do grupo que o template não cita |
|---|---|
| incremental, o padrão | deixados como estão |
| completo | apagados |

**O modo completo faz o grupo bater exatamente com o arquivo, e apaga o que alguém tiver acrescentado à
mão**, e é por isso que não é o padrão e que o `what-if` importa mais antes dele. A resposta mais nova
da Microsoft para a mesma necessidade é o **deployment stack**, que lembra dos recursos que implantou e
pode apagar ou desvincular os que saem do arquivo, e pode negar mudanças neles vindas de outras portas.
O Terraform se comporta como um stack por construção: apaga o que sai do arquivo, e só o que ele criou.
**Nenhum destes foi executado aqui.**

## Escolhendo uma porta

Cada porta tem um trabalho que faz melhor:

- **o portal** para olhar: o que existe, quanto custa, o que as métricas dizem, e para aprender quais são
  as configurações de um serviço antes de escrevê-las;
- **a linha de comando** para perguntas e para ações avulsas, e para scripts que colam as outras, como o
  passo que roda uma implantação num pipeline;
- **um arquivo declarativo** para tudo o que ainda deve existir no mês que vem: ele é revisado antes de
  rodar, consegue construir o mesmo ambiente duas vezes, e é o registro de por que as coisas estão como
  estão.

Entre as duas ferramentas declarativas, a escolha é sobretudo sobre o que mais você administra. **O
Bicep é do próprio Azure**: todo tipo de recurso e toda versão nova estão nele no dia em que saem, não há
arquivo de estado para cuidar, e ele não precisa de nada além da CLI do Azure. **O Terraform alcança
outros providers também**, o Entra ID, o GitHub, um DNS fora do Azure, com uma linguagem e um fluxo de
trabalho, ao preço de um arquivo de estado que precisa ser guardado, travado e protegido. Uma equipe que
já escreve Terraform para outros sistemas tem a resposta escolhida por ela.

::: track cloud-engineering
Na sua trilha vem em seguida o `azure-operations`, e as lições 4 a 7 dele levam as duas ferramentas
muito mais longe: módulos, parâmetros, deployment stacks, e o estado do Terraform guardado numa storage
account com trava.
:::

::: track *
Com uma assinatura de verdade, o próximo passo é o que este laboratório não conseguiu dar: rodar o
`what-if` ou o `terraform plan` contra um grupo de recursos vazio, ler cada linha, e só então implantar.
:::
