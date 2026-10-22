---
title: Um plano de teste, rodado sem a janela
version: 1
---

O REST Assured perguntava se cada resposta está certa. Um teste de carga pergunta como a aplicação
se comporta quando muitas requisições chegam juntas: quantas ela responde por segundo, e quanto
tempo as lentas levam. O JMeter descreve isso num **plano de teste**, um arquivo com extensão
`.jmx`. O editor dele é uma janela de desktop, e a maioria dos guias começa por ali. Um plano também
é XML puro, pequeno o bastante para ler, e a janela não tem nada a ver com rodá-lo: **um teste de
carga roda pela linha de comando**, numa máquina sem tela, como parte de um script.

Este plano manda vinte leitores virtuais contra o catálogo. Crie-o no projeto, onde ele é
versionado ao lado do código que testa, como `src/test/jmeter/books.jmx`. O Maven ignora esse
diretório.

```schooling-example
{
  "language": "xml",
  "file": "books.jmx",
  "parts": [
    {
      "code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<jmeterTestPlan version=\"1.2\" properties=\"5.0\" jmeter=\"5.6.3\">\n  <hashTree>\n    <TestPlan guiclass=\"TestPlanGui\" testclass=\"TestPlan\" testname=\"Bookshop catalogue\"/>\n    <hashTree>",
      "note": "Um plano de teste é uma árvore. Cada elemento é seguido de um `<hashTree>` com os filhos dele, então o `<hashTree/>` vazio depois de um elemento diz que ele não tem nenhum. É o formato que o próprio editor do JMeter grava."
    },
    {
      "code": "      <ThreadGroup guiclass=\"ThreadGroupGui\" testclass=\"ThreadGroup\" testname=\"Readers\">\n        <stringProp name=\"ThreadGroup.num_threads\">${__P(threads,20)}</stringProp>\n        <stringProp name=\"ThreadGroup.ramp_time\">${__P(rampup,2)}</stringProp>\n        <stringProp name=\"ThreadGroup.on_sample_error\">continue</stringProp>\n        <elementProp name=\"ThreadGroup.main_controller\" elementType=\"LoopController\" guiclass=\"LoopControlPanel\" testclass=\"LoopController\">\n          <boolProp name=\"LoopController.continue_forever\">false</boolProp>\n          <stringProp name=\"LoopController.loops\">${__P(loops,500)}</stringProp>\n        </elementProp>\n      </ThreadGroup>",
      "note": "Um **thread group** é um conjunto de usuários virtuais. Cada thread roda em ordem os samplers abaixo dele, espera cada resposta e recomeça até dar `loops` voltas. Vinte threads, iniciadas ao longo de dois segundos, cada uma dando 500 voltas. `${__P(threads,20)}` lê a propriedade `threads` e, se ela não existir, usa 20; assim uma execução muda a carga pela linha de comando sem editar o arquivo."
    },
    {
      "code": "      <hashTree>\n        <ConfigTestElement guiclass=\"HttpDefaultsGui\" testclass=\"ConfigTestElement\" testname=\"The bookshop\">\n          <stringProp name=\"HTTPSampler.protocol\">http</stringProp>\n          <stringProp name=\"HTTPSampler.domain\">${__P(host,localhost)}</stringProp>\n          <stringProp name=\"HTTPSampler.port\">${__P(port,8080)}</stringProp>\n        </ConfigTestElement>\n        <hashTree/>",
      "note": "Valores padrão para toda requisição HTTP do grupo: o esquema, o host e a porta, cada um também uma propriedade."
    },
    {
      "code": "        <HTTPSamplerProxy guiclass=\"HttpTestSampleGui\" testclass=\"HTTPSamplerProxy\" testname=\"GET /books/{id}\">\n          <stringProp name=\"HTTPSampler.method\">GET</stringProp>\n          <stringProp name=\"HTTPSampler.path\">/books/${__Random(1,6)}</stringProp>\n          <boolProp name=\"HTTPSampler.use_keepalive\">true</boolProp>\n        </HTTPSamplerProxy>\n        <hashTree/>",
      "note": "O primeiro **sampler**: uma requisição por volta, para um livro sorteado de 1 a 6, os seis títulos da migração da lição 13. `testname` é o rótulo pelo qual cada resultado e cada linha do relatório são agrupados. O keep-alive reaproveita a conexão, como um navegador ou um cliente HTTP faria."
    },
    {
      "code": "        <HTTPSamplerProxy guiclass=\"HttpTestSampleGui\" testclass=\"HTTPSamplerProxy\" testname=\"GET /books/search\">\n          <stringProp name=\"HTTPSampler.method\">GET</stringProp>\n          <stringProp name=\"HTTPSampler.path\">/books/search?q=the</stringProp>\n          <boolProp name=\"HTTPSampler.use_keepalive\">true</boolProp>\n        </HTTPSamplerProxy>\n        <hashTree/>",
      "note": "O segundo sampler, uma busca que encontra dois títulos."
    },
    {
      "code": "        <ResponseAssertion guiclass=\"AssertionGui\" testclass=\"ResponseAssertion\" testname=\"The answer names a book\">\n          <collectionProp name=\"Asserion.test_strings\">\n            <stringProp name=\"1073884426\">\"isbn\"</stringProp>\n          </collectionProp>\n          <stringProp name=\"Assertion.test_field\">Assertion.response_data</stringProp>\n          <intProp name=\"Assertion.test_type\">16</intProp>\n        </ResponseAssertion>\n        <hashTree/>",
      "note": "O JMeter já conta um 4xx ou um 5xx como erro. Uma **assertion** confere o que um status não diz: aqui, que o corpo contém `\"isbn\"`, o que qualquer livro ou lista de livros tem e uma página de erro não. Posta ao lado dos samplers, ela vale para os dois. `Asserion` está escrito errado no próprio código do JMeter, e o nome de cada texto é o hash code Java dele, que é como o JMeter o grava."
    },
    {
      "code": "      </hashTree>\n    </hashTree>\n  </hashTree>\n</jmeterTestPlan>"
    }
  ]
}
```

## A aplicação, como roda em produção

Um teste de carga mede uma aplicação rodando, então a livraria roda do jeito que vai para
produção: empacotada num jar e iniciada com `java -jar`, não dentro do `mvn`, cuja própria JVM e
cujos plugins dividiriam a máquina com ela. Gere o jar. Os testes acabaram de passar, e
`-DskipTests` os pula desta vez:

```
ana@vm:~/bookshop$ mvn -q package -DskipTests
```

Num segundo terminal, onde o `BOOKSHOP_JWT_SECRET` está definido como a lição 15 arrumou, inicie-a e
deixe-a rodando:

```sh
java -jar target/bookshop-0.1.0.jar
```

## Rodando o plano

```
ana@vm:~/bookshop$ jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -e -o target/jmeter/report
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.thoughtworks.xstream.converters.reflection.SunUnsafeReflectionProvider (file:/home/ana/opt/apache-jmeter-5.6.3/lib/xstream-1.4.20.jar)
WARNING: Please consider reporting this to the maintainers of class com.thoughtworks.xstream.converters.reflection.SunUnsafeReflectionProvider
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
Creating summariser <summary>
Created the tree successfully using src/test/jmeter/books.jmx
Starting standalone test @ 2026 Oct 22 20:27:27 GMT-03:00 (1792711647193)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary +   2306 in 00:00:03 =  837.9/s Avg:    15 Min:     2 Max:   162 Err:     0 (0.00%) Active: 20 Started: 20 Finished: 0
summary +  17694 in 00:00:08 = 2240.9/s Avg:     8 Min:     0 Max:   122 Err:     0 (0.00%) Active: 0 Started: 20 Finished: 20
summary =  20000 in 00:00:11 = 1878.3/s Avg:     9 Min:     0 Max:   162 Err:     0 (0.00%)
Tidying up ...    @ 2026 Oct 22 20:27:37 GMT-03:00 (1792711657897)
... end of run
```

Cinco opções, cada uma com uma função. `-n` roda sem a janela. `-t` dá o plano. `-l` é o **arquivo
de resultados**: uma linha por requisição, com o rótulo, o tempo, o status e se ela passou. `-j`
põe o log do próprio JMeter dentro de `target/` em vez de no diretório de onde você o rodou. `-e`
gera um relatório HTML a partir dos resultados quando a execução termina, e `-o` diz onde.

As quatro linhas `WARN StatusConsoleListener` são sobre a configuração de log do JMeter, e todo
comando do JMeter as imprime. As quatro linhas `WARNING` são a mesma queixa que a lição 1 encontrou
no Maven: uma biblioteca dentro do JMeter, o XStream, chama `sun.misc.Unsafe`, e o Java 25 avisa
sobre isso. Elas são sobre o JMeter, não sobre a livraria, e o próximo passo as cala.

Enquanto uma execução anda, o JMeter imprime uma linha `summary +` para cada trecho dela, com
`Active` dizendo quantas threads estavam rodando. A linha que importa vem no fim: `summary =`, para
a execução inteira. Ela conta 20000 requisições, as vinte threads vezes 500 voltas vezes dois
samplers, em 11 segundos, a 1878,3 requisições por segundo. Depois vêm o tempo de resposta médio, o
menor e o maior em milissegundos, e os erros. Nenhuma falhou. A próxima seção lê esses números. Antes, rode o mesmo
comando de novo:

```
ana@vm:~/bookshop$ jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -e -o target/jmeter/report
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
An error occurred: Cannot write to '/home/ana/bookshop/target/jmeter/report' as folder is not empty
```

O JMeter se recusa a escrever um relatório numa pasta que já tem um. Ele também teria acrescentado
as linhas da segunda execução ao mesmo arquivo de resultados, e um relatório gerado dele misturaria
duas execuções. **`-f` apaga os dois antes da execução**, e ele vai em todo comando que você
repetir.

O JMeter lê o `bin/setenv.sh` do próprio diretório a cada início, se o arquivo existir, e
`JVM_ARGS` é a variável que ele repassa ao Java. A mesma opção que a lição 1 deu ao Maven cala os
avisos:

```
ana@vm:~/bookshop$ echo 'JVM_ARGS="$JVM_ARGS --sun-misc-unsafe-memory-access=allow"' > ~/opt/apache-jmeter-5.6.3/bin/setenv.sh
```

```
ana@vm:~/bookshop$ time jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -f -e -o target/jmeter/report
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using src/test/jmeter/books.jmx
Starting standalone test @ 2026 Oct 22 20:27:41 GMT-03:00 (1792711661569)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary =  20000 in 00:00:07 = 2787.8/s Avg:     5 Min:     0 Max:   103 Err:     0 (0.00%)
Tidying up ...    @ 2026 Oct 22 20:27:48 GMT-03:00 (1792711668806)
... end of run

real	0m10.354s
user	0m10.744s
sys	0m0.844s
```

O `time` é do shell, e mede o próprio JMeter: o tempo decorrido e o tempo de processador que o
JMeter usou. A próxima seção precisa dos dois.

O relatório é um diretório de HTML. Abra `target/jmeter/report/index.html` num navegador e ele
mostra a mesma execução em tabelas e gráficos: um resumo das requisições que passaram e falharam,
estatísticas por rótulo e os tempos de resposta ao longo da execução.

```
ana@vm:~/bookshop$ ls target/jmeter target/jmeter/report
target/jmeter:
jmeter.log
report
results.jtl

target/jmeter/report:
content
index.html
sbadmin2-1.0.7
statistics.json
```
