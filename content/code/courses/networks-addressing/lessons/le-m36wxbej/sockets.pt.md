---
title: Uma conexão são quatro números
version: 1
---

Uma conexão TCP não é identificada por um endereço, nem por uma porta. **Ela é identificada por quatro
números juntos: o endereço e a porta do cliente, e o endereço e a porta do servidor.** Mude qualquer
um deles e é outra conexão. É esse conjunto, mais o protocolo, que o kernel procura em cada segmento
que chega, para decidir a que programa ele pertence.

Estas são as três conexões que o srv listou na seção anterior, escritas por extenso:

| endereço do cliente | porta do cliente | endereço do servidor | porta do servidor |
|---|---|---|---|
| 10.20.10.23 | 52730 | 10.20.10.10 | 80 |
| 10.20.10.21 | 60504 | 10.20.10.10 | 80 |
| 10.20.10.22 | 59648 | 10.20.10.10 | 80 |

Duas das quatro colunas são iguais em todas as linhas, e precisam ser: um cliente só conecta no que
conhece, e os três conheciam a porta 80 do `srv`. As outras duas tornam cada linha única. Três PCs
são três endereços diferentes, então aqui o endereço do cliente já bastaria. Mas duas abas do
navegador no pc1 abririam duas conexões a partir de um único endereço, e aí só a porta as distingue.

**A porta do servidor é fixa e conhecida de antemão; a do cliente é efêmera.** Ninguém escolheu a
`60504`. Quando o cliente conectou sem pedir uma porta, o kernel do pc1 pegou uma livre, usou-a nesta
conexão e vai entregá-la a outra conexão quando esta acabar. No Linux, a faixa de onde ele tira a
porta é uma configuração, `net.ipv4.ip_local_port_range`, e o padrão é de 32768 a 60999; todas as
portas de cliente nas capturas desta aula caem dentro dela. As portas conhecidas abaixo de 1024 — 22
para SSH, 80 para HTTP, 443 para HTTPS — são a outra metade da convenção: números em que um servidor
escuta para que ninguém precise avisar os clientes.

Ler uma linha do `ss`, então, é ler quatro números e um estado:

- `Local Address:Port` é o lado desta máquina e `Peer Address:Port` é o da outra, então a mesma
  conexão listada no cliente mostra os dois lados trocados — a próxima seção mostra exatamente isso,
  em duas máquinas ao mesmo tempo;
- `State` é o estado do TCP: `LISTEN` para um socket que espera, `ESTAB` para uma conversa em
  andamento, e alguns outros para os momentos de abrir e fechar;
- `Recv-Q` e `Send-Q` são bytes esperando para serem lidos pelo programa ou confirmados pelo outro
  lado, e numa conexão parada os dois são 0.

A ideia a abandonar aqui é a de que uma porta pertence a uma conversa, como se "a porta 80 estivesse
ocupada" enquanto um cliente está conectado. A porta 80 do srv é escutada uma vez e compartilhada por
todas as conexões que chegam nela. **O que não pode existir são duas conexões com os quatro números
iguais**, porque o kernel não saberia a que programa um segmento pertence. A aula 11 reencontra essa
regra pelo outro lado, quando um roteador reescreve o endereço e a porta do cliente na saída e precisa
manter cada conexão única enquanto faz isso.
