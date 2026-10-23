---
title: A documentação, e qual versão ela descreve
version: 1
---

**A documentação do Node fica no nodejs.org, e existe uma cópia dela por versão principal.** A
página em que você cai a partir de uma busca costuma ser a da versão mais nova, e uma opção descrita
ali pode não existir no Node 22. O endereço para guardar é `https://nodejs.org/docs/latest-v22.x/api/`,
que é a documentação do 22 mais recente, a linha que este curso usa.

## Linhas de versão

O Node lança uma versão principal nova duas vezes por ano. **As pares viram versões de suporte de
longo prazo (LTS)**, mantidas com correções por cerca de dois anos e meio, e as ímpares não. Um
servidor roda numa linha LTS. O seu Node sabe em qual linha está:

```
ana@dev:~/server$ node -p process.release
{
  name: 'node',
  lts: 'Jod',
  sourceUrl: 'https://nodejs.org/download/release/v22.22.0/node-v22.22.0.tar.gz',
  headersUrl: 'https://nodejs.org/download/release/v22.22.0/node-v22.22.0-headers.tar.gz'
}
ana@dev:~/server$ node -p 'process.versions.v8'
12.4.254.21-node.33
```

`lts: 'Jod'` é o nome da linha 22; toda linha LTS ganha um. Segundo o calendário de versões do
nodejs.org, o Node 22 é mantido até o fim de abril de 2027, e passar um projeto para uma linha mais
nova antes disso é manutenção comum, não emergência. O segundo comando é a versão do V8, o motor de
JavaScript dentro do Node, que a aula 2 abre.

## Estabilidade

Cada parte da API tem um **índice de estabilidade**, e ele decide quanto você deve construir em cima
dela:

| índice | o que significa |
|---|---|
| 0, deprecated | vai sair; não comece a usar |
| 1, experimental | pode mudar ou sumir em qualquer versão, até numa menor |
| 2, stable | só muda com uma versão principal |
| 3, legacy | continua, e existe algo melhor |

Recursos experimentais imprimem um aviso quando usados, e a aula 3 mostra um. Um servidor deve rodar
só sobre APIs **estáveis**, e onde este curso usa algo mais novo ele diz.

## Como ler uma entrada

Uma entrada traz a assinatura, depois as opções, depois **o histórico**: uma tabelinha das versões em
que a função foi acrescentada e alterada. Essa tabela responde a pergunta mais comum sobre qualquer
exemplo achado na internet — *isto vai funcionar no meu Node?* — e vale lê-la antes da descrição. O
`node --help` lista todas as opções de linha de comando do Node que você tem, e nada do que ele lista
falta no seu.
