---
title: A máscara, que o chmod reescreve
version: 1
---

**A máscara é o máximo que qualquer usuário nomeado, grupo nomeado ou o grupo dono pode ter.** Uma
entrada concede o que diz *e* o que a máscara permite; o que a máscara não permite não é concedido,
diga a entrada o que disser. O dono e os outros ficam fora dela. Ela existe para que as ferramentas
antigas, que só conhecem nove bits, ainda consigam estreitar um arquivo que tem ACL.

A armadilha é o que essas ferramentas antigas fazem com ela. Dê ao `portal` gravação no arquivo e
depois faça o que todo administrador já fez mil vezes, `chmod 640`, querendo dizer "o dono lê e
grava, o grupo lê":

```
ana@web:~$ sudo setfacl -m u:portal:rw /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt
user::rw-
user:portal:rw-
user:auditoria:r--
group::rw-
mask::rw-
other::---

ana@web:~$ sudo chmod 640 /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt
user::rw-
user:portal:rw-	#effective:r--
user:auditoria:r--
group::rw-	#effective:r--
mask::r--
other::---

ana@web:~$ echo "edited" | sudo -u joao tee -a /srv/clientes/silva.txt; sudo ls -l /srv/clientes/silva.txt
tee: /srv/clientes/silva.txt: Permission denied
edited
-rw-r-----+ 1 maria contabil 37 Oct 23 09:35 /srv/clientes/silva.txt
```

Antes do `chmod`, a máscara era `rw-` e nada ficava escondido. Depois, o `ls` mostra `rw-r-----`, como
pedido, mas veja o que mudou. **Num arquivo com ACL, os três bits do meio que o `ls` mostra são a
máscara, não o grupo dono.** `chmod g-w`, ou `chmod 640`, reescreveu a máscara para `r--`, e toda
entrada abaixo dela perdeu a gravação: o `getfacl` marca o `portal` e o grupo com
`#effective:r--`. O João, um contador cuja entrada de grupo ainda diz `rw-`, é recusado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l06-mask\" aria-label=\"A máscara como teto. Antes do chmod 640, as entradas do portal e do grupo dizem rw e a máscara é rw, então cada um fica com rw. Depois do chmod 640, a máscara é r, então o portal e o grupo ficam só com r, embora as próprias entradas ainda digam rw. O dono e o other ficam fora da máscara e não mudam.\"><text x=\"180.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">antes do chmod 640</text><rect x=\"20.0\" y=\"40.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mask::rw-</text><text x=\"328.0\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">teto</text><rect x=\"20.0\" y=\"100.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user:portal:rw-</text><text x=\"328.0\" y=\"117.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">efetivo rw-</text><rect x=\"20.0\" y=\"146.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group::rw-</text><text x=\"328.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">efetivo rw-</text><text x=\"540.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">depois do chmod 640</text><rect x=\"380.0\" y=\"40.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mask::r--</text><text x=\"688.0\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">teto</text><rect x=\"380.0\" y=\"100.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user:portal:rw-</text><text x=\"688.0\" y=\"117.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">efetivo r--</text><rect x=\"380.0\" y=\"146.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group::rw-</text><text x=\"688.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">efetivo r--</text><text x=\"360.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o dono e o other ficam fora da máscara</text></svg>", "caption": "O chmod num arquivo com ACL reescreve a máscara, e toda entrada abaixo dela encolhe."}
```

Ninguém quis tirar a gravação dos contadores. O comando fez exatamente o que faz num arquivo sem ACL,
e neste arquivo isso quer dizer outra coisa. Duas consequências:

- **Leia o `getfacl` e não o `ls`** em qualquer arquivo marcado com `+`. A coluna `#effective` é o
  acesso que as pessoas de fato têm.
- **Mude o acesso de um arquivo com ACL usando `setfacl`**, e defina a máscara de forma explícita
  quando quiser:

```
ana@web:~$ sudo setfacl -m u:portal:r,m::rw /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt | grep -E "portal|group::|mask"
user:portal:r--
group::rw-
mask::rw-
```

`m::rw` devolve a máscara, e o `portal` volta a só leitura, que era tudo de que ele precisava. Os
contadores voltam a gravar, pela entrada de grupo que a máscara não estreita mais.

## Por que funciona assim

A máscara deixa um programa que não sabe nada de ACL, como uma ferramenta de backup que restaura
arquivos com `chmod`, estreitar um arquivo com segurança.
O que ela põe nos bits de grupo limita
todas as entradas extras de uma vez, então um arquivo restaurado nunca fica mais aberto do que os
bits dizem. O preço é a armadilha acima, pago pelo administrador que esqueceu que o arquivo tinha ACL.
É por isso que vale reparar no `+` do `ls -l` toda vez.
