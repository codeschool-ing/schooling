---
title: O que é este curso, e o Google Cloud contra o qual ele roda
version: 1
---

Este curso é o térreo do Google Cloud: **como o ambiente se organiza, quem pode fazer o quê nele, o
que diz a fatura e como um pacote vai de um lugar a outro**. Ele parte do curso `cloud`, ou do que
ele ensina, então região, máquina virtual e política de acesso já são palavras que você tem. O que
este curso acrescenta é o jeito como o Google Cloud em particular constrói essas coisas, com os nomes
que a documentação, a linha de comando e os anúncios de vaga dele usam.

Vinte e seis lições, em quatro partes:

| lições | o que cobrem |
|---|---|
| 1 a 4 | onde as coisas ficam, e o que as contém: regiões e zonas, a hierarquia de recursos, projetos, políticas da organização |
| 5 a 10 | identidade: principals, papéis, como um pedido é julgado, contas de serviço, federação sem chave, o diretório por trás de tudo |
| 11 a 14 | dinheiro: contas de faturamento, orçamentos, a leitura de uma fatura, e a exportação que diz quem gastou o quê |
| 15 a 26 | a rede, e as ferramentas: a VPC, regras de firewall, rotas e NAT, rede compartilhada, DNS, balanceadores de carga, o caminho a partir de um datacenter, a linha de comando, o Cloud Shell, a API embaixo de tudo, o inventário, e os três jeitos de dirigir uma mesma API |

## Nenhuma conta do Google

**Nada neste curso exige conta no Google Cloud, cartão ou credencial.** Uma conta custa dinheiro no
instante em que algo fica ligado, e uma lição gravada contra uma conta seria o registro de uma tarde
nela. Então as lições rodam contra o que o próprio Google publica para trabalhar sem conta:

- **a Google Cloud CLI**, o `gcloud`, o programa de verdade, versão 589.0.0;
- **o emulador do Pub/Sub**, que o Google distribui como parte dessa CLI: um programa no seu próprio
  computador que responde à API do Pub/Sub do jeito que o serviço responde;
- **o Terraform**, com o provider do próprio Google, que lê a descrição de um ambiente e diz, sem
  tocar em nada, exatamente o que pediria ao Google para criar.

O mesmo arranjo serve aos três cursos de Google Cloud que vêm depois deste, `gcp-compute`,
`gcp-operations` e `gcp-data`. Esta lição o monta uma vez, e cada um desses cursos começa conferindo
que o seu ainda responde.

::: track cloud-engineering
Na sua trilha vêm a seguir o `gcp-compute` e o `gcp-operations`, e os dois rodam contra o
laboratório que você monta aqui. Guarde o `~/gcp` ao terminar: o próximo curso o confere em vez de
montá-lo de novo.
:::

::: track data
Na sua trilha vem a seguir o `gcp-data`, e ele roda contra o laboratório que você monta aqui. Guarde
o `~/gcp` ao terminar: esse curso o confere em vez de montá-lo de novo.
:::

::: track devops
Na sua trilha este é o único curso de Google Cloud, então ele precisa se sustentar sozinho, e se
sustenta: nada nele espera um curso posterior para ser explicado.
:::

::: track *
Se você seguir para o `gcp-compute`, o `gcp-operations` ou o `gcp-data`, cada um roda contra o
laboratório que você monta aqui. Guarde o `~/gcp` ao terminar, e eles o conferem em vez de montá-lo
de novo.
:::

## O que o laboratório não consegue fazer

**A maior parte do Google Cloud não tem emulador**, e um curso que escondesse isso ensinaria a coisa
errada. O Google publica emuladores para um punhado de serviços de dados, entre eles o Pub/Sub. Não
publica nenhum para a parte de que este curso trata: projetos, pastas e organizações, IAM,
faturamento, redes, DNS, balanceadores de carga. Nada no seu computador consegue responder a um
`gcloud projects create` como o Google responderia, e este curso não vai fingir que algo consegue.
Então as lições trabalham em três registros, e cada seção diz em qual está:

- **Rodado.** Todo comando num bloco de terminal foi digitado num laboratório montado exatamente como
  as três próximas seções mandam você montar o seu, e a saída está colada como a máquina imprimiu. O
  prompt é `ana@laptop:~/gcp$`. O que roda é o próprio `gcloud`, o emulador, o Terraform e os seus
  planos, e a API real do Google recusando um pedido sem credencial verdadeira, o que ela faz com as
  próprias palavras.
- **Planejado.** O provider do Google para o Terraform conhece todo campo de todo recurso que este
  curso encontra, e o `terraform plan` confere uma descrição contra todos eles sem falar com o Google.
  Um plano é uma resposta real de um programa real. **Não é a resposta do Google**: um plano que passa
  ainda pode ser recusado por uma política da organização, uma cota ou uma permissão faltando, e as
  lições dizem onde.
- **Lido.** O que nenhum dos dois consegue mostrar é ensinado pela documentação do Google, e **a seção
  diz com todas as letras que essa parte não foi rodada**. Não há transcrição nela, nem saída
  inventada para preencher uma.

**Também não há console neste curso.** Nem capturas de tela dele, nem desenho de um: o console é
redesenhado no calendário do Google, e uma imitação dele seria falsa. Onde o console importa, a lição
diz em palavras o que você vai encontrar lá.

## Uma conta real, se você quiser uma

Você nunca precisa de uma aqui. Se quiser experimentar o que aprendeu contra o próprio Google Cloud, a
seção **"Uma conta real, e a ordem para protegê-la"**, mais abaixo, diz como abrir uma com segurança.
Ela põe a proteção da conta antes de tudo, por um motivo: a primeira hora de uma conta nova é quando
protegê-la custa menos e deixá-la aberta custa mais.
