---
title: Rotacionando uma credencial que precisa ser estática
version: 1
---

Algumas credenciais não podem ser feitas na hora: o servidor Git emite tokens, e a automação de
imagens da aula 7 precisa de um que funcione às três da manhã sem ninguém. Essas são rotacionadas, e
**uma rotação são quatro passos numa ordem fixa**, porque cada passo só tira risco se o anterior deu
certo:

1. fazer a credencial nova, com a antiga ainda funcionando;
2. pôr a nova em todo lugar onde a antiga era usada;
3. conferir que tudo funciona com a nova;
4. revogar a antiga, e conferir que ela é recusada.

Em outra ordem, vira interrupção: revogar primeiro e a automação para até alguém notar; entregar sem
conferir e a revogação quebra o que ficou esquecido.

O token do `image-bot` é o exemplo. O novo ganha um nome próprio, para que os dois se distingam na
lista do Gitea:

```
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username image-bot --token-name automation-2 --scopes write:repository --raw > ~/image-bot-2.token 2>/dev/null && chmod 600 ~/image-bot-2.token
ana@laptop:~$ curl -s -u image-bot:change-me-please http://localhost:3000/api/v1/users/image-bot/tokens | jq -r '.[].name'
automation-2
automation
```

O Secret de onde o Flux o lê é substituído no lugar, com o mesmo comando que o criou na aula 7:

```
ana@laptop:~$ flux create secret git fleet-writer-auth --url=http://gitea:3000/ana/fleet.git --username=image-bot --password="$(cat ~/image-bot-2.token)"
► git secret 'fleet-writer-auth' created in 'flux-system' namespace
ana@laptop:~$ flux reconcile source git fleet-writer
► annotating GitRepository fleet-writer in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:2ae2f398ededc41379cfd3116d0bcc90c97c2269
ana@laptop:~$ flux get sources git fleet-writer
NAME        	REVISION          	SUSPENDED	READY	MESSAGE                                           
fleet-writer	main@sha1:2ae2f398	False    	True 	stored artifact for revision 'main@sha1:2ae2f398'	
```

O `flux reconcile` é o passo 3: o Flux buscou o `fleet` com o Secret que tem agora, então o token
novo funciona. Os dois tokens valem neste ponto, e é isso que torna a ordem segura.

E só então o token antigo sai. O Gitea deixa uma conta apagar os próprios tokens, pelo nome:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -u image-bot:change-me-please -X DELETE http://localhost:3000/api/v1/users/image-bot/tokens/automation
204
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: token $(cat ~/image-bot.token)" http://localhost:3000/api/v1/repos/ana/fleet
401
ana@laptop:~$ mv ~/image-bot-2.token ~/image-bot.token
ana@laptop:~$ flux reconcile source git fleet-writer && flux get sources git fleet-writer
► annotating GitRepository fleet-writer in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:2ae2f398ededc41379cfd3116d0bcc90c97c2269
NAME        	REVISION          	SUSPENDED	READY	MESSAGE                                           
fleet-writer	main@sha1:2ae2f398	False    	True 	stored artifact for revision 'main@sha1:2ae2f398'	
```

`204` para a remoção, e `401` para o token antigo logo depois: recusado, que é a conferência do
passo 4. O token novo vai para o lugar do arquivo antigo, e o Flux continua buscando.

**A ordem é a mesma para toda credencial estática deste curso.** A chave do cosign da aula 8 tem a
nova chave pública publicada ao lado da antiga. A chave do age da aula 9 pede todo arquivo recifrado
para as duas chaves antes. O controlador do Sealed Secrets faz isso sozinho, acrescentando uma chave
nova e mantendo a antiga. O que muda de uma para outra é só até onde o passo 2 precisa chegar, e
vale escrever essa lista antes do dia em que ela for necessária.
