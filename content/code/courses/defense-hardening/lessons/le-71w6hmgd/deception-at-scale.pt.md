---
title: Engano em escala
version: 1
---

**Nada nesta seção foi executado para este curso.** Os produtos e serviços abaixo estão descritos a
partir da própria documentação deles.

O laboratório montou três iscas à mão. Um escritório com mil máquinas faz a mesma coisa com
ferramentas que tornam a isca barata de espalhar e os alertas fáceis de encaminhar, e as ideias são as
que você já conhece.

## Canarytokens

O serviço gratuito **Canarytokens**, da Thinkst, gera honeytokens de muitos tipos: um documento que
avisa quando é aberto, uma URL que alerta quando visitada, chaves falsas de acesso a nuvem que alertam
quando alguém as tenta, um nome DNS que alerta quando é resolvido. Cada um manda um e-mail ou um
webhook a quem o criou, com o horário e o endereço de onde veio. É a conta-isca desta aula transformada
em serviço: o alerta dispara onde quer que a coisa roubada seja usada. Usá-lo é confiar os alertas a um
terceiro, o que é uma decisão como qualquer outro serviço externo.

## Plataformas de engano

Produtos comerciais de **engano** (deception), entre eles os próprios aparelhos Canary da Thinkst,
rodam máquinas-isca que imitam as de verdade, um servidor de arquivos Windows ou uma impressora de rede,
com configuração por um console e alertas para as ferramentas que o escritório já tem. O que vendem é
sobretudo o que a seção sobre posicionamento pediu: iscas que parecem certas, custam pouco para pôr e
nunca viram uma porta de entrada.

## Contas-isca num diretório

Num domínio Windows, a ideia da conta-isca funciona particularmente bem. Uma conta com nome atraente,
uma descrição sugerindo antigos direitos de administrador e nenhum uso é criada no Active Directory;
qualquer tentativa de entrar com ela, ou de pedir tíquetes de acesso para ela, aparece no log de
segurança dos controladores de domínio e vira alerta. Os próprios produtos de proteção de identidade da
Microsoft documentam esse padrão com o nome de **contas honeytoken**.

## O teste de qualquer um deles

Cada um desses é julgado pelas mesmas três perguntas que esta aula fez à própria isca: está onde um
invasor olharia, nunca enfraquece o que está ao lado, e uma pessoa vê o alerta em minutos. Um produto
de engano que falha na terceira é o mesmo que o arquivo no `web` sem ninguém lendo o log.
