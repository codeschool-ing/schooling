---
title: Um arquivo, dois objetos
version: 1
---

**Um primeiro manifesto costuma ser copiado de algum lugar e editado até funcionar, e isso deixa quem
lê sem saber quais linhas importam.** Quase todas importam. Este guarda os dois objetos com que toda
aplicação web no Kubernetes começa: um Deployment, que mantém cópias da loja rodando, e um Service,
que dá a essas cópias um endereço. Leia um pedaço de cada vez:

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\n  labels:\n    app: shop\n", "note": "**O que o objeto é e como se chama**: um Deployment, da API `apps/v1`, chamado `shop`. O label no próprio Deployment serve só para encontrá-lo."}, {"code": "spec:\n  replicas: 3\n", "note": "**Quantas cópias devem existir.** Este é o número que o laço da lição 1 mantém verdadeiro."}, {"code": "  selector:\n    matchLabels:\n      app: shop\n", "note": "**Quais pods contam como deste Deployment.** O seletor precisa bater com os labels do modelo abaixo, ou o API server recusa o objeto."}, {"code": "  template:\n    metadata:\n      labels:\n        app: shop\n", "note": "**O pod de que se fazem cópias.** Toda cópia recebe estes labels, e é assim que o seletor e, depois, o Service a encontram."}, {"code": "    spec:\n      containers:\n      - name: shop\n        image: shop:1.0\n        ports:\n        - containerPort: 8080\n", "note": "**O container dentro de cada pod**: a imagem e a porta em que ele escuta. `containerPort` documenta a porta; não abre nem publica nada."}, {"code": "---\n"}, {"code": "apiVersion: v1\nkind: Service\nmetadata:\n  name: shop\n", "note": "**Um segundo objeto no mesmo arquivo**, separado por `---`: um Service, também chamado `shop`. Objetos de tipos diferentes podem ter o mesmo nome."}, {"code": "spec:\n  selector:\n    app: shop\n", "note": "**O mesmo label de novo.** Todo pod com `app: shop` fica atrás deste Service, seja quem for que o criou."}, {"code": "  ports:\n  - port: 80\n    targetPort: 8080\n", "note": "**A porta 80 do endereço do Service leva à porta 8080 de um pod.** Os clientes usam a 80; a loja nunca precisa saber."}]}
```

Três coisas nele valem ser guardadas na memória agora, porque todas as lições seguintes dependem
delas.

**Os labels são a cola.** `app: shop` aparece quatro vezes, e nenhuma é decoração. O modelo o carimba
em todo pod; o seletor do Deployment o usa para contar os seus pods; o seletor do Service o usa para
saber para onde mandar o tráfego. Mude num lugar e não nos outros, e o Deployment deixa de reconhecer
os próprios pods, ou o Service fica sem ter para onde mandar uma requisição.

**Nada aqui nomeia um nó, um endereço ou um pod.** O arquivo diz o que deve existir e deixa o onde e
o qual para o cluster. É por isso que o mesmo arquivo roda sem mudança no laptop, num cluster
gerenciado e no próximo cluster que alguém montar.

**Dois números parecidos não são a mesma porta.** `8080` é onde a loja escuta dentro do container, e
`80` é o que o Service oferece aos clientes. `targetPort` liga os dois. Um cliente nunca fica sabendo
da 8080, então a loja poderia mudar de porta com uma edição neste arquivo e ninguém que a chama
perceberia.

O arquivo é YAML comum, e três detalhes derrubam as pessoas no primeiro. A indentação é estrutura,
então dois espaços no lugar errado movem um campo para outro objeto sem aviso. Um item de lista
começa com `-`, e é por isso que `containers` e `ports` têm traços e `selector` não tem. E `---`
sozinho numa linha separa documentos, então um arquivo pode guardar quantos objetos quiser, aplicados
juntos na ordem em que aparecem.
