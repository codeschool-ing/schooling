---
title: Uma landing zone, e o que o Control Tower constrói
version: 1
---

**Uma landing zone é o arranjo de várias contas inteiro como ele precisa estar antes de a primeira
carga de trabalho chegar**: a árvore das lições 3 e 4, mais os logs, as barreiras e o jeito de as
pessoas entrarem, montados para que toda conta acrescentada depois comece do mesmo jeito. A imagem
errada é um produto, ou uma conta só configurada com cuidado. Uma landing zone não é nenhum dos
dois. É uma base que vale para toda conta, as de hoje e as do ano que vem, e **a parte difícil é a
próxima conta**, não a primeira.

A lição 2 listou o que toda conta precisa e a lição 3 disse que seis contas montadas à mão viram seis
contas diferentes. Uma landing zone é a resposta para isso, e a AWS vende uma como serviço.

## Control Tower

**O AWS Control Tower constrói uma landing zone e a mantém em forma.** Ele é montado uma vez, a
partir da conta de gerenciamento, numa **região principal** que a empresa escolhe, e governa as
regiões que a empresa lista, então a loja escolheria `sa-east-1` para as duas coisas. O Control
Tower em si não custa nada; os serviços que ele liga são cobrados normalmente, o que a próxima seção
precifica.

**Nada disto foi rodado para o curso.** O moto não tem Control Tower, como a última seção desta lição
mostra, então o que segue é comportamento documentado da AWS.

## O que ele monta

| o Control Tower cria | para que serve | o nome da loja para isso |
|---|---|---|
| uma OU de segurança, chamada `Security` por padrão | as contas que vigiam as outras | `Security` |
| uma conta **Log Archive** nela | um bucket que recebe os registros do CloudTrail e do Config de toda conta | `log-archive` |
| uma conta **Audit** nela | acesso de leitura a toda conta para a equipe de segurança, e onde os alertas chegam | `security` |
| opcionalmente uma segunda OU, `Sandbox` por padrão | uma primeira casa para contas novas | `Sandbox` |
| uma trilha da organização no CloudTrail | toda chamada de API de toda conta, entregue na Log Archive | |
| o AWS Config em toda conta e região governada | um registro do que cada conta contém, e de como mudou | |
| o IAM Identity Center, a não ser que a empresa recuse | uma entrada única para as pessoas em todas as contas; lição 11 | |
| os controles obrigatórios | barreiras que protegem a própria landing zone; a próxima seção | |

Os nomes da terceira coluna são os das lições 2 e 3. **A conta Audit do Control Tower é a `security`
da loja**: o lugar de onde a equipe de segurança trabalha, com acesso de leitura em todo lugar e de
escrita em nenhum lugar onde não precise. A OU `Workloads` da loja não faz parte da montagem; uma
empresa cria as próprias OUs no Control Tower depois e as registra, e dali em diante o Control Tower
as governa.

## Account Factory

**Uma conta nova é feita pelo Control Tower, não pelo Organizations.** O Account Factory é a parte do
Control Tower que cria uma conta dentro de uma OU registrada e aplica a landing zone a ela antes de
alguém usá-la: a trilha a alcança, o Config começa a gravar, os controles da OU passam a valer, e as
pessoas certas conseguem entrar. Essa é a propriedade que a lição 2 pediu, uma conta nova que já
começa certa, entregue por um formulário ou uma chamada de API em vez de alguém lembrar uma lista de
passos.

Uma conta criada antes, ou convidada de fora como na lição 3, é **inscrita** (enrolled) em vez disso,
e recebe a mesma base.

## Drift

**Drift é a landing zone alterada pelas costas do Control Tower.** O Control Tower sabe o que montou,
e confere: uma conta movida entre OUs direto no Organizations, uma SCP que o Control Tower gerencia
editada ou desanexada à mão, uma OU que ele governa apagada. Cada uma dessas é informada como drift,
e é reparada pelo Control Tower, registrando a OU de novo ou reparando a landing zone.

A regra que decorre disso é a que faz uma landing zone gerenciada funcionar: **quando o Control Tower
cuida da árvore, a árvore é mudada pelo Control Tower.** As lições 3 e 4 usaram o Organizations
direto, o que é certo para entendê-lo e errado para uma organização sob o Control Tower, onde o mesmo
`move-account` produz drift.
