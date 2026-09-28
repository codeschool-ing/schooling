---
title: O que é este curso, e de onde vêm os números dele
version: 1
---

Este curso é sobre **a forma da nuvem, não sobre o console de ninguém**. Um diagrama do que um banco
de dados gerenciado tira das suas mãos continua certo daqui a dez anos; uma captura da tela onde você
clica para criar um fica errada na próxima vez que o provedor redesenhar a página. Você vai encontrar
AWS, Azure, Google Cloud e provedores menores pelo nome, e a aula 3 compara todos eles. O que as aulas
ensinam é o que os serviços deles têm em comum: uma máquina alugada por hora, um disco ligado a ela,
uma rede desenhada em volta, e as regras que dizem quem pode mexer em qualquer parte disso.

**Não existe conta de nuvem em lugar nenhum deste curso.** Uma conta pede cartão, custa dinheiro no
momento em que alguma coisa fica ligada, e teria transformado cada página no registro de uma tarde
numa conta. Por isso nada aqui é captura de console, conta a pagar ou resposta que um provedor deu a
um comando. Onde uma aula mostra configuração, como um documento de política ou um script de
inicialização, ela foi escrita para a aula e diz isso, e o que um provedor faria com ela é descrito,
não mostrado. Onde uma aula mostra um terminal, o comando rodou num laptop sem credenciais, e o
prompt diz `ana@laptop`.

## Os preços são uma lista publicada, lida por um programa

Nuvem se vende por unidade, então um curso sobre ela sem preços seria um curso sobre metade dela.
**Todo preço destas aulas é uma linha da lista pública de preços da AWS**, que a AWS publica como
arquivos JSON que qualquer pessoa baixa sem conta. O curso traz um programa pequeno ao lado do
`course.json`, o `prices.py`, que lê uma versão fixa de cada arquivo e imprime as linhas que as aulas
citam. Aqui ele imprime o cabeçalho e um bloco:

```
ana@laptop:~/cloud$ python3 prices.py lambda
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
```

Três coisas nesse cabeçalho valem toda vez que uma aula cita um número. Os preços estão em dólares
americanos e sem impostos. Cada um vem da **versão da oferta** impressa no topo, então rodar o programa
no ano que vem imprime a mesma tabela, mesmo que os preços em si tenham mudado; para os preços de hoje,
você trocaria as versões. E há duas colunas. `sa-east-1` é São Paulo, a região da AWS dentro do Brasil,
para onde uma empresa vai quando os usuários estão aqui ou quando os dados precisam ficar no país.
`us-east-1` é a Virgínia do Norte, a região mais antiga da AWS, e ela é **mais barata na maioria das linhas
desta tabela**, e mais cara em nenhuma: uma máquina `t3.micro` custa 0,01680 dólar por hora em São Paulo e 0,01040 na
Virgínia. A aula 9 trata do que a coluna mais barata custa em distância, e a aula 10 trata da conta
em si.

O bloco mostrado é o do Lambda, um serviço de que trata a aula 8, e é uma boa primeira amostra de
como a nuvem é vendida: 20 centavos por milhão de requisições, e uma unidade chamada GB-segundo que
ninguém encontra em nenhum outro lugar. A lista da AWS é a usada porque é publicada inteira, num
formato que um programa lê, e não porque o curso recomende a AWS. Os outros provedores cobram os
mesmos tipos de coisa nos mesmos tipos de unidade, e **são essas unidades que estas aulas ensinam você
a ler**.

## Para onde este curso leva, na sua trilha

::: track cloud-engineering
Este curso é o vocabulário do resto da sua trilha. `docker` vem logo depois dele, depois `kubernetes`,
`git` e `iac`, e então os três cursos do provedor que você escolher na bifurcação. Quando esses cursos
citarem um serviço, foi aqui que você aprendeu quais camadas ele tira das suas mãos.
:::

::: track data
Na sua trilha vêm em seguida `pipelines-etl` e `docker`, e depois o curso de fundamentos de um provedor
e o curso de dados dele. Esses cursos falam de um data warehouse gerenciado, de um stream gerenciado e
de um agendador gerenciado, e cada um é um ponto na linha que esta aula desenha: saber onde a linha
fica diz o que ainda é seu.
:::

::: track dba
Na sua trilha vem em seguida `nosql-operations`. O ângulo a observar neste curso é o banco de dados
gerenciado: leia a aula 5 pensando nos discos embaixo de um, e a aula 10 pensando na conta dele. É a
troca que esta aula descreve, feita no seu próprio assunto: o provedor aplica os patches no motor, e o
esquema, as consultas e os usuários continuam seus.
:::

::: track devops
Você já fez `docker` e `kubernetes`, então contêiner não é novidade; este curso é onde eles encontram um
provedor. Em seguida vêm o curso de fundamentos de um provedor, depois `iac`, `testing-cicd`, `gitops`
e `observability`. O Terraform, em `iac`, é a ferramenta que transforma em arquivos tudo o que este
curso desenha.
:::

::: track devsecops security
`cloud-security` vem logo depois deste curso, e parte da linha que esta aula desenha: o provedor
protege o que está abaixo dela, e tudo acima é seu para acertar ou errar. Leia com mais cuidado a aula
7, sobre identidade. É a única camada que continua sua em todo modelo.
:::

::: track networks-infra
A aula 6 é a mais próxima do seu ofício: uma rede com sub-redes, rotas e regras de firewall, desenhada
por uma API em vez de cabeada. Depois deste curso vêm `git` e `python`, e então `networks-automation` e
`iac`, que é onde a rede deixa de ser configurada à mão.
:::

::: track software-architecture
`iac` e `observability` vêm em seguida na sua trilha. Neste curso, as aulas 8 e 9 são onde moram as
decisões de arquitetura: construir sobre funções ou sobre máquinas, e quantas regiões e zonas um
sistema precisa aguentar perder.
:::

::: track *
Seja o que for que venha depois deste curso para você, as aulas 1, 7 e 10 são as que todo curso de
nuvem seguinte pressupõe: em que modelo você está, quem pode fazer o quê na conta, e quanto custa.
:::
