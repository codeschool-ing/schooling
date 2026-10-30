---
title: "O grupo de contêineres, que é o que o Azure roda"
version: 1
---

O nome sugere que o Azure roda um contêiner para você, e os comandos parecem concordar: `az
container create` recebe uma imagem e um tamanho. **O que ele cria é um grupo de contêineres: um ou
mais contêineres agendados juntos num host, compartilhando um ciclo de vida, uma rede local e um
conjunto de volumes.** O grupo é o recurso que o Azure nomeia, cobra, inicia, para e apaga. Um grupo
com um contêiner só é o caso comum, e continua sendo um grupo, então cada configuração desta lição
pertence ao grupo ou a um dos contêineres dele, e faz diferença qual.

Se você fez o curso `kubernetes`, já viu a ideia com outro nome. A documentação da Microsoft
compara um grupo de contêineres a um pod, e a comparação se sustenta: vários processos que vivem e
morrem como uma unidade, numa máquina, conversando por `localhost`. O que o Container Instances não
dá é o resto do Kubernetes. Não há cluster em volta do grupo, nenhum controlador mantendo um número
de cópias e nenhum serviço na frente delas. Essa ausência é o assunto da seção 05.

## O que os contêineres de um grupo compartilham

Quatro coisas, e cada uma tem uma consequência que você vai encontrar nesta lição.

**O host.** Os contêineres de um grupo são colocados na mesma máquina, que é da Microsoft, e você
nunca a vê. A documentação da Microsoft diz que um contêiner no Container Instances fica tão isolado
quanto ficaria numa máquina virtual, então o grupo de um estranho no mesmo hardware fica tão longe
do seu quanto outra máquina virtual ficaria.

**O ciclo de vida.** O grupo inicia e para por inteiro. Reiniciá-lo reinicia todos os contêineres
dele, e atualizá-lo também: não dá para reiniciar ou atualizar sozinho um contêiner de um grupo com
vários. A cobrança também segue o grupo. O FAQ de preços da Microsoft diz que o medidor corre desde
o momento em que a primeira imagem começa a ser baixada até o grupo parar, e continua correndo
enquanto qualquer contêiner do grupo ainda estiver rodando.

**A rede local.** Os contêineres de um grupo se alcançam por `localhost`, em qualquer porta, esteja
ela aberta para fora ou não. A próxima seção mostra o mesmo arranjo com o Docker, no seu laptop.

**Os volumes.** Um grupo declara volumes, e cada contêiner monta os que nomeia, num caminho que ele
mesmo escolhe. Existem quatro tipos: um compartilhamento do Azure Files, que a lição 3 apresentou e
que sobrevive ao grupo; um secreto, que entrega aos contêineres valores sensíveis como arquivos
somente leitura, guardados em memória e nunca gravados em disco; um diretório vazio, espaço de
rascunho que os contêineres compartilham, que sobrevive à queda de um contêiner e some quando o
grupo para; e um repositório Git clonado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"Um grupo de contêineres chamado shop, desenhado como uma borda tracejada: um host e um ciclo de vida. Acima dele, um endereço IP público e um rótulo DNS, shop-sp.brazilsouth.azurecontainer.io, porta 8080, chegando ao contêiner shop. Dentro, dois contêineres: shop, rodando python app.py na porta 8080 e pedindo 1 CPU e 1,5 GB, e um sidecar que chama /healthz a cada minuto e pede 0,5 CPU e 0,5 GB. Os dois se alcançam por localhost. Embaixo, um volume, um compartilhamento do Azure Files, montado nos contêineres que o nomeiam. O Azure aloca ao grupo a soma dos pedidos, 1,5 CPU e 2 GB.\"><rect x=\"32\" y=\"12\" width=\"290\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um endereço IP público e um rótulo DNS</text><text x=\"177\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp.brazilsouth.azurecontainer.io</text><rect x=\"12\" y=\"78\" width=\"696\" height=\"228\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"694\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">grupo de contêineres shop: um host, um ciclo de vida</text><line x1=\"177\" y1=\"58\" x2=\"177\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><path d=\"M171 102 L177 112 L183 102 Z\" fill=\"var(--amber)\"></path><text x=\"188\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">porta 8080, aberta nos dois</text><rect x=\"32\" y=\"112\" width=\"290\" height=\"104\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">shop</text><text x=\"177\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">python app.py  :8080</text><text x=\"177\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pede 1 CPU, 1,5 GB</text><rect x=\"398\" y=\"112\" width=\"290\" height=\"104\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">sidecar</text><text x=\"543\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chama /healthz a cada minuto</text><text x=\"543\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pede 0,5 CPU, 0,5 GB</text><line x1=\"322\" y1=\"172\" x2=\"398\" y2=\"172\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">localhost</text><rect x=\"32\" y=\"240\" width=\"656\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">volume: um compartilhamento do Azure Files, montado nos contêineres que o nomeiam</text><line x1=\"177\" y1=\"216\" x2=\"177\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></line><line x1=\"543\" y1=\"216\" x2=\"543\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></line><text x=\"708\" y=\"322\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o Azure aloca ao grupo a soma: 1,5 CPU e 2 GB</text></svg>", "caption": "O que um grupo de contêineres compartilha. Os contêineres ficam num só host, iniciam e param juntos, alcançam um ao outro por localhost e montam os mesmos volumes; quem está fora vê um endereço só. O tamanho do grupo é a soma do que os contêineres pedem.", "same": ["shop", "sidecar"]}
```

Os recursos se somam do mesmo jeito. **Um grupo recebe a soma do que os contêineres dele pedem**,
então um grupo cujos dois contêineres pedem 1 CPU e 0,5 CPU é um grupo de 1,5 CPU, e é cobrado como
um só. A seção 04 trata desses pedidos.

Dois limites de forma valem ser conhecidos antes de projetar em cima disso. Grupos com vários
contêineres rodam **só contêineres Linux**: um grupo Windows tem exatamente um contêiner. E um grupo
tem no máximo 60 contêineres e 20 volumes, limites fixos que nenhum pedido ao suporte aumenta.

## O sidecar

Um segundo contêiner num grupo costuma estar lá para ajudar o primeiro, e o padrão tem nome:
**sidecar**. Os exemplos da Microsoft são os de sempre. Um contêiner que puxa o conteúdo mais
recente do controle de versão ao lado do que o serve. Um contêiner de logs que recolhe o que a
aplicação escreve e manda para um armazenamento de longo prazo. Um contêiner de monitoramento que
chama a aplicação de tempos em tempos e dispara um alerta quando ela para de responder.

Para a loja, o último é o que faz sentido hoje: um contêiner pequeno ao lado do `shop` que pergunta
`http://localhost:8080/healthz` uma vez por minuto. Ele não precisa de endereço próprio nem de porta
aberta para ninguém, porque alcança a loja onde a loja escuta. **O preço é que os dois são uma
unidade**: se o sidecar for atualizado, a loja reinicia junto. A lição 9 volta aos sidecars quando
o Dapr roda como um, ao lado da loja.

## Como o grupo é alcançado

Um grupo é alcançável de um de dois jeitos, e **é um ou o outro**.

**Um endereço público.** O grupo recebe um endereço IP na internet e, se você pedir, um rótulo DNS.
O rótulo `shop-sp` em São Paulo vira o nome `shop-sp.brazilsouth.azurecontainer.io`, que é o
*rótulo*, depois a *região*, depois `azurecontainer.io`. Uma porta precisa ser aberta duas vezes
para ser alcançável: no endereço do grupo e no contêiner que escuta nela. Um endereço público leva
no máximo cinco portas.

**O endereço não é seu para guardar.** A documentação da Microsoft diz que o endereço IP de um grupo
pode mudar quando o grupo reinicia, e desaconselha anotá-lo em qualquer lugar. O rótulo DNS é a
metade estável, e é ele que qualquer coisa de fora deve chamar. Um endereço público fixo só é
possível pondo na frente alguma coisa que tenha um, como um Application Gateway, que a lição 22 do
`azure-foundations` apresentou.

**Um endereço privado, numa rede virtual.** O grupo é implantado numa sub-rede de uma das suas redes
virtuais, da lição 16 do `azure-foundations`, e é alcançável pela rede e pelo que estiver ligado a
ela, inclusive um escritório por VPN. Três regras vêm junto. A sub-rede precisa ser **delegada** ao
Container Instances e passa a conter grupos de contêineres e mais nada. Um grupo numa rede virtual
não tem **nem endereço público nem rótulo DNS**. E ele chega à internet só por um **NAT gateway**,
que a documentação da Microsoft chama de única saída suportada. A Microsoft também pede uma
sub-rede de pelo menos `/24`, porque as menores enchem: os endereços tomados por grupos apagados
não são devolvidos rápido o bastante para serem reaproveitados.

A linha de comando conhece as duas primeiras regras e recusa antes de perguntar qualquer coisa ao
Azure. Aqui estão duas tentativas de pôr a loja numa rede virtual e dar a ela uma cara pública ao
mesmo tempo:

```
ana@laptop:~/azure$ az container create --resource-group shop --name shop --image shopregistry.azurecr.io/shop:1.0 --ports 8080 --vnet shop-vnet --subnet aci --dns-name-label shop-sp
ERROR: Can not use "--subnet" or "--vnet" with "--dns-name-label".
ana@laptop:~/azure$ az container create --resource-group shop --name shop --image shopregistry.azurecr.io/shop:1.0 --ports 8080 --vnet shop-vnet --subnet aci --ip-address Public
ERROR: Can not use "--subnet" or "--vnet" with IP address type "Public".
```

As duas recusas vêm das verificações que a própria CLI faz dos argumentos, por isso aparecem sem
assinatura. A primeira é o rótulo DNS, a segunda o tipo de endereço público, e a ordem das palavras
importa menos do que o que elas dizem: um grupo numa sub-rede é privado, por qualquer caminho que
você tente dizer o contrário.

**Qual escolher decorre de quem chama a loja.** Os clientes estão na internet, então a API de
pedidos quer um endereço público, e a seção 05 pergunta se o Container Instances é mesmo o lugar
dela. Um job que lê o banco de dados da loja e escreve um relatório não tem quem o chame, e cabe na
rede, ao lado do banco, com um endereço privado e uma rota de saída pelo NAT gateway.
