---
title: Quando uma rota digitada é a resposta certa
version: 1
---

Uma **rota estática** é uma linha na tabela de rotas que uma pessoa escreveu: *para chegar a esta rede,
entregue o pacote àquele vizinho*. Nada no roteador a produziu e nada vai mudá-la. Ela fica exatamente
como foi digitada até alguém digitar de novo.

A imagem comum é que roteamento estático é a versão de iniciante, o que se faz até aprender OSPF. Essa
imagem erra sobre onde as rotas estáticas vivem. **Quase todo computador que você já usou faz
roteamento estático**: o gateway padrão que a aula 14 leu num PC é uma rota estática, digitada por um
administrador ou entregue pelo DHCP, e o PC nunca a discute com ninguém. A maioria dos roteadores na
borda da internet é igual. Uma filial com um enlace até a matriz, um roteador doméstico com um enlace
até o provedor, e a rota do próprio provedor apontando o bloco de um cliente para o cabo desse cliente
são todos estáticos, e todos estão certos.

## O que você ganha ao digitá-la

- **Previsibilidade.** A tabela guarda o que o engenheiro escreveu e mais nada. Quando um pacote vai
  pelo caminho errado, o motivo é uma linha que você consegue ler, e não o resultado de um cálculo de
  protocolo.
- **Nada para atacar e nada para configurar errado na rede.** Um protocolo de roteamento escuta os
  vizinhos, então um vizinho que mente, ou um erro em outro roteador, pode reescrever a tabela deste. Uma
  rota estática não escuta ninguém.
- **Custo zero.** Nenhuma mensagem, nenhum temporizador, nenhuma memória para o banco de dados de um
  vizinho.
- **Ela vence.** A aula 14 pôs a distância administrativa de uma rota estática em 1, abaixo de todo
  protocolo de roteamento, então uma rota digitada vence uma aprendida para o mesmo prefixo. Isso é útil
  quando é intencional e uma armadilha quando você esqueceu que ela estava lá.

## O que ela custa

**Toda mudança é feita à mão, em cada roteador que o tráfego atravessa.** No laboratório desta aula,
ligar duas redes através de três roteadores exige quatro rotas: duas em direção à rede distante e duas
de volta. Uma quarta rede significaria visitar cada roteador de novo. O trabalho cresce com o número de
redes e com o número de roteadores ao mesmo tempo, e é por isso que ninguém opera uma rede grande assim.

**Uma rota estática só percebe os cabos do próprio roteador.** Se o cabo ligado neste roteador perde o
sinal, o roteador para de usar as rotas por ele. Se um cabo dois roteadores adiante falha, nada aqui
muda, e os pacotes continuam indo em direção à quebra. A seção sobre rotas flutuantes mostra isso
acontecendo no laboratório, e a aula 16 é a resposta.

## A regra prática

| situação | estática serve? |
|---|---|
| uma entrada e uma saída: uma filial, uma casa, um host | sim, uma rota padrão é tudo de que precisa |
| um enlace fixo até a rede de um parceiro, que quase não muda | sim |
| dois caminhos, em que o reserva é só para quando o seu próprio cabo falha | sim, com uma rota flutuante |
| vários roteadores, vários caminhos, falhas que é preciso contornar | não, use um protocolo de roteamento |

**Estática onde há um caminho só, dinâmica onde há escolha.** O resto desta aula digita as rotas num
laboratório de três roteadores, descobre o que toda rota precisa e que um iniciante esquece, e depois
quebra um cabo para achar o limite do que digitar consegue fazer.
