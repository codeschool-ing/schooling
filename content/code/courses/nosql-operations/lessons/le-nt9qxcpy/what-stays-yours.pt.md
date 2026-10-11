---
title: O que continua sendo seu
version: 1
---

Tudo acima da linha é uma decisão sobre **os seus dados e o seu dinheiro**, e o provedor executa
qualquer uma que você tome, inclusive a errada. Um MongoDB gerenciado aceita uma shard key que manda
toda escrita para um único shard; um Cassandra gerenciado guarda uma partição de um gigabyte; um
Redis gerenciado expulsa as sessões de clientes logados se essa for a política que recebeu. Nada
disso é uma queda pela qual o provedor responde, e nada disso aparece na página de status dele.

## A lista, com a aula que ensinou cada item

| continua seu | por que o provedor não pode decidir | aula |
|---|---|---|
| o modelo de dados: documentos, partições, que dado é duplicado | ele decorre das suas consultas, que só você conhece | 3, 4 |
| índices | um índice é uma troca entre as leituras que você faz e as escritas que você paga | 7 |
| a shard key | ela é fixada na criação, e mudá-la depois é uma migração de tudo | 10 |
| write concern, read preference, níveis de consistência | cada um é uma escolha por operação entre latência e uma garantia | 9, 17 |
| a política de expulsão, e se o Redis é cache ou banco | a mesma memória cheia é normal para um e perda de dados para o outro | 14 |
| capacidade, e a conta que ela gera | o provedor vende mais; decidir que você precisa é seu | 20 |
| testes de restauração | um backup que ninguém restaurou é uma esperança, e o do provedor não é exceção | 11 |
| quem tem acesso, e de onde | o provedor aplica as regras; ele não sabe quem deveria estar nelas | |

**A conta merece uma frase própria.** Nas suas próprias máquinas, um banco que cresce custa um disco
que você compra uma vez. Num serviço gerenciado, quase todo eixo é uma linha da fatura:
armazenamento, memória, operações ou unidades de capacidade, armazenamento de backup além da franquia
gratuita, e dados saindo da rede do provedor. Uma tabela mal modelada que lê mil linhas para devolver
dez (aula 18) é uma consulta lenta no seu hardware e um custo mensal num serviço que cobra por
leitura.

## Testes de restauração, quando outra pessoa faz o backup

Os backups do provedor são reais, e são também a única parte do serviço que você não consegue ver
funcionando até usá-la. **Um teste de restauração num serviço gerenciado responde três perguntas**
que a documentação não responde: quanto tempo leva restaurar os seus dados de verdade, o que falta na
cópia restaurada (usuários e papéis, índices ainda sendo construídos, configurações que ficam fora
dos dados) e quem na sua equipe sabe onde fica o botão.

A maioria dos serviços restaura numa instância nova ao lado da antiga, não por cima dela. Faça
exatamente isso, num calendário, aponte uma cópia da aplicação para o resultado e anote o tempo que
levou. O número vai para o runbook, e é o mesmo número de que o plano de saída da próxima seção
precisa.

## Acesso

Um banco gerenciado é alcançável por uma rede que não é sua, por padrão de mais lugares que os
contêineres deste curso, que não tinham porta publicada nenhuma. **As três configurações que o mantêm
privado** existem em todo provedor com nomes diferentes: o banco alcançável só pela sua rede privada
(um peering de VPC ou um endpoint privado), e não pela internet; TLS obrigatório em toda conexão; e
uma conta por aplicação e por pessoa, cada uma com o mínimo de que precisa, para que uma senha vazada
abra uma porta só. O provedor grava um log de auditoria de quem se conectou; lê-lo é com você.
