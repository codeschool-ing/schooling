---
title: "Para que serve, e o que fica de fora"
version: 1
---

É fácil ler o Container Instances como um jeito pequeno e barato de pôr um serviço web no Azure, e a
primeira implantação incentiva isso: um comando, um nome público, a loja respondendo em menos de um
minuto. **O que ele roda é um grupo, mantido na sua política de reinício, e nada mais.** Ele não
guarda uma contagem de cópias, não inicia uma segunda quando a primeira está ocupada, não implanta
uma versão nova sem parar a antiga e não põe um endereço na frente de vários grupos. A própria
documentação da Microsoft diz que ele oferece "algumas das capacidades básicas de agendamento das
plataformas de orquestração", sem os serviços pelos quais essas plataformas são escolhidas. Esta
seção trata de onde isso é exatamente o certo, e de onde é uma lacuna que você mesmo teria de
preencher. Ela é lida da documentação da Microsoft; nada nela precisa de assinatura para ser
entendido.

## O que ele faz bem

**Jobs que rodam e terminam.** O primeiro exemplo que a própria Microsoft dá das políticas de
reinício é a tarefa de uma execução só: um build, uma rodada de testes, uma imagem renderizada. A
loja tem dois desses. O relatório de vendas noturno lê os pedidos do dia, escreve um arquivo e
termina, e a exportação mensal para o financeiro faz o mesmo uma vez por mês. Cada um é um grupo com
`OnFailure`, iniciado num horário por alguma coisa que consiga chamar o Azure, como o Logic App da
lição 19, e cobrado pelos minutos que roda. Nada fica rodando entre uma noite e outra, então não há
nada a pagar nesse intervalo.

O arquivo do relatório precisa sobreviver ao grupo, e o disco do próprio grupo não sobrevive. É o
compartilhamento do Azure Files da lição 3, montado como volume. As partes do grupo do relatório que
diferem das do grupo da loja:

```yaml
properties:
  osType: Linux
  restartPolicy: OnFailure
  containers:
  - name: report
    properties:
      image: shopregistry.azurecr.io/report:1.0
      resources:
        requests:
          cpu: 1
          memoryInGB: 1
      volumeMounts:
      - name: reports
        mountPath: /reports
  volumes:
  - name: reports
    azureFile:
      shareName: reports
      storageAccountName: shopreportssp
      storageAccountKey: <the storage account's key>
```

Sem `ipAddress`: um job que ninguém chama não precisa de endereço. Duas coisas neste arquivo são
custos. **A chave da conta de armazenamento fica na definição**, que é o motivo que a Microsoft dá
para preferir um template quando outros recursos vêm junto com o grupo: em Bicep a chave pode ser
lida da conta na implantação e nunca escrita em lugar nenhum. E **uma montagem do Azure Files exige
que o contêiner rode como root**, segundo a documentação da Microsoft. A imagem da loja roda como
`nobody`, como o `id` mostrou na seção 03, então a imagem do relatório é construída de outro jeito
de propósito, e essa é uma troca que alguém deve fazer sabendo, em vez de descobrir depois.

**Picos.** Um grupo inicia em segundos e é cobrado por segundo, então um trabalho que chega de uma
vez e depois para custa os minutos que levou. A Microsoft é clara sobre o outro lado: para trabalho
longo e constante, contêineres num cluster de máquinas virtuais costumam sair mais baratos que os
mesmos contêineres no Container Instances.

**Agentes de build.** Um job de integração contínua é um contêiner que roda um build e termina, que
é de novo o caso do job, e a documentação da Microsoft cita builds e testes entre os próprios
exemplos. Cada pull request dos três desenvolvedores pode ganhar um grupo que roda os testes e para.

**Pods para o AKS.** Os *nós virtuais* registram o Container Instances num cluster AKS como um nó de
capacidade ilimitada. Um pod agendado ali roda como um grupo de contêineres, sem esperar o cluster
acrescentar uma máquina virtual, e é pago por segundo. A lição 11 monta o lado do AKS. Aqui o
Container Instances não é o orquestrador. O Kubernetes é, e o Container Instances é a capacidade que
ele pega emprestada.

## O que fica de fora

| você precisa de | um grupo de contêineres dá | onde isso é feito |
|---|---|---|
| mais cópias quando a loja está ocupada | um grupo; mais grupos são você quem cria | Container Apps, lição 8; AKS, lição 11 |
| uma versão nova sem interromper o serviço | uma atualização reinicia todos os contêineres no lugar | revisões do Container Apps, lição 8; slots do App Service, lição 18 |
| um endereço na frente de várias cópias | nenhum próprio | um balanceador de carga ou um Application Gateway, lição 22 do `azure-foundations` |
| um endereço IP público que nunca muda | um endereço que pode mudar num reinício | um rótulo DNS, ou um Application Gateway na frente |
| o log da semana passada | 4 MB enquanto roda, 16 KB ou 1.000 linhas depois de parado | Log Analytics, lições 8 a 13 do `azure-operations` |
| uma imagem `arm64` | só x64 | o mesmo programa, construído para `amd64` |

**A linha da atualização é a que a loja sentiria.** Implantar `shop:1.1` num grupo rodando reinicia
os contêineres dele no lugar, e enquanto reiniciam ninguém responde. Com um grupo só não há segunda
cópia para segurar os clientes, nem tráfego para mover aos poucos. Um balanceador de carga pode
espalhar o tráfego por vários grupos numa rede virtual, e a Microsoft documenta exatamente isso com
um Standard Load Balancer. Só que aí é você quem cria os grupos, conta, atualiza um de cada vez e
confere se cada um está saudável: o trabalho de um orquestrador, feito à mão.

Há também uma lista curta de coisas que o Container Instances não faz de jeito nenhum: nada de
contêineres privilegiados, pelo FAQ da Microsoft, e uma lista de portas reservadas para o serviço,
entre elas a 22 e a 3389, que um grupo não deve usar. A 8080 não está nela.

## NGroups, e a lacuna se fechando

A Microsoft começou a preencher a lacuna de dentro do serviço. O **NGroups**, em preview quando este
curso leu a documentação em 30 de outubro de 2026, mantém um número declarado de grupos de
contêineres feitos a partir de um modelo, um *container group profile*, e acrescenta atualizações
graduais, distribuição entre zonas de disponibilidade e balanceamento de carga. É o mais perto que o
Container Instances chega de um serviço que roda cópias da loja. Sendo preview, não traz promessa de
chegar à disponibilidade geral nesta forma, e este curso não se apoia nele.

## Escolhendo, para a loja

Ponha as quatro cargas da loja contra as duas listas. **A API de pedidos não é uma carga para o
Container Instances**: atende clientes o dia inteiro, precisa ficar no ar durante uma implantação e
um dia vai precisar de uma segunda cópia. A lição 8 a roda no Container Apps, que tem as três
coisas. O relatório noturno e a exportação do financeiro são jobs, e um grupo com `OnFailure` e um
compartilhamento de arquivos é a coisa mais simples do Azure para rodá-los. As rodadas de teste dos
desenvolvedores também são jobs.

A imagem da API de pedidos é a parte que segue adiante. O `shop:1.0` que você construiu aqui roda sem
mudança nas lições 8, 11 e 18, e a lição 21 põe os quatro serviços lado a lado, com contas. O
Container Instances é o que tem menos coisa entre você e o contêiner, o que é a vantagem dele para um
job e a fraqueza dele para um serviço.
