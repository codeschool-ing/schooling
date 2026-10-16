---
title: Instalando o k6 e uma primeira execução
version: 1
---

O JMeter, na aula 4, guarda um plano de teste num arquivo XML que uma janela edita por você. **O
k6 guarda um teste num arquivo JavaScript que você mesmo escreve**, e essa diferença decide quase
tudo o que vem depois: o teste mora no repositório ao lado do código, passa por revisão de código
como qualquer outra mudança, e um diff dele diz em palavras o que mudou. O k6 é um programa só,
escrito em Go, da Grafana Labs. O JavaScript roda dentro do k6, num motor próprio, então aqui não
há Node.js nem `npm install`.

## Um programa só

O k6 é publicado como um pacote no GitHub, com um arquivo dentro. No shell da VM:

```sh
cd ~
curl -fsSLO https://github.com/grafana/k6/releases/download/v1.8.1/k6-v1.8.1-linux-amd64.tar.gz
tar -xzf k6-v1.8.1-linux-amd64.tar.gz
sudo install k6-v1.8.1-linux-amd64/k6 /usr/local/bin/
```

Num Mac com Apple silicon a VM é ARM, e o pacote é `k6-v1.8.1-linux-arm64.tar.gz`, nas duas
linhas que o citam. **Essas quatro linhas não foram rodadas para este curso**, porque o computador
em que ele foi gravado não alcança o GitHub. O k6 das transcrições foi compilado a partir do mesmo
código-fonte da v1.8.1, e é por isso que a linha de versão cita o compilador Go dessa compilação:

```
ana@nft:~$ k6 version
k6 v1.8.1 (go1.25.1, linux/amd64)
```

Uma versão que você baixa cita, no lugar, a versão de Go com que foi compilada, e o resto é igual.

## O menor teste

Crie uma pasta para os scripts desta aula e abra o primeiro:

```sh
mkdir -p ~/k6 && nano ~/k6/first.js
```

```javascript
// k6/first.js
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 5,
  duration: '10s',
};

export default function () {
  http.get('http://127.0.0.1:8000/shows/990');
  sleep(1);
}
```

Isso é um teste inteiro. `options` diz cinco usuários virtuais por dez segundos, e a função padrão
é o que cada um deles faz sem parar: pede o espetáculo 990 e espera um segundo. Inicie a
bilheteria num terminal, como na aula 1 (`cd ~/boxoffice && python3 app.py`), e rode o teste num
segundo terminal, na sua pasta pessoal:

```
ana@nft:~$ k6 run -q k6/first.js


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=29.91ms min=16.02ms med=27.68ms max=69.25ms p(90)=51.79ms p(95)=62.09ms
      { expected_response:true }...: avg=29.91ms min=16.02ms med=27.68ms max=69.25ms p(90)=51.79ms p(95)=62.09ms
    http_req_failed................: 0.00%  0 out of 50
    http_reqs......................: 50     4.820475/s

    EXECUTION
    iteration_duration.............: avg=1.03s   min=1.01s   med=1.02s   max=1.07s   p(90)=1.05s   p(95)=1.06s  
    iterations.....................: 50     4.820475/s
    vus............................: 5      min=5       max=5
    vus_max........................: 5      min=5       max=5

    NETWORK
    data_received..................: 16 kB  1.6 kB/s
    data_sent......................: 4.0 kB 381 B/s
```

**A opção `-q` esconde a barra de progresso**, que o k6 redesenha na mesma linha a cada segundo
enquanto roda; sem ela aparecem também um logo e uma linha por segundo, e o resumo do fim é o
mesmo. Todas as execuções desta aula usam `-q` para as transcrições guardarem só o resultado.

Olhe `http_reqs` antes de qualquer outra coisa. Cinco usuários, cada um mandando uma requisição e
depois dormindo um segundo, deveriam mandar um pouco menos de cinco por segundo, e o resumo diz
`4.820475/s`. **Cada usuário virtual espera a resposta antes de dormir e pedir de novo**, que é o
usuário virtual da aula 3 com o seu tempo de reflexão. Então um servidor que ficasse lento
receberia menos requisições, e o teste aliviaria justo no momento em que deveria apertar mais. A
próxima seção escreve o mesmo tipo de teste do jeito contrário.
