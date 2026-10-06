---
title: Quando recorrer a ele
version: 1
---

Um servidor é um programa, um protocolo e uma fronteira, e cada um tem custo. A execução da seção 03 iniciou um processo separado para cada hospedeiro, com o `tee` na frente, e trocou de quatro a seis mensagens antes e em volta de uma chamada de ferramenta. Para um agente que é dono das próprias ferramentas, uma função no processo (o `@function_tool` da aula 8, a função simples da aula 10) faz o mesmo trabalho sem nada disso.

O MCP vale o lugar quando uma destas é verdade:

- **A ferramenta é usada por mais de um hospedeiro.** A mesma consulta de pedidos para o agente de suporte, o assistente de chat da equipe e o editor de um desenvolvedor: um servidor, escrito e corrigido uma vez.
- **A ferramenta pertence a outra pessoa.** Outra equipe, ou um fornecedor, publica um servidor; você se conecta a ele em vez de escrever um adaptador para a API deles, e eles podem mudar o lado deles sem quebrar o seu enquanto o protocolo se mantiver.
- **A ferramenta deve rodar em outro lugar.** Um servidor com acesso ao banco de pedidos pode rodar perto do banco, sob conta própria, e o hospedeiro do agente o alcança pela rede com credenciais (aula 16) em vez de guardar ele mesmo a senha do banco.
- **Quem escolhe as ferramentas é a pessoa, não o desenvolvedor.** Assistentes que deixam os usuários acrescentar servidores foram o que tornou o MCP comum: o hospedeiro é fixo, e as ferramentas são o que a pessoa instalar.

O terceiro motivo é também um argumento de segurança. Uma ferramenta no seu processo roda com as permissões do seu processo, e um servidor stdio local também (a seção 08 da aula 7 de `ai-dev` diz isso com todas as letras). Um servidor remoto pode receber exatamente o acesso de que precisa e nada mais, que é o privilégio mínimo da aula 17 desenhado como fronteira de processo.

E o custo na direção contrária: **todo servidor que você conecta é código que você roda ou um serviço em que você confia**, com as próprias descrições na frente do seu modelo. A pergunta a fazer não é se existe um servidor para alguma coisa, mas se você aceitaria as palavras do autor dele no seu prompt e o processo dele na sua máquina ou na frente dos seus dados.
