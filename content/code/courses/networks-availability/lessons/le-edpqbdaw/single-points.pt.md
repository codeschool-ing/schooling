---
title: Achando o ponto único de falha
version: 1
---

Um **ponto único de falha**, um SPOF, é uma parte cuja falha sozinha derruba o serviço. Achá-los é o
primeiro trabalho de um projeto de disponibilidade, e eles raramente estão onde as pessoas olham primeiro,
porque as pessoas olham para os servidores.

Aqui está o data center do laboratório como uma requisição para `www.example.com` o vê, com cada parte
pintada conforme tem ou não um gêmeo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"O data center do laboratório como uma requisição o vê. Os usuários chegam ao roteador do provedor, isp em 192.0.2.1, que tem um único enlace para o data center, um só segmento 192.0.2.0/24. Dentro estão o servidor DNS ns em 192.0.2.53, dois balanceadores lb1 e lb2 em 192.0.2.11 e .12 dividindo www.example.com em 192.0.2.80, e três servidores web, web1 a web3, em 192.0.2.21 a .23, cada balanceador ligado a todos os servidores web. O roteador do provedor, o enlace dele, o segmento e o servidor DNS aparecem como únicos; os balanceadores e os servidores web, como tendo um gêmeo.\"><rect x=\"20\" y=\"128\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"68.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">usuários</text><path d=\"M116 150 L140 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"140\" y=\"128\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"190.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.1</text><path d=\"M240 150 L300 150\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"270\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">um enlace</text><rect x=\"300\" y=\"30\" width=\"400\" height=\"236\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"312\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data center, um segmento</text><text x=\"688\" y=\"47\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.0/24</text><path d=\"M300 150 L320 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M300 150 L320 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M300 150 L320 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"320\" y=\"70\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ns</text><text x=\"370.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.53</text><rect x=\"320\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb1</text><text x=\"370.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.11</text><rect x=\"320\" y=\"190\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb2</text><text x=\"370.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.12</text><path d=\"M420 150 L560 90\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 150 L560 150\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 150 L560 210\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 210 L560 90\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 210 L560 150\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 210 L560 210\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"560\" y=\"70\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"615.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.21</text><rect x=\"560\" y=\"130\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web2</text><text x=\"615.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.22</text><rect x=\"560\" y=\"190\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web3</text><text x=\"615.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.23</text><text x=\"320\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">www.example.com = 192.0.2.80</text><rect x=\"20\" y=\"284\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"289\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">único: a falha dele sozinha derruba o site</text><rect x=\"380\" y=\"284\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400\" y=\"289\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tem um gêmeo que pode assumir</text></svg>", "caption": "Cinco máquinas têm um gêmeo e quatro coisas não têm. As únicas estão todas no caminho de entrada, por onde toda requisição tem de passar."}
```

Os servidores estão bem. Três servidores web atrás de dois balanceadores sobrevivem à perda de qualquer um
deles, e a aula 16 mede isso: quando o balanceador de `lb1` foi morto, `lb2` assumiu e o site voltou a
responder depois de 2,694 segundos, e quando `web2` parou, o balanceador mandou todas as requisições para
`web1` e `web3`. **Todo o resto do desenho é único.** Há um roteador para a internet, `isp`, num enlace
só. Há um servidor DNS, `ns`: se ele parar, um navegador que ainda não guardou o endereço em cache não
encontra `www.example.com` de jeito nenhum, e cinco máquinas saudáveis ficam inalcançáveis pelo nome. E
todas as máquinas da sala estão penduradas num único segmento, `192.0.2.0/24`, que numa sala de verdade é
um switch ou um par deles.

## Um método, não um palpite

Percorra o caminho de uma requisição da máquina do usuário até a resposta e de volta, e em cada caixa e
cada linha faça uma pergunta: **se só isto falhasse, a requisição ainda daria certo?** Depois percorra de
novo pelo que o caminho usa sem estar nele. A consulta do nome acontece antes da requisição. O certificado
precisa ser válido, e o relógio contra o qual ele é conferido precisa estar certo. E debaixo de tudo isso
tem a energia.

A segunda volta acha a maioria dos que as pessoas esquecem:

| muitas vezes esquecido | o que ele derruba junto |
|---|---|
| um provedor, ou dois provedores cujos cabos entram juntos no prédio | tudo o que fala com o lado de fora |
| um servidor DNS, ou dois na mesma rede | todos os nomes, enquanto todos os endereços continuam funcionando |
| o gateway padrão da LAN de um escritório | todos os hosts dela, por mais roteadores que estejam ligados |
| uma alimentação elétrica ou um nobreak | o rack inteiro |
| uma pessoa que sabe como o failover funciona | a recuperação, às três da manhã |

A terceira linha está no laboratório. Todo host da matriz tem exatamente um gateway padrão,
`192.168.10.1`, e a aula 15 começa com a tabela de rotas do laptop dizendo isso. Um segundo roteador na
mesma LAN não muda nada para um host que só manda para o primeiro, então **redundância que os hosts não
conseguem usar não é redundância**. A aula 15 resolve isso fazendo o próprio endereço do gateway mudar de
um roteador para o outro.

## Nem todo vale a pena remover

Cada SPOF removido custa dinheiro e acrescenta uma parte que também pode falhar: o mecanismo de failover.
Um segundo link de provedor custa uma mensalidade. Um segundo servidor DNS em outro lugar é barato e quase
sempre vale a pena. Um segundo data center pode dobrar a conta. A decisão é a aritmética da seção anterior
contra o custo de uma hora fora do ar para aquele negócio em particular, e a aula 17 transforma essa
decisão numa promessa que alguém assina. **Uma lista dos SPOFs que você manteve de propósito é um projeto;
uma lista que você nunca fez é uma surpresa.**
