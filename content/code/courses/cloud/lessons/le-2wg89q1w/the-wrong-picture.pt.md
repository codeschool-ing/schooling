---
title: O computador de outra pessoa
version: 1
---

Tem uma frase impressa em adesivos e canecas: *a nuvem não existe, é só o computador de outra
pessoa*. **Ela é verdadeira.** Todo serviço deste curso roda em servidores físicos dentro de prédios,
com energia, refrigeração e gente que troca discos com defeito. Uma máquina virtual em `sa-east-1` é uma
fatia de um servidor de verdade, num prédio de verdade na região de São Paulo, e quando esse prédio fica
sem energia a máquina para como qualquer outra.

Ela também é inútil, porque descreve igualmente bem uma empresa de hospedagem dos anos 1990. Alugar o
computador de outra pessoa é mais antigo que a web: colocation, servidores dedicados e hospedagem
compartilhada já faziam isso. Se a frase fosse a história inteira, nada teria mudado, e muita coisa
mudou.

## O que a frase deixa de fora

Compare dois jeitos de conseguir um servidor para uma loja que espera um dezembro movimentado.

O jeito antigo: você escreve para uma empresa de hospedagem, fecha um contrato de um ano e espera um
técnico instalar uma máquina num rack. Você paga o mesmo todo mês, a loja vendendo ou não. Quando
dezembro triplica o tráfego, você encomenda uma segunda máquina e espera de novo, e em janeiro continua
pagando pelas duas.

O jeito da nuvem: um programa que você roda, ou um formulário que o roda por você, manda um pedido para
a API do provedor. **Quem responde é um software, não um vendedor**, e a máquina existe minutos depois.
Ela é uma fatia de um servidor maior que outros clientes compartilham, do tamanho que você pediu. Em
dezembro você pede mais três; em janeiro devolve, e a conta para de contá-las. O preço em São Paulo da
menor máquina da tabela do curso é 0,01680 dólar por hora, então um mês inteiro dela, 730 horas (365
dias vezes 24, dividido por 12), custa 12,26 dólares.

Quatro coisas mudam, e nenhuma delas é de quem é o computador:

- como você obtém: pedindo a uma API, sem nenhuma pessoa no caminho;
- o que você obtém: uma fatia de hardware compartilhado, tão pequena quanto você precisar;
- por quanto tempo fica com ela: até devolver, o que pode ser amanhã;
- como você paga: pela unidade que usou, uma hora, um gigabyte ou uma requisição.

A próxima seção dá nome oficial a essas quatro, e a mais uma.

## A segunda coisa que ela esconde

A frase também esconde uma pergunta que importa mais que o preço. Com o servidor na sua própria sala,
toda tarefa era sua: a energia, os discos, o sistema operacional, os backups. Com o computador de outra
pessoa, **algumas dessas tarefas passam a ser dela**, e quais depende inteiramente do que você alugou.
Uma máquina virtual deixa para você o sistema operacional e tudo acima dele. Uma aplicação pronta, como
um webmail, deixa quase nada para você, mas nunca nada.

"Fomos para a nuvem" não responde, portanto, à pergunta *quem aplica os patches no servidor*. É o começo da
pergunta, e os três nomes de que esta aula trata, IaaS, PaaS e SaaS, são três respostas para ela.

Vale nomear uma segunda imagem errada enquanto você está aqui: **a nuvem como o lugar para onde os
arquivos vão**, a pasta que sincroniza entre o celular e o laptop. Esse é um tipo de serviço de nuvem,
uma aplicação pronta para guardar arquivos, e é só um canto do assunto. Este curso trata do assunto inteiro: as
máquinas, os discos e as redes sobre os quais serviços assim são construídos, e os serviços feitos para
quem escreve software, e não para quem guarda fotos.
