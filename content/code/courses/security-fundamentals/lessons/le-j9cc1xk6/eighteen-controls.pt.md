---
title: Dezoito controles, em ordem
version: 1
---

O **Center for Internet Security (CIS)** é uma organização sem fins lucrativos que publica, entre outras
coisas, os **CIS Controls**: uma lista curta e priorizada das ações de defesa que param os ataques mais
comuns. Eles começaram em 2008 como uma lista reunida por profissionais que olharam o que os atacantes de
fato faziam e perguntaram quais defesas os teriam parado. A versão atual, a **v8.1**, saiu em 2024 e
mantém a estrutura da v8 de 2021: **18 controles**, divididos em **153 salvaguardas**.

| nº | controle | do que trata |
|---|---|---|
| 1 | inventário e controle de ativos da empresa | conhecer cada aparelho que você tem |
| 2 | inventário e controle de ativos de software | conhecer cada programa, e permitir só o aprovado |
| 3 | proteção de dados | saber onde estão os dados sensíveis, e protegê-los |
| 4 | configuração segura de ativos e software | endurecer cada sistema a partir dos padrões inseguros |
| 5 | gestão de contas | toda conta conhecida, necessária, e desativada quando não for |
| 6 | gestão de controle de acesso | menor privilégio e MFA (aulas 6, 9) |
| 7 | gestão contínua de vulnerabilidades | achar e corrigir falhas conhecidas (aula 2) |
| 8 | gestão de logs de auditoria | coletar logs e mantê-los utilizáveis (aulas 10, 11) |
| 9 | proteções de e-mail e navegador | os dois caminhos por onde atacantes mais entram |
| 10 | defesas contra malware | parar e detectar software malicioso |
| 11 | recuperação de dados | backups que restauram (aula 12) |
| 12 | gestão da infraestrutura de rede | manter os equipamentos de rede seguros e atualizados |
| 13 | monitoramento e defesa da rede | vigiar a rede, segmentá-la (aula 5) |
| 14 | conscientização e treinamento em segurança | pessoas como camada (aula 4) |
| 15 | gestão de provedores de serviço | fornecedores que guardam seus dados |
| 16 | segurança de software de aplicação | software que você constrói ou compra |
| 17 | gestão de resposta a incidentes | um plano, papéis e prática (aula 10) |
| 18 | testes de invasão | testar as defesas como um atacante testaria |

### Por que a ordem importa

A lista não é alfabética nem por assunto. Ela segue **mais ou menos a ordem em que uma defesa deve ser
construída**, e as duas primeiras são o exemplo mais claro: você não protege, não aplica patch, não
configura nem monitora um aparelho que não sabe que existe. Muitos incidentes começam na máquina de que
ninguém lembrava: um servidor velho embaixo de uma mesa, um ambiente de teste esquecido ligado, um
notebook que foi embora com um ex-funcionário. Inventário não tem glamour, e vem primeiro porque todo
controle seguinte depende dele.

Essa ordem é a força particular dos CIS Controls ao lado dos frameworks das aulas 14 e 15. A ISO 27001 e
o NIST CSF dizem a uma organização o que um programa completo cobre. Os CIS Controls dizem **por onde
começar**, e essa é a pergunta que uma equipe pequena de fato tem.
