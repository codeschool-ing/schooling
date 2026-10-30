---
title: Configurações de entrada e de saída
version: 1
---

Um serviço com caminho para a VPC ainda tem duas perguntas separadas a responder, e as equipes as
misturam. **Entrada (ingress) é quem pode mandar requisições ao serviço. Saída (egress) é para onde
vão as conexões que o próprio serviço abre.** Elas ficam em lugares diferentes, falham de jeitos
diferentes, e mudar uma nunca muda a outra.

## Entrada: três valores, no serviço

A entrada pertence ao serviço como um todo, não a uma revisão. O provider lista os valores que
aceita, e o jeito mais rápido de vê-los é escrever um que ele não aceita:

```
ana@laptop:~/gcp/run-vpc$ sed -i 's/INGRESS_TRAFFIC_ALL/INTERNAL/' main.tf
ana@laptop:~/gcp/run-vpc$ terraform validate -no-color

Error: expected ingress to be one of ["INGRESS_TRAFFIC_ALL" "INGRESS_TRAFFIC_INTERNAL_ONLY" "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" ""], got INTERNAL

  with google_cloud_run_v2_service.orders,
  on main.tf line 19, in resource "google_cloud_run_v2_service" "orders":
  19:   ingress  = "INTERNAL"
```

Os três que significam algo:

| valor | quem alcança o serviço |
|---|---|
| `INGRESS_TRAFFIC_ALL` | qualquer um na internet, pela URL do próprio serviço |
| `INGRESS_TRAFFIC_INTERNAL_ONLY` | só o tráfego de dentro das suas redes VPC e de alguns serviços do Google |
| `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` | o tráfego interno, mais um Application Load Balancer externo que você põe na frente |

**Entrada é uma verificação de rede, não de identidade.** Um serviço com `INGRESS_TRAFFIC_ALL`
ainda pode recusar todo chamador sem permissão de invocá-lo; isso é IAM, o papel
`roles/run.invoker`, e o `gcp-foundations` trata de como ele é concedido. As duas se combinam: o
serviço orders só precisa ser chamado pelo front-end web e pelo worker, então deve aceitar só
tráfego interno e exigir também uma identidade de invocador.

A entrada também tem uma armadilha que vale uma frase. O tráfego de outro serviço do Cloud Run só
conta como interno se sair desse serviço **pela VPC**. Um chamador sem saída para a VPC chega ao
serviço orders pela rede do Google, que `INGRESS_TRAFFIC_INTERNAL_ONLY` recusa. Essa é a surpresa
mais comum depois de fechar um serviço.

## Saída: dois valores, na revisão

A saída pertence ao bloco `vpc_access`, e o provider aceita dois valores:

```
ana@laptop:~/gcp/run-vpc$ sed -i 's/PRIVATE_RANGES_ONLY/PRIVATE_ONLY/' main.tf
ana@laptop:~/gcp/run-vpc$ terraform validate -no-color

Error: expected template.0.vpc_access.0.egress to be one of ["ALL_TRAFFIC" "PRIVATE_RANGES_ONLY" ""], got PRIVATE_ONLY

  with google_cloud_run_v2_service.orders,
  on main.tf line 31, in resource "google_cloud_run_v2_service" "orders":
  31:       egress = "PRIVATE_ONLY"
```

- **`PRIVATE_RANGES_ONLY`** manda para a VPC o tráfego de faixas de endereço privadas, e todo o
  resto, incluindo a internet pública e as APIs públicas do Google, sai como sairia sem VPC.
- **`ALL_TRAFFIC`** manda toda conexão de saída para a VPC. Dali ela segue as rotas da VPC, o que
  quer dizer que a internet só é alcançável se a VPC tiver uma saída, normalmente o Cloud NAT.

O segundo existe por uma exigência recorrente: **um endereço de saída fixo.** A API de um parceiro
que só admite endereços IP conhecidos não pode ser chamada dos endereços compartilhados que o Cloud
Run usa por padrão. Com `ALL_TRAFFIC` e um gateway Cloud NAT segurando um endereço reservado, toda
requisição que o serviço faz sai desse endereço, e o parceiro pode admiti-lo. O preço são as
cobranças do próprio gateway NAT e mais um componente no caminho, então ele é escolhido pela
exigência, nunca como padrão.

## Montando a loja

| serviço | entrada | saída |
|---|---|---|
| `web` | `INGRESS_TRAFFIC_ALL`, público | direta, `PRIVATE_RANGES_ONLY`, para chamar `orders` |
| `orders` | `INGRESS_TRAFFIC_INTERNAL_ONLY` | direta, `PRIVATE_RANGES_ONLY` |
| um serviço que chama o parceiro de pagamento | só interna | direta, `ALL_TRAFFIC` pelo Cloud NAT |

O front-end não tem banco privado próprio, e mesmo assim ganha saída direta: as chamadas dele para
`orders` precisam sair pela VPC para contar como internas, que é a armadilha acima. Com
`PRIVATE_RANGES_ONLY`, isso não muda mais nada no jeito como `web` alcança a internet.
