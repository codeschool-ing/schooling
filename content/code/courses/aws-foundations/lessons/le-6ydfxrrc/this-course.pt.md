---
title: O que é este curso, e a AWS contra a qual ele roda
version: 1
---

Este curso é o térreo da AWS: **como as contas se organizam, quem pode fazer o quê nelas, o que a
fatura diz e como um pacote vai de um lugar a outro**. Ele pressupõe o curso `cloud`, ou o que ele
ensina, então região, máquina virtual e política de acesso já são palavras que você tem. O que este
curso acrescenta é o jeito como a AWS em particular constrói essas coisas, com os nomes que a
documentação dela, a linha de comando e os anúncios de vaga usam.

Vinte e seis lições, em quatro partes:

| lições | o que cobrem |
|---|---|
| 1 a 5 | onde as coisas ficam, e as contas que as guardam: regiões, a conta, o AWS Organizations, as service control policies, a landing zone |
| 6 a 12 | identidade: principais, políticas, como uma requisição é julgada, roles, credenciais para máquinas, login único e chaves de acesso |
| 13 a 15 | dinheiro: orçamentos e tags, como ler uma fatura, e o relatório que diz quem gastou o quê |
| 16 a 26 | a rede, e as ferramentas: VPCs, rotas, filtros, endpoints, peering, DNS, balanceadores de carga, CloudFront, o caminho vindo de um datacenter, a linha de comando e a API por baixo dela |

## Nenhuma conta AWS

**Nada neste curso exige uma conta AWS, um cartão ou uma chave.** Uma conta custa dinheiro no
momento em que algo fica ligado, e uma lição gravada contra uma conta seria o registro de uma tarde
nela. Então a AWS com que cada lição conversa é o **moto**: um programa de código aberto, escrito em
Python, que responde à API da AWS numa porta do seu próprio computador. Você o roda num terminal e
usa a linha de comando real da AWS em outro. A linha de comando não percebe a diferença; ela envia
as mesmas requisições assinadas que enviaria à AWS, e o moto responde no formato da própria AWS.

O mesmo arranjo serve aos três cursos de AWS que vêm depois deste, `aws-compute`, `aws-operations`
e `aws-data`. Esta lição o monta uma vez, e cada um daqueles cursos começa conferindo se o seu
ainda responde.

::: track cloud-engineering
Na sua trilha vêm a seguir `aws-compute` e `aws-operations`, e os dois rodam contra o laboratório
que você monta aqui. Guarde o `~/aws` ao terminar: o próximo curso o confere em vez de montá-lo de
novo.
:::

::: track data
Na sua trilha vem a seguir `aws-data`, e ele roda contra o laboratório que você monta aqui. Guarde o
`~/aws` ao terminar: aquele curso o confere em vez de montá-lo de novo.
:::

::: track devops
Na sua trilha este é o único curso de AWS, então ele precisa se sustentar sozinho, e se sustenta:
nada nele espera um curso posterior para ser explicado.
:::

::: track *
Se você seguir para `aws-compute`, `aws-operations` ou `aws-data`, cada um roda contra o
laboratório que você monta aqui. Guarde o `~/aws` ao terminar, e eles vão conferi-lo em vez de
montá-lo de novo.
:::

## O que o moto não é

O moto responde como a AWS e **aplica muito menos regras do que a AWS aplica**, e um curso que
escondesse isso ensinaria a coisa errada. Quatro diferenças importam aqui, e as lições que as
encontram voltam a dizê-lo:

- **Ele não julga permissões, a menos que você peça.** De saída, toda chamada dá certo, até uma que
  uma política deveria negar. A lição 7 liga a verificação do moto, e dali em diante um usuário sem
  permissão é recusado. O que o moto verifica são as políticas do próprio usuário, a política de
  confiança de uma role e um deny explícito. Ele **não** verifica permission boundaries, service
  control policies, session policies nem a política do próprio bucket além dos objetos, e trata toda condição de uma
  política como atendida. As lições 4 e 8 ensinam essas pela documentação da AWS e dizem quais
  linhas não foram rodadas.
- **Ele não carrega tráfego.** Uma VPC no moto é um registro com um id e uma faixa CIDR. Um security
  group guarda as regras e não filtra nada, porque nada passa. As lições 16 a 24 montam a rede de
  verdade, como configuração, e raciocinam sobre os pacotes em vez de enviá-los.
- **Ele não envia fatura e não conhece preço.** Cada preço destas lições vem da **lista pública de
  preços da AWS**, um conjunto de arquivos JSON que qualquer pessoa pode baixar, lido por um programa
  curto que a última seção desta lição mostra. Cada preço vem com a data da lista de onde saiu.
- **Ele não tem console.** Não há o que capturar em tela, e uma imitação desenhada do console da AWS
  seria uma falsificação. Onde o console importa, a lição diz em palavras o que você vai encontrar
  lá.

Onde o moto não consegue mostrar o que a AWS faz, a lição ensina o comportamento pela documentação
da AWS e **diz claramente que essa parte não foi rodada**. Todo o resto, cada comando e cada linha
de saída num terminal, foi rodado num laboratório montado exatamente do jeito que as próximas três
seções mandam você montar o seu. O prompt diz `ana@laptop:~/aws$`.

## Uma conta real, se você quiser

Você nunca precisa de uma aqui. Se quiser testar o que aprendeu na própria AWS, a seção **"Uma conta
real, e a ordem em que protegê-la"**, mais adiante, diz como abrir uma com segurança. Ela põe a proteção da conta
antes de qualquer outra coisa, por um motivo: a primeira hora de uma conta nova é quando protegê-la
custa menos e deixá-la aberta custa mais.
