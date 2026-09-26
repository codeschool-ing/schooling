---
title: Reescrevendo
version: 1
---

O artigo reescrito, comparado linha a linha com o antigo:

```
ana@host:~$ diff -u kb/intranet-on-a-new-computer.md kb/intranet-new.md
--- kb/intranet-on-a-new-computer.md    2026-09-26 01:29:02.284627093 -0300
+++ kb/intranet-new.md  2026-09-26 01:29:12.190095166 -0300
@@ -1,9 +1,17 @@
-# Intranet on a new computer
+# The intranet does not open on a new computer
 
-Add the intranet to the hosts file:
+Symptom: the browser cannot reach http://intranet/, or curl says
+"Could not resolve host: intranet" or "Couldn't connect to server".
+Applies to: an office computer set up by hand. Needs: sudo on it.
 
-    echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts
+1. On the computer: getent hosts intranet
+   Expected: nothing, or an old address to replace.
+2. On your own computer, srv1's current address: getent hosts srv1
+3. On the computer, put the line "<that address> intranet" in /etc/hosts,
+   replacing any intranet line already there.
+4. On the computer: curl -sS http://intranet/
+   Expected: intranet: welcome
 
-Then open http://intranet/ in the browser.
+If step 4 fails, escalate to level 2 with the output of steps 1, 2 and 4.
 
-Last reviewed: 2024-03-11
+Owner: service desk. Last reviewed: 2026-09-26, followed on pc2.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"As partes de um artigo de base de conhecimento, de cima para baixo. Título: o problema, como alguém procuraria. Sintoma: a mensagem exata, para a busca achar. Se aplica a e precisa: quando é o artigo certo, e que acesso. Passos: cada um com o que deve mostrar. Se falhar: para onde ir depois. Dono e revisado: quem o mantém verdadeiro, e quando foi seguido pela última vez.\"><defs><marker id=\"ar-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">título</text><text x=\"236\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o problema, como alguém procuraria</text><rect x=\"20\" y=\"62\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sintoma</text><text x=\"236\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a mensagem exata, para a busca achar</text><rect x=\"20\" y=\"108\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">se aplica a, precisa</text><text x=\"236\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quando é o artigo certo, e que acesso</text><rect x=\"20\" y=\"154\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">passos</text><text x=\"236\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada um com o que deve mostrar</text><rect x=\"20\" y=\"200\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">se falhar</text><text x=\"236\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para onde ir depois</text><rect x=\"20\" y=\"246\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dono, revisado</text><text x=\"236\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem o mantém verdadeiro, e quando foi seguido</text></svg>", "caption": "Parecido com a forma de um runbook, aula 8, com uma diferença no topo: um artigo precisa ser achado antes de ser seguido, então o título e o sintoma são escritos nas palavras com que as pessoas procuram."}
```

Cada problema da seção anterior tem uma linha que o responde: um título nas palavras do sintoma, as
mensagens de erro citadas exatamente, **um passo que consulta o endereço em vez de dá-lo**, um resultado
esperado depois dos passos que importam, para onde ir se falhar, e um dono. Depois o artigo novo é seguido,
passo a passo, no `pc2`, antes de substituir o antigo:

```
ana@pc2:~$ getent hosts intranet
10.30.0.200     intranet
ana@host:~$ getent hosts srv1
10.30.0.29      srv1
ana@pc2:~$ sudo sed -i 's/^.* intranet$/10.30.0.29 intranet/' /etc/hosts && grep intranet /etc/hosts
10.30.0.29 intranet
ana@pc2:~$ curl -sS -m 10 http://intranet/
intranet: welcome
```

O passo 1 acha a linha velha que a primeira tentativa deixou, o passo 2 dá `10.30.0.29`, o passo 3 troca a linha
e o passo 4 imprime a página esperada. O *followed on pc2* da última linha é verdade, e é a expressão que
faz o *last reviewed* valer a leitura.
