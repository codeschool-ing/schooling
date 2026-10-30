---
title: O ambiente flexível
version: 1
---

O ambiente padrão roda o seu código na sandbox do Google, nos runtimes que o Google oferece. **O
ambiente flexível roda o seu código num contêiner, em máquinas do Compute Engine que o App Engine
cria e gerencia por você.** Foi a resposta, anos atrás, a tudo que a sandbox não fazia: qualquer
linguagem, bibliotecas nativas, threads em segundo plano, escrita no disco local.

## O que muda no arquivo

O mesmo `app.yaml`, com uma linha a mais e outro formato de escalonamento:

```yaml
# storefront-flex/app.yaml
runtime: python
env: flex
entrypoint: gunicorn -b :$PORT main:app
runtime_config:
  operating_system: ubuntu22
  runtime_version: "3.12"
resources:
  cpu: 1
  memory_gb: 1
automatic_scaling:
  min_num_instances: 1
  max_num_instances: 3
```

`env: flex` é a chave. `runtime: custom` no lugar faria o App Engine construir o `Dockerfile` da
pasta, e é assim que qualquer linguagem entra. `resources` dimensiona a máquina em vCPUs e GiB, não
por classe, e **`min_num_instances` não pode ser zero**: um serviço flexível tem sempre pelo menos
uma máquina rodando. A aplicação precisa escutar na porta 8080, que é o valor de `$PORT`. Nada
disso foi publicado; o arquivo é o formato documentado.

## O que custa estar sempre ligado

Instâncias flexíveis são cobradas por vCPU-hora e por GiB-hora enquanto rodam, sem franquia
gratuita. A seção 03 imprimiu as duas taxas da tabela, e uma instância do tamanho acima, o mês
inteiro, é a soma delas em 730 horas:

```
ana@laptop:~/gcp$ python3 -c 'print(round((0.0526 * 1 + 0.0071 * 1) * 730, 2))'
43.58
```

**Uns 44 dólares por mês para uma máquina pequena que nunca vai a zero**, antes do disco, e o dobro
disso no mínimo padrão, que é de duas instâncias a menos que o arquivo diga outra coisa. Contra as
28 horas gratuitas por dia do ambiente padrão, a diferença é o argumento inteiro: o flexível é
para uma aplicação que precisa dele, não um padrão.

## Por que ele é quase história

Tudo que o ambiente flexível oferecia, um contêiner com qualquer linguagem e qualquer biblioteca
numa infraestrutura gerenciada pelo Google, é o que o Cloud Run faz, com escala a zero, cobrança
por requisição e deploys medidos em segundos em vez de minutos. A própria documentação do Google
aponta o trabalho novo em contêiner para o Cloud Run e documenta um caminho de migração do flexível
para ele. **Um app flexível que você herda continua funcionando; um novo tem pouco motivo para
existir.** A lição 8 começa o Cloud Run.
