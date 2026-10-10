---
title: O SoapUI, descrito de fora
version: 1
---

**O SoapUI é um aplicativo de desktop para testar web services, e foi feito primeiro para SOAP.**
Ele lê um WSDL e o transforma em requisições prontas, encadeia essas requisições em casos de teste,
confere cada resposta com asserções, e consegue se passar por um serviço que ainda não existe. Tudo
das seções 05 e 06 tem uma tela nele. **Ele não foi executado para este curso**: é um aplicativo
gráfico em Java, e a máquina em que estas lições foram gravadas não tem tela. O que vem a seguir
descreve as telas dele em palavras, e nada disso é uma captura.

## O produto e a licença

Há dois produtos com um nome dentro. O **SoapUI Open Source** é gratuito, publicado pela SmartBear
sob a European Union Public Licence e baixado de soapui.org; é ele que esta seção descreve. O
**ReadyAPI** é o produto pago da SmartBear construído sobre ele, com um editor melhor para testes
orientados a dados, relatórios e suporte, vendido por assinatura em termos que a SmartBear define e
pode mudar. Artigos mais antigos chamam o pago de *SoapUI Pro*, o nome que ele tinha antes.

O SoapUI também testa APIs REST, e muitas equipes o usam só para isso. A força dele continua sendo o
WSDL: para REST ele não tem de onde ler as operações, a não ser que você lhe dê um documento OpenAPI.

## Um projeto a partir do WSDL

Você começa com **New SOAP Project**, dá um nome e o endereço do WSDL,
`http://localhost:8085/invoice?wsdl`, e deixa marcado *Create sample requests*. O SoapUI lê o WSDL
da seção 04 e monta uma árvore à esquerda:

- o projeto, que guarda a **interface** `InvoiceBinding`, com o nome do binding do WSDL;
- debaixo dela a operação `IssueInvoice`;
- debaixo desta uma requisição chamada *Request 1*, que é o envelope da seção 05 com um `?` onde
  vai cada valor.

Abrir a requisição mostra dois painéis: o envelope à esquerda, que você edita, e a resposta à
direita depois que você aperta a seta verde. O campo de endereço acima deles vem do `soap:address`.
O `SOAPAction` e o `content-type` são preenchidos a partir do binding, então os dois cabeçalhos que
você digitou para o curl nunca chegam a ser digitados. Esse é o argumento inteiro a favor de um
WSDL, visto da cadeira de quem testa.

## Suítes, casos, passos e asserções

Uma requisição sozinha é uma verificação manual. Para um teste repetível você acrescenta uma
**TestSuite**, e dentro dela um **TestCase**, que é uma lista de **passos de teste** rodados em
ordem:

| passo | faz | o equivalente no curl |
|---|---|---|
| SOAP Request | manda um envelope para uma operação | um `curl --data-binary` |
| Property Transfer | copia um valor de uma resposta para a próxima requisição, por XPath | guardar o `invoiceNumber` numa variável do shell |
| Groovy Script | roda código que você escreve, para o que os outros passos não fazem | uma linha de bash |
| Delay | espera | `sleep` |

Cada passo SOAP Request carrega as próprias **asserções**, escolhidas numa lista. As que esta lição
já escreveu à mão estão todas lá:

| asserção | confere | em `soap/check.sh` |
|---|---|---|
| Valid HTTP Status Codes | o status é um de uma lista | `check '…: HTTP status' 200` |
| Not SOAP Fault | a resposta não tem `Fault` | `boolean(//*[local-name()="Fault"])` é `false` |
| SOAP Fault | a resposta **é** uma falha, para um caso negativo | os casos de `500` |
| XPath Match | uma expressão XPath dá um valor esperado | `string(//faultcode)` é `soap:Client` |
| Contains | a resposta contém um trecho de texto | — |
| Schema Compliance | a resposta bate com os tipos do WSDL | — |

**A Schema Compliance é a única sem linha no script.** Ela confere cada elemento da resposta contra
o XML Schema do WSDL, o que pegaria um `issuedAt` que não é uma data ou um `invoiceNumber` que
sumiu, sem uma asserção por campo. A lição 10 faz o mesmo para JSON com JSON Schema.

Numa asserção XPath Match você declara os namespaces, e o SoapUI oferece um botão que declara todos
os que a resposta usa. Então lá `//inv:invoiceNumber` funciona, e o contorno com `local-name()` da
seção 06 não é necessário.

## Serviços mock, e a linha de comando

O SoapUI também gera um **MockService** a partir do mesmo WSDL: um serviço falso, numa porta que
você escolhe, que responde cada operação com uma resposta que você edita. Uma equipe o usa para
construir quem chama antes de o serviço real existir, ou para fazer o real falhar quando quiser. É a
ideia da lição 11, que constrói mocks para uma dependência REST.

O projeto inteiro é salvo como um arquivo XML, que vai para o controle de versão ao lado do código.
Um script chamado `testrunner.sh` (`testrunner.bat` no Windows), no diretório `bin` do SoapUI, roda
as suítes de um projeto sem a janela e pode escrever relatórios JUnit, que é como um pipeline as
roda, do jeito que o Newman roda uma coleção do Postman na lição 6.

## Você não precisa do SoapUI para testar SOAP

O SoapUI é uma comodidade, e grande quando um WSDL tem quarenta operações. Nada do que ele manda é
especial: a seção 05 chamou o serviço com o curl, e as ferramentas das lições anteriores também
conseguem. O Postman manda um envelope como corpo XML cru com os dois cabeçalhos; o REST Assured,
na lição 7, posta XML e lê as respostas com o `XmlPath` dele; o Karate, na lição 8, tem uma palavra
`soap action` exatamente para isso. Escolha o SoapUI quando a equipe já guarda os projetos nele ou o
WSDL é grande, e escolha a ferramenta onde seus testes de API já moram quando não é.
