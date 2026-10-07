---
title: Troca de segredos, e a primeira hora depois de um vazamento
version: 2
---

**Trocar** (*rotacionar*) um segredo quer dizer substituí-lo por um valor novo e fazer o antigo parar
de funcionar. Feita como rotina, limita quanto tempo qualquer cópia de um segredo continua útil. Feita
depois de um vazamento, é o passo que mais importa, e feita na ordem errada causa uma interrupção
provocada por você mesmo.

Aqui a transportadora troca o token da produção: a simulação é reiniciada aceitando só
`lab-live-token-2`, e o `shipquote` ainda apresenta o antigo. Pare a transportadora da 9092 com
Ctrl-C e suba-a de novo com o token novo:

```sh
CARRIER_TOKEN=lab-live-token-2 CARRIER_PORT=9092 python3 ~/carrier/server.py
```

Peça uma cotação e leia o log. Depois ponha o token novo na configuração da produção,

```sh
sed -i 's/=lab-live-token$/=lab-live-token-2/' ~/envs/production/config.env
```

e reinicie a produção, que é o último comando abaixo:

```
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=1200&subtotal=5000"; echo
{"cep": "01310-100", "zone": "SP", "cents": 2190, "price": "R$ 21,90"}
ana@laptop:~/shipquote$ tail -2 ~/envs/production/app.log
carrier unavailable, using the table: HTTP Error 401: Unauthorized
GET /quote?cep=01310-100&weight=1200&subtotal=5000 200 2.2ms v=1.5.0
ana@laptop:~/shipquote$ ops/restart.sh production && curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=1200&subtotal=5000"; echo
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
```

A primeira cotação voltou com **R$ 21,90**, o preço da tabela, em vez dos R$ 18,60 da transportadora, e
o log diz por quê: `carrier unavailable, using the table: HTTP Error 401: Unauthorized`. A reserva da
aula 2 manteve a loja respondendo, e a linha de log que o teste com spy da aula 2 protege é o único
sintoma visível. Depois a configuração é atualizada, o processo reiniciado, e a próxima cotação volta
a vir da transportadora.

## Trocar sem interromper

O intervalo entre essas duas cotações é a interrupção que uma troca descuidada causa. Fornecedores a
evitam permitindo **dois segredos válidos ao mesmo tempo** por um período:

1. criar o segredo novo, enquanto o antigo continua funcionando;
2. implantar o novo em todo lugar que o usa;
3. confirmar que todo consumidor mudou, pelos logs do fornecedor ou do programa;
4. revogar o antigo.

A simulação do laboratório aceita um token por vez, então só consegue mostrar a versão com o
intervalo.

## Depois de um vazamento

Quando um segredo vazou, por um commit, um log ou um notebook, a ordem é outra, porque o valor antigo
agora está nas mãos de outra pessoa:

1. **Revogue ou troque primeiro**, aceitando uma interrupção curta se o fornecedor não aceitar duas
   chaves ao mesmo tempo. Cada minuto em que o valor vazado funciona é um minuto em que outra pessoa
   pode usá-lo.
2. **Confira se foi usado**: os logs de acesso do fornecedor, as remessas estranhas, a conta.
3. **Ache como vazou** e feche esse caminho: o commit, a linha de log, a permissão.
4. **Limpe** as cópias que você controla, como o histórico da seção 03, sabendo que as cópias que você
   não controla já estão fora de alcance.

Limpar o histórico primeiro e trocar depois, a ordem intuitiva, deixa o segredo funcionando o tempo
todo. A política do próprio repositório para a credencial de deploy tira o problema do caminho: uma
credencial federada expira em uma hora, então uma vazada para de funcionar sozinha.
