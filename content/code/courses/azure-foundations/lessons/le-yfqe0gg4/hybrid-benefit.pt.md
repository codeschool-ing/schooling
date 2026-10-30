---
title: Azure Hybrid Benefit, e a licença que você já pagou
version: 1
---

**O preço de uma máquina virtual Windows tem duas partes, a máquina e a licença do Windows, e a fatura
as mostra como uma.** O mesmo tamanho de máquina custa mais com Windows do que com Linux, e a diferença
é a Microsoft cobrando o Windows Server por hora. Uma empresa que já tem licenças de Windows Server ou
de SQL Server para o próprio datacenter, com **Software Assurance** (o contrato de manutenção de
licenças da Microsoft) ou por assinatura, pagaria a mesma licença duas vezes. O **Azure Hybrid
Benefit** é o acordo de que ela não paga: você declara que uma máquina está coberta por uma licença
sua, e o Azure cobra essa máquina pela taxa básica de computação, o preço sem a parte do Windows.

## O que ele cobre, e quem responde por isso

| | o benefício |
|---|---|
| Windows Server | uma máquina declarada sob o benefício é cobrada pela taxa básica de computação |
| SQL Server | licenças de SQL Server cobrem o SQL Server em máquinas virtuais do Azure e os serviços gerenciados de SQL do Azure; licenças Standard e Enterprise convertem em proporções diferentes |
| Red Hat Enterprise Linux e SUSE Linux Enterprise | um benefício parecido que deixa uma assinatura existente da Red Hat ou da SUSE cobrir a máquina |
| na mudança | a documentação da Microsoft permite que uma licença que apoia uma migração seja usada no datacenter e no Azure ao mesmo tempo por até 180 dias |

**O Azure não confere se você tem a licença.** Declarar o benefício é uma afirmação sua, e ela é
auditada do jeito que licenciamento de software sempre é: pelo fornecedor, depois, contra os seus
registros. Uma máquina marcada como coberta quando a empresa não tem mais licença sobrando é uma
fatura mais barata este mês e um passivo de licenciamento depois. Então quem conta licenças, a equipe
de compras ou de gestão de ativos de software, precisa concordar com o número de máquinas que levam a
marca. A própria documentação da Microsoft diz para começar por aí, e é o passo mais pulado.

## Onde vai a marca

Numa máquina virtual, o benefício é uma propriedade, `licenseType`. Esta lição não é sobre máquinas,
que o `azure-compute` monta inteiras; o fragmento abaixo traz só as propriedades de que esta lição
trata. Salve-o como `vm.bicep` em `~/azure/bill`:

```bicep
param location string = resourceGroup().location

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-shop-reports'
  location: location
  properties: {
    licenseType: 'Windows_Server'
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
  }
}
```

Compile, e depois uma cópia com o valor escrito errado:

```
ana@laptop:~/azure/bill$ az bicep build --file vm.bicep --stdout | jq -c '.resources[0] | {name, licenseType: .properties.licenseType}'
{"name":"vm-shop-reports","licenseType":"Windows_Server"}
ana@laptop:~/azure/bill$ sed "s/'Windows_Server'/'Windows_Sever'/" vm.bicep > typo.bicep
ana@laptop:~/azure/bill$ az bicep build --file typo.bicep --stdout | jq -c '.resources[0] | {name, licenseType: .properties.licenseType}'
{"name":"vm-shop-reports","licenseType":"Windows_Sever"}
```

**As duas compilaram.** O Bicep conhece `licenseType` como um texto, como a lição 13 viu no tipo de
limite de um orçamento, então `Windows_Sever` é um texto perfeitamente bom para ele. É o Resource
Manager que confere o valor. E repare no que falta sem uma palavra do compilador: uma máquina de
verdade precisa de um disco, de um perfil de sistema operacional e de uma interface de rede, e nenhum
deles é exigido pelo tipo. **Um fragmento que compila é um fragmento**, que é o que a lição 1 quis
dizer com um arquivo com o formato certo.

## Lendo-o na fatura

O benefício aparece na fatura como uma ausência: as horas de uma máquina Windows coberta aparecem só
no medidor de computação, sem o medidor da licença do Windows ao lado. Duas conferências decorrem
disso, as duas na análise de custos e as duas **não executadas aqui**:

- **agrupe os custos das máquinas virtuais por medidor** e procure medidores de licença do Windows em
  máquinas que a empresa acredita estarem cobertas. Cada um é uma licença paga duas vezes;
- **conte as máquinas com a marca** e compare com o número de licenças que a equipe de ativos diz
  estarem disponíveis. Mais marcas do que licenças é o passivo descrito acima.

Para o SQL Server, a Microsoft também deixa o benefício ser gerido de forma central, no escopo de uma
assinatura ou da conta de cobrança inteira, atribuindo um número de licenças em vez de marcar máquina
por máquina, e o Azure as aplica ao uso de SQL Server naquele escopo. A aritmética da seção anterior
vale para ele também: uma licença atribuída a uma máquina que fica desligada a maior parte do mês
economiza o preço da licença nas horas em que ela roda e nada nas horas em que não roda.
