---
title: O caminho de volta, e quanto ele custa
version: 1
---

O motivo de manter o blue rodando é o próximo comando. Voltar é a mesma edição, no sentido
contrário:

```
ana@laptop:~/shipquote$ time sed -i 's/"blue": 0, "green": 100/"blue": 100, "green": 0/' ~/envs/routes.json

real	0m0.004s
user	0m0.000s
sys	0m0.003s
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.5.0", "env": "production-blue", "carrier": "table"}
ana@laptop:~/shipquote$ grep -c "^error" ~/envs/production-green/app.log; grep "^error" ~/envs/production-green/app.log | sort | uniq -c
77
     77 error: KeyError: 57
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8302/quote?cep=57020-050&weight=700&subtotal=8990"; echo
{"error": "internal error"}
```

Três milissegundos, e os clientes estão no 1.5.0 de novo. Nenhum build, nenhum deploy, nenhum
processo iniciado: o blue nunca parou. Essa velocidade é o que o blue-green vende, e é por isso que o
erro acima foi um incidente curto e não longo.

Os dois últimos comandos mostram por que aconteceu. O log da green tem 77 linhas, todas iguais,
`KeyError: 57`, e pedir uma cotação para Alagoas direto à green reproduz o erro. A green continua lá
para ser examinada, fora do tráfego. A aula 11 segue esse erro até a correção.

## Quanto custa o blue-green

- **Produção em dobro.** Duas cópias completas rodam o tempo todo, ou pelo menos enquanto dura cada
  release. Para um processo pequeno isso não é nada; para uma frota é uma conta de verdade. Algumas
  equipes criam a green para o release e a removem quando o blue é aposentado.
- **Um banco só.** Os dois lados costumam dividi-lo, porque copiar os dados da produção a cada
  release não é prático. As mudanças de schema da green ficam valendo também para o blue, então a
  regra do rolling update continua: o release novo precisa funcionar com os dados que o antigo
  gravou, e o antigo com os dados que o novo grava, enquanto voltar for possível.
- **Tudo de uma vez.** A troca leva todos os clientes num passo só. O blue-green deixou a volta
  rápida; não fez nada para deixar a ida pequena. O bug acima alcançou todos os clientes durante o
  segundo que levou para alguém perceber.
- **Estado no processo.** Uma requisição em andamento no blue quando os pesos mudam termina lá; um
  cliente com a sessão guardada na memória do blue a perde. Sessões ficam num armazenamento que os
  dois lados conseguem ler.

## Depois da troca

Quando a green já atendeu o bastante para merecer confiança, o blue é o lado parado, e o próximo
release vai para o blue. As cores nunca querem dizer "antigo" e "novo"; elas dão nome a dois lugares,
e o release se alterna entre eles.
