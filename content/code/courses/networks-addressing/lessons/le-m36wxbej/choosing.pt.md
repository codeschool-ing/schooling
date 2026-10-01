---
title: Qual modelo, e quanto custa
version: 1
---

Nenhum dos dois é o modelo moderno. A web, o e-mail e o DNS são cliente-servidor e vão continuar
sendo; a distribuição de arquivos e algumas chamadas são ponto a ponto; e a maioria dos sistemas reais
mistura os dois, com um servidor para a parte que precisa morar num lugar só. **A escolha é uma troca
entre controle num lugar só e dependência desse lugar.**

| | cliente-servidor | ponto a ponto |
|---|---|---|
| onde o serviço mora | nos servidores que você opera | espalhado pelos pares |
| quando uma máquina falha | servidor fora do ar é serviço fora do ar | um par a menos, os outros seguem |
| custo quando os usuários crescem | seu: mais servidores, mais banda | dividido: cada par novo também serve |
| achar o outro lado | um endereço e uma porta publicados | um tracker, uma DHT ou um servidor que apresente os pares |
| controle, logs, atualizações | num lugar só | cada par roda a sua cópia |
| através de NAT e firewalls | clientes conectam para fora, o que é permitido | pares também precisam receber, o que não é |

Cada linha é algo que esta aula mostrou ou que agora você sabe explicar. O ponto único de falha é o
srv: três conexões e uma máquina embaixo de todas. A linha do custo é o motivo de o BitTorrent
existir: um arquivo que um servidor manda para mil pessoas sai desse servidor mil vezes, enquanto
entre pares cada cópia que chega pode ser repassada. A última linha é a recusa que o r1 deu ao isp.

Para quem opera a rede, os dois modelos também parecem diferentes no fio. **O tráfego
cliente-servidor é previsível**: clientes conectam para fora em portas conhecidas, e uma regra de
firewall pode dizer "o escritório pode alcançar a porta 443 lá fora" e valer. O tráfego ponto a ponto
entra e sai em portas que o programa escolhe, entre máquinas que ninguém listou de antemão, e é por
isso que muitas empresas o bloqueiam na borda e que é difícil prestar contas dele onde é permitido.

A maioria dos serviços que você vai encontrar é híbrida, e vale ler a linha que cada um traça:

- **uma chamada de vídeo** é combinada pelos servidores do provedor e manda a mídia ponto a ponto
  quando as redes permitem, por um relay quando não permitem;
- **o BitTorrent** move o arquivo entre pares e acha os pares por um tracker, que é uma consulta
  cliente-servidor, ou pela DHT;
- **um jogo online** guarda num servidor o estado que decide a partida, para que nenhuma máquina de
  jogador possa se declarar vencedora, mesmo quando os jogadores trocam voz diretamente.

Então a pergunta a fazer sobre um serviço é qual parte dele precisa ficar num lugar só. O que precisa
ser confiável, registrado ou mantido consistente vai para um servidor. O que é volumoso e igual para
todos pode ser dividido entre pares.
