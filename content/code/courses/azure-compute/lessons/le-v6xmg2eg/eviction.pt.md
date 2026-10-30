---
title: O despejo, seus dois motivos e suas duas políticas
version: 1
---

A preocupação de sempre com o Spot é o preço: ele sobe, e a máquina vai embora. Esse é um motivo de
despejo, e é o que dá para desligar. **Uma máquina Spot é despejada quando o Azure precisa da
capacidade para trabalho pay-as-you-go, ou quando o preço Spot sobe acima do máximo que você disse
que pagaria.** O primeiro motivo está sempre presente. O segundo só existe se você definir um máximo.
E o que sobra da máquina depois é uma segunda decisão, a política de despejo, tomada quando a máquina
é criada.

## Capacidade, e preço se você pedir

O portal chama as duas escolhas de *eviction types*, capacity only e price or capacity. A API não tem
propriedade com esse nome. **O tipo de despejo é o valor de `maxPrice`**:

- `-1` quer dizer que a máquina nunca é despejada por preço. Você paga o preço Spot do momento, ou
  o preço padrão se ele for menor, e a documentação da Microsoft é explícita: você nunca é cobrado
  acima do preço padrão. Só a capacidade pode levar a máquina.
- Um número é um máximo em dólares americanos por hora, com até cinco casas decimais: `0.05` são
  cinco centavos. A máquina é despejada por capacidade como antes, e também sempre que o preço Spot
  subir acima dele.

Um máximo não baixa a conta, já que você paga o preço Spot do momento, seja ele qual for. Ele compra
um teto para o custo de uma hora, e paga o teto em despejos. A tabela de resultados da documentação,
resumida:

| situação | o que acontece |
| --- | --- |
| criar uma máquina com um máximo igual ou acima do preço atual | criada, se houver capacidade e cota |
| criar uma com um máximo abaixo do preço atual | não é criada: o erro diz que o máximo tem de ser pelo menos o preço atual |
| o preço sobe acima do máximo de uma máquina em execução | despejada, com aviso tentado até 30 segundos antes |
| o preço volta a cair depois desse despejo | nada: a máquina não é reiniciada, e se você a reiniciar, é cobrada pelo preço atual |
| mudar o máximo | só com a máquina desalocada |

A ajuda da CLI dá às duas escolhas uma linha cada:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o -- "--eviction-policy : [^:]*: [A-Za-z, ]*\."
--eviction-policy : The eviction policy for the Spot priority virtual machine. Default eviction policy is Deallocate for a Spot priority virtual machine. Allowed values: Deallocate, Delete.
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o -- "--max-price \[Preview\] : [^.]*\. [^.]*\."
--max-price [Preview] : The maximum price (in US Dollars) you are willing to pay for a Spot VM/VMSS. -1 indicates that the Spot VM/VMSS should not be evicted for price reasons.
```

**Copiar o vocabulário do portal para um arquivo é o primeiro erro que espera aqui**, e o segundo é
escrever `-1` como texto. Os dois de uma vez, numa cópia do arquivo da seção anterior:

```
ana@laptop:~/azure$ sed -e "s/maxPrice: -1/maxPrice: '-1'/" -e "s/    evictionPolicy: 'Deallocate'/&\n    evictionType: 'CapacityOnly'/" report-vm.bicep > wrong.bicep
ana@laptop:~/azure$ diff report-vm.bicep wrong.bicep
12a13
>     evictionType: 'CapacityOnly'
14c15
<       maxPrice: -1
---
>       maxPrice: '-1'
ana@laptop:~/azure$ bicep build wrong.bicep
/home/ana/azure/wrong.bicep(13,5) : Warning BCP037: The property "evictionType" is not allowed on objects of type "VirtualMachineProperties". Permissible properties include "additionalCapabilities", "applicationProfile", "availabilitySet", "capacityReservation", "diagnosticsProfile", "extensionsTimeBudget", "host", "hostGroup", "licenseType", "platformFaultDomain", "proximityPlacementGroup", "scheduledEventsPolicy", "scheduledEventsProfile", "securityProfile", "userData", "virtualMachineScaleSet". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP037]
/home/ana/azure/wrong.bicep(15,17) : Warning BCP036: The property "maxPrice" expected a value of type "int | null" but the provided value is of type "'-1'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

Os dois são pegos. `evictionType` não é propriedade de uma máquina virtual, e o aviso lista as que
são; o `'-1'` entre aspas é texto onde o tipo quer um número. A segunda linha do aviso tem um detalhe
que vale ler: o tipo diz `int`. **O Bicep não tem números decimais**, e a documentação do Bicep da
Microsoft diz isso numa frase, "floating point, decimal, or binary formats aren't currently
supported". Então um máximo de cinco centavos não pode ser escrito do jeito óbvio:

```
ana@laptop:~/azure$ sed "s/maxPrice: -1/maxPrice: 0.05/" report-vm.bicep > price.bicep
ana@laptop:~/azure$ bicep build price.bicep
/home/ana/azure/price.bicep(14,19) : Error BCP020: Expected a function or property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP020]
/home/ana/azure/price.bicep(14,19) : Error BCP236: Expected a new line or comma character at this location. [https://aka.ms/bicep/core-diagnostics#BCP236]
/home/ana/azure/price.bicep(14,19) : Error BCP022: Expected a property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP022]
/home/ana/azure/price.bicep(14,19) : Error BCP055: Cannot access properties of type "0". An "object" type is required. [https://aka.ms/bicep/core-diagnostics#BCP055]
/home/ana/azure/price.bicep(14,21) : Error BCP018: Expected the ":" character at this location. [https://aka.ms/bicep/core-diagnostics#BCP018]
ana@laptop:~/azure$ ls price.*
price.bicep
```

Isso são erros, não avisos. Um aviso, como a lição 1 mostrou, ainda grava um template; um erro não
grava nenhum, e por isso o `ls` só encontrou o `.bicep`. O jeito de escrever um
decimal em Bicep é a função `json`, que transforma o texto `'0.05'` no número JSON `0.05` quando o
template é implantado:

```
ana@laptop:~/azure$ sed -i "s/maxPrice: 0.05/maxPrice: json('0.05')/" price.bicep
ana@laptop:~/azure$ bicep build price.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.billingProfile" price.json
{
  "maxPrice": "[json('0.05')]"
}
```

Isso compilou sem aviso, e o template leva a expressão `[json('0.05')]`, que o Resource Manager
avalia. O arquivo do relatório da loja fica com `-1`: um relatório que roda de noite não tem motivo
para ser despejado por preço além de por capacidade.

## O que sobra depois

A política de despejo decide o que o despejo deixa, e há duas:

| depois de um despejo | `Deallocate`, o padrão | `Delete` |
| --- | --- | --- |
| a máquina | continua lá, parada e desalocada | some |
| os discos dela | mantidos, e cobrados | apagados com ela |
| os núcleos dela | ainda contados na sua cota Spot | liberados |
| os endereços IP não estáticos dela | liberados | somem com a máquina |
| a volta | você a inicia de novo, na mesma região e zona, quando houver capacidade; isso pode falhar | você cria uma nova, de qualquer tamanho, em qualquer lugar |

**Deallocate mantém a máquina e continua cobrando os discos dela enquanto ela espera.** A
documentação tem o cuidado de acrescentar que não há garantia de que o reinício dê certo: a
capacidade volta quando volta, e uma máquina desalocada não pode mudar de zona ou de região para
achá-la. Alguma coisa tem de continuar tentando, porque nada a reinicia por você. O guia da Microsoft
sugere um pipeline agendado que tenta o reinício até funcionar.

A linha da cota é a que pega as pessoas de surpresa. Suponha, com um número ilustrativo, uma cota
Spot de 20 vCPUs, e dez máquinas `D2s_v5` despejadas com `Deallocate`. As 20 vCPUs continuam
contadas na cota por máquinas que não estão rodando, então as substitutas não podem ser criadas até
alguém apagar as antigas ou a capacidade voltar e elas reiniciarem.

**Delete não deixa nada para pagar nem nada para reiniciar**, então a substituta tem de vir de algo
fora da máquina: um scale set aumentando a contagem, ou a sua própria automação. Em troca, ela pode
ser de qualquer tamanho e em qualquer zona que tenha espaço, e é por isso que o guia a chama de
política mais flexível e a recomenda primeiro quando o trabalho permite. O mesmo guia acrescenta um
detalhe que decorre do Delete: o disco do sistema operacional morre com a máquina a cada despejo,
então um disco de SO efêmero, o assunto da lição 3, não custa nada perder e inicia mais rápido.

A regra prática do próprio guia para escolher:

- `Delete` quando o trabalho e os dados dele são descartáveis, quando você não quer pagar por
  discos entre uma execução e outra, e quando a substituta pode ter outro tamanho ou outra zona.
- `Deallocate` quando o trabalho precisa deste tamanho exato neste lugar exato, quando instalá-lo
  de novo demora, e quando esperar um tempo desconhecido por capacidade é aceitável.

A máquina do relatório da loja fica com `Deallocate`: é uma máquina só, as ferramentas dela estão
instaladas no próprio disco, e o relatório pode esperar aquela máquina voltar. O trabalho em
andamento fica em outro lugar, como explica a próxima seção. O scale set da última seção desta
lição fica com `Delete`.

## Com que frequência acontece

A taxa é publicada, em dois lugares, e nenhum dos dois é uma promessa. O portal mostra uma taxa de
despejo por tamanho e região ao lado do histórico de preços, **dada por hora**. Nas palavras da
documentação, uma taxa de 10% quer dizer 10% de chance de a máquina ser despejada na próxima hora,
com base nos últimos sete dias. O Azure Resource Graph guarda os mesmos dados numa tabela chamada
`SpotResources`, com 90 dias de preços e as taxas de despejo dos últimos 28 dias, que podem ser
consultadas entre tamanhos e regiões. O guia dá as taxas em faixas, de 0 a 5%, de 5 a 10% e assim por
diante até 20% ou mais. Nada disso foi consultado aqui, já que todo caminho até lá precisa de uma
assinatura; o que este curso pode fazer é a conta com uma taxa, duas seções adiante.
