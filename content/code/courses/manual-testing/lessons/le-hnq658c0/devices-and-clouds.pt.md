---
title: Aparelhos reais, emuladores e nuvens de dispositivos
version: 1
---

O modo responsivo costuma ser tratado como teste num celular. Ele é o teste de um navegador de
desktop na largura de um celular, que pega a maior parte dos defeitos de layout e deixa passar um
conjunto específico de outros. **O modo responsivo imita o tamanho, a densidade de pixels, a entrada
por toque e o nome que o navegador dá a si mesmo. Ele não troca o motor**, então o Chrome ajustado
para parecer um iPhone continua desenhando a página com o Blink, e não traz junto nada do resto que
o celular tem.

## O que só um celular de verdade mostra

As diferenças que o modo responsivo não alcança são as que o cliente encontra na mão:

- o motor: o Safari num iPhone desenha com o WebKit, e uma peculiaridade de layout do WebKit é
  invisível no Chrome em qualquer largura;
- o teclado na tela, que sobe quando alguém toca no campo de ingressos e cobre metade da página, às
  vezes incluindo o botão Book;
- as fontes que o celular tem, que deixam as palavras mais largas ou mais estreitas que no laptop;
- os ajustes do celular, como um tamanho de texto maior escolhido por quem lê com dificuldade;
- o dedo, que é mais largo que o ponteiro do mouse e cai no link vizinho quando dois estão perto;
- a velocidade do celular e a rede dele, que um laptop numa boa conexão esconde.

Nada disso torna o modo responsivo inútil. Ele é a primeira conferência, rodada a cada mudança numa
página, porque custa um atalho de teclado. Os outros são para as células da matriz que concentram
mais clientes.

## Três jeitos de chegar a um motor de verdade

**Um emulador ou simulador** roda o software de um celular no laptop. O Android Emulator, que vem
com o Android Studio do Google, roda o Android, e as imagens de sistema dele que incluem os apps do
Google trazem o Chrome para Android de verdade. O Simulator da Apple, que vem com o Xcode, roda o iOS
com o motor do Safari, e o Xcode só roda num Mac. O motor é o real; o hardware, o teclado sob o
polegar e a velocidade continuam sendo os do laptop.

**Celulares próprios** cobrem o resto. Um time que testa para celular costuma guardar uma gaveta com
alguns, escolhidos nas primeiras linhas da sua tabela de público, e anota que versão de sistema cada
um roda. Um celular na gaveta fica desatualizado, às vezes de um jeito útil, já que os celulares dos
clientes também ficam.

**Uma nuvem de dispositivos reais** aluga celulares e navegadores de desktop que ficam no prédio de
outra empresa. BrowserStack, Sauce Labs e LambdaTest são três das empresas que oferecem isso: você
abre o site delas, escolhe um aparelho e um navegador, e a tela do aparelho aparece no seu próprio
navegador, onde você toca e digita com o mouse e o teclado. Elas existem para que um time possa
testar num iPhone sem ter um, ou num modelo que usaria uma vez só. Elas também rodam testes
automatizados nos mesmos aparelhos, assunto a que os cursos de automação desta trilha voltam.
Nenhuma delas foi usada neste curso, e os planos e preços delas mudam, então quanto uma custa é uma
pergunta para o site dela no dia.

## Alcançando o boxoffice de outro lugar

Todos esses caminhos esbarram no mesmo fato sobre o seu laboratório. O boxoffice escuta em
`127.0.0.1`, um endereço que quer dizer *esta máquina*, então um celular, mesmo um na mesma rede
Wi-Fi, não consegue abri-lo, e um celular numa nuvem de dispositivos muito menos. Um emulador no
laptop consegue, porque roda na mesma máquina; o Android Emulator alcança o laptop por um endereço
próprio, `10.0.2.2`, e a documentação dele diz isso.

As nuvens de dispositivos resolvem com um **túnel**: um programa pequeno que você roda na sua máquina
e que abre uma conexão de saída até o serviço, para que o celular deles alcance a sua aplicação por
ela. É prático e é uma decisão, porque dá a uma máquina de fora da sua organização um caminho até
algo de dentro. Onde a aplicação guarda dados de clientes reais, a regra da aula 20 vale antes de
qualquer túnel ser aberto: dados de teste em ambientes de teste, nunca os dados reais de alguém, e
um aparelho de outra empresa vê tudo o que você mostrar a ele.

## Juntando para o boxoffice

Para o boxoffice 1.0, a escolha de Ana na seção 03 desta aula fica concreta:

| célula | como Ana chega a ela |
|---|---|
| Chrome num celular Android | o Android Emulator para a passada completa, e um celular real na nuvem de dispositivos para uma olhada curta |
| Safari num iPhone | uma nuvem de dispositivos, pelo túnel dela, já que ninguém no time tem iPhone |
| Chrome, Edge e Firefox no Windows | os mesmos navegadores no laptop Ubuntu dela, e uma máquina Windows emprestada por uma tarde de passadas curtas |
| Safari num Mac | a nuvem de dispositivos de novo |
| toda página a 360 | o modo responsivo no Chrome e no Firefox, a cada versão nova |

Cada linha dessa tabela tem um custo e uma lacuna, e as lacunas vão para o plano ao lado das células
que não foram testadas de jeito nenhum. Uma afirmação de compatibilidade vale o que vale a lista de
onde ela foi conferida, e **"testado no celular" não quer dizer nada até dizer qual celular, com que
motor e como**.
