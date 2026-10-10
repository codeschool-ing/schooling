---
title: Decidir com vários critérios, e conferir a decisão
version: 1
---

Algumas decisões têm uma troca no centro, e os cenários da seção anterior bastam. Outras têm cinco
critérios puxando para direções diferentes, três opções e uma sala cheia de gente em que cada pessoa
se importa com um critério diferente. **Uma matriz de decisão ponderada não toma essa decisão por
você. Ela torna a discordância visível, põe a discordância em números e mostra qual parte dela muda
de fato a resposta.** Usada assim, é uma das ferramentas mais úteis que um arquiteto tem. Usada como
oráculo, ela lava opiniões e as devolve em casas decimais.

## A decisão: onde mora o faturamento dos embarcadores

Depois que uma entrega é paga, a Carreto precisa faturar o embarcador: um extrato mensal de cada
carga, cada uma ligada ao seu CT-e autorizado, com as condições de pagamento do embarcador. Hoje uma
analista financeira monta isso numa planilha. O time de Payments do Bruno e o time Shipper precisam
escolher onde o faturamento novo vai morar, e há três opções na mesa:

- **A: um módulo dentro do monólito**, que já guarda os cadastros dos embarcadores e as chaves dos
  CT-e;
- **B: um serviço novo de faturamento**, do Payments, com banco de dados próprio;
- **C: um produto de cobrança hospedado**, integrado à Carreto pela API dele.

Antes de qualquer nota, a Renata separou uma coisa. **Toda fatura precisa referenciar o seu CT-e
autorizado.** Isso não é um critério para ser pesado contra a velocidade; é uma restrição, e uma
opção que não a cumpre está fora, tenha a nota que tiver no resto. As três conseguem cumpri-la, a C
com trabalho de integração, então as três seguem. Misturar restrições com pesos é o jeito mais comum
de uma matriz mentir: uma exigência legal com peso de 25% pode perder a votação para a conveniência.

## Montando a matriz

Os critérios vêm dos atributos de qualidade e das seis perguntas da aula 5, e os pesos vêm das
pessoas que são donas deles. Elas chegaram a cinco, depois de uma hora de discussão que foi, ela
mesma, a parte mais útil do exercício:

| critério | peso | A: módulo do monólito | B: serviço novo | C: produto hospedado |
|---|---|---|---|---|
| tempo até a primeira fatura | 30% | 5 | 2 | 4 |
| independência do time (implantar sem o monólito) | 20% | 2 | 5 | 4 |
| custo de operação | 15% | 5 | 2 | 3 |
| encaixe com os dados do CT-e | 25% | 4 | 4 | 2 |
| custo de saída | 10% | 4 | 4 | 1 |
| **total ponderado** | 100% | **4,05** | **3,30** | **3,05** |

Cada total é a soma de peso vezes nota. Para A: 0,30 × 5 + 0,20 × 2 + 0,15 × 5 + 0,25 × 4 + 0,10 × 4
= 1,50 + 0,40 + 0,75 + 1,00 + 0,40 = 4,05. As notas vão de 1 a 5, e cada uma é um julgamento que o
time justificou com uma frase: o módulo do monólito tira 5 em tempo porque os cadastros dos
embarcadores já estão lá, e 2 em independência porque toda mudança no faturamento espera a
implantação do monólito, que acontece duas vezes por semana.

**Três regras mantêm a matriz honesta:**

- **Combinar os pesos antes de alguém dar nota.** Pesos definidos depois que as notas são conhecidas
  são ajustados, de propósito ou não, até a favorita ganhar.
- **Manter os critérios independentes.** "Custo de operação" e "custo da conta de nuvem" avaliados
  separadamente contam a mesma coisa duas vezes e dobram o peso dela em silêncio.
- **Escrever o motivo ao lado de cada nota.** Um 4 que ninguém sabe explicar é um chute, e a matriz
  vira um chute multiplicado por um peso.

A ganha, 4,05 contra 3,30 e 3,05. O trabalho da matriz não termina aí.

## A checagem de sensibilidade

Os pesos são os números mais moles da tabela. Os 30% para o tempo até a primeira fatura foram o
argumento da Helena; os 20% para a independência do time foram a concessão do Bruno. **A pergunta que
importa é se a vencedora sobrevive a uma mudança razoável neles**, e responder leva cinco minutos.

Passe dez pontos do tempo para a independência, deixando tempo com 20% e independência com 30%. A cai
para 3,75 e B sobe para 3,60. A continua ganhando, por menos. Passe vinte pontos, para 10% e 40%, e A
cai para 3,45 enquanto B chega a 3,90. **B ganha.** A C, por acaso, não se mexe: ela tira 4 nos dois
critérios, então passar peso de um para o outro não muda nada para ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Um gráfico de linhas. Na horizontal, o peso dado à independência do time, de 0 a 50 por cento, com o tempo até a primeira fatura ficando com o resto dos 50 por cento. Na vertical, o total ponderado, de 2,5 a 5. A opção A, o módulo do monólito, cai de 4,65 para 3,15. A opção B, um serviço novo, sobe de 2,70 para 4,20. A opção C, um produto hospedado, fica plana em 3,05. O peso de hoje, 20 por cento, está marcado, e ali A está na frente. As linhas de A e B se cruzam em 32,5 por cento, e acima disso B ganha.\"><path d=\"M90 300 L660 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M90 300 L90 36\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M90 248 L650 248\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><path d=\"M90 144 L650 144\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><path d=\"M90 40 L650 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><text x=\"82\" y=\"252\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">3,0</text><text x=\"82\" y=\"148\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">4,0</text><text x=\"82\" y=\"44\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">5,0</text><text x=\"96\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">total ponderado</text><text x=\"90\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">0%</text><text x=\"202\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">10%</text><text x=\"314\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">20%</text><text x=\"426\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">30%</text><text x=\"538\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">40%</text><text x=\"650\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">50%</text><text x=\"660\" y=\"342\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">peso da independência do time</text><path d=\"M314 44 L314 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></path><text x=\"320\" y=\"292\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hoje: 20%</text><path d=\"M90 76.4 L650 232.4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M90 279.2 L650 123.2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M90 242.8 L650 242.8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><text x=\"110\" y=\"66\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">A: módulo do monólito</text><text x=\"650\" y=\"112\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">B: serviço novo</text><text x=\"650\" y=\"264\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">C: produto hospedado</text><circle cx=\"454\" cy=\"177.8\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M457 172 L472 104\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"466\" y=\"96\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">B ganha acima de 32,5%</text></svg>", "caption": "A mesma matriz, recalculada conforme o peso passa do tempo até a primeira fatura para a independência do time. Nos 20% de hoje A lidera com folga; as linhas se cruzam em 32,5%. A decisão depende desse único peso, e por isso é sobre ele que vale discutir."}
```

O cruzamento fica em 32,5%. Abaixo dele, ganha A; acima, B. **Isso transforma um debate vago numa
pergunta só, com um número: a independência do time vale um terço desta decisão?** Também mostra à
Renata quais discussões não valem a pena. Ninguém precisa gastar mais uma hora com custo de operação
ou custo de saída; passar dez pontos para dentro ou para fora de qualquer um dos dois, de ou para
qualquer outro critério, mantém A como vencedora.

A checagem também protege contra a falsa precisão. A com 4,05 e B com 3,30 parece um resultado claro.
O gráfico mostra que a margem depende quase toda de um peso que duas pessoas definiram numa conversa.
Se esse peso fosse 35% em vez de 20%, a mesma tabela teria escolhido diferente, com a mesma
confiança.

O que o time fez com isso foi simples. O Bruno argumentou que a independência ia pesar mais daqui a
dois anos, quando o faturamento ganhar regras próprias; a Helena argumentou que as primeiras faturas
tinham de sair neste trimestre. O Tomás decidiu: A, o módulo no monólito, construído atrás de uma
interface para poder ser extraído depois, com um registro de decisão que cita o cruzamento em 32,5% e
diz o que faria o time revisitá-la, a saber, mais de uma mudança por semana no faturamento travada
pelo calendário de implantação do monólito. **O registro leva a matriz, a checagem de sensibilidade e
a condição para mudar de rumo.**

## Outros jeitos de decidir bem

A matriz é uma ferramenta. Alguns hábitos de aulas anteriores fazem tanto trabalho quanto ela, e
andam juntos:

- **Decidir no último momento responsável**, que a aula 2 apresentou: não antes de poder chegar a
  informação que mudaria a resposta, e não depois que esperar começa a custar opções. A decisão do
  faturamento esperou o pagamento em 24 horas entrar no ar, porque isso definiu como o Payments
  saberia que uma entrega estava paga.
- **Medir o esforço pela porta.** Os dois eixos da aula 5 decidem quanto disso uma decisão recebe.
  Uma porta de mão dupla dentro de um time não precisa de matriz; precisa de alguém que escolha e siga.
- **Perguntar antes de decidir.** O processo de aconselhamento da aula 3 quer dizer que as pessoas
  afetadas e as que entendem do assunto foram consultadas. Os pesos da matriz são um lugar onde esse
  conselho fica visível.
- **Considerar não fazer nada.** A planilha da analista financeira é uma quarta opção. Ela perdeu
  porque o volume da Carreto crescia mais rápido do que uma pessoa consegue faturar à mão, mas ela
  deve estar na lista, e a aula 14 faz disso um hábito.
- **Escrever a decisão**, com a matriz e a checagem, para que a próxima pessoa que perguntar por que o
  faturamento está no monólito encontre o cruzamento e a condição, e não um dar de ombros.

## O que o arquiteto tem nisso tudo

Não a resposta. Na decisão do faturamento a Renata não deu nenhuma nota e não definiu nenhum peso.
**Ela era dona do método**: separar a restrição dos critérios, garantir que os pesos fossem
definidos antes das notas, rodar a checagem de sensibilidade e pôr o cruzamento na frente das pessoas
cuja discordância ele media. A decisão foi do Tomás, com o Bruno e a Helena um de cada lado, e ficou
melhor por ser visivelmente deles.

Essa é a linha que esta aula traçou três vezes. Decisões estruturais caras de reverter ou que
atravessam times são de arquitetura; trocas entre atributos de qualidade ficam explícitas com
cenários; decisões entre vários critérios são tomadas com uma matriz e conferidas quanto à
sensibilidade. **Em todos os casos, a contribuição do arquiteto é tornar a decisão decidível**, e
depois garantir que ela fique escrita.
