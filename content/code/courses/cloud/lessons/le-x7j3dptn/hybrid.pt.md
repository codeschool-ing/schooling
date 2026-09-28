---
title: "Híbrida: uma carga dos dois lados"
version: 1
---

Dois ambientes de uma mesma empresa não viram híbridos por serem da mesma empresa. Uma firma com um
datacenter para o ERP e uma conta pública para o site de marketing, nunca ligados, tem dois ambientes
separados. **O híbrido começa quando uma carga usa os dois**: quando algo de um lado não faz o seu
trabalho sem algo do outro.

Os arranjos que levam as pessoas a ligá-los são poucos e reconhecíveis:

- uma loja online cuja vitrine roda numa região pública, perto dos clientes e capaz de crescer numa
  promoção, enquanto o estoque e os pedidos ficam no banco do ERP no prédio da empresa;
- o cloud bursting, o exemplo da NIST: o lado privado roda a carga até lotar e o excesso vai para
  capacidade pública enquanto durar;
- backup e recuperação de desastres, em que as cópias e um ambiente reserva ficam numa região pública
  e a produção fica em casa;
- uma fábrica cujos controladores de máquina precisam ficar no chão de fábrica, mandando as leituras
  para uma região pública onde a análise roda.

## O que atravessa a emenda

Ligue dois ambientes e três coisas precisam passar entre eles.

**A rede vem primeiro**, porque nada mais passa sem ela. Os dois espaços de endereços são ligados e
roteados um para o outro, de um de dois jeitos. Uma VPN site a site é um túnel IPsec criptografado
pela internet pública: barata de montar, com latência e vazão que variam com o que a internet estiver
fazendo. Um link dedicado é um circuito privado do seu datacenter, ou de uma instalação onde você tem
presença, até a rede do provedor; a AWS chama a sua versão de Direct Connect, a Azure de
ExpressRoute e o Google de Cloud Interconnect. Ele tem uma taxa pela porta, com tráfego ou sem, e
pode levar semanas para ser contratado, e em troca a capacidade e a latência ficam estáveis. De
qualquer jeito, **as faixas de endereços privados dos dois lados não podem se sobrepor**: se a rede
do escritório e a rede na nuvem usam a mesma faixa, os roteadores de cada lado não sabem para qual
delas vai um pacote. A aula 6 monta o lado da nuvem dessa rede.

A identidade vem em segundo. Pessoas e programas de um lado precisam de acesso a recursos do outro, e
manter duas listas de usuários separadas é como a conta de alguém que saiu da empresa sobrevive num
dos lados. A resposta de costume é a *federação*: o lado da nuvem confia no diretório da empresa para
dizer quem a pessoa é, e só decide o que ela pode fazer. A aula 7 trata de papéis e políticas.

Os dados vêm em terceiro, e são eles que decidem o desenho. Qual cópia é a verdadeira, como o outro
lado é mantido em dia, e com que frequência alguém lê através do link. **Toda leitura através da
emenda custa tempo**, e num dos sentidos custa dinheiro, que é a próxima seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um arranjo híbrido. À esquerda, nas instalações da empresa: um banco de dados do ERP, o diretório da empresa e um servidor de arquivos. À direita, uma região de nuvem pública: um front-end web, servidores de aplicação e armazenamento de objetos. Entre os dois, três coisas atravessam a emenda. Rede: uma VPN IPsec pela internet, ou um link dedicado. Identidade: o login do lado da nuvem confia no diretório da empresa. Dados: replicação, backups e relatórios. Embaixo, o lado do provedor na conta: o tráfego que entra na região custa 0,0000 USD por GB, o que sai para a internet começa em 0,1500 USD por GB em sa-east-1.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"214\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">na empresa</text><rect x=\"34\" y=\"60\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco do ERP</text><rect x=\"34\" y=\"116\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">diretório da empresa</text><rect x=\"34\" y=\"172\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor de arquivos</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"214\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">região pública</text><rect x=\"514\" y=\"60\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">front-end web</text><rect x=\"514\" y=\"116\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidores de aplicação</text><rect x=\"514\" y=\"172\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">armazenamento de objetos</text><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rede: VPN IPsec, ou um link dedicado</text><path d=\"M224 92 L496 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#hs-ah)\" marker-end=\"url(#hs-ah)\"></path><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identidade: o login confia no diretório</text><path d=\"M224 148 L496 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#hs-ah)\" marker-end=\"url(#hs-ah)\"></path><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados: replicação, backups, relatórios</text><path d=\"M224 204 L496 204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#hs-ah)\" marker-end=\"url(#hs-ah)\"></path><path d=\"M20 252 L700 252\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M230 276 L496 276\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"236\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">entrando na região: 0,0000 USD por GB</text><path d=\"M496 302 L230 302\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"490\" y=\"292\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">saindo para a internet: a partir de 0,1500 USD por GB</text></svg>", "caption": "O que um arranjo híbrido precisa levar pela emenda, e de que lado da conta cai cada sentido. Os preços são as linhas de sa-east-1 da lista pública; um link dedicado tem tabela de preços própria, que não está citada aqui."}
```

## A emenda é uma dependência

A vitrine acima consulta o estoque em toda página de produto. Se a VPN cai, a vitrine não fica lenta;
ela para, numa região pública perfeitamente saudável. Ligar dois ambientes quer dizer que as falhas
deles também ficam ligadas, e o link é uma terceira coisa que pode falhar.

Os desenhos que convivem bem com isso mantêm o tráfego pela emenda **pouco, grosso e assíncrono**: uma
cópia do estoque atualizada a cada poucos minutos do lado da nuvem, pedidos numa fila que o ERP
esvazia quando pode, relatórios mandados uma vez por noite. Uma página que precisa de uma travessia
por requisição é uma página que o link consegue derrubar.

Vale reconhecer pelo nome uma última forma de híbrido. AWS Outposts, Azure Stack e Google Distributed
Cloud colocam o hardware do provedor, rodando o software do provedor e respondendo à API do provedor,
dentro do seu prédio. A emenda continua lá, agora entre esse rack e a região que o gerencia.
