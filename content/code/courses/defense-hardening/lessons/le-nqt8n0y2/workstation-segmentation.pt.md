---
title: A estação do próprio administrador
version: 1
---

**Tudo nesta aula confia no `admin`.** Ele guarda a chave, é a única máquina que o `jump` aceita, e
num escritório de verdade guardaria o certificado do dia. Então a última pergunta é o que o próprio
`admin` faz o dia inteiro, e a resposta incômoda na maioria dos escritórios é: tudo. O administrador
lê e-mail nele, abre anexos, navega pela documentação de fornecedores e depois entra nos servidores a
partir da mesma sessão.

Essa é a brecha que todo diagrama arrumado de bastião deixa. **Um servidor de salto protege os
servidores de toda máquina, menos daquela que tem permissão de usá-lo**, e se a estação do próprio
administrador estiver comprometida, o atacante usa o bastião exatamente como foi projetado.

## Uma estação só para administrar

A resposta tem nome na documentação da Microsoft, a **estação de trabalho de acesso privilegiado**
(PAW, privileged access workstation): uma máquina, ou uma máquina virtual separada no computador do
administrador, usada para administrar e para mais nada. Sem cliente de e-mail, sem navegação geral,
sem documentos de fora; uma lista curta de programas permitidos; e a única máquina cujo endereço o
firewall do bastião cita. A pessoa mantém uma estação comum para todo o resto, e as duas nunca dividem
uma chave.

No laboratório, o `admin` faz esse papel e o `desk` faz a estação comum, e as regras que você escreveu
já tratam as duas de forma diferente. O que o laboratório não mostra é a disciplina que as mantém
diferentes, porque isso não é configuração: é uma decisão de que ler e-mail no `admin` não é
permitido, escrita e conferida.

## Camadas

Organizações maiores generalizam a mesma ideia em **camadas** (tiers), um modelo que a Microsoft
documentou para o Active Directory e depois incorporou ao seu "modelo de acesso corporativo". A camada
0 é o que controla a identidade de todo mundo, os controladores de domínio e a autoridade
certificadora; a camada 1 são os servidores; a camada 2 são as estações. A regra é que **credenciais
só descem**: um administrador da camada 0 nunca entra numa estação da camada 2, porque no momento em
que entra, quem controla essa estação pode capturar o que ele digitou. O servidor de salto e a PAW são
o que torna a regra prática, em vez de só enunciada.

A autoridade certificadora SSH da seção anterior é camada 0 nesse modelo: a chave mais protegida desta
aula, guardada offline, assinando a partir de uma máquina que não faz mais nada.

## Windows: uma senha por máquina

Um controle do Windows pertence a esta aula porque tira um caminho que as regras dela não veriam.
Máquinas Windows têm uma conta local de Administrador embutida, e por anos o costume era dar a ela a
mesma senha em todas as máquinas, definida uma vez na imagem. Quem a descobrisse num notebook entrava
em todos. O **Windows LAPS** (Local Administrator Password Solution) dá a cada máquina a sua própria
senha aleatória de administrador local, troca-a numa agenda e a guarda no Active Directory ou no
Microsoft Entra ID, onde só pessoas nomeadas podem lê-la, com cada leitura registrada. Ele não foi
executado para este curso; este parágrafo vem da documentação da Microsoft. A contrapartida Linux
neste laboratório é o que a aula 1 fez: nenhuma senha de root compartilhada, nenhum segundo root, e
administradores que entram como eles mesmos.
