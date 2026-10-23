---
title: Redes e logs, e o que cada um faz antes de você mexer
version: 1
---

**A pergunta a fazer sobre a rede e os logs de qualquer provedor não é o que dá para configurar, mas
o que já vale no primeiro dia, antes de alguém configurar qualquer coisa.** Os padrões decidem como é
a maioria das contas, porque a maioria das configurações nunca é mudada. Esta seção compara os
padrões, pela documentação de cada provedor; nada disso foi executado.

## A rede padrão deixa algo entrar

Os três entregam a uma conta ou projeto novo uma rede, ou deixam criar uma com padrões num clique, e
os padrões não são os mesmos:

| | modelo de firewall | o que é permitido antes de você escrever uma regra |
|---|---|---|
| AWS | **security groups**, com estado e só de permissão, mais network ACLs sem estado | um security group padrão que admite tráfego dos próprios membros e permite toda saída; a aula 1 achou uma VPC padrão em cada região |
| Azure | **network security groups**, com estado, com regras de permissão e de negação ordenadas por prioridade | regras padrão que permitem todo tráfego dentro da rede virtual, o tráfego do balanceador de carga do Azure e toda saída para a internet |
| Google Cloud | **regras de firewall da VPC**, com estado, de permissão e de negação por prioridade, aplicadas às instâncias por tag ou por conta de serviço | na rede `default`, regras prontas permitindo SSH e RDP de qualquer lugar, ICMP e tudo o que é interno |

**A rede `default` do Google Cloud merece o aviso.** As regras pré-preenchidas documentadas dela
incluem `default-allow-ssh` e `default-allow-rdp`, que admitem as portas 22 e 3389 a partir de
`0.0.0.0/0`. Uma máquina virtual lançada ali com endereço público responde SSH da internet sem
ninguém ter escrito regra nenhuma. A orientação do próprio Google é apagar a rede `default` em
projetos de produção, e o Organization Policy tem uma restrição, `compute.skipDefaultNetworkCreation`,
que impede projetos novos de ganharem uma.

O alcance também difere, como a aula 3 do curso `cloud` observou: uma VPC da AWS e uma rede virtual do
Azure pertencem a uma região, enquanto uma rede VPC do Google Cloud é global, com sub-redes regionais.
Uma regra de firewall numa rede do Google vale, portanto, em toda região que a rede cobre.

## O que é registrado antes de você pedir

| | mudanças de configuração | leitura dos próprios dados | guardado por |
|---|---|---|---|
| AWS | **histórico de eventos do CloudTrail**, eventos de gerenciamento, ligado por padrão | eventos de dados do S3 e de outros serviços: desligados até uma trilha ser configurada para registrá-los, e cobrados | 90 dias no histórico de eventos; mais só numa trilha que você criar |
| Azure | **Activity Log**, por assinatura, ligado por padrão | logs de recurso: desligados até uma configuração de diagnóstico mandá-los a algum lugar | 90 dias para o Activity Log; mais só num destino que você escolher |
| Google Cloud | **logs de auditoria de Admin Activity**, sempre ligados e impossíveis de desligar | **logs de auditoria de Data Access**: desligados por padrão, exceto para o BigQuery | 400 dias para Admin Activity, no bucket de logs `_Required` |

**A coluna do meio é a que dói depois de um incidente.** Nos três, "quem mudou as permissões do
bucket" é respondido por padrão, e "quem leu o arquivo dos pacientes" não é, a menos que alguém tenha
ligado esse registro antes e pago por ele. A aula 15 trata de fazer isso na AWS e de proteger o que é
registrado. No Azure as entradas na conta são ainda outro log: o Microsoft Entra ID guarda os
próprios logs de entrada e de auditoria, separados do Activity Log.

## Os serviços que vigiam

| | detecta ameaças nos logs | dá nota à configuração |
|---|---|---|
| AWS | GuardDuty | Security Hub, com regras do AWS Config |
| Azure | as proteções de workload do Microsoft Defender for Cloud | a gestão de postura do Microsoft Defender for Cloud |
| Google Cloud | a detecção de ameaças do Security Command Center | os achados de postura do Security Command Center |

Cada um lê só o próprio provedor. **Uma empresa em dois provedores roda dois deles, ou um terceiro
produto que lê os dois**, que é a emenda de registro da aula 4 com preço. A aula 16 trata da segunda
coluna, e escreve uma versão pequena dela.
