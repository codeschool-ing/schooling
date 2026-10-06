---
title: Um pequeno exercício
version: 1
---

A pergunta deste exercício, combinada antes: **se alguém na internet tentar adivinhar a senha da ana
no portal, alguma coisa na loja vê?** O passo vermelho é a ana, numa máquina na internet, mandando seis
pedidos com seis senhas erradas. O passo azul é o administrador lendo o log do portal no `www`.

### Vermelho

```
ana@outside:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code}\n" -u ana:wrong-$i http://www.example.com/payslips/ana; done
401
401
401
401
401
401
```

O laço manda o mesmo pedido seis vezes, cada uma com uma senha errada diferente, e imprime só o código
de status de cada resposta. Seis vezes `401`: o login segurou, como a aula 8 mostrou que seguraria.

### Azul

A pergunta agora não é se o ataque funcionou, e sim se ele foi **visto**:

```
root@www:~# grep -c ' 401 ' /var/log/lab/portal.log
6
root@www:~# grep ' 401 ' /var/log/lab/portal.log | cut -d' ' -f1 | sort | uniq -c
      6 203.0.113.50
```

O `grep -c` conta as linhas do log que contêm ` 401 `: seis, uma por tentativa. O segundo comando
guarda só o endereço no começo de cada uma dessas linhas e as conta por endereço: as seis vieram de
`203.0.113.50`. Então o log viu tudo, e uma pessoa lendo veria seis logins falhos de um endereço na
internet.

### O que o exercício achou

O roxo é sobre a próxima pergunta, e aqui está ela: **alguém conseguiria agir com isso?** Ler o log
cru responde:

```
root@www:~# head -3 /var/log/lab/portal.log
192.168.10.20 ana "GET /payslips/ana HTTP/1.1" 200 -
203.0.113.50 - "GET /payslips/ana HTTP/1.1" 401 -
203.0.113.50 - "GET /payslips/ana HTTP/1.1" 401 -
```

Faltam duas coisas, e nenhuma teria sido notada sem tentar.

**Não há hora em linha nenhuma.** Seis falhas em dois segundos e seis falhas espalhadas num mês têm a
mesma cara. A primeira é alguém adivinhando; a segunda é uma pessoa que esquece a senha de vez em
quando. Sem hora, nenhuma regra separa as duas, e a aula 11 mostra que separá-las é todo o trabalho de
uma detecção.

**Tentativas falhas não trazem nome de usuário.** Um pedido bem-sucedido registra `ana`; um falho
registra `-`, porque o portal só anota um nome depois que a senha confere. Então o log diz que um
endereço está adivinhando, mas não **de quem** é a conta que ele adivinha. Se o atacante espalhasse as
tentativas por todas as contas da equipe, o log também não mostraria isso.

Os dois achados vão para o registro de riscos da loja como melhoria do portal: registrar a hora de todo
pedido, e registrar o nome de usuário **alegado** numa tentativa falha, marcado como alegado. O portal
do laboratório os deixa de fora porque um log com horas reais imprimiria números diferentes a cada
execução deste curso; um portal de verdade não pode deixar. Esse é o resultado honesto do exercício: o
controle funcionou, a detecção não teria como funcionar, e agora a loja sabe por quê.
