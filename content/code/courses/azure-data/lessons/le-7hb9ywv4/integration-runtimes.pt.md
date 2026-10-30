---
title: "Integration runtimes: onde a cópia acontece de fato"
version: 1
---

**Um integration runtime é a máquina que roda as atividades de uma factory, e escolher um é escolher
por qual rede os dados passam.** A factory só guarda definições e horários; quando uma cópia começa,
é um integration runtime que abre a origem, lê, converte e escreve. Há três tipos. Esta seção é
ensinada a partir da documentação da Microsoft e não foi executada.

## O integration runtime do Azure

**O integration runtime do Azure é gerido pela Microsoft, roda no Azure e está em toda factory sem
precisar ser criado**: é o `AutoResolveIntegrationRuntime` que um linked service usa quando não cita
nenhum outro. Ele alcança qualquer coisa com endpoint público, e com uma rede virtual gerenciada
ligada alcança os armazenamentos por endpoints privados, que é o arranjo de que precisa uma empresa
que fechou suas contas de armazenamento para a internet.

**Uma cópia nele é dimensionada em data integration units, as DIUs**, a medida da Microsoft de
processador, memória e rede para uma cópia. O Data Factory escolhe um número por cópia se você não
fixar um, e uma cópia grande entre dois armazenamentos na nuvem fica mais rápida, mais ou menos na
proporção, com mais delas, até o ponto em que a origem ou o destino não acompanham. As DIUs também são
o que a cópia paga, por DIU-hora, o que torna a configuração uma escolha entre uma noite rápida e uma
barata.

"AutoResolve" quer dizer que o runtime roda numa região que o Data Factory escolhe, perto do destino.
Para a Quitanda, cujos armazenamentos estão todos em `brazilsouth`, é ali que a cópia roda. Uma empresa
que precisa dizer em que país seus dados foram processados fica mais segura com um runtime do Azure
fixado numa região, que o `azurerm_data_factory_integration_runtime_azure` declara com a `location`
dele.

## O integration runtime self-hosted

**Um integration runtime self-hosted é um software que você instala numa máquina Windows sua, dentro
da rede onde mora um armazenamento que o Azure não alcança.** O sistema de estoque antigo da Quitanda
roda num SQL Server no depósito de Guarulhos, atrás do firewall da empresa. A factory não consegue
abrir uma conexão para dentro dessa rede, então uma máquina lá dentro roda o runtime, que abre
conexões para fora, por HTTPS, até o Data Factory, pede trabalho, lê o SQL Server ao lado e manda as
linhas para o Azure. Nada precisa ser aberto no firewall para tráfego de entrada.

O que ele custa é a máquina: você a instala, aplica os patches, a mantém ligada e garante que um
reinício na noite da carga não vire um dia perdido. A Microsoft documenta até quatro nós para um
runtime self-hosted, para que uma máquina possa falhar e a cópia continue; as mesmas máquinas podem
servir várias factories. O software do runtime se atualiza sozinho por padrão, o que vale saber antes
da primeira vez que uma cópia mudar de comportamento de um dia para o outro.

## O integration runtime Azure-SSIS

**O terceiro tipo existe por um motivo: pacotes do SQL Server Integration Services.** Uma empresa que
passou dez anos escrevendo pacotes SSIS nos próprios servidores pode rodá-los sem mudança num cluster
de máquinas do Azure que o Data Factory gerencia, ligado e desligado como um pool, cobrado por nó por
hora enquanto roda. É um jeito de levar um legado para a nuvem sem reescrevê-lo, e um pipeline novo
não tem motivo para usá-lo.

## Escolhendo

| o armazenamento é | o runtime |
|---|---|
| um serviço do Azure ou qualquer coisa com endpoint público | o runtime do Azure, como vem |
| um serviço do Azure fechado para a internet, atrás de um endpoint privado | o runtime do Azure com rede virtual gerenciada |
| na rede da própria empresa, ou numa rede virtual que a factory não alcança | um runtime self-hosted, numa máquina dentro dessa rede |
| um pacote SSIS que alguém já escreveu | o runtime Azure-SSIS |

Um pipeline pode usar mais de um: a cópia do estoque da Quitanda roda no runtime self-hosted de
Guarulhos e cai no lago, e a cópia seguinte, de raw para curated, roda no runtime do Azure, porque nada
nela sai do Azure.
