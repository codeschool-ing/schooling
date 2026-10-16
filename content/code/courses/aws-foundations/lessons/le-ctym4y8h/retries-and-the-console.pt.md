---
title: Novas tentativas, o console como cliente, e para onde o curso segue
version: 1
---

**Um cliente que chama a AWS precisa esperar que algumas chamadas falhem e deem certo um instante
depois, e todo SDK as repete por você.** A mesma camada que assina e pagina também conta as
tentativas, espera um pouco mais a cada vez, e desiste depois de um limite. Esta seção mede a linha
de comando fazendo isso, põe o console entre os clientes, e encerra o curso.

## Novas tentativas, medidas numa chamada que sempre falha

O moto responde toda chamada de `rolesanywhere` com um erro interno, como a lição 12 descobriu, o
que faz dela uma falha confiável de observar. O `grep` guarda o cabeçalho da tentativa e as linhas de
nova tentativa:

```
ana@laptop:~/aws$ aws rolesanywhere list-trust-anchors --debug 2>&1 | grep -oE "'amz-sdk-request': b'[^']*'|Retry needed, retrying request after delay of: [0-9.]*|reached max retries: [0-9]*" | head -6
'amz-sdk-request': b'attempt=1'
Retry needed, retrying request after delay of: 0.5274532777405271
'amz-sdk-request': b'ttl=20261016T190257Z; attempt=2; max=3'
Retry needed, retrying request after delay of: 1.4379720271632055
'amz-sdk-request': b'ttl=20261016T190257Z; attempt=3; max=3'
reached max retries: 2
```

**Três tentativas, depois o erro**, que diz ter chegado a duas novas tentativas. Cada requisição diz
ao serviço qual tentativa ela é com o `amz-sdk-request`. As esperas antes da segunda e da terceira
são aleatórias e curtas, porque a espera dobra a partir de uma base pequena e uma parte aleatória
impede que mil clientes que falharam juntos tentem de novo juntos. O limite é uma configuração:

```
ana@laptop:~/aws$ AWS_MAX_ATTEMPTS=1 aws rolesanywhere list-trust-anchors --debug 2>&1 | grep -c "Sending http request"
1
```

**Uma requisição, nenhuma nova tentativa.** O mesmo par de configurações existe em todo SDK e no
`~/.aws/config`, como `max_attempts` e `retry_mode`; o programa da seção anterior as escreveu no
`Config` dele.

A documentação da AWS descreve três modos de nova tentativa, e o padrão do AWS CLI 2 é o segundo:

| modo | o que faz |
|---|---|
| `legacy` | o comportamento dos SDKs mais antigos, com menos tipos de erro repetidos |
| `standard` | 3 tentativas por padrão, espera exponencial com jitter, um teto na espera |
| `adaptive` | `standard`, mais uma taxa que o cliente baixa sozinho quando sofre limitação |

**A limitação de taxa (throttling) é a falha para a qual as novas tentativas existem.** Toda API tem
uma taxa por conta e região, e quem passa dela recebe `ThrottlingException`, `Throttling` ou
`TooManyRequestsException`, conforme o serviço, muitas vezes com HTTP 400 ou 429. Uma nova tentativa
com espera em geral passa; um programa que repete sem espera piora a situação para si e para todo
mundo na conta. O moto nunca limita, então este parágrafo vem da documentação da AWS e não foi
executado. Uma requisição que falhou por um motivo que repetir não resolve, como `AccessDenied` ou
um parâmetro malformado, não é repetida.

## O console também é um cliente

**O AWS Management Console é uma aplicação web que, por trás das telas, faz as mesmas chamadas de
API assinadas**, com credenciais temporárias de quem entrou nele: um usuário raiz, um usuário do IAM,
ou uma role alcançada pelo Identity Center como na lição 11. Abrir a página do EC2 lista as
instâncias com `DescribeInstances`; apertar um botão para lançar uma manda `RunInstances`. É por isso
que uma permissão que falta ao console aparece como o mesmo `AccessDenied` que um comando
receberia, e por isso o console não consegue fazer nada que a API não ofereça.

Ele não foi executado aqui. **O console exige uma conta e um navegador**, e este curso não desenha
imagens dele, porque as telas mudam no ritmo da AWS enquanto as chamadas por trás delas não mudam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l26-clients\" aria-label=\"Quatro clientes, uma API. O console no navegador, a linha de comando da AWS, um programa com boto3 e o curl com --aws-sigv4 mandam, cada um, uma requisição HTTPS assinada ao mesmo endpoint de serviço. O serviço avalia as mesmas políticas do IAM para todos, e o CloudTrail registra cada chamada, com o User-Agent do cliente.\"><defs><marker id=\"l26-clients-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-clients-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"26.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o console</text><text x=\"125.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no navegador</text><path d=\"M222.0 50.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"86.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aws</text><text x=\"125.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a linha de comando</text><path d=\"M222.0 110.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"146.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boto3</text><text x=\"125.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um programa</text><path d=\"M222.0 170.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"206.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">curl --aws-sigv4</text><text x=\"125.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">à mão</text><path d=\"M222.0 230.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"350.0\" y=\"100.0\" width=\"160.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"430.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o serviço</text><text x=\"430.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mesmas políticas</text><text x=\"430.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para os quatro</text><path d=\"M512.0 140.0 L558.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-amber)\"></path><rect x=\"560.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CloudTrail</text><text x=\"630.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um registro cada</text><text x=\"430.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma requisição HTTPS assinada</text></svg>", "caption": "O console é mais um cliente: ele assina as mesmas chamadas, e é julgado e registrado do mesmo jeito.", "same": ["CloudTrail"]}
```

## O CloudTrail registra a chamada, seja quem for que a fez

Toda chamada que chega à AWS, do console, da linha de comando, de um SDK ou do `curl`, é o tipo de
evento que o **AWS CloudTrail** registra: quem fez, de qual endereço, com qual chave ou sessão de
role, quando, e o que foi pedido. O registro traz o `User-Agent` do cliente, então mostra qual
cliente foi, e é o mesmo registro em qualquer caso. Essa é a trilha que a lição 12 buscou pelo id da
chave depois de um vazamento. O CloudTrail em si pertence ao curso `aws-operations`, e o moto 5.2.3
responde o `lookup-events` com um erro interno, então ele não foi executado aqui.

## Onde este curso deixa você

Vinte e seis lições atrás, o laboratório eram dois programas num laptop. Desde então ele guardou uma
organização de contas, as políticas e roles que decidem quem pode fazer o quê nelas, a fatura e a
lista de preços, as redes que os pacotes atravessam, e a API por baixo de tudo isso. **O vocabulário
é a parte que dura**: conta, principal, política, role, região, sub-rede, requisição.

::: track cloud-engineering
Nesta trilha vêm mais dois cursos da AWS. O `aws-compute` põe máquinas, contêineres e funções nas
contas e redes montadas aqui, e o `aws-operations` entrega para elas, as observa e lê a fatura, com o
CloudTrail entre as ferramentas. Os dois pressupõem a identidade e a rede deste curso, então os
perfis, as roles e as VPCs que você criou são de onde eles partem.
:::

::: track data
Nesta trilha vem um curso da AWS, o `aws-data`: o armazenamento, os bancos de dados gerenciados e os
serviços de análise em que os dados da loja vão morar. Ele pressupõe o modelo de contas e a
identidade deste curso, então as roles e políticas daqui são o que os pipelines dele vão vestir.
:::

::: track devops
Nesta trilha este curso é a AWS inteira. Os cursos seguintes, `iac`, `testing-cicd`, `gitops` e
`observability`, são escritos para qualquer provedor; as contas, as roles para máquinas e pipelines,
e as redes que você montou aqui são para onde você aponta as ferramentas deles.
:::

::: track *
Daqui os cursos da AWS se dividem por assunto: `aws-compute` para o que roda, `aws-operations` para
entregar e observar, `aws-data` para onde os dados moram. Cada um pressupõe este, e nenhum o repete.
:::
