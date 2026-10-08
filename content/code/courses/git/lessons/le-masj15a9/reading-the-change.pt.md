---
title: Lendo a mudança
version: 2
---

O pull request do Bruno é o #31, para o ticket #30: *os clientes querem escolher quando buscar o pedido*. O
site de hospedagem mostra o diff, e para uma mudança pequena isso basta. Para qualquer coisa que você
queira **rodar**, traga o branch para a sua máquina.

Na sua ainda não há Bruno. Este bloco faz tudo o que a revisão precisa, a partir de uma semana nova: a
cópia compartilhada da aula 7, o clone do próprio Bruno em `~/bruno/site` com o nome dele configurado
naquele clone, o branch dele com dois commits, e o push. A última linha traz você de volta à cópia da
Ana:

```bash
cd ~ && rm -rf ~/site ~/remotes ~/bruno && bash ~/make-site.sh && cd ~/site
git init -q --bare ~/remotes/site.git
git remote add origin ~/remotes/site.git
git push -q -u origin main
git clone -q ~/remotes/site.git ~/bruno/site && cd ~/bruno/site
git config user.name 'Bruno Lima' && git config user.email bruno@example.com
git switch -q -c 30-pickup-times
printf '<h1>Order ahead</h1>\n<form class="order">\n  <label>Pickup time <input name="pickup" type="time"></label>\n  <button>Order</button>\n</form>\n' > order.html
printf '<p><a href="order.html">Order ahead</a></p>\n' >> index.html
git add -A && git commit -qm 'Let customers choose a pickup time' -m 'Refs #30'
sed -i 's/darkorange/saddlebrown/' style.css && printf '.order label { display: block; }\n' >> style.css
git commit -qam 'Style the order form' -m 'Refs #30'
git push -q -u origin 30-pickup-times
cd ~/site
```

Depois, o lado da Ana:

```
ana@vm:~/site$ git fetch
remote: Enumerating objects: 10, done.
remote: Counting objects: 100% (10/10), done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 7 (delta 2), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (7/7), 794 bytes | 794.00 KiB/s, done.
From /home/ana/remotes/site
 * [new branch]      30-pickup-times -> origin/30-pickup-times
ana@vm:~/site$ git switch 30-pickup-times
Switched to a new branch '30-pickup-times'
branch '30-pickup-times' set up to track 'origin/30-pickup-times'.
ana@vm:~/site$ git log --oneline main..
8b19b3c Style the order form
4156a0f Let customers choose a pickup time
```

O `git switch` acha o `origin/30-pickup-times` e cria um branch local que o acompanha, como a aula 7
mostrou. Os dois commits são o pull request inteiro. Antes de ler qualquer linha, veja a forma:

```
ana@vm:~/site$ git diff --stat main...
 index.html | 1 +
 order.html | 5 +++++
 style.css  | 3 ++-
 3 files changed, 8 insertions(+), 1 deletion(-)
```

Três arquivos e oito linhas. Isso já diz alguma coisa: um ticket sobre pedidos mexeu no `style.css`, e só
em poucas linhas. Agora as linhas em si:

```
ana@vm:~/site$ git diff main...
diff --git a/index.html b/index.html
index f1e3c9f..40fee17 100644
--- a/index.html
+++ b/index.html
@@ -1,3 +1,4 @@
 <h1>Padaria Sol</h1>
 <p>Bread from half past five.</p>
 <p><a href="menu.html">See the menu</a></p>
+<p><a href="order.html">Order ahead</a></p>
diff --git a/order.html b/order.html
new file mode 100644
index 0000000..49c300b
--- /dev/null
+++ b/order.html
@@ -0,0 +1,5 @@
+<h1>Order ahead</h1>
+<form class="order">
+  <label>Pickup time <input name="pickup" type="time"></label>
+  <button>Order</button>
+</form>
diff --git a/style.css b/style.css
index 773418d..3b5e278 100644
--- a/style.css
+++ b/style.css
@@ -1 +1,2 @@
-h1 { color: darkorange; }
+h1 { color: saddlebrown; }
+.order label { display: block; }
```

Percorra com as quatro perguntas:

1. **Faz o que o ticket pediu?** Faz: uma página com um campo de horário, com link na página inicial.
2. **Funciona?** Abra o `order.html` num navegador e aperte *Order* com o campo vazio. Ele envia. Nada
   impede um cliente de pedir para horário nenhum, ou para as três da manhã. Essa é a descoberta
   importante, e só lendo talvez ela passasse; rodando, ficou óbvia.
3. **A próxima pessoa vai entender?** São cinco linhas, e sim.
4. **Combina com o resto?** A cor do título mudou de `darkorange` para `saddlebrown` em todas as páginas do
   site. Isso não tem nada a ver com o ticket #30.

O `main...` com três pontos compara o branch com **o ponto em que ele saiu do `main`**, então mostra só o
trabalho do Bruno, mesmo que o `main` tenha andado desde então. Com dois pontos, mostraria também, ao
contrário, o que entrou no `main` nesse meio-tempo.

## Quando a mudança é grande demais para revisar

Um pull request de duas mil linhas não pode ser lido com a atenção que essas quatro perguntas pedem, e
todo mundo sabe que ele acaba aprovado assim mesmo. É justo, e útil, dizer isso: pergunte se dá para
dividir, ou peça para quem escreveu mostrar a mudança por cima. Uma revisão que finge ter lido o que só
passou os olhos é pior que uma que diz que não conseguiu.
