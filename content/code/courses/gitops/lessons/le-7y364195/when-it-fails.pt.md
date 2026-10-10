---
title: Quando a organização quebra alguma coisa
version: 1
---

Uma organização falha nas referências: um arquivo apontando para outro por caminho ou por nome. Cada
uma destas foi produzida de propósito, com uma Kustomization de teste aplicada à mão e apagada depois.

## Um caminho que mudou de lugar

Uma Kustomization ainda apontando para o `./staging` antigo, depois da mudança para
`apps/bulletin/staging`:

```
ana@laptop:~/setup$ flux get kustomizations probe-path
NAME      	REVISION	SUSPENDED	READY	MESSAGE                                                                                           
probe-path	        	False    	False	kustomization path not found: stat /tmp/kustomization-21424086/staging: no such file or directory	
```

`kustomization path not found`, com o caminho completo dentro do artefato. O Flux não faz nada com um
caminho que não acha, e os objetos que aplicou antes ficam como estão; a Kustomization continua não
pronta até o caminho ser corrigido no Git.

## Uma dependência que não existe

Um `dependsOn` citando uma Kustomization que não está lá, um erro de digitação ou uma que foi
renomeada:

```
ana@laptop:~/setup$ flux get kustomizations probe-depends
NAME         	REVISION	SUSPENDED	READY	MESSAGE                                                                                                  
probe-depends	        	False    	False	dependency 'flux-system/stagin' not found: kustomizations.kustomize.toolkit.fluxcd.io "stagin" not found	
```

A Kustomization espera, e diz pelo quê. Uma Kustomization renomeada é a causa comum, e é por isso que
um renome em `clusters/` ganha uma busca pelo nome antigo na pasta inteira antes do merge.
