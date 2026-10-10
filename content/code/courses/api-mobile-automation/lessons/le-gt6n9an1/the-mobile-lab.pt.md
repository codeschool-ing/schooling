---
title: O laboratório da segunda metade
version: 1
---

**As lições 14 a 22 precisam de um aparelho Android para testar, e o curso não dá nenhum**: você roda
um emulador no seu computador, liga um celular seu, ou empresta um aparelho em algum lugar online.
Esta seção compara os três, diz quanto cada um custa e recomenda um. A próxima monta o recomendado, e
a que vem depois do app diz o que fazer quando ele falha.

Seja qual for o aparelho, três coisas vão no seu próprio computador:

- **Android Studio**, o ambiente de desenvolvimento Android do Google, gratuito. Ele traz o **SDK**,
  as bibliotecas e ferramentas de que um build Android precisa, e o **emulador**. Você vai usá-lo
  para compilar e instalar o app, olhar as telas dele e, na lição 16, rodar o Espresso;
- **o boxoffice**, da lição 1, rodando como antes: o app pede a ele os espetáculos;
- **Node 22**, da lição 1, sobre o qual rodam o Appium da lição 15 e o Detox da lição 17.

## Três jeitos de ter um aparelho

| caminho | o que você tem | quanto custa | o que ele não faz |
|---|---|---|---|
| **um emulador no seu computador** (recomendado) | um Pixel virtual numa janela, qualquer versão do Android | 8 GB de memória no mínimo, 16 GB para ficar confortável; uns 10 GB de disco; um processador com virtualização ligada | dizer como o app se comporta no hardware de um modelo real (lição 19) |
| **um celular seu, por USB** | a coisa de verdade: a tela, os sensores, as manias do fabricante | nada, se você tem um Android dos últimos cinco ou seis anos | rodar a versão do Android ou o tamanho de tela que você não comprou |
| **online** | um emulador numa máquina na nuvem com virtualização, ou um aparelho numa nuvem de dispositivos | uma conta; tempo de uma cota gratuita, depois dinheiro | estar à mão: cada execução espera uma máquina, e algumas lições pedem que você toque o aparelho |

**O emulador é o caminho recomendado.** Ele pode ser qualquer celular e qualquer versão do Android
que você pedir, volta ao estado inicial num segundo, e é o que todo testador Android usa todo dia,
com ou sem aparelhos reais. O custo é o seu computador. Os números da tabela são os que o Google
publica para o Android Studio no momento em que isto foi escrito; com 8 GB de memória ele roda,
devagar, se você fechar o navegador enquanto isso.

O emulador é ele mesmo uma máquina virtual, então precisa do suporte de virtualização do seu
processador: Intel VT-x ou AMD-V, ligado no firmware do computador, e no Windows o recurso
*Plataforma do Hipervisor do Windows*. É também por isso que o caminho da máquina virtual da lição 1
não serve aqui: um emulador dentro de uma máquina virtual precisa de virtualização aninhada, que a
maioria dos notebooks não oferece. **Se você fez a lição 1 numa máquina virtual, instale o Android
Studio no seu próprio sistema agora**, e deixe o boxoffice onde está ou rode-o no seu sistema também.

**Um celular seu** é o caminho certo para um computador que não roda um emulador. Ligue as *Opções do
desenvolvedor* (toque sete vezes em *Número da versão* em *Sobre o telefone*), depois a *Depuração
USB*, e conecte com um cabo; o Android pergunta no celular se deve confiar no computador. Duas coisas
diferem do emulador, e as próximas seções dizem onde: o celular chega ao seu computador por
`adb reverse` em vez do endereço especial do emulador, e tudo que depende de uma versão específica do
Android, como a permissão de notificação da lição 21, depende da que o seu celular roda. Este caminho
não foi executado para este curso.

**Online**, existem duas rotas e nenhuma foi executada para este curso. As máquinas Linux que o
GitHub hospeda para o Actions permitem virtualização de hardware, então um workflow consegue iniciar
um emulador e rodar testes nele; repositórios públicos já rodaram nelas de graça, em termos que o
GitHub define e pode mudar. E as nuvens de dispositivos da lição 20 dão um celular real pela rede,
com um período de teste medido em minutos. As duas servem para rodar uma suíte e servem pouco para
aprender, porque você não pode se sentar na frente do aparelho.

## No Windows e num Mac

O Android Studio roda no Windows, no macOS e no Linux, e o emulador junto. **No Windows, instale o
Android Studio e o Node no próprio Windows, não dentro do WSL**, e digite os comandos desta metade
no PowerShell: `adb`, `emulator` e `npx appium` são os mesmos comandos ali, e um emulador não é
alcançado com facilidade de dentro do WSL. O boxoffice pode ficar no WSL; o Windows alcança um
servidor no WSL em `localhost`. Num Mac com Apple silicon, o emulador roda imagens ARM nativamente e é
rápido. Toda transcrição desta metade foi gravada no Ubuntu 24.04, então um caminho ou um prompt vão
parecer diferentes no seu.
