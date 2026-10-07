---
title: Site a site, um túnel de que o caixa não sabe nada
version: 1
---

"VPN" costuma trazer à cabeça um aplicativo num laptop e um botão que alguém aperta. **Uma VPN site a
site não tem botão nem usuário.** Ela liga duas redes, de roteador a roteador, e as pessoas e máquinas
nelas nunca ficam sabendo que ela existe.

Os dois escritórios estão ligados assim, pelo túnel WireGuard da aula 4 entre `hq` e `branch`. **Esta
aula começa onde a primeira seção da aula 4 terminou**, numa rede recém montada: gere os três pares de
chaves como a aula 4 fez, escreva os três `wg0.conf` daquela seção com as suas próprias chaves e suba o
túnel com `sudo wg-quick up wg0` em `hq` e em `branch`. O laptop da Ana sobe depois, na seção sobre
túnel dividido. Este é o caixa traçando o caminho até o servidor de arquivos da matriz:

```
ana@till:~$ traceroute -n -q 1 192.168.10.10
traceroute to 192.168.10.10 (192.168.10.10), 30 hops max, 60 byte packets
 1  192.168.20.1  0.069 ms
 2  10.20.0.1  2.324 ms
 3  192.168.10.10  2.618 ms
ana@till:~$ ip route
default via 192.168.20.1 dev eth0 
192.168.20.0/24 dev eth0 proto kernel scope link src 192.168.20.30 
```

Três saltos. O primeiro é `branch`, o gateway do caixa. **O segundo é `10.20.0.1`, o endereço de `hq`
dentro do túnel, e toda a travessia da internet é esse único salto.** O roteador do provedor encaminhou
UDP criptografado e nunca viu os pacotes do traceroute lá dentro, então não tinha por que responder
como salto. O terceiro é `files`. Os 2,324 ms no salto 2 não são distância: nenhum enlace do
laboratório tem atraso, então todo tempo aqui é trabalho de um computador só.

A tabela de rotas do caixa é a outra metade da prova. Ela tem uma rota padrão para o gateway e a
própria LAN, e mais nada: nenhum endereço de túnel, nenhum software de VPN, nenhuma chave. Ela seria
igual se os dois escritórios estivessem ligados por uma linha dedicada. **Qual tráfego
vai para o outro escritório é decidido uma vez, no roteador, para todo dispositivo atrás dele**,
impressoras, câmeras e caixas incluídos. Nenhum deles conseguiria rodar um cliente de VPN se alguém
pedisse.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 270\" role=\"img\" aria-label=\"Dois painéis. Site a site: os roteadores hq e branch ligados por um túnel tracejado, sempre de pé; files e laptop ficam atrás de hq e o caixa, till, atrás de branch, e os dispositivos não rodam nada. Acesso remoto: três dispositivos, Ana em casa, um laptop no hotel e um celular, cada um com o seu túnel tracejado até hq, o concentrador; um túnel por pessoa, cada um com a sua chave.\"><defs><marker id=\"sh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"360\" height=\"250\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></rect><text x=\"24\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">site a site</text><rect x=\"40\" y=\"110\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"90.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"240\" y=\"110\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"290.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><path d=\"M140 122 C 175 90, 205 90, 240 122\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><text x=\"190\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um túnel, sempre de pé</text><rect x=\"30\" y=\"190\" width=\"56\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"58.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">files</text><path d=\"M58 190 L90 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"92\" y=\"190\" width=\"56\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">laptop</text><path d=\"M120 190 L90 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"262\" y=\"190\" width=\"56\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><path d=\"M290 190 L290 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"190\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dispositivos não rodam nada</text><rect x=\"390\" y=\"10\" width=\"360\" height=\"250\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></rect><text x=\"404\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">acesso remoto</text><rect x=\"640\" y=\"115\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"685\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"685\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">concentrador</text><rect x=\"410\" y=\"60\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Ana em casa</text><path d=\"M530 76 L 636 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><rect x=\"410\" y=\"122\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um laptop no hotel</text><path d=\"M530 138 L 636 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><rect x=\"410\" y=\"184\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um celular</text><path d=\"M530 200 L 636 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><text x=\"570\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um túnel por pessoa, cada um com a sua chave</text></svg>", "caption": "Onde o túnel termina decide quem ele conhece. O site a site termina em roteadores e conhece dois escritórios; o acesso remoto termina em cada dispositivo e conhece cada pessoa."}
```

Esse arranjo tem um caráter próprio:

- está sempre de pé. Ninguém faz login, e o túnel está lá às três da manhã para o backup tanto
  quanto às nove para as pessoas;
- autentica um local, não uma pessoa. **Qualquer coisa ligada na LAN da filial chega à matriz como
  a filial**, o laptop de um visitante incluído. Então cada ponta ainda precisa de regras de firewall dizendo
  quais endereços do outro escritório alcançam quais servidores, e de uma rede de visitantes mantida fora
  do túnel, na própria VLAN (aula 19 de `networks-addressing`);
- tem poucos pares, com endereços fixos. A configuração muda quando um escritório abre ou se muda, e
  quem cuida dela é a equipe de rede;
- as rotas aqui são escritas à mão. Com dois escritórios são duas linhas. Com trinta, os escritórios
  rodam um protocolo de roteamento pelos túneis, OSPF ou BGP das aulas 16 e 17 de `networks-addressing`,
  que é onde o GRE dentro de IPsec das aulas 1 e 2 ainda se justifica.
