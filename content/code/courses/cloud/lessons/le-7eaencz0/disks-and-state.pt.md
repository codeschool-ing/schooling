---
title: "Discos, stop e terminate: o que sobrevive"
version: 1
---

Num computador embaixo da mesa, o disco fica dentro da caixa, e desligar a caixa não faz nada com
ele. **Uma instância tem dois tipos de disco, e eles se comportam de formas opostas** quando ela é
desligada, e é por isso que "parei a instância e meus arquivos sumiram" e "apaguei a instância e
continuo pagando" são frases que as pessoas dizem no primeiro mês.

## Um volume de rede e um disco local

O disco raiz de uma instância comum nem está no host. É um **volume de rede**, um dispositivo de
blocos servido por um sistema de armazenamento em outro lugar da mesma zona e ligado à instância pela
rede. Na AWS isso é o EBS, e a aula 5 o coloca ao lado dos outros tipos de armazenamento. Como o
volume vive separado do host, ele sobrevive ao host: pare a instância, e o volume espera, com cada
arquivo dele, até a instância iniciar de novo em outro lugar.

Ele é cobrado enquanto espera. Um volume `gp3` custa 0,1520 USD por GB-mês em `sa-east-1` na tabela,
então o disco raiz de 20 GB de uma instância parada custa 3,04 USD por mês enquanto ninguém o apagar.

O outro tipo é o **instance store**: discos fisicamente dentro do host, o `d` de um tipo como
`m7gd.large`. São rápidos, porque nada fica entre a instância e o disco, e estão incluídos no preço
da instância. Também pertencem ao host. Quando a instância para, ela sai do host e os discos ficam
para trás, e o que havia neles se perde. Um reboot os mantém, porque um reboot não sai do host.

## Reboot, stop, terminate

| | reboot | stop | terminate |
|---|---|---|---|
| a instância | reinicia no mesmo host | desligada, host liberado | apagada, de vez |
| o volume de rede raiz | mantido | mantido, e ainda cobrado | apagado junto, a menos que você tenha dito outra coisa |
| o instance store | mantido | apagado | apagado |
| um IPv4 público dado no lançamento | mantido | liberado; um novo no início | liberado |
| cobrança de processador | continua | para | para |

Duas linhas pegam as pessoas. **Stop não é botão de pausa para a conta do disco**: o volume raiz
continua cobrando. E **o endereço público muda** num stop e start, porque o provedor empresta
endereços IPv4 públicos de um pool; o que apontava para o endereço antigo, um registro DNS ou o
favorito de um colega, agora aponta para outra pessoa. Manter um fixo é um recurso separado e
cobrado: um endereço IPv4 público custa 0,0050 USD por hora na tabela, 3,65 USD por mês em 730 horas.

## O que uma substituta perde

Até aqui toda linha supôs que a mesma instância volta. Na segunda metade desta aula ela não volta: um
grupo substitui uma instância com defeito por uma nova, lançada da imagem. **Uma substituta mantém o
que está na imagem e nada mais.** Tudo o que foi escrito desde o primeiro boot daquela máquina vai
embora com ela: os arquivos que os usuários enviaram para o disco dela, os arquivos de log, a
configuração que alguém consertou à mão via SSH na terça passada, um banco SQLite no diretório home.

Essa é a diferença por trás de uma expressão antiga de operações, **pets e cattle**, bichos de
estimação e gado. Um servidor pet tem nome, foi configurado à mão, e quando adoece alguém entra nele e
cuida até sarar, porque nada mais sabe o que há nele. O gado é numerado, feito a partir de uma imagem,
e quando um adoece é substituído, porque todos são iguais e o substituto também é.

Nenhum dos dois é categoria moral. Um único servidor de banco de dados de que você cuida com atenção é
um pet razoável, desde que o disco dele tenha backup. O que dá errado é um pet que todo mundo acha que
é gado: uma máquina num grupo, substituída numa noite pelo grupo fazendo o seu trabalho, levando junto
a única cópia de alguma coisa. A última seção desta aula é sobre guardar essa coisa em outro lugar.
