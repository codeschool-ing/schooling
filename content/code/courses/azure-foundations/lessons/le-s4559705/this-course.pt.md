---
title: O que é este curso, e o Azure contra o qual ele roda
version: 1
---

Este curso é o térreo do Azure: **como um tenant se divide, quem pode fazer o quê dentro dele, o que
a fatura diz e como um pacote vai de um lugar a outro**. Ele pressupõe o curso `cloud`, ou o que ele
ensina, então região, máquina virtual e política de acesso já são palavras que você tem. O que este
curso acrescenta é o jeito como a Microsoft em particular constrói essas coisas, com os nomes que a
documentação, a linha de comando e os anúncios de vaga dela usam.

Vinte e seis lições, em quatro partes:

| lições | o que cobrem |
|---|---|
| 1 a 5 | onde as coisas ficam, e os contêineres que as guardam: regiões, o tenant e a sua hierarquia, mover recursos, Azure Policy, landing zones |
| 6 a 12 | identidade: Microsoft Entra ID, service principals, identidades gerenciadas, acesso baseado em papéis, elevação sob demanda, acesso condicional, e a ponte com o diretório próprio de um escritório |
| 13 a 15 | dinheiro: orçamentos, leitura de fatura, e tags que dizem quem gastou o quê |
| 16 a 26 | a rede, e as ferramentas: redes virtuais, filtros, rotas, private endpoints, peering, DNS, balanceadores de carga, o caminho a partir de um datacenter, a linha de comando e a API por baixo dela |

## Nenhuma conta do Azure, e nada fingindo ser uma

**Nada neste curso precisa de uma conta do Azure, de um cartão ou de uma chave.** Uma conta custa
dinheiro no momento em que alguma coisa fica ligada, e uma lição gravada contra uma conta seria o
registro de uma tarde nela. Então o curso é construído com o que roda no seu próprio computador sem
conta nenhuma.

Isso é menos do que você talvez esperasse, e é melhor saber agora. **Nenhum programa imita o Azure
Resource Manager**, o serviço por onde passa todo pedido para criar, mudar ou apagar alguma coisa no
Azure. A Microsoft publica emuladores para alguns serviços de dados, e o curso `azure-data` os usa;
para assinaturas, identidades, permissões, redes e faturas não há nada. Um curso que escrevesse um
script para responder como o Azure e chamasse as respostas de respostas do Azure estaria ensinando a
partir de uma falsificação, então este não faz isso.

O que roda, aqui e na sua máquina:

- **a CLI do Azure de verdade**, `az`, que conhece todo comando e todo parâmetro, confere o que você
  digita e recusa qualquer coisa que precise de conta antes de mandar um byte;
- **Bicep**, a linguagem da Microsoft para descrever recursos do Azure, cujo compilador transforma um
  arquivo exatamente no JSON que o Resource Manager receberia. A maior parte do que este curso
  constrói, ele constrói em Bicep e compila;
- **Terraform**, com os providers da Microsoft para o Azure e para o Entra ID, que confere uma
  configuração contra o esquema real de cada recurso;
- **a biblioteca Azure Identity**, que mostra em ordem todos os jeitos como um programa procura
  credenciais;
- e três coisas na internet que respondem a qualquer um: **os endpoints de login do Microsoft Entra
  ID**, que recusam um tenant inventado com as próprias palavras, **o DNS público**, onde os
  servidores de nomes do Azure respondem, e a cópia publicada das **definições nativas do Azure
  Policy**.

**Onde uma lição precisa do próprio Azure, ela ensina a partir da documentação da Microsoft e diz
com todas as letras que aquela parte não foi executada**: nenhuma transcrição, e nenhuma saída
escrita para parecer uma. Das 82 seções de leitura deste curso, 59 mostram uma transcrição do laboratório, a maioria compilando
ou conferindo um arquivo; as outras 23 são lidas, e dizem isso.
Todo comando e toda linha de saída num terminal foi executado num laboratório montado exatamente do
jeito que as próximas três seções mandam você montar o seu. O prompt diz `ana@laptop:~/azure$`.

O mesmo laboratório serve aos três cursos de Azure que vêm depois deste, `azure-compute`,
`azure-operations` e `azure-data`. Esta lição o monta uma vez, e cada um daqueles cursos começa
conferindo se o seu ainda responde, e acrescenta o que precisa.

::: track cloud-engineering
Na sua trilha vêm em seguida `azure-compute` e `azure-operations`, e os dois partem do laboratório
que você monta aqui. Guarde o `~/azure` ao terminar: o próximo curso o confere em vez de montá-lo de
novo.
:::

::: track data
Na sua trilha vem em seguida `azure-data`, e ele parte do laboratório que você monta aqui. Guarde o
`~/azure` ao terminar: aquele curso o confere em vez de montá-lo de novo.
:::

::: track devops
Na sua trilha este é o único curso de Azure, então ele precisa se sustentar sozinho, e se sustenta:
nada nele espera um curso posterior para ser explicado.
:::

::: track *
Se você seguir para `azure-compute`, `azure-operations` ou `azure-data`, cada um parte do laboratório
que você monta aqui. Guarde o `~/azure` ao terminar, e eles vão conferi-lo em vez de montá-lo de
novo.
:::

## O que compilar não é

Um arquivo Bicep que compila, ou uma configuração Terraform que valida, é **um arquivo com o formato
certo**. Não é um recurso que existe, e três coisas que só o Azure pode dizer ficam sem ser ditas:

- **se você tem permissão.** As permissões são julgadas pelo Resource Manager quando o pedido chega.
  As lições 4, 9 e 10 ensinam como esse julgamento funciona, a partir da documentação;
- **se os valores fazem sentido juntos.** Uma sub-rede maior que a sua rede, um nome que outra pessoa
  já pegou, um tamanho que a região não vende: o compilador confere o tipo de um valor, e o Azure
  confere o valor;
- **quanto custa.** A Microsoft publica os seus preços por uma API pública que não precisa de conta.
  A última seção da lição 1 mostra um programa curto que a lê, e **a máquina onde este curso foi
  gravado não conseguiu alcançar essa API**, então nenhum preço destas lições foi lido por aquele
  programa. Onde uma lição precisa de um número para raciocinar, ela diz de onde o número veio.

## Uma conta de verdade, se você quiser uma

Você nunca precisa de uma aqui. Se quiser experimentar o que aprendeu contra o próprio Azure, a seção
**"Uma conta de verdade, e a ordem em que protegê-la"** mais abaixo diz como abrir uma com segurança.
Ela põe a proteção da conta antes de qualquer outra coisa, por um motivo: a primeira hora de uma conta
nova é quando ela é mais barata de proteger e mais cara de deixar aberta.
