---
title: Scans sem autenticação, com credenciais e por agente
version: 1
---

Um scanner de rede pode olhar um host de três jeitos, e a escolha entre eles muda o que ele acha
mais do que a escolha do produto. **Nenhum dos três foi executado para este curso.** Nessus e Qualys
exigem licença ou conta registrada, o OpenVAS precisa de uma máquina só para ele, e os três são
feitos para hosts numa rede, o que o laptop de um aluno rodando o linkbox não é. O que vem a seguir
vem da documentação dos fornecedores, e não há transcrição nem captura de tela de nenhum deles nesta
aula.

### Sem autenticação: um estranho na porta

Um scan sem autenticação, também chamado de remoto, conecta no host como qualquer cliente faria. Ele
descobre quais portas respondem, o que cada serviço diz de si, quais versões de protocolo e cifras
TLS aceita, e como são as páginas padrão. A partir dessas respostas ele infere software e versões, e
a partir das versões, avisos de segurança.

Essa inferência é o ponto fraco, nas duas direções:

- **Falsos negativos**, quando a versão não é anunciada. A seção anterior mostrou um: o linkbox
  responde `Server: gunicorn` sem número, então não há o que comparar.
- **Falsos positivos**, quando a versão é anunciada mas não é a verdade inteira. Debian, Ubuntu e Red
  Hat corrigem uma vulnerabilidade fazendo **backport** do patch para a versão que já distribuem, sem
  mudar o número da versão de origem. Um banner que ainda parece a versão antiga casa com um aviso que
  o pacote já não tem.

Um scan sem autenticação ainda vale a pena. Ele vê exatamente o que alguém de fora vê, que é a
pergunta certa para tudo o que fica exposto à internet, e é o único scan que acha um serviço que
ninguém sabia que estava escutando.

### Com credenciais: um scanner com uma conta

Um scan com credenciais, que parte da documentação chama de autenticado, dá ao scanner uma conta no
host: uma chave SSH no Linux, uma conta Windows para os serviços que o Windows expõe a
administradores. O scanner entra e lê o que o próprio host sabe. Isso é o banco de pacotes, o nível de
patches, os arquivos de configuração, a versão do kernel. **É o mesmo tipo de leitura que o Trivy faz
numa imagem, feito numa máquina viva.**

Ele acha mais, porque vê pacotes que nenhuma porta aberta revela, como uma biblioteca vulnerável
usada por um job agendado. E erra menos, porque lê a versão exata do pacote da distribuição, com o
backport incluído, em vez de um banner. Tenable, Greenbone e Qualys documentam o scan com credenciais
como o mais preciso, por esse motivo.

O custo é uma conta em cada host, nas mãos de uma ferramenta que alcança todos os hosts. **A
credencial do scanner é um dos segredos mais valiosos da organização**, e é tratada como tal. Ela recebe uma conta dedicada em vez da conta de alguém, o menor privilégio que cada fornecedor documenta para as
suas checagens, guardada no cofre de credenciais do próprio scanner ou num vault, e rotacionada. A
aula 17 volta ao jeito de uma máquina guardar um segredo.

### Agentes: o scanner se muda para dentro

Um agente é um programa pequeno instalado em cada host (a Tenable vende os Nessus Agents, a Qualys o
Qualys Cloud Agent) que coleta as mesmas informações locais que um scan com credenciais lê e as envia
para a plataforma do fornecedor. Nada precisa alcançar o host de fora, então um agente funciona num
laptop que nunca está na rede do escritório quando o scan roda, e numa instância de nuvem que vive uma
hora. O preço é software rodando em cada máquina, que precisa ser implantado, atualizado e merecer a
mesma confiança que qualquer outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l11-vantage\" aria-label=\"Três jeitos de um scanner de rede olhar um host. Sem autenticação, de fora, ele só pode perguntar às portas abertas o que elas são. Com credenciais, ele entra por SSH e lê o banco de pacotes e a configuração do host. Um agente roda dentro do host, lê os mesmos registros e os envia para a plataforma do fornecedor.\"><defs><marker id=\"sp-l11-vantage-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l11-vantage-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l11-vantage-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"300\" y=\"20\" width=\"400\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um host</text><rect x=\"255\" y=\"60\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">portas abertas</text><rect x=\"380\" y=\"60\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">serviços</text><rect x=\"380\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">banco de pacotes</text><rect x=\"540\" y=\"130\" width=\"145\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"612.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">arquivos de configuração</text><rect x=\"540\" y=\"210\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"612.5\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">agente</text><text x=\"612.5\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">instalado no host</text><rect x=\"20\" y=\"60\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sem autenticação</text><text x=\"105.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pergunta às portas</text><path d=\"M190 80 L253 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-vantage-ah-paper-dim)\"></path><rect x=\"20\" y=\"140\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">com credenciais</text><text x=\"105.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entra, lê os registros</text><path d=\"M190 160 L378 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-vantage-ah-phosphor)\"></path><text x=\"240\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">ssh</text><rect x=\"20\" y=\"220\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">plataforma do fornecedor</text><path d=\"M538 240 L192 240\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l11-vantage-ah-amber)\"></path><text x=\"400\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">envia para fora</text><path d=\"M612 208 L612 172\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-vantage-ah-amber)\"></path></svg>", "caption": "Só o scan sem autenticação fica de fora. Os outros dois leem o que o próprio host registra, e por isso sabem as versões exatas."}
```

| | sem autenticação | com credenciais | agente |
|---|---|---|---|
| do que precisa | alcance de rede | alcance de rede e uma conta | software no host |
| lê | o que os serviços respondem | os registros do próprio host | os registros do próprio host |
| precisão da versão | inferida de banners | exata, com backports | exata, com backports |
| acha um host não listado | sim | sim, e entra onde consegue | não, só hosts com agente |
| risco principal | falsos positivos e pontos cegos | a credencial do scanner | mais um programa em toda parte |

### E os containers?

Um scan com credenciais de um nó do Kubernetes lê os pacotes do nó: o kernel, o runtime de
containers, o sistema operacional. Os pacotes dentro de cada imagem são outra pergunta, porque vivem
nas camadas da imagem e não no banco de pacotes do nó. As plataformas comerciais vendem scan de
containers e de registry como produtos à parte. Este curso responde a essa pergunta com um scanner de
artefato, no pipeline, antes de a imagem existir em qualquer outro lugar.
