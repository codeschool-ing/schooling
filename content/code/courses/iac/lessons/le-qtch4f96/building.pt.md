---
title: Construir a imagem, e rodá-la
version: 1
---

Três comandos, na mesma ordem dos do Terraform. `packer init` instala os plugins que o bloco
`packer` pede, `packer fmt` confere a formatação, e `packer validate` confere o template sem
construir nada:

```
ana@laptop:~/shop/image$ packer init .
ana@laptop:~/shop/image$ packer fmt -check .
ana@laptop:~/shop/image$ packer validate .
The configuration is valid.
```

O `packer init` não imprimiu nada porque o plugin do Docker já estava instalado neste notebook; numa
máquina nova ele o baixa e avisa. O `fmt -check` fica calado quando o arquivo já está formatado.
Depois, o build:

```
ana@laptop:~/shop/image$ packer build .
docker.web: output will be in this color.

==> docker.web: Creating a temporary directory for sharing data...
==> docker.web: Starting docker container...
==> docker.web: Run command: docker run -v /tmp/tmp2323089762:/packer-files -d -i -t --entrypoint=/bin/sh -- ubuntu:24.04
==> docker.web: Container ID: 4d07b26f46f96b7f27b91fd55dae33d244021c2e9c73e3b9742b5562463ab978
==> docker.web: Provisioning with shell script: /tmp/packer-shell915544868
==> docker.web: debconf: delaying package configuration, since apt-utils is not installed
==> docker.web: Committing the container
==> docker.web: Image ID: sha256:62e9c4686c66329965b7e533d2162c07b0e77cca1a3e37ffd7b09aa314cdbc58
==> docker.web: Killing the container: 4d07b26f46f96b7f27b91fd55dae33d244021c2e9c73e3b9742b5562463ab978
==> docker.web: Running post-processor:  (type docker-tag)
==> docker.web (docker-tag): Tagging image: sha256:62e9c4686c66329965b7e533d2162c07b0e77cca1a3e37ffd7b09aa314cdbc58
==> docker.web (docker-tag): Repository: shop-web:1.0.0
Build 'docker.web' finished after 17 seconds 998 milliseconds.

==> Wait completed after 17 seconds 998 milliseconds

==> Builds finished. The artifacts of successful builds are:
--> docker.web: Imported Docker image: sha256:62e9c4686c66329965b7e533d2162c07b0e77cca1a3e37ffd7b09aa314cdbc58
--> docker.web: Imported Docker image: shop-web:1.0.0 with tags shop-web:1.0.0
```

Leia como **os quatro passos da seção anterior**. O Packer liga um contêiner a partir do
`ubuntu:24.04` (a linha `Run command` é o `docker run` que ele usou), roda nele o script do
provisioner, faz o commit do contêiner como imagem, mata o contêiner e entrega a imagem ao
post-processor, que põe a tag. A linha do `debconf` é o apt reclamando dentro do contêiner, não um
erro. E a imagem existe:

```
ana@laptop:~/shop/image$ docker images shop-web
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
shop-web:1.0.0   62e9c4686c66        219MB         70.3MB        
```

## Um build bem-sucedido não é uma imagem que funciona

**O Packer informou sucesso porque cada passo saiu com status zero.** É só isso que ele confere.
Então a Ana liga a imagem do jeito que uma máquina ligaria:

```
ana@laptop:~/shop/image$ docker run --rm shop-web:1.0.0
nginx: [emerg] socket() [::]:80 failed (97: Address family not supported by protocol)
```

O nginx parou na hora. O site padrão dele escuta em IPv6 além de IPv4, e a máquina onde esta aula
foi gravada não dá IPv6 nenhum aos contêineres:

```
ana@laptop:~/shop/image$ docker run --rm shop-web:1.0.0 grep -n "listen" /etc/nginx/sites-available/default
22:	listen 80 default_server;
23:	listen [::]:80 default_server;
27:	# listen 443 ssl default_server;
28:	# listen [::]:443 ssl default_server;
80:#	listen 80;
81:#	listen [::]:80;
ana@laptop:~/shop/image$ docker run --rm shop-web:1.0.0 ls /proc/net/if_inet6
ls: cannot access '/proc/net/if_inet6': No such file or directory
```

A segunda linha `listen` do site padrão, `[::]:80`, é a que o nginx não consegue abrir, e a ausência
de `/proc/net/if_inet6` é o kernel dizendo que aqui não há IPv6. No seu notebook a imagem talvez
ligue sem problema. Esse é justamente o ponto: o build rodou numa máquina e a imagem roda em outras,
e **o código de saída de um provisioner não diz nada sobre o resultado funcionar onde vai rodar**.
Só ligar a imagem diz, e é por isso que um pipeline de imagens roda a imagem e pergunta algo a ela
antes de publicá-la, do mesmo jeito que a aula 13 roda um módulo antes de confiar nele.

**A correção pertence ao template, não a um contêiner em execução.** A Ana apaga as linhas de IPv6
no provisioner e dá ao resultado uma versão nova, porque `1.0.0` já nomeia uma imagem, e essa imagem
não muda:

```
ana@laptop:~/shop/image$ git diff
diff --git a/web.pkr.hcl b/web.pkr.hcl
index 90e9556..87b3f2a 100644
--- a/web.pkr.hcl
+++ b/web.pkr.hcl
@@ -24,12 +24,13 @@ build {
     inline = [
       "apt-get update -qq",
       "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
-      "echo 'shop web 1.0.0' > /var/www/html/index.html",
+      "sed -i '/::/d' /etc/nginx/sites-available/default",
+      "echo 'shop web 1.0.1' > /var/www/html/index.html",
     ]
   }
 
   post-processor "docker-tag" {
     repository = "shop-web"
-    tags       = ["1.0.0"]
+    tags       = ["1.0.1"]
   }
 }
```

```
ana@laptop:~/shop/image$ packer build . 2>&1 | grep -E "Image ID|Repository|finished"
==> docker.web: Image ID: sha256:2aaf4859b5ed8c589de37aa9784d5c3255b5787efd06da56dd39cfd15923dc02
==> docker.web (docker-tag): Repository: shop-web:1.0.1
Build 'docker.web' finished after 12 seconds 930 milliseconds.
==> Builds finished. The artifacts of successful builds are:
```

## Rodando

Agora o contêiner fica de pé, e responde:

```
ana@laptop:~/shop/image$ docker run -d --name shop-web-check -p 127.0.0.1:18080:80 shop-web:1.0.1
dbb954be4eb30f1e8adeedda449c922f76b6725aacbabce213e1709a6bfaa80d
ana@laptop:~/shop/image$ curl -s localhost:18080
shop web 1.0.1
ana@laptop:~/shop/image$ docker rm -f shop-web-check
shop-web-check
```

`-d` roda em segundo plano, `-p 127.0.0.1:18080:80` liga a porta 18080 do notebook à porta 80 do
contêiner, e o `curl` pede a página que o provisioner escreveu. A página diz `1.0.1` porque o
template diz. Numa loja de verdade, a conferência antes de publicar é esse pedido, feito por um
script, derrubando o pipeline quando a resposta está errada.

**Uma versão nomeia uma imagem, para sempre.** A `1.0.0` continua no notebook, ainda quebrada, com o
próprio nome (a lista de imagens da próxima seção mostra), e fica assim: uma versão publicada e
encontrada com defeito é seguida por uma versão mais nova, nunca reconstruída sob o número antigo.
Escrever o número à mão no template, duas vezes por build, é como um número acaba reutilizado, e a
próxima seção o tira de lá.
