---
title: Fazendo a conta sem calculadora
version: 1
---

Converter cada octeto para binário funciona e é lento. Há um atalho que dá a rede e o broadcast de
qualquer endereço em poucos segundos, e ele se apoia no padrão da seção anterior: toda faixa começa num
múltiplo do próprio tamanho. **O método do tamanho do bloco** tem quatro passos.

1. **Ache o octeto interessante**: aquele em que a máscara não é nem 255 nem 0. Os octetos antes dele são
   copiados do endereço; os depois dele são 0 na rede e 255 no broadcast.
2. **Tamanho do bloco = 256 − o valor da máscara nesse octeto.**
3. **O valor da rede nesse octeto é o maior múltiplo do tamanho do bloco que não passa do valor do
   endereço.**
4. **O valor do broadcast nesse octeto é o valor da rede + tamanho do bloco − 1.**

Faça um que não está neste laboratório: `172.16.45.77/20`.

- `/20` é 16 + 4, então a máscara é `255.255.240.0` e o octeto interessante é o **terceiro**.
- Tamanho do bloco: 256 − 240 = **16**.
- Os múltiplos de 16 são 0, 16, 32, 48 e assim por diante. O terceiro octeto do endereço é 45, que fica
  entre 32 e 48, então o terceiro octeto da rede é **32**: a rede é `172.16.32.0`.
- Broadcast: 32 + 16 − 1 = 47 no terceiro octeto, e 255 depois dele: `172.16.47.255`.
- Tamanho: 20 bits de rede deixam 12 de host, então 2^12 = **4096** endereços e 4094 hosts. O mesmo número
  de novo pelo bloco: 16 valores do terceiro octeto, cada um com 256 valores do quarto, 16 × 256 = 4096.

Agora confira. O sipcalc imprime mais que o ipcalc, e cada linha pode ser comparada com a conta acima:

```
ana@sales1:~$ sipcalc 172.16.45.77/20
-[ipv4 : 172.16.45.77/20] - 0

[CIDR]
Host address		- 172.16.45.77
Host address (decimal)	- 2886741325
Host address (hex)	- AC102D4D
Network address		- 172.16.32.0
Network mask		- 255.255.240.0
Network mask (bits)	- 20
Network mask (hex)	- FFFFF000
Broadcast address	- 172.16.47.255
Cisco wildcard		- 0.0.15.255
Addresses in network	- 4096
Network range		- 172.16.32.0 - 172.16.47.255
Usable range		- 172.16.32.1 - 172.16.47.254

-
```

`Network address 172.16.32.0`, `Broadcast address 172.16.47.255`, `Addresses in network 4096` e uma faixa
utilizável de `.32.1` a `.47.254`. **O método e a calculadora concordam, e o método levou quatro linhas
de aritmética.** O sipcalc acrescenta duas leituras que valem nota. `Host address (decimal) 2886741325`
e `(hex) AC102D4D` são o endereço como o número único de 32 bits que a aula 8 disse que ele era: `AC` é
172, `10` é 16, `2D` é 45, `4D` é 77. E `Cisco wildcard 0.0.15.255` é a máscara do avesso, 255 − 240 = 15
no terceiro octeto, como a primeira seção desta aula explicou.

Mais um, com o octeto interessante em outro lugar: `10.0.77.200/21`. `/21` é 16 + 5, então a máscara é
`255.255.248.0`, o terceiro octeto de novo, e o bloco é 256 − 248 = 8. Os múltiplos de 8 perto de 77 são
72 e 80, então a rede é `10.0.72.0` e o broadcast é 72 + 8 − 1 = 79 no terceiro octeto: `10.0.79.255`. O
quarto octeto do endereço, 200, não importou nada, porque ali a máscara é 0. Esse não passou por uma
calculadora no laboratório; é aritmética, e **o jeito de confiar nela é conferir uma vez com o ipcalc
ou o sipcalc em qualquer máquina Linux**, até você confiar no método sozinho.

O deslize comum é aplicar o tamanho do bloco no octeto errado. Para `/20` o bloco de 16 está no
terceiro octeto; tomar `172.16.45.64` como rede, como se o bloco estivesse no quarto, dá uma faixa ao
mesmo tempo pequena demais e no lugar errado. **Ache o octeto interessante antes de qualquer coisa**, e o
resto vem junto.
