---
title: Conferindo o código
version: 1
---

O servidor não recebe um código do celular para procurar em algum lugar. Ele calcula o código sozinho, a
partir da própria cópia do segredo e do próprio relógio, e compara. No laboratório, o servidor `www`
confere o código que o app da ana mostrou às 13:00:00:

```
root@www:~# oathtool --totp -b --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 593771; echo "exit $?"
0
exit 0
root@www:~# oathtool --totp -b --now '2026-10-06 13:02:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 593771; echo "exit $?"
oathtool: password "593771" not found in range 59709724 .. 59709724
exit 2
```

Com um código para conferir, o `oathtool` responde onde na janela o achou e sai com 0, ou diz `not found`
("não encontrado") e sai com erro. Às 13:00:00 o código bate; dois minutos depois o mesmo código é
recusado, porque passaram quatro passos e o servidor agora espera outro. Um código digitado de um print,
de um bilhete ou de uma página de phishing de dois minutos atrás não vale nada.

### Quando os relógios discordam

O relógio do celular e o do servidor nunca são exatamente iguais, e uma pessoa leva alguns segundos para
digitar. Um código mostrado às 12:59:45 pertence ao passo anterior, e quando chega o servidor já está no
seguinte:

```
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 12:59:45 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
907684
root@www:~# oathtool --totp -b --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 907684; echo "exit $?"
oathtool: password "907684" not found in range 59709720 .. 59709720
exit 2
root@www:~# oathtool --totp -b -w 1 --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 907684; echo "exit $?"
1
exit 0
```

Sem tolerância, o servidor recusa o código, o que trancaria fora uma pessoa que não fez nada de errado.
Com uma janela de um passo, `-w 1`, ele aceita e informa que o achou a um passo de distância. Servidores
reais aceitam uma janela pequena, em geral um passo para cada lado, e não mais: cada passo a mais são
trinta segundos a mais em que um código roubado ainda funciona.

### Provando a implementação

Como alguém sabe que o `oathtool`, um app autenticador ou o código do servidor calculam o TOTP direito? A
RFC publica **vetores de teste**: um segredo conhecido, uma hora conhecida e o código que tem de sair.
Aqui está o primeiro, para o instante 59 segundos depois de 1970, com oito dígitos:

```
ana@laptop:~$ oathtool --totp -d 8 --now '1970-01-01 00:00:59 UTC' 3132333435363738393031323334353637383930
94287082
```

`94287082` é o valor impresso no Apêndice B da RFC 6238. Uma implementação que erra isso está errada,
faça o que fizer de resto. A plataforma em que este curso roda confere o próprio código de TOTP contra os
mesmos vetores, o que é um bom hábito para tudo de que a segurança depende: **teste contra a
especificação, e não contra a sua ideia dela.**

### O que o servidor precisa proteger

O servidor guarda uma cópia do segredo de cada usuário, e quem roubar esses segredos calcula os códigos
de todos para sempre. Então os segredos ficam guardados cifrados, o banco que os guarda está entre os
mais protegidos do sistema, e desligar ou redefinir o MFA é uma ação registrada com quem a fez. O segredo
é o fator; os seis dígitos são só a sombra dele.
