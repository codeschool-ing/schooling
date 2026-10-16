---
title: A vida de uma credencial é o seu risco
version: 1
---

**Uma credencial que vaza é perigosa enquanto continuar funcionando.** Quase nenhum vazamento é
notado quando acontece: um token colado num chamado, o backup de um notebook no bucket errado, uma
linha de log que imprimiu um cabeçalho. O que limita o estrago não é a detecção, é a expiração, e
uma credencial que nunca expira transforma todo vazamento passado num vazamento presente.

Este curso já criou uma dúzia de credenciais, e elas não são todas iguais:

| credencial | criada na | vive | se vazar |
|---|---|---|---|
| os tokens do Gitea, da Ana e dos robôs | aulas 2, 3, 4, 7 | até ser revogada | faz push e merge como aquela conta |
| a chave privada do cosign e sua senha | aula 8 | até ser trocada | assina qualquer coisa como a chave de release |
| as chaves do Sealed Secrets | aula 9 | renovadas a cada 30 dias, as antigas mantidas | abre todo selo já feito |
| a chave privada do age | aula 9 | até ser trocada | lê todo arquivo SOPS do histórico |
| a chave de unseal e o token root do Vault | aula 9 | até ser revogada | tudo o que o Vault guarda |
| o token de longa duração do `vault-auth` | aula 9 | enquanto o Secret dele existir | pergunta ao API server sobre qualquer token |
| um token de ServiceAccount do `kubectl create token` | aula 9 | uma hora | age como aquela ServiceAccount |
| um token do Vault vindo do login do Kubernetes | aula 9 | dez minutos | lê o token de produção |

**As duas últimas são a forma a buscar**: feitas na hora, para um propósito, e extintas antes que
alguém consiga usar uma cópia. Todo o resto acima delas é credencial que alguém precisa rotacionar à
mão, num calendário, e revogar no dia em que vazar. Cada rotação é um pequeno projeto: fazer a nova,
entregá-la em todo lugar onde a antiga era usada, conferir que nada mais usa a antiga e só então
revogá-la.

Esta aula faz três coisas a respeito. Cria uma senha de banco de dados que vive uma hora, para que
não haja o que rotacionar. Rotaciona as que precisam ser estáticas, e revoga algumas. E estreita o
que cada identidade pode fazer, para que a próxima que vazar possa fazer menos.
