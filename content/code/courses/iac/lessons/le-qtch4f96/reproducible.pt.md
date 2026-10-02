---
title: Reprodutível, e imutável na prática
version: 1
---

Um número de versão diz *qual* imagem roda. Não diz que construir o mesmo template de novo daria a
mesma imagem, e do jeito que o template está, não daria. Duas das entradas dele são nomes que se
movem: `ubuntu:24.04`, que a seção sobre versionamento mostrou sendo reconstruída sob a mesma tag, e `nginx`,
que significa a versão que o repositório oferecer no dia do build. **Um build é reprodutível quando
toda entrada é nomeada por algo que não se move.** A Ana fixa as duas.

A imagem base ganha o **digest**, o hash do conteúdo dela, que o Docker registra quando baixa uma
imagem:

```
ana@laptop:~/shop/image$ docker image inspect ubuntu:24.04 --format '{{index .RepoDigests 0}}'
ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3
```

Um digest não é um ponteiro. Se o conteúdo mudasse, o hash seria outro, então `ubuntu@sha256:…`
nomeia uma única imagem enquanto ela existir em algum lugar. O pacote ganha uma versão exata, lida do
repositório, partindo dessa mesma base:

```
ana@laptop:~/shop/image$ docker run --rm ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3 sh -c 'apt-get update -qq && apt-cache policy nginx'
nginx:
  Installed: (none)
  Candidate: 1.24.0-2ubuntu7.18
  Version table:
     1.24.0-2ubuntu7.18 500
        500 http://archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages
        500 http://security.ubuntu.com/ubuntu noble-security/main amd64 Packages
     1.24.0-2ubuntu7 500
        500 http://archive.ubuntu.com/ubuntu noble/main amd64 Packages
```

```
ana@laptop:~/shop/image$ git diff
diff --git a/web.pkr.hcl b/web.pkr.hcl
index 554e9e1..5ea1fd9 100644
--- a/web.pkr.hcl
+++ b/web.pkr.hcl
@@ -18,7 +18,7 @@ variable "commit" {
 }
 
 source "docker" "web" {
-  image  = "ubuntu:24.04"
+  image  = "ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3"
   pull   = false
   commit = true
   changes = [
@@ -35,7 +35,7 @@ build {
   provisioner "shell" {
     inline = [
       "apt-get update -qq",
-      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
+      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx=1.24.0-2ubuntu7.18 > /dev/null",
       "sed -i '/::/d' /etc/nginx/sites-available/default",
       "echo 'shop web ${var.version}' > /var/www/html/index.html",
     ]
```

```
ana@laptop:~/shop/image$ packer build -var version=1.2.0 -var commit=$(git rev-parse --short HEAD) . 2>&1 | grep -E "Run command|Image ID|finished"
==> docker.web: Run command: docker run -v /tmp/tmp564079577:/packer-files -d -i -t --entrypoint=/bin/sh -- ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3
==> docker.web: Image ID: sha256:5bf5dd66bfe52e5688e85696de7134dd1678c816c9fabe3b7456ae246aa6824c
Build 'docker.web' finished after 15 seconds 730 milliseconds.
==> Builds finished. The artifacts of successful builds are:
ana@laptop:~/shop/image$ docker run --rm shop-web:1.2.0 dpkg-query -W nginx
nginx	1.24.0-2ubuntu7.18
```

A linha `Run command` mostra o contêiner ligado a partir do digest, não da tag, e a imagem tem a
versão que o template pediu e nenhuma outra. Se o repositório deixar de oferecer essa versão, o
próximo build falha no `apt-get install`, de forma barulhenta, no dia do build, em vez de produzir
outra coisa em silêncio. A tabela de versões acima lista duas versões do nginx, a que veio com o
lançamento e a atualização mais nova; uma atualização mais antiga não está nela.

Reprodutível aqui quer dizer o mesmo software, nas mesmas versões, a partir do mesmo template. Não
quer dizer um arquivo idêntico byte a byte: dois builds ainda diferem nas datas gravadas dentro da
imagem, então os ids também diferem. O que importa é que nada do que foi *instalado* difira, e que
qualquer diferença seja um diff que alguém commitou.

## Fixar não é congelar

A objeção a tudo isso é a certa: uma imagem fixada nunca recebe correção de segurança. **Fixar torna
as atualizações deliberadas, não raras.** O arranjo que funciona é um rebuild agendado, digamos uma
vez por semana, no pipeline que a aula 15 descreve: ele procura um digest de base mais novo e versões
de pacote mais novas, escreve isso no template como um commit, constrói a próxima versão, roda e
publica. As atualizações chegam num calendário, cada uma um diff revisado e um número de versão novo,
e cada rollout é a mudança de uma linha da seção anterior. Uma correção que não pode esperar segue o
mesmo caminho, rodado no mesmo dia.

## Imutável, com evidência

A aula 1 afirmou que na infraestrutura imutável o drift não tem onde morar. Eis o que isso quer dizer
num contêiner em execução. Alguém corrige a página à mão, lá dentro:

```
ana@laptop:~/shop/image$ docker run -d --name shop-web-live -p 127.0.0.1:18080:80 shop-web:1.2.0
4b606ab40d89b7e598275ad4372c34ab0b416ed81f1920ca4a02d7e8858d83e8
ana@laptop:~/shop/image$ docker exec shop-web-live sh -c "echo 'fixed by hand' > /var/www/html/index.html"
ana@laptop:~/shop/image$ curl -s localhost:18080
fixed by hand
ana@laptop:~/shop/image$ docker diff shop-web-live | grep www
C /var/www
C /var/www/html
C /var/www/html/index.html
```

A edição manual funciona, e o Docker consegue até listá-la: `docker diff` compara o contêiner em
execução com a imagem de onde ele veio, e `C` marca o que mudou. Isso é drift, e num servidor mutável
ficaria lá até alguém perceber. Aqui a próxima substituição o remove:

```
ana@laptop:~/shop/image$ docker rm -f shop-web-live
shop-web-live
ana@laptop:~/shop/image$ docker run -d --name shop-web-live -p 127.0.0.1:18080:80 shop-web:1.2.0
e60654d2ded5b68af1f6d60f81eb1f01bfc6728962e8495f6240f1b01defcd49
ana@laptop:~/shop/image$ curl -s localhost:18080
shop web 1.2.0
ana@laptop:~/shop/image$ docker diff shop-web-live | grep www
```

O contêiner novo é a imagem de novo, e o `docker diff` não encontra nada no diretório web. **Neste
modelo uma correção feita à mão se perde por desenho**, então as únicas correções que duram são as
feitas no template e entregues como versão nova. É a troca inteira que a aula 1 descreveu, agora em
comandos: uma etapa de build e uma versão para cada mudança, em troca de máquinas que são exatamente
o que a imagem delas diz, toda vez que uma é ligada.

O que continua mutável é o que a aula 1 disse que deveria: os dados. O banco, o bucket com as imagens
da loja e os logs vivem fora da imagem, e um servidor web substituído não perde nada disso porque
nunca guardou nada disso.
