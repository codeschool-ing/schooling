---
title: Quando o Flux informa uma falha
version: 1
---

O Flux informa uma falha como `READY False` no objeto que falhou, com o motivo na mensagem, e a
cadeia da fonte até a Kustomization diz onde olhar primeiro: **uma fonte que não está pronta deixa
tudo o que vem depois parado no tempo, então leia a cadeia da esquerda para a direita.** Cada uma
destas foi produzida de propósito, e consertada de novo.

## Credenciais que pararam de funcionar

O Secret `fleet-auth` é trocado por um token que não existe, e a fonte é mandada buscar:

```
ana@laptop:~/fleet$ kubectl -n flux-system create secret generic fleet-auth --from-literal=username=flux --from-literal=password=0123456789abcdef --dry-run=client -o yaml | kubectl apply -f -
Warning: resource secrets/fleet-auth is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
secret/fleet-auth configured
ana@laptop:~/fleet$ flux reconcile source git flux-system
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✗ context deadline exceeded
ana@laptop:~/fleet$ flux get sources git
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                                                                      
flux-system	main@sha1:218c0baa	False    	False	failed to checkout and determine revision: unable to list remote for 'http://gitea:3000/ana/fleet.git': authentication required: Failed to authenticate user	
           	                  	         	     	                                                                                                                                                            	
ana@laptop:~/fleet$ flux get kustomizations
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                              
flux-system	main@sha1:218c0baa	False    	True 	Applied revision: main@sha1:218c0baa	
staging    	main@sha1:218c0baa	False    	True 	Applied revision: main@sha1:218c0baa	
```

O `GitRepository` não está pronto, e a mensagem é a recusa do servidor Git. As Kustomizations
continuam dizendo `True`, sobre o último artefato que aplicaram, e essa é a armadilha: **nada está
sendo publicado e nada mais adiante parece quebrado.** O `flux get sources git` é o primeiro comando
depois de qualquer "minha mudança não chegou".

## Um deployment que nunca fica pronto

Com `wait: true`, uma Kustomization só está pronta quando o que ela aplicou está. Um pull request
leva o staging para uma tag de imagem que não existe:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-1.9
ana@laptop:~/fleet$ git commit --quiet -am "staging: bulletin 1.9"
ana@laptop:~/fleet$ flux reconcile kustomization staging --with-source
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:419a987b0b377a51f0d172d951d2746cf749837d
► annotating Kustomization staging in flux-system namespace
✔ Kustomization annotated
◎ waiting for Kustomization reconciliation
✗ context deadline exceeded
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                           
staging	main@sha1:218c0baa	False    	False	health check failed after 2m0.020638498s: timeout waiting for: [Deployment/staging/bulletin status: 'InProgress']	
```

O `flux reconcile` desistiu de esperar antes, com `context deadline exceeded`. A própria Kustomization
diz mais: `health check failed` depois dos dois minutos do `timeout`, citando o Deployment que não
ficou pronto, e o `REVISION` ainda mostra a última revisão que deu certo, a revisão para onde voltar.
A aula 2 achou a mesma falha lendo pods; aqui o agente a informa, num objeto que qualquer um
consulta. A correção é a mesma: um revert, por um pull request.
