---
title: Convivendo com o SOAP
version: 1
---

Os serviços SOAP vão durar mais que a carreira de muita gente que lê esta seção. O FarmRegistry
fica até o Coleta sair, os serviços da NF-e ficam enquanto a autoridade tributária quiser, e o
próprio SAP expõe como SOAP boa parte do que faz. Um time que constrói algo novo na Serra Alta vai
chamar SOAP por anos, e a reação errada é a natural para um engenheiro vindo do mundo do JSON:
tratar o SOAP como um incômodo e resolver logo. **O objetivo não é evitar o SOAP, e sim mantê-lo na
borda do seu sistema, num lugar só, para que nada mais no seu código saiba que ele está ali.**

## Como é resolver logo

O time do Rota encontrou o FarmRegistry em 2022. Precisavam do tamanho dos tanques para planejar
rotas, o serviço estava lá, e ninguém no time tinha usado SOAP. Então fizeram o que parecia menor:
copiaram uma requisição da ferramenta de teste para um template de string em Kotlin, mandaram com o
cliente HTTP que já tinham, e tiraram os quatro valores da resposta com expressões regulares sobre
`<fr:tankLitres>` e os vizinhos.

Funcionou por catorze meses. Aí o barramento recebeu um patch, e o FarmRegistry passou a responder
com `ns2:` onde antes escrevia `fr:`. O XML significava exatamente a mesma coisa, porque um prefixo
é só um nome local para um namespace; as expressões regulares não acharam nada, o parser caiu num
tamanho de tanque zero, e o Rota não planejou coleta para 37 fazendas naquela noite. Três caminhões
saíram na manhã seguinte para fazendas às quais não tinham sido mandados, porque os motoristas
sabiam mais que o plano.

Cada passo dessa falha é comum. **Tratar XML como texto quebra com mudanças que não são
mudanças**, um valor padrão silencioso transformou uma falha de leitura numa resposta errada, e um
500 com um fault dentro teria seguido o mesmo caminho.

## Gere o cliente a partir do contrato

O WSDL existe para que ninguém precise escrever envelopes à mão. Toda plataforma comum tem um
gerador: na JVM, o `wsdl2java` do Apache CXF; no .NET, o `dotnet-svcutil`; em Python, a biblioteca
`zeep` lê o WSDL e monta as chamadas quando o programa roda. O que sai é um cliente tipado: um
método por operação, uma classe por mensagem, uma exceção por fault declarado, e um parser de XML de
verdade, que lê namespaces e não prefixos.

Três hábitos tornam seguro depender do cliente gerado:

- **Guarde uma cópia do WSDL no seu repositório e gere o cliente no build.** Buscá-lo no endereço
  `?wsdl` do serviço quando o programa sobe faz de uma mudança no barramento uma mudança no seu
  programa, sem revisão, num dia que você não escolheu.
- Compare no build a cópia com a publicada, para que um contrato alterado falhe num teste com um
  diff em vez de falhar em produção com um stack trace.
- Fixe a versão do gerador junto com as outras dependências; duas versões da mesma ferramenta podem
  gerar nomes de classe diferentes a partir do mesmo WSDL.

## Embrulhe num adaptador

O cliente gerado fala a língua do serviço: `GetFarmTankResponse`, `farmCode` como string,
`lastCollection` como um tipo de calendário do XML, `FarmNotFoundFault`. Se esses tipos se
espalharem pelo Rota, o planejador de rotas fica escrito nos termos do FarmRegistry, e trocar o
FarmRegistry, que a aula 13 planeja fazer, significa mexer no planejador.

Por isso a segunda versão da integração do Rota pôs uma fronteira. O Rota define o que precisa nas
suas próprias palavras — uma interface `FarmTanks` com um método que recebe um `FarmId` do Rota e
devolve um `Tank` com capacidade, volume médio diário e hora do último esvaziamento, ou "esta
fazenda não é conhecida". Uma classe implementa essa interface usando o cliente gerado, e é a única
classe do Rota que importa alguma coisa gerada. **O adaptador é onde o SOAP termina: tipos gerados
entram de um lado, os tipos do próprio Rota saem do outro, e o resto do programa não percebe a
diferença.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-adapter\" aria-label=\"Rota chamando o FarmRegistry, da esquerda para a direita. Dentro do Rota: o planejador de rotas chama a interface FarmTanks, implementada por um adaptador que contém o cliente gerado, o mapeamento de faults para respostas, os timeouts com uma nova tentativa e o recurso à resposta de ontem. Uma linha tracejada marca a fronteira: à esquerda dela tudo está nos tipos do próprio Rota, à direita tudo é SOAP. Depois da fronteira a chamada vai para o serviço FarmRegistry no barramento e daí para o Coleta no IBM i. Abaixo do barramento, uma caixa tracejada mostra o stub com envelopes gravados que substitui o barramento nos testes do Rota.\"><defs><marker id=\"l08-adapter-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"232.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">os tipos do próprio Rota</text><text x=\"598.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SOAP</text><rect x=\"18.0\" y=\"98.0\" width=\"104.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planejador</text><text x=\"70.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de rotas</text><rect x=\"146.0\" y=\"98.0\" width=\"104.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FarmTanks</text><text x=\"198.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">interface</text><path d=\"M122.0 120.0 L144.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><rect x=\"272.0\" y=\"52.0\" width=\"176.0\" height=\"150.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">adaptador</text><rect x=\"280.0\" y=\"82.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente gerado</text><rect x=\"280.0\" y=\"112.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">faults → respostas</text><rect x=\"280.0\" y=\"142.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">timeouts, uma nova tentativa</text><rect x=\"280.0\" y=\"172.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resposta de ontem</text><path d=\"M250.0 120.0 L270.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><path d=\"M466.0 40.0 L466.0 270.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"466.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a fronteira</text><rect x=\"488.0\" y=\"98.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FarmRegistry</text><text x=\"548.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">no barramento</text><path d=\"M448.0 120.0 L486.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><rect x=\"626.0\" y=\"98.0\" width=\"84.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta</text><text x=\"668.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IBM i</text><path d=\"M608.0 120.0 L624.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><rect x=\"488.0\" y=\"206.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"568.0\" y=\"219.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stub com envelopes</text><text x=\"568.0\" y=\"232.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gravados, nos testes</text><path d=\"M448.0 190.0 L486.0 218.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path></svg>", "caption": "O SOAP termina no adaptador. Tudo à esquerda da linha está escrito nos termos do Rota, então uma mudança no barramento, ou o fim do FarmRegistry, mexe numa classe só.", "same": ["Coleta", "IBM i", "SOAP", "interface"]}
```

Essa fronteira tem nome no domain-driven design, a camada anticorrupção, e ela pode ser muito mais
que uma conversão de tipos: os códigos de fazenda do Coleta têm dígito verificador, os volumes vêm
em litros inteiros, e os horários trazem um fuso que o Rota não quer. A aula 13 constrói a camada
direito, porque ela vira a costura ao longo da qual o Coleta é substituído. Aqui a questão é menor:
ponha todo detalhe de SOAP numa classe, e a próxima mudança no barramento mexe numa classe.

## Faults são respostas com significado

Um fault não é um tipo só de erro. O trabalho mais importante do adaptador é transformar cada tipo
na reação certa, e a reação certa depende de quem é a culpa e de se tentar de novo pode ajudar:

| o que voltou | o que significa | o que o adaptador do Rota faz |
|---|---|---|
| `soap:Client` com um detail `FarmNotFound` | a fazenda não está no Coleta: saiu, ou o código está errado | devolve "fazenda desconhecida", que o planejador tira da rota e informa ao relacionamento com fazendas; nunca tenta de novo |
| `soap:Client` sem detail conhecido | o Rota mandou algo que o serviço não consegue ler: um bug do lado do Rota | lança um erro, alerta o time do Rota; nunca tenta de novo |
| `soap:Server` | o FarmRegistry, ou o Coleta atrás dele, falhou | tenta de novo uma vez depois de dois segundos, e então recorre ao plano B |
| HTTP 502, 503 ou 504 sem envelope | algo entre os dois falhou: um proxy, a frente do próprio barramento | tratado como `soap:Server` |
| nenhuma resposta dentro do timeout | desconhecido: a requisição pode ou não ter sido processada | para esta leitura, o mesmo que `soap:Server` |

**O plano B é uma decisão de negócio, não de protocolo.** O tanque de uma fazenda não muda de
tamanho entre ontem e hoje, então, quando o FarmRegistry está fora, o Rota planeja com a resposta
de ontem e marca o plano como montado sobre dados em cache. A aula 12 chama isso de modo degradado e
faz a pergunta para toda integração.

A última linha esconde a armadilha. `GetFarmTank` só lê, então perguntar duas vezes não faz mal.
Uma operação SOAP que grava — `RegisterBankAccount`, no processo de cadastro de fazendas, é uma —
não pode ser repetida às cegas depois de um timeout, porque a primeira chamada pode ter dado certo e
a segunda vai fazer o trabalho de novo. Se uma gravação pode ser repetida com segurança é uma
propriedade que a operação precisa receber, e a aula 10 trata de como.

## Timeouts são números que alguém escolheu

O cliente HTTP com que o Rota começou esperava a resposta indefinidamente. Na noite de um lote lento
do Coleta, uma rodada de planejamento ficou travada quarenta minutos esperando uma chamada. Um
timeout é uma afirmação sobre quanto tempo quem chama pode esperar, e deve vir de medições do
serviço, não ficar no padrão de uma biblioteca.

Os números de Joana para o FarmRegistry, de um mês de estatísticas do barramento: a chamada mediana
leva 0,3 segundo, o percentil 99, 1,8 segundo, porque algumas chamadas esperam o Coleta atrás do MQ.
O Rota agora usa um timeout de conexão de 2 segundos e um de leitura de 5: longo o bastante para uma
chamada lenta mas saudável terminar, curto o bastante para uma chamada morta custar segundos a uma
rodada de planejamento, e não minutos. Com uma nova tentativa, uma fazenda cujas duas chamadas
travam custa 5 + 2 + 5 = 12 segundos antes do plano B, e o planejador pede os tanques em paralelo,
oito de cada vez.

## Teste contra envelopes gravados

Um teste que precisa do barramento é um teste que espera na fila do time de integração e falha
quando o ambiente compartilhado está ocupado. **Os testes do adaptador do Rota rodam contra
envelopes gravados**: pares reais de requisição e resposta capturados uma vez do barramento de
teste, com os dados das fazendas trocados por valores inventados, guardados junto do código e
reproduzidos por um pequeno stub local que responde como o FarmRegistry.

As gravações que mais importam não são as felizes. O time capturou um fault `FarmNotFound` pedindo
um código que não existe, um fault `soap:Server` pedindo ao time do barramento que parasse a fila do
Coleta por dez minutos no ambiente de teste, uma resposta com prefixos `ns2:`, e uma resposta com um
elemento a mais que o WSDL ainda não declara. Cada uma é um teste, e cada teste confere o que o
adaptador devolve, não que XML ele mandou. Quando o time do barramento anuncia uma mudança, o time
do Rota grava os envelopes novos e roda os testes antes de a mudança chegar à produção.

Nada disso é particular do SOAP. É o que qualquer time deveria fazer quando depende de um sistema
que não controla. O SOAP facilita mais que a maioria, porque o contrato está num arquivo e os faults
estão declarados nele.
