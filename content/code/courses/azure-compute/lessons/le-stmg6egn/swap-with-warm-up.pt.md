---
title: O swap, e o aquecimento antes da troca
version: 1
---

Um swap é fácil de imaginar como uma cópia: os arquivos do staging são copiados por cima da
produção, e a produção reinicia com eles. Se fosse assim, todo swap seria um reinício da produção,
e os clientes no meio de um pedido o veriam. **Um swap prepara o slot de staging até ele poder
servir como produção, e então troca o roteamento dos dois slots.** A produção continua respondendo
com a versão antiga o tempo todo, e a documentação diz a consequência: o slot de destino continua no
ar enquanto a origem é preparada e aquecida, tenha o swap sucesso ou não. O swap em si é lido aqui
da documentação da Microsoft, porque precisa de uma assinatura. O que é praticado é a razão do passo
mais longo dele: uma versão da loja que demora para ficar pronta, rodada no laptop e consultada até
ficar.

## Cinco passos, todos menos um no staging

Num swap do `staging` para `production`, o App Service faz isto:

1. Aplica as configurações fixas da produção a toda instância do staging, com as de implantação
   contínua e de autenticação, se houver. Isso é uma mudança de configuração, e reinicia toda
   instância do staging. O código novo passa a rodar com as configurações que terá na produção, no
   endereço do staging;
2. Espera toda instância terminar de reiniciar. Se alguma instância falha, o swap desfaz as
   mudanças no staging e para;
3. Aquece cada instância: uma requisição a cada uma, e uma instância que responde conta como
   aquecida;
4. Troca o roteamento quando toda instância está aquecida. A partir deste momento o endereço da
   produção alcança o que era o staging, e os slots trocaram de conteúdo;
5. Faz o mesmo do outro lado: o conteúdo antigo da produção, agora no staging, recebe as
   configurações fixas do staging e reinicia.

Com o cache local ligado há mais uma requisição e mais um reinício entre o segundo e o terceiro; a
documentação diz que o cache local não é suportado em apps em contêiner, então a loja nunca o tem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 375\" role=\"img\" aria-label=\"Uma linha do tempo da esquerda para a direita com duas faixas. A faixa da produção mostra shop:1.0 respondendo a toda requisição até a troca do roteamento, e shop:1.1 respondendo depois dela. A faixa do staging mostra os passos: um, as configurações fixas da produção vão para o staging e toda instância do staging reinicia, e o swap com prévia para aqui; dois, o swap espera toda instância reiniciar, com pings de partida até um status da lista; três, uma requisição de aquecimento em cada instância, e um status fora da lista para o swap; quatro, o roteamento é trocado e os dois slots trocam de conteúdo; cinco, o conteúdo antigo é reiniciado com as configurações do staging. Uma nota: voltar atrás é o mesmo swap de novo.\"><defs><marker id=\"l18w-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18w-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">produção</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">staging</text><rect x=\"110\" y=\"25\" width=\"410\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop:1.0 responde a toda requisição</text><rect x=\"520\" y=\"25\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop:1.1 responde</text><rect x=\"110\" y=\"75\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">1  as configurações fixas da produção vão para o staging</text><text x=\"142\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toda instância do staging reinicia</text><rect x=\"110\" y=\"135\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">2  espera toda instância reiniciar</text><text x=\"142\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pings de partida até um status da lista</text><rect x=\"110\" y=\"195\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">3  requisição de aquecimento em cada instância</text><text x=\"142\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um status fora da lista para o swap</text><rect x=\"110\" y=\"255\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">4  roteamento trocado</text><text x=\"142\" y=\"287\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois slots trocam de conteúdo</text><rect x=\"110\" y=\"315\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"331\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">5  conteúdo antigo reiniciado</text><text x=\"142\" y=\"347\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com as configurações do staging</text><path d=\"M310 121 L310 133\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M310 181 L310 193\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M310 241 L310 253\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M310 301 L310 313\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M520 25 L520 368\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M510 278 L518 278\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-amber)\"></path><text x=\"530\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o swap com prévia para aqui</text><path d=\"M528 98 L512 98\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"530\" y=\"350\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">voltar atrás: o mesmo swap de novo</text></svg>", "caption": "Tudo antes da troca acontece no slot de staging; a produção continua respondendo com a versão antiga até o roteamento mudar, e se algum passo falha ele não muda nunca.", "same": ["staging"]}
```

**O passo 3 é onde os padrões são generosos.** Sem aquecimento configurado, a requisição vai para a
raiz da aplicação, `/`, e a documentação diz o que conta: se uma instância devolve qualquer resposta
HTTP, ela é considerada aquecida. Qualquer resposta inclui um 503. O passo espera até 90 segundos
por requisição e tenta de novo até cinco vezes; só um estouro de tempo em toda tentativa para o
swap.

Duas configurações de app mudam isso. `WEBSITE_SWAP_WARMUP_PING_PATH` nomeia o caminho, e
`WEBSITE_SWAP_WARMUP_PING_STATUSES` lista os códigos de status que contam, separados por vírgulas.
**Um status fora da lista para o swap**, e a produção não é tocada, porque nada chegou a ela ainda.
A documentação também nomeia um elemento, `applicationInitialization`, para o mesmo trabalho; ele
mora num arquivo `Web.config`, que é IIS no Windows, e um contêiner Python não tem nenhum.

No Linux existe também uma espera anterior, e os reinícios do passo 2 passam por ela, porque
reiniciar um contêiner é dar partida em um. Toda vez que o App Service dá partida num contêiner, ele
pede `WEBSITE_WARMUP_PATH`, por padrão `/robots933456.txt`, de novo e de novo até ele responder, e só
então manda tráfego. Aqui também **qualquer status conta, a não ser que `WEBSITE_WARMUP_STATUSES`
liste alguns**, e com uma lista ele continua pedindo até chegar um da lista ou até acabar
`WEBSITES_CONTAINER_START_TIME_LIMIT`, 230 segundos por padrão. O arquivo da loja põe os dois pares
em `/healthz` e `200`, nos dois slots, para que a partida espere a loja ficar pronta e o swap confira
mais uma vez antes de trocar.

## Uma loja que demora a ficar pronta

A loja da lição 7 fica pronta no momento em que escuta. Uma API de pedidos de verdade raramente
fica: ela abre as conexões com o banco, carrega o catálogo e a tabela de preços, enche um cache.
Para ver o que os padrões fariam com isso, aqui está uma versão que escuta na hora e responde 503
até passar um número de segundos. Ela importa o `app.py` da lição 7 e não muda nada nele. Salve ao
lado dele como `~/azure/shop/warm.py`:

```schooling-example
{"language": "python", "file": "warm.py", "parts": [{"code": "# warm.py\nimport json\nimport os\nimport threading\nimport time\nfrom http.server import ThreadingHTTPServer\n\nimport app\n\nWARMUP = float(os.environ.get('SHOP_WARMUP_SECONDS', '20'))\nREADY = threading.Event()\n\n", "note": "`import app` é o arquivo da lição 7, sem mudança, então o código da API de pedidos existe uma vez só. A duração do aquecimento vem de uma variável de ambiente, que no App Service é uma configuração de app. `READY` é uma marca que uma thread liga e toda thread de requisição lê, e `threading.Event` é o jeito seguro da biblioteca padrão de dividir uma."}, {"code": "\nclass WarmingShop(app.Shop):\n    def do_GET(self):\n        if not READY.is_set():\n            return self.answer(503, {'status': 'warming'})\n        super().do_GET()\n\n    def do_POST(self):\n        if not READY.is_set():\n            return self.answer(503, {'status': 'warming'})\n        super().do_POST()\n\n", "note": "Até a marca ser ligada, **toda requisição recebe um 503**, em qualquer caminho, incluindo `/healthz` e páginas que a loja não tem. Isso é um servidor escutando que não está pronto, que é exatamente o estado que uma checagem que aceita qualquer status não consegue distinguir de um pronto. Depois da marca, os handlers da lição 7 respondem como antes."}, {"code": "\ndef warm_up():\n    time.sleep(WARMUP)\n    READY.set()\n    print(json.dumps({'msg': 'ready', 'after_s': WARMUP}), flush=True)\n\n", "note": "O sleep faz as vezes do trabalho de verdade: abrir conexões com o banco, carregar o catálogo, encher um cache. Ele roda numa thread própria para que o servidor possa responder, com 503, enquanto isso acontece. A linha de log usa o formato JSON da loja, então o momento em que ela fica pronta está no log do contêiner."}, {"code": "\nif __name__ == '__main__':\n    threading.Thread(target=warm_up, daemon=True).start()\n    print(json.dumps({'msg': 'listening', 'port': app.PORT, 'version': app.VERSION,\n                      'warmup_s': WARMUP}), flush=True)\n    ThreadingHTTPServer(('0.0.0.0', app.PORT), WarmingShop).serve_forever()\n", "note": "O mesmo servidor da lição 7, na mesma porta, com a classe de handler nova. A thread de aquecimento começa primeiro e o servidor escuta na hora, então **escutar e estar pronto são dois momentos**, a alguns segundos um do outro, e o log tem uma linha para cada."}]}
```

E a imagem dela, `~/azure/shop/Dockerfile.warm`, que é a da lição 7 com o arquivo novo somado e a
versão posta em 1.1:

```dockerfile
# Dockerfile.warm
FROM python:3.12-slim
WORKDIR /app
COPY app.py warm.py ./
ENV PORT=8080 SHOP_VERSION=1.1
EXPOSE 8080
USER nobody
CMD ["python", "warm.py"]
```

Construa como `shop:1.1`, a tag que o slot de staging roda:

```sh
docker build --tag shop:1.1 --file shop/Dockerfile.warm shop
```

Depois rode com um aquecimento de seis segundos, passado como variável de ambiente, que é como uma
configuração de app chegaria. Pergunte uma vez por segundo por dois caminhos: o `/healthz` da loja,
e o caminho que o App Service pede por padrão.

```
ana@laptop:~/azure$ ls shop
Dockerfile.warm
app.py
warm.py
ana@laptop:~/azure$ docker run -d --name shop-warm -p 8088:8080 -e SHOP_WARMUP_SECONDS=6 shop:1.1 > /dev/null
ana@laptop:~/azure$ for i in $(seq 1 20); do h=$(curl -s -o /dev/null -w '%{http_code}' localhost:8088/healthz); r=$(curl -s -o /dev/null -w '%{http_code}' localhost:8088/robots933456.txt); echo "$i  /healthz $h  /robots933456.txt $r"; [ "$h" = 200 ] && break; sleep 1; done
1  /healthz 000  /robots933456.txt 000
2  /healthz 503  /robots933456.txt 503
3  /healthz 503  /robots933456.txt 503
4  /healthz 503  /robots933456.txt 503
5  /healthz 503  /robots933456.txt 503
6  /healthz 503  /robots933456.txt 503
7  /healthz 503  /robots933456.txt 503
8  /healthz 200  /robots933456.txt 404
ana@laptop:~/azure$ docker logs shop-warm | grep msg
{"msg": "listening", "port": 8080, "version": "1.1", "warmup_s": 6.0}
{"msg": "ready", "after_s": 6.0}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8088/version
{"version": "1.1", "host": "8b8c2663dde3", "up_s": 6.9}
```

**Isto é o Docker do laptop, não o App Service**, e o tempo é o do laptop. Leia como três estados. Na
primeira consulta nada respondeu, `000`: o contêiner ainda estava iniciando o Python. Da segunda à
sétima a loja estava escutando e não estava pronta, e respondeu 503 nos dois caminhos. Na oitava o
`/healthz` disse 200 e o caminho padrão disse 404, porque a loja não tem essa página. Uma checagem
de partida no caminho padrão sem lista de status teria dado a loja como pronta na segunda consulta,
seis segundos antes da hora, e o aquecimento de um swap em `/` teria feito o mesmo. Com `/healthz` e
`200`, a checagem de partida só dá a loja como pronta na oitava consulta, e o swap só troca um slot
que já responde 200.

A lista de status tem mais uma armadilha. A documentação separa os códigos com vírgulas:

```
ana@laptop:~/azure$ sed "s/WARMUP_PING_STATUSES', value: '200'/WARMUP_PING_STATUSES', value: '200;202'/" shop-web.bicep > statuses.bicep
ana@laptop:~/azure$ bicep build statuses.bicep
```

`200;202` compila, porque para o compilador é uma string como outra qualquer. O que o App Service
faz com uma lista que não consegue separar não está documentado; este curso não descobriria sem uma
assinatura, e um arquivo não é o lugar para descobrir.

## Prévia, auto swap, e voltar atrás

**O swap com prévia** para depois do passo 1 e espera. O staging fica então rodando o código novo com
as configurações da produção, no endereço dele, e alguém pode testar exatamente o que os clientes vão
receber antes de qualquer coisa chegar a eles. A CLI chama as três metades de `preview`, `swap` e
`reset`:

```
ana@laptop:~/azure$ az webapp deployment slot swap --help | sed -n '/^Arguments/,/^$/p'
Arguments
    --slot -s   [Required] : The name of the slot.
    --action               : Swap types. use 'preview' to apply target slot's settings on the source
                             slot first; use 'swap' to complete it; use 'reset' to reset the swap.
                             Allowed values: preview, reset, swap.  Default: swap.
    --preserve-vnet        : Preserve Virtual Network to the slot during swap, default to 'true'.
                             Allowed values: false, true.
    --target-slot          : Target slot to swap, default to 'production'.
```

`--target-slot` tem `production` como padrão, e a documentação pede que a produção seja sempre o
destino, para que a preparação aconteça sempre do outro lado. A prévia não está disponível com a
autenticação ligada em algum dos slots. Sem uma conta, a primeira metade responde como todo comando
aqui:

```
ana@laptop:~/azure$ az webapp deployment slot swap --resource-group shop --name shop-sp --slot staging --action preview
ERROR: Please run 'az login' to setup account.
```

**O auto swap** faz o swap de um slot para a produção toda vez que algo é implantado nele. A
documentação é curta sobre onde: ele não é suportado em web apps no Linux nem em Web App for
Containers, que é a loja nos dois casos. A configuração é uma propriedade de `siteConfig`, e o
compilador não tem como saber em que tipo de app ela está:

```
ana@laptop:~/azure$ sed "0,/alwaysOn: true/! s/alwaysOn: true/alwaysOn: true\n      autoSwapSlotName: 'production'/" shop-web.bicep > autoswap.bicep
ana@laptop:~/azure$ grep -n autoSwapSlotName autoswap.bicep
58:      autoSwapSlotName: 'production'
ana@laptop:~/azure$ bicep build autoswap.bicep
```

**Voltar atrás é o mesmo swap de novo.** Depois de um swap, o staging guarda a versão que a produção
rodava um minuto antes, já aquecida, então o swap dos mesmos dois slots a devolve, com os mesmos
cinco passos e os mesmos zero reinícios da produção. Isso só vale enquanto ninguém implantou no
staging desde então. E um custo cai na versão antiga, não na nova: no passo 5 as antigas instâncias
de produção são recicladas, e uma operação longa nelas é abandonada. Um pedido escrito pela metade
quando o swap terminou é problema do código da loja sobreviver.

## Depois da troca: o health check

O aquecimento protege o momento do swap. `healthCheckPath` protege cada minuto depois dele. Com ele
definido, o App Service pede esse caminho a toda instância uma vez por minuto, e uma instância que
responde qualquer coisa fora de 200 a 299 depois de dez requisições sai do balanceador de carga.
`WEBSITE_HEALTHCHECK_MAXPINGFAILURES` move os dez para qualquer valor de 2 a 10. Uma instância
retirada continua sendo consultada e volta quando responde bem; uma que fica doente por uma hora é
substituída, no máximo uma por hora e três por dia por plano. **Não mais que metade das instâncias
sai por padrão**, então um plano de quatro com três falhando mantém duas servindo, uma saudável e uma
não; a razão da documentação é não sobrecarregar as saudáveis. Com toda instância falhando, nenhuma
sai.

Duas consequências para a loja. A checagem precisa de pelo menos duas instâncias para ter para onde
mandar o tráfego, o que o `capacity: 2` do plano dá. E o caminho deve responder 200 só quando a
instância consegue servir de verdade, que é o que o `warm.py` faz com `/healthz`: um endpoint, lido
pela partida, pelo swap e pela checagem. Mudar a configuração do health check reinicia o app, então
a documentação sugere fazer a mudança num slot e trazê-la com um swap.
