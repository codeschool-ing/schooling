---
title: Tempo de resposta, e muita gente ao mesmo tempo
version: 1
---

O primeiro número de qualquer conversa sobre desempenho é quanto tempo leva uma requisição. O curl
mede isso com `-w`, que imprime variáveis depois da transferência: aqui, o código de status e o
tempo total em segundos. O `-o /dev/null` joga a página fora, porque o que interessa é o tempo:

```
ana@laptop:~$ curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' http://127.0.0.1:8000/
200 0.002166s
```

**Uma página em cerca de dois milissegundos.** No Windows, digite o mesmo comando com `NUL` no lugar
de `/dev/null`; num navegador, a aba Network (Rede) das ferramentas de desenvolvedor mostra um tempo
para cada requisição.

Esse número é verdadeiro e quase inútil, e ver por quê é a primeira lição de teste de desempenho. O
cliente e o servidor estão na mesma máquina, então a requisição não atravessou rede nenhuma. Uma
pessoa pediu uma página, sem mais ninguém usando a aplicação. E é uma build de teste num notebook,
não o servidor do teatro. **Uma medição só diz algo sobre as condições em que foi feita**, então um
resultado de desempenho nunca é relatado sem elas: que build, que máquina, que rede, quantos
usuários, que página.

## Vinte ao mesmo tempo

A pergunta seguinte é o que acontece quando as pessoas chegam juntas. Um laço consegue disparar vinte
curls sem esperar cada um terminar, o que é mais ou menos vinte pessoas apertando Enter no mesmo
instante. Cada um imprime o seu tempo, e `sort` com `tail` guardam os três mais lentos:

```
ana@laptop:~$ for i in $(seq 20); do curl -s -o /dev/null -w '%{time_total}\n' http://127.0.0.1:8000/ & done | sort -n | tail -n 3
0.029441
0.032561
0.036099
```

O mais lento dos vinte levou cerca de 36 milissegundos, contra uns dois da requisição sozinha.
Ainda rápido, e ainda um notebook conversando consigo mesmo. Os seus números vão variar a cada
rodada, o que é mais uma coisa que quem testa desempenho planeja: uma medição é uma anedota, e um
teste de carga relata **percentis** sobre milhares de requisições, como o tempo abaixo do qual
chegaram 95% delas.

O que os vinte mostram é a forma. **Requisições que chegam juntas esperam umas pelas outras**, então
o tempo de cada uma cresce com o número das que chegam. Até certa carga o crescimento é pequeno;
depois dela, a fila cresce mais rápido do que esvazia, os tempos de resposta sobem forte, e então
as requisições começam a falhar. Essa dobra é o que os testes de carga e de estresse existem para
achar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" data-fig=\"l14-load-curve\" aria-label=\"Um gráfico de linha com pessoas usando ao mesmo tempo na base e tempo de resposta na lateral, sem números em nenhum eixo. A linha corre quase plana, dobra e depois sobe forte, e depois da subida cruzes marcam requisições que falham. Uma linha vertical tracejada marca o pico esperado na parte plana. Uma chave sobre a parte plana até o pico diz teste de carga: ainda plano no pico? Uma chave sobre a curva e a subida diz teste de estresse: onde dobra, e como falha?\"><path d=\"M70.0 280.0 L640.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 70.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"355.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pessoas usando ao mesmo tempo</text><text x=\"70.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tempo de resposta</text><path d=\"M70.0 264.0 L72.9 264.0 L75.8 263.9 L78.8 263.9 L81.7 263.8 L84.6 263.8 L87.5 263.8 L90.4 263.7 L93.4 263.7 L96.3 263.6 L99.2 263.6 L102.1 263.5 L105.1 263.5 L108.0 263.5 L110.9 263.4 L113.8 263.4 L116.7 263.3 L119.7 263.3 L122.6 263.3 L125.5 263.2 L128.4 263.2 L131.3 263.1 L134.3 263.1 L137.2 263.1 L140.1 263.0 L143.0 263.0 L146.0 262.9 L148.9 262.9 L151.8 262.9 L154.7 262.8 L157.6 262.8 L160.6 262.7 L163.5 262.7 L166.4 262.6 L169.3 262.6 L172.2 262.6 L175.2 262.5 L178.1 262.5 L181.0 262.4 L183.9 262.4 L186.8 262.4 L189.8 262.3 L192.7 262.3 L195.6 262.2 L198.5 262.2 L201.5 262.2 L204.4 262.1 L207.3 262.1 L210.2 262.0 L213.1 262.0 L216.1 261.9 L219.0 261.9 L221.9 261.9 L224.8 261.8 L227.7 261.8 L230.7 261.7 L233.6 261.7 L236.5 261.7 L239.4 261.6 L242.4 261.6 L245.3 261.5 L248.2 261.5 L251.1 261.5 L254.0 261.4 L257.0 261.4 L259.9 261.3 L262.8 261.3 L265.7 261.3 L268.6 261.2 L271.6 261.2 L274.5 261.1 L277.4 261.1 L280.3 261.0 L283.3 261.0 L286.2 261.0 L289.1 260.9 L292.0 260.9 L294.9 260.8 L297.9 260.8 L300.8 260.8 L303.7 260.7 L306.6 260.7 L309.5 260.6 L312.5 260.6 L315.4 260.6 L318.3 260.5 L321.2 260.5 L324.1 260.4 L327.1 260.4 L330.0 260.4 L332.9 260.3 L335.8 260.3 L338.8 260.2 L341.7 260.2 L344.6 260.1 L347.5 260.1 L350.4 260.1 L353.4 260.0 L356.3 260.0 L359.2 259.9 L362.1 259.9 L365.0 259.9 L368.0 259.8 L370.9 259.8 L373.8 259.7 L376.7 259.7 L379.7 259.7 L382.6 259.6 L385.5 259.6 L388.4 259.5 L391.3 259.5 L394.3 259.4 L397.2 259.4 L400.1 259.4 L403.0 259.3 L405.9 259.2 L408.9 259.1 L411.8 258.9 L414.7 258.6 L417.6 258.2 L420.6 257.7 L423.5 257.1 L426.4 256.4 L429.3 255.6 L432.2 254.7 L435.2 253.7 L438.1 252.6 L441.0 251.3 L443.9 249.9 L446.8 248.3 L449.8 246.6 L452.7 244.8 L455.6 242.8 L458.5 240.7 L461.4 238.4 L464.4 236.0 L467.3 233.4 L470.2 230.6 L473.1 227.7 L476.1 224.6 L479.0 221.4 L481.9 217.9 L484.8 214.3 L487.7 210.5 L490.7 206.6 L493.6 202.4 L496.5 198.1 L499.4 193.6 L502.3 188.9 L505.3 184.0 L508.2 178.9 L511.1 173.6 L514.0 168.2 L517.0 162.5 L519.9 156.6 L522.8 150.5 L525.7 144.2 L528.6 137.7 L531.6 131.0 L534.5 124.1 L537.4 117.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M549.5 104.8 L559.5 114.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M549.5 114.8 L559.5 104.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M578.0 92.8 L588.0 102.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M578.0 102.8 L588.0 92.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M606.5 83.0 L616.5 93.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M606.5 93.0 L616.5 83.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"583.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">requisições falham</text><path d=\"M298.0 280.0 L298.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"298.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pico esperado</text><text x=\"454.2\" y=\"250.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a curva</text><path d=\"M70.0 233.0 L70.0 225.0 L298.0 225.0 L298.0 233.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"70.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">teste de carga: ainda plano no pico?</text><path d=\"M383.5 50.0 L383.5 42.0 L537.4 42.0 L537.4 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"537.4\" y=\"31.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">teste de estresse: onde dobra, e como falha?</text></svg>", "caption": "A forma típica do tempo de resposta contra a carga, não uma medição do boxoffice. O teste de carga confere o pico esperado; o teste de estresse vai atrás da curva."}
```

O desenho é a forma típica, não uma medição do boxoffice. Onde fica a dobra é a pergunta, e ela só
se responde medindo: um teste de carga confere que o sistema continua na parte plana no pico
esperado, e um teste de estresse segue empurrando até achar a parte íngreme e as falhas.

## As ferramentas que fazem isso de verdade

Um laço de shell basta para mostrar a ideia e passa longe de bastar para testar. Testes de carga de
verdade simulam centenas ou milhares de **usuários virtuais**, cada um seguindo um roteiro, parando
entre páginas como uma pessoa faz, chegando aos poucos em vez de todos de uma vez, e a ferramenta
registra cada tempo de resposta e cada erro. Três ferramentas são comuns:

- **k6**, em que o roteiro do usuário é escrito em JavaScript;
- **JMeter**, uma ferramenta Java mais antiga, cujos planos de teste se montam num editor gráfico;
- **Locust**, em que o roteiro é escrito em Python.

O Gatling é uma quarta que você vai ver citada. Este curso não instala nenhuma delas e não rodou
nenhuma; o `non-functional-testing` as ensina, junto com o jeito de modelar uma carga realista antes
de rodar uma.

## Duas regras que vale saber já

**Nunca faça teste de carga num sistema que você não recebeu permissão para testar.** Para quem
cuida dos servidores, um teste de carga é indistinguível de um ataque, e apontar um para um site em
produção, ou para o site de outra pessoa, pode derrubá-lo para clientes de verdade. Testes de carga
rodam contra um ambiente separado para eles, com os donos avisados antes.

**Relate lentidão com um número, não com um adjetivo.** "A reserva está lenta" é uma impressão.
"Enviar o formulário de reserva de Hamlet levou 4,2 segundos em três de cinco tentativas, na build
1.1 do ambiente de teste, às 10:15, sem mais nada rodando" pode ser conferido, comparado com a
próxima build e contestado. Quando nenhum requisito dá um número para comparar, diga isso no
relatório; a seção 02 desta aula explica por que essa lacuna importa.
