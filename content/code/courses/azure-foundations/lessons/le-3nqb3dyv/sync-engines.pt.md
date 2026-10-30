---
title: Connect Sync e Cloud Sync
version: 1
---

**A Microsoft oferece dois programas que copiam o Active Directory para o Entra ID, e a diferença entre
eles é onde o trabalho acontece.** Os dois são descritos a partir da documentação da Microsoft; nenhum
foi executado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-sync\" aria-label=\"Os dois programas de sincronização lado a lado. À esquerda, o Connect Sync: na rede do escritório, um servidor guarda o motor inteiro e o banco de dados dele, lê o Active Directory e escreve no Entra ID. À direita, o Cloud Sync: na rede do escritório, dois agentes leves de provisionamento respondem a pedidos de um serviço de provisionamento que roda no Entra ID, que guarda a configuração e o motor. Os dois copiam do Active Directory para o Entra ID.\"><defs><marker id=\"l12-sync-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-sync-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"185.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Connect Sync</text><rect x=\"20.0\" y=\"40.0\" width=\"330.0\" height=\"76.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Microsoft Entra ID</text><rect x=\"20.0\" y=\"170.0\" width=\"330.0\" height=\"116.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"34.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rede do escritório</text><rect x=\"40.0\" y=\"240.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Active Directory</text><text x=\"535.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Cloud Sync</text><rect x=\"370.0\" y=\"40.0\" width=\"330.0\" height=\"76.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Microsoft Entra ID</text><rect x=\"370.0\" y=\"170.0\" width=\"330.0\" height=\"116.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"384.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rede do escritório</text><rect x=\"390.0\" y=\"240.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Active Directory</text><rect x=\"190.0\" y=\"200.0\" width=\"140.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"230.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">motor</text><text x=\"260.0\" y=\"243.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e banco de dados</text><path d=\"M141.0 257.0 L189.0 257.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-paper-dim)\"></path><path d=\"M260.0 199.0 L260.0 117.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-amber)\"></path><text x=\"180.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma cópia do diretório</text><rect x=\"540.0\" y=\"64.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">motor e</text><text x=\"615.0\" y=\"90.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">configuração</text><rect x=\"540.0\" y=\"214.0\" width=\"70.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agente</text><path d=\"M575.0 213.0 L575.0 117.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-amber)\"></path><rect x=\"620.0\" y=\"214.0\" width=\"70.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agente</text><path d=\"M655.0 213.0 L655.0 117.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-amber)\"></path><path d=\"M491.0 257.0 L560.0 257.0 L560.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-paper-dim)\"></path><text x=\"455.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma cópia do diretório</text></svg>", "caption": "A mesma cópia, feita por um motor inteiro no chão ou por agentes respondendo a um na nuvem.", "same": ["Active Directory", "Cloud Sync", "Connect Sync", "Microsoft Entra ID"]}
```

## Microsoft Entra Connect Sync

**O Connect Sync é um motor de sincronização completo instalado num servidor da rede da empresa.** Ele
lê o Active Directory, mantém um banco de dados próprio do que já viu, descobre o que mudou, aplica as
regras que dizem quais atributos vão para onde, e escreve o resultado no Entra ID. O agendador dele roda
um ciclo a cada trinta minutos por padrão, e os hashes de senha, quando a empresa os sincroniza, têm um
processo próprio que roda a cada dois minutos.

É o mais antigo e o mais capaz dos dois. Ele lida com várias florestas, regras complexas para juntar
contas que existem em mais de uma delas, e todo writeback que a Microsoft oferece. Essa capacidade tem
um preço: um servidor para atualizar e manter no ar, um banco de dados nele, e uma atualização que a
empresa precisa lembrar de fazer. O antecessor dele, o Azure AD Connect versão 1, deixou de ter suporte
em agosto de 2022, e a documentação da Microsoft avisa que instalações que ainda o rodam podem parar
sem aviso. Um servidor de sincronização é o tipo de máquina que todo mundo esquece até ela ser o motivo
de ninguém novo conseguir fazer login.

## Microsoft Entra Cloud Sync

**O Cloud Sync leva o motor para o Entra ID e deixa só um agente no chão.** O *agente de
provisionamento* é um programa pequeno num servidor da rede. Ele mantém uma conexão de saída com a
Microsoft, escuta pedidos, consulta o Active Directory quando o serviço da nuvem pede, e devolve o que
encontra. A configuração, o agendamento e o processamento moram na nuvem.

**Vários agentes podem rodar ao mesmo tempo, em servidores diferentes**, e a documentação da Microsoft
descreve a troca entre eles como automática: perder um servidor não para a sincronização. Nada é
instalado além do agente, então não há banco de dados para manter. Ele serve a uma empresa com um
diretório simples, a uma empresa juntando vários diretórios pequenos depois de uma aquisição, e a
qualquer empresa que prefira não rodar mais um servidor.

## Escolhendo

| | Connect Sync | Cloud Sync |
|---|---|---|
| o que fica no local | o motor inteiro, com o banco de dados | um agente leve |
| alta disponibilidade | um servidor ativo, com um reserva que você configura | vários agentes ativos, trocando sozinhos |
| onde se configura | no servidor | no Entra ID |
| diretórios complexos e todo writeback | sim | não todos os cenários |

O conselho da própria Microsoft, na documentação do Cloud Sync, é passar do Connect Sync para o Cloud
Sync onde o cenário for suportado, usando a ferramenta de migração dela onde a instalação se
qualificar, e ficar no Connect Sync onde não for. **A loja tem uma floresta, um domínio e algumas
centenas de pessoas**, então o Cloud Sync serve, com dois agentes em dois servidores. Uma empresa com
várias florestas e contas que precisam ser juntadas entre elas é o caso para o qual o Connect Sync
ainda existe.

Seja qual for o que roda, a sincronização em si agora é uma dependência do login de todo mundo cuja
conta nasce no chão. **Monitore-a como um serviço**, com um alerta sobre a saúde dela: uma
sincronização que parou na sexta é uma segunda-feira com funcionários novos que não existem na nuvem e
gente que saiu e ainda existe.
