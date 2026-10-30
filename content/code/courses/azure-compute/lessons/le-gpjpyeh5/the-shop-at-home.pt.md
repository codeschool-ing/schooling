---
title: "A loja, em casa e depois escrita para o Azure"
version: 1
---

A API de pedidos da loja é um programa Python de menos de cinquenta linhas, numa imagem própria, e
a partir desta lição ela é a carga de trabalho do curso. **O Container Instances nesta lição, o
Container Apps na lição 8, o AKS na lição 11 e o App Service na lição 18 rodam todos esta mesma
imagem**, então vale saber o que ela faz antes que qualquer um deles a receba. Esta seção a roda
com o Docker, no seu laptop, e depois descreve o mesmo contêiner ao Container Instances no arquivo
que o Azure lê. A primeira metade é praticada por inteiro. A segunda termina onde uma assinatura
começaria.

## O programa

Ele não usa nada fora da biblioteca padrão do Python, então a imagem não precisa de nada do PyPI.
Crie um diretório para ele:

```sh
mkdir -p ~/azure/shop
```

e salve isto como `~/azure/shop/app.py`. O botão de copiar leva o arquivo inteiro, sem as notas:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport json\nimport os\nimport socket\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\n", "note": "A biblioteca padrão e mais nada, então a imagem não precisa de nada do PyPI e é construída igual em qualquer lugar. O `ThreadingHTTPServer` atende cada requisição numa thread própria, para que um cliente lento não segure o próximo."}, {"code": "VERSION = os.environ.get('SHOP_VERSION', '1.0')\nPORT = int(os.environ.get('PORT', '8080'))\nSTARTED = time.time()\nORDERS = []\n\n\n", "note": "Tudo o que muda de um lugar para outro vem do ambiente: a versão que ele informa e a porta em que escuta. A imagem fica igual e as configurações mudam em volta dela. `ORDERS` é uma lista em memória, de propósito: some sempre que o processo para, e a seção 04 mostra isso acontecer."}, {"code": "class Shop(BaseHTTPRequestHandler):\n    def answer(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header('Content-Type', 'application/json')\n        self.send_header('Content-Length', str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n", "note": "Toda resposta sai do mesmo jeito, em JSON e com o tamanho declarado, para que o `curl` e a verificação de saúde de um balanceador a leiam igual."}, {"code": "    def do_GET(self):\n        if self.path == '/healthz':\n            self.answer(200, {'status': 'ok'})\n        elif self.path == '/version':\n            self.answer(200, {'version': VERSION, 'host': socket.gethostname(),\n                              'up_s': round(time.time() - STARTED, 1)})\n        elif self.path == '/orders':\n            self.answer(200, ORDERS)\n        else:\n            self.answer(404, {'error': 'no such page'})\n\n", "note": "Três páginas. `/healthz` é para uma máquina perguntar se o processo está vivo. `/version` diz qual cópia respondeu, pelo nome do host, e há quantos segundos ela está no ar, coisa de que as lições 8 e 18 dependem quando duas versões rodam ao mesmo tempo. `/orders` lista o que foi enviado."}, {"code": "    def do_POST(self):\n        if self.path != '/orders':\n            return self.answer(404, {'error': 'no such page'})\n        size = int(self.headers.get('Content-Length', 0))\n        order = json.loads(self.rfile.read(size) or b'{}')\n        order['id'] = len(ORDERS) + 1\n        ORDERS.append(order)\n        self.answer(201, order)\n\n", "note": "Um pedido novo é o JSON que chegou, com o próximo número como `id`, respondido com `201 Created`."}, {"code": "    def log_message(self, fmt, *args):\n        print(json.dumps({'path': self.path, 'status': args[1], 'version': VERSION}), flush=True)\n\n\n", "note": "A biblioteca padrão registra cada requisição na saída de erro, num formato próprio. Isto troca o registro por uma linha JSON na saída padrão, porque a saída padrão e a de erro são tudo o que uma plataforma de contêineres coleta, e `flush=True` manda cada linha na hora, em vez de esperar um buffer encher."}, {"code": "if __name__ == '__main__':\n    print(json.dumps({'msg': 'listening', 'port': PORT, 'version': VERSION}), flush=True)\n    ThreadingHTTPServer(('0.0.0.0', PORT), Shop).serve_forever()\n", "note": "Uma linha para dizer que começou, e então atender até ser parado. `0.0.0.0` quer dizer todas as interfaces: um servidor escutando em `127.0.0.1` dentro de um contêiner não pode ser alcançado de fora, seja qual for a porta publicada."}]}
```

E isto como `~/azure/shop/Dockerfile`:

```dockerfile
# Dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
ENV PORT=8080
EXPOSE 8080
USER nobody
CMD ["python", "app.py"]
```

Sete linhas, e duas delas são decisões. `ENV PORT=8080` dá ao programa a porta padrão, e quem
iniciar o contêiner pode definir `PORT` com outro valor sem precisar de imagem nova. **`USER
nobody` quer dizer que o processo não roda como root**: uma falha no programa entrega a um atacante
uma conta que não é dona de nada. A seção 05 mostra o único lugar do Container Instances em que essa
escolha custa alguma coisa.

## Construída e rodando

O curso `docker` construiu imagens como esta. `--quiet` tira da tela o progresso da construção e
imprime só o id da imagem nova, que muda em cada máquina:

```
ana@laptop:~/azure$ ls shop
Dockerfile
app.py
ana@laptop:~/azure$ docker build --quiet --tag shop:1.0 shop | cut -c1-19
sha256:d19c8b927c16
ana@laptop:~/azure$ docker image ls shop:1.0 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
shop:1.0  178MB
```

178 MB, quase tudo Python e o Debian enxuto embaixo dele. Rodando, com a porta 8080 do contêiner
publicada na do laptop:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0 | cut -c1-12
fd5ab8c782d8
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/healthz
{"status": "ok"}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/version
{"version": "1.0", "host": "fd5ab8c782d8", "up_s": 0.7}
ana@laptop:~/azure$ curl -s -w '\n' -X POST localhost:8080/orders -d '{"item": "coffee", "qty": 2}'
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/orders
[{"item": "coffee", "qty": 2, "id": 1}]
ana@laptop:~/azure$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/nothing
404
```

As quatro páginas responderam como o `app.py` diz que deveriam. `/version` informa a versão vinda
do ambiente, o nome do host, que dentro de um contêiner é o id curto do contêiner, e os segundos
desde que o processo começou. O pedido voltou com um `id`, e `/orders` o lista. Uma página que não
existe dá 404. Cada requisição deixou uma linha de JSON no log, depois da linha que o programa
imprimiu ao começar:

```
ana@laptop:~/azure$ docker logs shop
{"msg": "listening", "port": 8080, "version": "1.0"}
{"path": "/healthz", "status": "200", "version": "1.0"}
{"path": "/version", "status": "200", "version": "1.0"}
{"path": "/orders", "status": "201", "version": "1.0"}
{"path": "/orders", "status": "200", "version": "1.0"}
{"path": "/nothing", "status": "404", "version": "1.0"}
```

**Esse log é a única janela para o programa, aqui e no Azure.** O Container Instances guarda o que
um contêiner escreve na saída padrão e na de erro, e `az container logs` lê de volta, como o `docker
logs` fez aqui. A seção 05 diz quão pouco disso é guardado.

## Um segundo contêiner, no mesmo localhost

A seção anterior disse que os contêineres de um grupo se alcançam por `localhost`. O Docker consegue
pôr dois contêineres nesse arranjo: `--network container:shop` inicia um contêiner dentro da rede
de outro que já existe, em vez de numa rede própria. A imagem da loja tem Python, então ela serve
de segundo contêiner, perguntando à loja pela saúde dela exatamente como um sidecar faria:

```
ana@laptop:~/azure$ docker run --rm --network container:shop shop:1.0 python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/healthz').read().decode())"
{"status": "ok"}
ana@laptop:~/azure$ docker run --rm shop:1.0 python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/healthz').read().decode())" 2>&1 | tail -n 1
urllib.error.URLError: <urlopen error [Errno 111] Connection refused>
```

A primeira chamada alcançou a loja em `localhost:8080`. O segundo contêiner, iniciado sem a flag,
tem um `localhost` só dele, sem nada escutando, e a conexão foi recusada. **Um grupo no Container
Instances é o primeiro arranjo**, e o Azure o monta para todos os contêineres do grupo, sem flag
nenhuma para lembrar.

Mais um fato sobre o contêiner rodando, de que a seção 05 precisa:

```
ana@laptop:~/azure$ docker exec shop id
uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)
```

## Escrita para o Azure

O Container Instances recebe um grupo de duas formas além das flags do `az container create`: um
arquivo YAML e um template do Resource Manager, escrito em Bicep ou em JSON. A Microsoft recomenda o
arquivo YAML quando o grupo é tudo o que você está implantando, e um template quando outros recursos
vêm junto, como uma conta de armazenamento para um compartilhamento de arquivos. Aqui está o grupo
da loja em YAML. Salve como `~/azure/shop-aci.yaml`:

```schooling-example
{"language": "yaml", "file": "shop-aci.yaml", "parts": [{"code": "# shop-aci.yaml\napiVersion: '2021-10-01'\nlocation: brazilsouth\nname: shop\ntype: Microsoft.ContainerInstance/containerGroups\n", "note": "O tipo do recurso e a versão da API, o mesmo par que a lição 1 viu num template. A Microsoft documenta o formato YAML para a versão `2021-10-01` da API. `name` é o nome do grupo, e é por ele que todo comando `az container` seguinte o chama."}, {"code": "properties:\n  osType: Linux\n  restartPolicy: Always\n", "note": "Duas configurações que são do grupo e não de um contêiner: o sistema operacional que todos os contêineres dele rodam, e a política de reinício, assunto da seção 04."}, {"code": "  containers:\n  - name: shop\n    properties:\n      image: shopregistry.azurecr.io/shop:1.0\n      environmentVariables:\n      - name: SHOP_VERSION\n        value: '1.0'\n", "note": "Os contêineres, uma lista de um. A imagem precisa estar num registro que o Azure alcance, e `shopregistry.azurecr.io` guarda o lugar do registro que a lição 10 cria. `'1.0'` vai entre aspas para que o YAML o mantenha como texto e não o leia como número."}, {"code": "      ports:\n      - port: 8080\n      resources:\n        requests:\n          cpu: 1\n          memoryInGB: 1.5\n", "note": "A porta em que o contêiner escuta e o que ele pede: uma CPU e 1,5 GB de memória. O pedido é o único tamanho que todo contêiner é obrigado a declarar."}, {"code": "  ipAddress:\n    type: Public\n    dnsNameLabel: shop-sp\n    ports:\n    - protocol: TCP\n      port: 8080\n", "note": "Como o grupo é alcançado: um endereço público, o rótulo DNS `shop-sp`, e a 8080 aberta no grupo e também no contêiner. Uma porta escrita só num dos dois lugares não é alcançável por nenhum."}]}
```

Cada linha dele é algo que você acabou de fazer à mão. A imagem é a que você construiu, quando
estiver num registro. `SHOP_VERSION` é o que `/version` informa. A porta 8080 é o que `-p 8080:8080`
publicou, e `shop-sp` é o nome que um cliente digita no lugar de `localhost`. A única configuração
que o Docker nunca pediu é o tamanho, e a seção 04 trata dele.

**A imagem que o Azure roda precisa ser construída para `amd64`.** O Container Instances roda só
imagens x64, e a documentação da Microsoft diz que uma imagem construída só para `arm64` pode não
iniciar. Num laptop Arm, o que inclui um Mac com Apple silicon, o `docker build` faz uma imagem
`arm64`, a não ser que receba outra ordem, com `--platform linux/amd64`. A lição 10 constrói e
envia a imagem que o Azure baixa.

Entregar o arquivo ao Azure é um comando, e ele encontra a mesma recusa que todo comando deste curso
que precisa de assinatura:

```
ana@laptop:~/azure$ az container create --resource-group shop --file shop-aci.yaml
ERROR: Please run 'az login' to setup account.
```

## Numa assinatura

O que vem a seguir não foi executado neste curso: precisa de uma assinatura. Com uma, o grupo vai
para um grupo de recursos, e os comandos abaixo o criam, perguntam o nome DNS completo dele e se ele
foi provisionado, leem o log, chamam o grupo por esse nome e o apagam, o que pede confirmação
antes. Um registro privado também exige que o grupo prove quem é ao baixar a imagem, com as
credenciais do registro ou, melhor, uma identidade gerenciada, da lição 8 do `azure-foundations`.

```sh
az group create --name shop --location brazilsouth
az container create --resource-group shop --file shop-aci.yaml
az container show --resource-group shop --name shop --query "{FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}" --output table
az container logs --resource-group shop --name shop
curl -s http://shop-sp.brazilsouth.azurecontainer.io:8080/version
az container delete --resource-group shop --name shop
```

O mesmo grupo sem arquivo é um único `az container create` com `--image`, `--cpu`, `--memory`,
`--ports 8080`, `--ip-address Public`, `--dns-name-label shop-sp` e `--environment-variables
SHOP_VERSION=1.0`. O arquivo é o que você guarda no Git, e `az container export` escreve um a partir
de um grupo que já existe. No seu laptop, o contêiner continua rodando; pare e remova antes da
próxima seção:

```sh
docker rm -f shop
```
