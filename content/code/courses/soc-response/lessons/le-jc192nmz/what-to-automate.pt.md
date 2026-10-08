---
title: O que vale automatizar
version: 1
---

**SOAR**, *security orchestration, automation and response*, é o nome da maquinaria que age sobre os
alertas: recebe um do SIEM, executa uma sequência de passos e aciona outros sistemas (um firewall, um
diretório, uma ferramenta de chamados, um canal de mensagens) pelas interfaces deles. Como no SIEM, os
produtos diferem e a ideia não.

Uma crença comum é que o SOAR serve para responder mais rápido do que uma pessoa consegue. **A maior parte
do valor dele está na parte chata antes da resposta**: juntar os mesmos fatos pela centésima vez, na mesma
ordem, sem esquecer nenhum. A decisão costuma continuar sendo de uma pessoa. Cinco perguntas decidem se um
passo cabe a uma máquina:

| pergunta | automatize quando |
|---|---|
| **Com que frequência?** | acontece muitas vezes por semana; uma tarefa anual sai mais barata à mão |
| **Quanto julgamento?** | as mesmas entradas merecem sempre a mesma saída |
| **Quão reversível?** | um erro se desfaz em segundos, sem nada perdido |
| **Quão amplo?** | mexe num endereço, num host, numa conta, nunca numa rede inteira |
| **Quão bem entendido?** | a equipe já fez à mão, do mesmo jeito, vezes o bastante para escrever |

O enriquecimento passa nas cinco, e é por isso que é a primeira coisa que toda equipe automatiza. Bloquear
um endereço externo no firewall passa na maioria: frequente, estreito, reversível num comando. Desativar a
conta de um funcionário falha na segunda e na quarta, porque para o trabalho de alguém e a decisão certa
depende de quem a pessoa é e do que estava fazendo. Apagar um notebook falha em quase todas.

A tabela tem uma sexta linha que ninguém escreve: **automatize só o que você consegue medir**. Um playbook
que roda quatrocentas vezes por mês sem ninguém contar quantas vezes acertou é uma fonte de incidentes, não
uma defesa contra eles. A última seção desta aula volta a isso.
