---
title: Tags, ou quem está gastando
version: 1
---

Uma conta agrupada por serviço responde o que está sendo comprado: tanto de EC2, tanto de NAT gateway,
tanto de S3. Ela não responde **quem está comprando**, e é nessa pergunta que toda conversa sobre custo
vira. Três times dividem uma conta; a conta subiu um terço; cada time tem certeza de que não foi ele.
**Um custo que você não consegue atribuir a alguém é um custo que ninguém consegue gerenciar**, porque
ninguém pode decidir mudá-lo.

## As tags são a atribuição

Uma tag é uma chave e um valor presos a um recurso: uma máquina, um volume, um bucket, um load balancer.
Todos os provedores têm; o Google Cloud chama de labels. Um conjunto pequeno e fixo em todo recurso
basta para responder à maioria das perguntas:

| chave | valor de exemplo | o que responde |
| --- | --- | --- |
| `team` | `payments` | a quem perguntar, e de qual orçamento sai |
| `project` | `shop` | a que produto o gasto pertence |
| `environment` | `production`, `staging`, `test` | se atende clientes ou pode ser desligado |

Com essas três, os 298,64 da estimativa deixam de ser um número só. A mesma conta agrupada por
`environment` pode mostrar que staging custa quase tanto quanto produção, o que é uma descoberta;
agrupada por `team`, mostra com quem falar sobre isso.

**Uma tag precisa ser ativada antes de aparecer na conta.** Na AWS, uma tag que você põe nos recursos
não é uma tag de alocação de custo até alguém ativá-la nas configurações de cobrança. Até lá, os
recursos a carregam e os relatórios de custo a ignoram. E uma tag só atribui o custo incorrido enquanto
ela estava no recurso. Uma máquina marcada em março não diz nada sobre quem pagou por ela em fevereiro.

## Algumas linhas não aceitam tag

Nem toda linha de uma conta pertence a um recurso. Impostos, um plano de suporte e algumas cobranças de
tráfego chegam como valores da conta inteira. Em vez de deixá-las sem dono, combine uma regra uma vez,
como dividi-las na proporção do gasto marcado de cada time, e aplique todo mês do mesmo jeito. **Uma
regra de que as pessoas não gostam mas entendem vale mais que um número que ninguém sabe explicar.**

## Recursos sem dono

O relatório mais útil que as tags produzem é o que lista **o que não tem tag nenhuma**. Um recurso sem
tag é um recurso que ninguém reivindicou quando foi criado: a máquina de teste de um workshop, o volume
deixado por uma instância apagada, o endereço reservado e nunca usado. É aí que moram as linhas-surpresa
de antes nesta aula. Revisar toda semana o gasto sem tag, e apagar ou reivindicar cada item, é a
economia mais barata que existe.

## Uma política de tags, em linhas gerais

Tags só funcionam se forem consistentes. `Team`, `team` e `teem` são três chaves diferentes para um
relatório de cobrança, e `prod`, `production` e `Production` são três ambientes diferentes. Uma política
de tags põe a convenção por escrito e deixa o provedor conferir:

- quais chaves são obrigatórias em quais tipos de recurso;
- como cada chave é escrita, inclusive maiúsculas e minúsculas;
- quais valores são permitidos, onde a lista é fechada, como é em `environment`;
- se um recurso sem as tags obrigatórias pode ou não ser criado.

O AWS Organizations tem tag policies e o Azure tem o Azure Policy, que pode recusar ou sinalizar um
recurso; `aws-foundations` e `azure-foundations` mostram a sintaxe. A imposição mais forte é a que
ninguém precisa lembrar: quando a infraestrutura é escrita como código, como no curso `iac`, as tags
são definidas uma vez como padrão e todo recurso as carrega.
