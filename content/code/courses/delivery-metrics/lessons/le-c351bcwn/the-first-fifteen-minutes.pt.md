---
title: A cobrança em dobro de 30 de setembro, minuto a minuto
version: 1
---

Em 30 de setembro, às 17h20, o pipeline do time de Billing fez o deploy da versão `D047`, com quatro mudanças. Ela está em `deploys.csv`, marcada como falha, com o serviço restaurado às 18h15. Esta seção, e as duas próximas aulas, desmontam essa falha. Os minutos abaixo e as falas das pessoas foram escritos para o curso; o deploy, o horário dele e a restauração são os que `billing.py` produziu.

Era o último dia do mês, quando rodam as cobranças das assinaturas mensais. Uma das quatro mudanças, `BIL-218`, tinha acrescentado uma retentativa para quando o provedor de cartão demorasse a responder. Sob a carga de fim de mês, o provedor ficou lento, e a retentativa cobrou de novo cartões cuja primeira cobrança tinha, na verdade, passado.

## Os primeiros quinze minutos

**17h38.** A dona de uma loja liga para o suporte: foi cobrada duas vezes pela assinatura. A atendente, Lia, confere a conta dela e vê as duas cobranças.

**17h41.** Lia posta no canal do time de Billing, com o id da loja e os ids das duas cobranças. **Ela não espera** encontrar um segundo caso; uma cobrança em dobro num produto de pagamentos basta para perguntar.

**17h44.** Rafa, de plantão naquela semana, confirma o recebimento e vai olhar. Encontra mais onze cobranças duplicadas nos últimos vinte minutos.

**17h46.** Rafa declara um incidente com o comando do chat, que cria o canal `#inc-0930-double-charge`, e o classifica como **SEV2**: dinheiro de verdade, mas ele ainda não sabe quantas lojas.

**17h49.** Bia entra e assume como **comandante do incidente**. Ela nomeia os papéis numa só mensagem: Rafa líder técnico, Duda escriba, Caio comunicação. A primeira tarefa de Caio é dizer ao suporte o que falar: "Sabemos das cobranças em dobro desde as 17h20, estamos trabalhando nisso, os reembolsos virão."

**17h53.** Rafa relata 140 cobranças duplicadas, e subindo. Bia eleva o incidente para **SEV1** e pede a Caio que avise o head de engenharia e publique um aviso na página de status.

São quinze minutos desde a primeira ligação, e ninguém sabe ainda a causa. Ninguém precisa saber. As pessoas certas estão trabalhando, cada uma sabe o seu papel, o time de suporte tem uma frase para dizer, e os usuários têm um aviso. **O que vem a seguir é uma decisão entre consertar e desfazer**, e a aula 14 continua daí.

## O que deu certo, e o que não deu

A resposta teve a forma que esta aula descreve: uma pergunta cedo do suporte, uma declaração barata, uma severidade elevada conforme os fatos chegavam, papéis nomeados numa só mensagem. Duas coisas merecem atenção para mais adiante.

**A detecção veio de um cliente.** O deploy saiu às 17h20 e o primeiro sinal foi uma ligação dezoito minutos depois. Nenhum alerta disparou. A aula 18 trata de quais alertas deveriam existir, e uma cobrança duplicada é uma forte candidata.

**O tempo para restaurar em `deploys.csv` começou às 17h20**, no deploy, e não às 17h46, na declaração. A aula 5 disse para decidir quando começa o relógio da restauração, e aqui está por que isso importa: medido a partir da declaração, este incidente parece duas vezes mais rápido do que foi para as lojas.
