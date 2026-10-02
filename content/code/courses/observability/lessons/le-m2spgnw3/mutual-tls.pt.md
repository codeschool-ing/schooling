---
title: TLS mútuo, e a requisição recusada
version: 1
---

O `connection_security_policy="mutual_tls"` acima quer dizer que o proxy do cliente e o proxy do servidor
se autenticaram com certificados e criptografaram a conexão. Nenhuma das aplicações tem uma linha de
código de TLS. O `istiod` emite para cada carga um certificado da sua identidade, o nome SPIFFE em
`source_principal`, e o renova.

Por padrão o Istio é **permissivo**: aceita TLS mútuo de proxies e texto puro de qualquer outra coisa,
para que um mesh possa ser adotado um serviço por vez. Um pod fora do mesh mostra isso:

```
ana@obs:~/shop$ kubectl create namespace outside && kubectl -n outside run probe --image=shop:1.4.0 --image-pull-policy=Never --restart=Never --command -- sleep 600
namespace/outside created
pod/probe created
ana@obs:~/shop$ kubectl -n outside exec probe -- python -c "import urllib.request; print(urllib.request.urlopen('http://server.shop-mesh/', timeout=3).status)"
200
```

**200.** O pod no namespace `outside` não tem proxy nem certificado, e foi respondido. Uma política torna
o namespace estrito:

```
ana@obs:~/shop$ cat k8s/strict.yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata: {name: default, namespace: shop-mesh}
spec:
  mtls: {mode: STRICT}
ana@obs:~/shop$ kubectl apply -f k8s/strict.yaml
peerauthentication.security.istio.io/default created
```

A mesma requisição de novo:

```
ana@obs:~/shop$ kubectl -n outside exec probe -- python -c "import urllib.request; print(urllib.request.urlopen('http://server.shop-mesh/', timeout=3).status)" 2>&1 | tail -2
ConnectionResetError: [Errno 104] Connection reset by peer
command terminated with exit code 1
```

A conexão foi reiniciada: o proxy do servidor pediu um certificado que a sonda não tinha, e fechou a conexão antes de qualquer HTTP ser trocado. E o cliente dentro do mesh, que vinha fazendo requisições ao servidor duas vezes por segundo o
tempo todo, não registrou nada nos últimos vinte segundos:

```
ana@obs:~/shop$ kubectl -n shop-mesh logs deploy/client -c client --since=20s | wc -l
0
```

**Zero linhas: nenhum erro.** Ele nem percebeu a mudança, porque o proxy dele já falava TLS mútuo.

Duas observações de observabilidade. **A identidade vira um rótulo**: `source_principal` diz qual carga
fez uma requisição, verificada por um certificado em vez de declarada num cabeçalho, que é o que uma
auditoria de quem chamou um serviço de pagamentos quer. E **uma conexão recusada não tem status HTTP**: a
requisição do pod de fora nunca chegou a ser uma requisição, então ela não aparece em nenhum contador de
requisições, só como uma conexão reiniciada nas estatísticas do proxy e no log de erro do próprio
chamador.
