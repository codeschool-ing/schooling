---
title: Versionar o que você constrói
version: 1
---

Uma imagem é algo que outras pessoas ligam, então ela precisa do mesmo que a aula 10 pediu de um
módulo: **um nome que sempre signifique o mesmo conteúdo**. Com a versão digitada no template, cada
build exige uma edição em dois lugares, e no dia em que alguém esquecer um deles, `1.0.1` passa a
nomear duas imagens diferentes.

A Ana tira a versão do template e põe o commit do git ao lado dela. As duas viram variáveis, a versão
também entra na imagem como label, e um segundo post-processor anota o que foi construído:

```
ana@laptop:~/shop/image$ git diff
diff --git a/web.pkr.hcl b/web.pkr.hcl
index 87b3f2a..554e9e1 100644
--- a/web.pkr.hcl
+++ b/web.pkr.hcl
@@ -7,6 +7,16 @@ packer {
   }
 }
 
+variable "version" {
+  type        = string
+  description = "The image's version: a new one for every build that ships."
+}
+
+variable "commit" {
+  type        = string
+  description = "The git commit the image was built from."
+}
+
 source "docker" "web" {
   image  = "ubuntu:24.04"
   pull   = false
@@ -14,6 +24,8 @@ source "docker" "web" {
   changes = [
     "CMD [\"nginx\", \"-g\", \"daemon off;\"]",
     "EXPOSE 80",
+    "LABEL org.opencontainers.image.version=${var.version}",
+    "LABEL org.opencontainers.image.revision=${var.commit}",
   ]
 }
 
@@ -25,12 +37,21 @@ build {
       "apt-get update -qq",
       "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
       "sed -i '/::/d' /etc/nginx/sites-available/default",
-      "echo 'shop web 1.0.1' > /var/www/html/index.html",
+      "echo 'shop web ${var.version}' > /var/www/html/index.html",
     ]
   }
 
   post-processor "docker-tag" {
     repository = "shop-web"
-    tags       = ["1.0.1"]
+    tags       = [var.version]
+  }
+
+  post-processor "manifest" {
+    output     = "manifest.json"
+    strip_path = true
+    custom_data = {
+      version = var.version
+      commit  = var.commit
+    }
   }
 }
```

Três mudanças, cada uma respondendo a uma pergunta diferente mais tarde.

**As variáveis não têm default**, então um build que não recebe a versão se recusa a começar:

```
ana@laptop:~/shop/image$ packer build .
Error: Unset variable "version"

A used variable must be set or have a default value; see
https://packer.io/docs/templates/hcl_templates/syntax for details.

Error: Unset variable "commit"

A used variable must be set or have a default value; see
https://packer.io/docs/templates/hcl_templates/syntax for details.
```

Essa recusa é o objetivo. Não existe build sem número, nem número inventado pelo Packer.

**Os labels vão para dentro da imagem.** `org.opencontainers.image.version` e `.revision` são nomes
da lista de labels padrão da Open Container Initiative, então outras ferramentas sabem onde procurar.
Quem encontrar a imagem numa máquina meses depois pode perguntar a ela de onde veio, sem acesso a log
de build nenhum.

**O post-processor manifest** escreve `manifest.json` no diretório do template, com o id de cada
imagem que o build produziu e o que mais for acrescentado em `custom_data`. É o que a etapa seguinte
de um pipeline lê para saber o que foi construído: qual id de imagem, a partir de qual commit, com
qual nome.

O build recebe os dois valores de fora, o commit vindo do próprio git:

```
ana@laptop:~/shop/image$ packer build -var version=1.1.0 -var commit=$(git rev-parse --short HEAD) . 2>&1 | grep -E "Image ID|Repository|manifest|finished after"
==> docker.web: Image ID: sha256:66c75f9f452ad4603eb62f125b1e170888e6424e383fd9b6c05b6c8776669b4a
==> docker.web (docker-tag): Repository: shop-web:1.1.0
==> docker.web: Running post-processor:  (type manifest)
Build 'docker.web' finished after 15 seconds 604 milliseconds.
```

```
ana@laptop:~/shop/image$ jq . manifest.json
{
  "builds": [
    {
      "name": "web",
      "builder_type": "docker",
      "build_time": 1790955038,
      "files": null,
      "artifact_id": "sha256:66c75f9f452ad4603eb62f125b1e170888e6424e383fd9b6c05b6c8776669b4a",
      "packer_run_uuid": "e5aaf2b3-230a-b64d-49c2-248bff336809",
      "custom_data": {
        "commit": "95a92c5",
        "version": "1.1.0"
      }
    }
  ],
  "last_run_uuid": "e5aaf2b3-230a-b64d-49c2-248bff336809"
}
```

```
ana@laptop:~/shop/image$ docker image inspect shop-web:1.1.0 --format '{{json .Config.Labels}}'
{"org.opencontainers.image.revision":"95a92c5","org.opencontainers.image.version":"1.1.0"}
ana@laptop:~/shop/image$ docker run --rm shop-web:1.1.0 cat /var/www/html/index.html
shop web 1.1.0
ana@laptop:~/shop/image$ git log --oneline -1
95a92c5 version and commit come from outside
```

O commit no label e no manifest é o que o `git log` imprime, então a imagem pode ser rastreada até o
template exato que a construiu. A lista de imagens agora tem três versões, cada uma uma imagem
própria:

```
ana@laptop:~/shop/image$ docker images shop-web
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
shop-web:1.0.0   62e9c4686c66        219MB         70.3MB        
shop-web:1.0.1   2aaf4859b5ed        219MB         70.3MB        
shop-web:1.1.0   66c75f9f452a        219MB         70.3MB        
```

## Por que não `latest`

O Docker dá a uma imagem a tag `latest` quando ninguém nomeia uma, e muito deploy diz `latest`
porque ela está sempre lá. **Uma tag é um ponteiro, e um ponteiro pode ser movido.** A `latest` é
movida por todo build, então duas máquinas ligadas a partir de `shop-web:latest` com uma semana de
diferença podem estar rodando imagens diferentes enquanto todo arquivo que as descreve continua
igual. E um rollback para `latest` não é rollback nenhum, porque ela nomeia o que foi construído por
último, que é justamente o que se quer desfazer.

A imagem base mostra a mesma coisa vista de fora. O Ubuntu 24.04 saiu em abril de 2024, e esta é a
data em que foi criada a imagem por trás da tag `ubuntu:24.04` neste notebook:

```
ana@laptop:~/shop/image$ docker image inspect ubuntu:24.04 --format '{{.Created}}'
2026-09-11T11:44:06.579973371Z
```

A Canonical reconstrói essa imagem a cada leva de atualizações e move a tag para a nova. É o certo a
fazer do lado deles, e significa que `ubuntu:24.04` é uma base diferente em dias diferentes.

A regra que sai daí é curta. **Em produção, nomeie imagens por uma versão que nunca é reutilizada**,
e trate uma tag como `latest` ou `24.04` como conveniência para uma pessoa no terminal. Registries
conseguem impor isso: o Amazon ECR, por exemplo, pode ser configurado para recusar o push de uma tag
que já existe. A imagem base precisa de um nome mais forte que uma versão, e a última seção desta
aula dá um a ela.
