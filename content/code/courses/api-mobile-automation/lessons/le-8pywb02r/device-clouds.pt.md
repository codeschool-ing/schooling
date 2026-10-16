---
title: Nuvens de aparelhos, e o que alugar um celular envolve
version: 1
---

**Uma nuvem de aparelhos é um data center cheio de celulares reais, cada um num cabo ligado a um
computador, alugados pela internet por minuto.** Você envia o app, escolhe aparelhos num catálogo de
fabricantes, modelos e versões, e ou conduz um à mão numa janela do navegador ou aponta uma suíte
automatizada para ele. Voltam os resultados com um vídeo da tela, o log do aparelho e capturas de
tela, que é mais do que um celular na sua mesa registra sozinho.

Os nomes no momento em que este curso foi escrito incluem o **Firebase Test Lab**, do Google; o
**BrowserStack**; o **Sauce Labs**; e o **AWS Device Farm**, da Amazon. A maioria oferece iPhones
além de celulares Android, o que faz de uma nuvem um dos caminhos que a lição 18 citou para testar
num iPhone real sem ter um, e algumas oferecem emuladores e simuladores ao lado dos aparelhos reais,
por menos.

## Dois jeitos de usar uma

- **À mão.** Uma sessão ao vivo mostra a tela de um celular real no seu navegador e manda os seus
  cliques para ele. É como quem testa explora um defeito relatado de um modelo que ninguém da equipe
  tem, o terceiro passo da lista da lição 19, sem comprar o celular.
- **Automatizado.** Uma sessão Appium vai para o servidor da nuvem em vez do servidor no seu
  computador, ou um pacote Espresso ou XCUITest é enviado e rodado lá. A seção 06 mostra os dois.
  Vários aparelhos rodam ao mesmo tempo, cada um uma linha da matriz da seção 04.

## O que custa

**Toda nuvem cobra por tempo de aparelho, e a maioria também por quantos aparelhos podem rodar ao
mesmo tempo.** Vale fazer a conta antes de escolher um plano: uma suíte que leva certo número de
minutos, rodada em cada uma das 12 linhas da seção 04 toda noite, custa doze vezes esse número em
minutos de aparelho por noite, e com dois aparelhos permitidos em paralelo leva seis vezes a duração
da suíte para terminar. Testes grátis, franquias gratuitas e preços mudam com frequência, então
nenhum é citado aqui; leia a página do próprio fornecedor no dia em que decidir.

O que custa além de dinheiro é tempo e certeza. Um celular na nuvem é mais lento de alcançar que um
emulador na sua mesa: o app é enviado e instalado, todo comando atravessa a internet, e um modelo
popular pode estar ocupado quando você pede. Uma falha também tem mais causas possíveis: o app, o
celular, a rede entre vocês, ou a própria nuvem. **O vídeo é o que decide**: assista à execução antes
de registrar o defeito.

## O seu servidor precisa ser alcançável

O app num celular da nuvem pede ao boxoffice como qualquer outra cópia, e **nem `10.0.2.2` nem
`localhost` significam o seu computador para um celular no prédio de outra pessoa.** Há duas
respostas. Ou o app é compilado apontando para uma cópia de teste do servidor que a internet alcança,
com dados de teste, que é contra o que a maioria das equipes roda as suítes na nuvem; ou o túnel da
própria nuvem leva as requisições do celular de volta ao seu computador. O BrowserStack chama o túnel
dele de *Local* e o Sauce Labs chama o seu de *Sauce Connect*; cada um é um programa que você inicia
ao lado do seu servidor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 288\" role=\"img\" aria-label=\"Do seu lado, o teste, uma cópia de teste do boxoffice e o programa de túnel da nuvem. No data center da nuvem, o servidor Appium dela e celulares reais como um Galaxy A15, um Moto G24 e um Redmi 13C, além do vídeo e dos logs guardados a cada execução. O teste manda comandos ao servidor da nuvem, que conduz um celular; o app no celular pede ao boxoffice pelo túnel, de volta do seu lado.\"><defs><marker id=\"f20cloud-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"230\" height=\"220\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"135\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o seu lado</text><rect x=\"40\" y=\"64\" width=\"190\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o teste</text><text x=\"135\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">node --test</text><rect x=\"40\" y=\"128\" width=\"190\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><text x=\"135\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma cópia de teste</text><rect x=\"40\" y=\"190\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"135\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o programa de túnel</text><text x=\"135\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o da própria nuvem</text><rect x=\"330\" y=\"30\" width=\"350\" height=\"220\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"505\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o data center da nuvem</text><rect x=\"350\" y=\"64\" width=\"140\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"420\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o servidor dela</text><text x=\"420\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Appium, HTTPS</text><rect x=\"520\" y=\"64\" width=\"145\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Galaxy A15</text><text x=\"592.5\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android 14</text><rect x=\"520\" y=\"122\" width=\"145\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Moto G24</text><text x=\"592.5\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android 14</text><rect x=\"520\" y=\"180\" width=\"145\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Redmi 13C</text><text x=\"592.5\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android 14</text><rect x=\"350\" y=\"128\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"420\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vídeo, logs</text><text x=\"420\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">guardados a cada execução</text><line x1=\"230\" y1=\"87\" x2=\"348\" y2=\"87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f20cloud-ah)\"></line><text x=\"289\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">comandos</text><line x1=\"490\" y1=\"87\" x2=\"518\" y2=\"87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f20cloud-ah)\"></line><line x1=\"518\" y1=\"212\" x2=\"232\" y2=\"212\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#f20cloud-ah)\"></line><text x=\"430\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o app pede ao boxoffice pelo túnel</text><line x1=\"135\" y1=\"190\" x2=\"135\" y2=\"176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f20cloud-ah)\"></line><text x=\"350\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10.0.2.2 e localhost não significam nada num celular no prédio de outra pessoa</text></svg>", "caption": "Os comandos vão para a nuvem; as requisições do próprio app precisam achar o caminho de volta até um servidor que ele alcance.", "same": ["Android 14", "Galaxy A15", "Moto G24", "Redmi 13C"]}
```

De um jeito ou de outro, o endereço que o app pede faz parte do build: o `baseUrl` do Tickets, da
lição 14, é uma linha, e um build para a nuvem a muda. O teste muda também, porque o teste da lição
15 perguntava os lugares ao boxoffice a partir do seu computador, e precisa perguntar à mesma cópia
do servidor que o celular usa.

## Os celulares dos outros

O celular em que você testa foi usado por outro cliente uma hora atrás e será usado por outro depois
de você. Os fornecedores descrevem como limpam um aparelho entre sessões, e essa é a política deles
para ler, não uma garantia para presumir. Então:

- **só contas e dados de teste**: o nome, o cartão ou o ingresso de um cliente real não têm o que
  fazer num celular alugado, e no Brasil a LGPD tem algo a dizer sobre pô-los ali;
- **segredos como variáveis de ambiente da execução**, nunca digitados no app na tela e nunca no
  código do teste, pelos motivos que a lição 3 deu;
- **os vídeos e as capturas de tela ficam guardados nos servidores do fornecedor**, então o que a
  tela mostrou agora está lá também.
