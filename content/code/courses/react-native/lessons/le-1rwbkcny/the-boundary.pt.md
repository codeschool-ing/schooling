---
title: O que este curso roda, e o que ele só lê
version: 1
---

**Quase todo este curso roda num computador comum, sem celular conectado.** Os componentes, o estilo,
a navegação, as listas, os formulários, a busca de dados e as animações do React Native são
JavaScript, e rodam em dois lugares que não precisam de nada além do Node.js: em **testes**, com o
Jest, que renderiza os seus componentes sem tela e deixa você apertar os botões deles; e num
**navegador**, porque o Expo constrói o mesmo app para a web, desenhado com HTML no lugar das views
nativas. Toda transcrição dessas aulas foi gravada assim, num computador Linux, e você pode repetir
cada uma no seu.

**Uma parte precisa de um aparelho, e algumas partes precisam de um Mac.** Este curso diz quais, aqui,
para que ninguém descubra o muro no meio de uma aula.

## Aula por aula

| aulas | o que você pratica num computador | o que precisa de mais |
|---|---|---|
| 1 a 11 | tudo: o projeto, componentes, estilos, listas, navegação, estado, dados, formulários | um celular com o Expo Go, se quiser ver as views nativas |
| 12 | animações, em testes e no navegador | o quanto ficam suaves se julga num aparelho |
| 13 | permissões como configuração; escolher uma imagem no navegador | a câmera em si |
| 14 | armazenamento no navegador e em testes | o cofre seguro, que usa o chaveiro do celular |
| 15 | localização no navegador, com uma posição que você define | mapas, e localização em segundo plano |
| 16 | o que o app faz com uma notificação | entregar uma notificação push a um celular |
| 17 | um módulo nativo em Kotlin, compilado num app Android | a metade em Swift, que precisa do Xcode |
| 18 e 19 | logs, erros, source maps, tamanho do bundle | o depurador ligado a um app num aparelho |
| 20 | um build de release Android, assinado com a sua própria chave | compilar na nuvem do Expo, e qualquer coisa de iOS |
| 21 | o que uma atualização contém, e quando ela é segura | publicá-la, o que exige uma conta no Expo |
| 22 | leitura | — |

**Os builds Android das aulas 3, 17, 18 e 20 precisam do Android SDK**, que roda em Linux, Windows e
macOS. Eles produzem um arquivo de app e o examinam. **Instalar esse arquivo num emulador ou num
celular não foi feito quando este curso foi gravado**: o computador não tinha virtualização por
hardware para um emulador nem um celular conectado. Onde uma aula chega a esse passo, ela diz isso e
dá o comando que você rodaria com um aparelho conectado.

## Marcado onde acontece

Dentro de uma aula, tudo o que **não foi rodado** aparece em itálico e diz isso, assim: *o simulador
de iOS não foi rodado*. É ensinado a partir da documentação da própria plataforma, sem transcrição e
sem captura de tela, porque a transcrição de algo que nunca rodou seria inventada. Tudo o que aparece
num bloco de terminal foi rodado, no computador em que este curso foi gravado, e imprimiu exatamente
o que você vê.

## A questão do Mac

**Você não precisa de um Mac para terminar este curso.** Precisa de um, ou de um build pago na nuvem,
para colocar um app iOS num iPhone: o Xcode é a única ferramenta que constrói um, a Apple o licencia
só para macOS, e o simulador de iOS vem com ele. A aula 20 é sobre a segunda via — o serviço de build
do Expo roda o Xcode nos Macs do Expo — e o que ela custa. Tudo o que este curso ensina sobre iOS que
não precisa do Xcode, ele ensina: a configuração que o Expo escreve para ele, as permissões que ele
pede, as regras que a loja dele aplica.

## Serviços de que este curso não depende

O Expo oferece serviços pagos na nuvem: builds (EAS Build), atualizações (EAS Update) e envios às
lojas (EAS Submit). As aulas 20 e 21 os explicam e dizem quanto custam no dia que cada aula informa,
e **nenhuma das duas exige que você se cadastre**: cada uma ensina primeiro a alternativa local e
gratuita. As lojas são o outro custo, e o curso `mobile-delivery` é sobre elas.
