---
title: As duas senhas, e a que ninguém troca
version: 1
---

Há duas senhas naquela caixa e elas protegem coisas completamente diferentes. As pessoas conhecem
uma delas.

## A senha do Wi-Fi, que é a chave do rádio

É a que está impressa na etiqueta e que se dá às visitas. Ela controla **quem pode entrar na
rede**, e também faz algo menos óbvio: criptografa o tráfego entre cada aparelho e o roteador. Sem
ela, o rádio é legível por qualquer um ao alcance.

Três gerações estão em uso:

- **WEP** — quebrado desde o começo dos anos 2000 e quebrável em minutos. Se uma caixa só oferece
  WEP, ela é velha o bastante para ser trocada.
- **WPA2** — o padrão que quase tudo usa, e é adequado.
- **WPA3** — melhor, e vale ligar se todo aparelho aceitar. A maioria das caixas oferece um modo
  misto para os anos de transição.

Trocá-la desconecta todo aparelho da casa até que cada um receba a nova, que é exatamente o que faz
as pessoas evitarem trocá-la, e exatamente por que ela deve ser trocada no dia em que a pessoa
errada a descobrir.

## A senha de administração, que é a chave da caixa

É a que abre a página de configuração do roteador — a página em `192.168.0.1` ou parecido, onde a
rede é configurada.

**Ela muito frequentemente ainda é `admin` / `admin`.**

Isso importa de um jeito que a senha do Wi-Fi não importa, porque quem tem a página de configuração
tem a própria rede: pode ler a senha do Wi-Fi em texto claro, mudar para onde vão as consultas de
nome, abrir um caminho de fora para um aparelho de dentro, e deixar tudo isso no lugar.

Duas coisas seguem daí:

- **Troque, uma vez, e anote.** A página de configuração de um roteador é o único lugar onde
  *escrito no papel dentro de uma gaveta* é um gerenciador de senhas perfeitamente bom.
- **Nunca exponha a página de configuração à internet.** Costuma haver um ajuste chamado
  *gerenciamento remoto* ou *administração pela WAN*, e ele deve ficar desligado. Ele existe para
  que um técnico de suporte se conecte de fora; é também como um estranho faz isso.

## A rede de visitantes, que é de graça e ninguém usa

A maioria das caixas consegue rodar uma **segunda rede Wi-Fi com nome e senha próprios**, na qual
os aparelhos alcançam a internet e **não alcançam mais nada dentro de casa**.

Esse é o lugar certo para dois tipos de coisa:

- **visitas**, que assim nunca ficam sabendo a senha de verdade e não alcançam o disco de rede;
- **tudo que é barato e se conecta** — uma lâmpada inteligente, uma tomada, uma câmera, uma
  televisão. Isso são computadores, rodam software que ninguém atualiza, e não têm o que fazer na
  mesma rede que um notebook com os seus documentos.

Leva dez minutos para configurar e é a maior melhoria isolada de segurança disponível numa rede
doméstica.

## E o botão de reset

Um furinho atrás, segurado por dez segundos, devolve a caixa ao estado em que saiu de fábrica: o
nome e a senha de Wi-Fi da etiqueta, a senha de administração padrão, e nenhum dos seus ajustes.

É a resposta certa quando algo está mal configurado e ninguém sabe o quê. É a resposta errada
quando a internet está fora, porque não muda nada na linha e te custa a conexão Wi-Fi de todo
aparelho no momento em que você menos consegue consertá-los.
