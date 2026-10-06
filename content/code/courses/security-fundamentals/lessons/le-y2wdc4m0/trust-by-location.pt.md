---
title: Confiança pela localização
version: 1
---

A aula 5 terminou com a rede da loja dividida em zonas, e com um aviso: o perímetro não basta sozinho,
porque atacantes entram sem atravessá-lo. Esta aula é sobre a suposição que torna isso perigoso, e ela
fica mais fácil de ver numa frase pela qual a maioria das redes ainda vive:

> **se um pedido vem de dentro, provavelmente é um de nós.**

Isso é **confiança implícita**, ou confiança pela localização. O endereço de rede de onde um pedido
vem é usado como prova de quem o mandou. Ela aparece em todo lugar quando você procura:

| onde | a confiança implícita |
|---|---|
| uma página da intranet sem login | "só a equipe a alcança" |
| um banco que aceita qualquer conexão do segmento de servidores | "lá só tem servidor nosso" |
| a página de administração de uma impressora sem senha | "está na rede interna" |
| uma VPN que, depois de conectada, alcança tudo | "fez login uma vez, então está tudo bem" |

Toda linha falha na mesma situação: **algo lá dentro não é o que deveria ser.** Um notebook da equipe
infectado por um anexo de e-mail está lá dentro. Também estão o celular de um visitante no Wi-Fi
errado, a máquina de um terceirizado ligada numa tomada sobrando e um servidor comprometido semana
passada que anda quieto desde então. Cada um deles herda toda a confiança que o lugar carrega.

A outra direção também falha. Alguém da equipe trabalhando de casa, com a própria senha correta, está fora, e uma política baseada em localização o trata como um estranho. Isso empurra as pessoas para
gambiarras: uma VPN ligada o dia inteiro, ou arquivos mandados para um e-mail pessoal para abrir em
casa.

### De onde veio o nome

O termo **Zero Trust** foi cunhado por John Kindervag, na Forrester Research, em 2010, como reação
exatamente a esse modelo. O Google descreveu a própria saída de uma rede interna privilegiada numa
série de artigos a partir de 2014, com o nome de **BeyondCorp**: a equipe deles alcança aplicações
internas de qualquer rede, e a rede em que estão não concede nada. Em 2020, o instituto nacional de
padrões dos Estados Unidos, o NIST, publicou o **SP 800-207, Zero Trust Architecture**, que é a
referência que a maioria das organizações usa hoje e a fonte do vocabulário das duas próximas seções.
