---
title: As camadas sob uma aplicação em execução
version: 1
---

Antes que alguém possa dizer quem opera o quê, é preciso uma lista do **que existe para operar**. O
site de uma loja que responde a uma requisição se apoia em nove camadas, e cada uma tem tarefas
que voltam toda semana, esteja alguém olhando ou não.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 374\" role=\"img\" aria-label=\"As camadas sobre as quais uma aplicação roda, do prédio embaixo aos dados em cima. Instalações: o prédio, energia, refrigeração e vigilância. Hardware: servidores, discos e os cabos entre eles. Rede física: switches, roteadores e os enlaces para fora. Virtualização: um servidor físico cortado em muitas máquinas virtuais. Rede virtual: os endereços, sub-redes e regras de firewall dessas máquinas. Sistema operacional: kernel, pacotes, usuários e patches de segurança. Runtime: a linguagem, o interpretador e o servidor web. Aplicação: o código e os pacotes que ele puxa. Dados: pedidos, clientes e arquivos, o que o código guarda. Ao lado de todas, identidade e acesso: quem pode mexer em cada camada.\"><defs><marker id=\"stk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">camada</text><text x=\"196\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que é</text><rect x=\"20\" y=\"328\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"343.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">instalações</text><text x=\"196\" y=\"343.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o prédio, energia, refrigeração, vigilância</text><rect x=\"20\" y=\"292\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"307.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">hardware</text><text x=\"196\" y=\"307.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servidores, discos, os cabos entre eles</text><rect x=\"20\" y=\"256\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">rede física</text><text x=\"196\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">switches, roteadores, os enlaces para fora</text><rect x=\"20\" y=\"220\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">virtualização</text><text x=\"196\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um servidor físico cortado em muitas VMs</text><rect x=\"20\" y=\"184\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"199.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">rede virtual</text><text x=\"196\" y=\"199.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">endereços, sub-redes, regras de firewall</text><rect x=\"20\" y=\"148\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sistema operacional</text><text x=\"196\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">kernel, pacotes, usuários, patches</text><rect x=\"20\" y=\"112\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">runtime</text><text x=\"196\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a linguagem, o interpretador, o servidor web</text><rect x=\"20\" y=\"76\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">aplicação</text><text x=\"196\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o código e os pacotes que ele puxa</text><rect x=\"20\" y=\"40\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">dados</text><text x=\"196\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pedidos, clientes, arquivos: o que o código guarda</text><rect x=\"566\" y=\"40\" width=\"134\" height=\"318\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"633\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">identidade e acesso</text><text x=\"633\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem pode mexer</text><text x=\"633\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em cada camada</text></svg>", "caption": "Nove camadas e uma coluna ao lado delas. Todo modelo de hospedagem desta página roda a mesma pilha; o que muda de um para outro é quem opera cada camada, e o resto da aula desenha isso como uma linha.", "same": ["hardware", "runtime"]}
```

Leia de baixo para cima.

As **instalações** são o prédio: o contrato de energia, os geradores para quando ela falta, a
refrigeração que leva o calor embora e os vigias na porta. O hardware são os servidores, os discos e
os cabos entre eles, e a tarefa dele é trocar o que quebra, o que num prédio com milhares de discos
acontece todo dia. A rede física são os switches e roteadores que ligam esses servidores entre si e
os enlaces que levam o tráfego para a internet.

A **virtualização** é o software que corta um servidor físico em muitas máquinas virtuais, cada uma com
a sua parte de processador e de memória, cada uma sem enxergar as outras. É a camada que torna possível
o agrupamento de recursos, e tem patches próprios. Em cima dela fica a **rede virtual**: os endereços
que as suas máquinas têm, como elas se agrupam em sub-redes, e as regras de firewall que decidem o que
pode chegar a elas. É uma rede em todos os sentidos que o curso `networks` ensinou, desenhada por
configuração em vez de cabos, e é o assunto da aula 6.

O **sistema operacional** é onde mora a maior parte do trabalho conhecido: instalar patches de
segurança, criar usuários, vigiar o disco enchendo, ler os logs. O runtime é o que o seu código
precisa para rodar: a linguagem e o interpretador dela, o Python 3.11 por exemplo, e o servidor web na
frente dele. Uma versão de linguagem chega ao fim do suporte numa data publicada, e depois dessa data as
correções de segurança param.

A **aplicação** é o código que alguém escreveu para este negócio, junto com os pacotes que ele importa,
e os dados são o que esse código guarda: os pedidos, os clientes, as fotos dos produtos. Os dados
são a única camada que não se compra de novo. Todas as outras podem ser refeitas com uma compra ou um
download; os pedidos do mês passado só existem onde você os guardou.

Ao lado das nove, a **identidade e o acesso** decidem quem pode mexer em cada uma: as contas, as senhas,
as chaves e os papéis, no provedor e dentro da sua própria aplicação. Aparece desenhada como uma coluna,
e não como camada, porque atravessa a pilha. Uma pessoa com o acesso errado à rede virtual pode expor o
banco de dados; uma pessoa com o acesso errado à aplicação pode apagar os pedidos. A aula 7 trata disso.

## As tarefas não vão embora

O resto desta aula se apoia numa coisa que o desenho mostra. **Toda camada tem tarefas, e ir para
a nuvem não elimina nenhuma delas.** Os discos continuam quebrando, o sistema operacional continua
precisando de patches, os dados continuam precisando de backup. O que muda é quem faz cada tarefa, e se
você consegue vê-la sendo feita.

Isso dá à pergunta da seção anterior uma forma precisa. Para qualquer serviço que você alugue, dá para
subir por esta pilha e perguntar de cada camada: isto ainda é meu? As próximas três seções fazem isso
com IaaS, PaaS e SaaS, e a resposta é sempre um corte numa altura: **o provedor opera tudo abaixo dele,
e você opera tudo acima**.
