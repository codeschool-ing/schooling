---
title: Desvio, e como ele é achado
version: 2
---

**Desvio** (*drift*) é a diferença que se acumula entre ambientes, ou entre um ambiente e a definição
dele, quando mudanças são feitas fora do pipeline. Uma configuração editada num servidor durante um
incidente, um pacote atualizado à mão, uma correção "temporária" que ninguém desfez. Cada uma
transforma um ambiente num objeto único, e um release testado num deixa de dizer qualquer coisa sobre o
outro.

Eis um desvio feito de propósito. Num fim de semana de promoção, alguém edita à mão a cópia implantada
da homologação para baixar o limite do frete grátis para R$ 190,00, querendo testar uma promoção, e a
reinicia. Nada passa pelo pipeline. Faça o mesmo, com um `sed` no arquivo implantado e o script de
reinício:

```sh
sed -i 's/FREE_FROM = 19900 /FREE_FROM = 19000 /' ~/envs/staging/current/shipquote/quote.py
ops/restart.sh staging
```

Depois os dois ambientes recebem as perguntas de sempre:

```
ana@laptop:~/shipquote$ for port in 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.5.0", "env": "staging", "carrier": "http://127.0.0.1:9091"}
{"version": "1.5.0", "env": "production", "carrier": "http://127.0.0.1:9092"}
ana@laptop:~/shipquote$ for port in 8200 8300; do curl -s "http://127.0.0.1:$port/quote?cep=69005-010&weight=5000&subtotal=19800"; echo; done
{"cep": "69005-010", "zone": "N", "cents": 0, "price": "R$ 0,00"}
{"cep": "69005-010", "zone": "N", "cents": 3000, "price": "R$ 30,00"}
ana@laptop:~/shipquote$ diff -r -x __pycache__ ~/envs/staging/current ~/envs/production/current
diff -r -x __pycache__ /home/ana/envs/staging/current/shipquote/quote.py /home/ana/envs/production/current/shipquote/quote.py
8c8
< FREE_FROM = 19000         # an order of R$ 199,00 or more ships free
---
> FREE_FROM = 19900         # an order of R$ 199,00 or more ships free
ana@laptop:~/shipquote$ ops/deploy.sh staging dist/shipquote-1.5.0.tar.gz && diff -r -x __pycache__ ~/envs/staging/current ~/envs/production/current && echo "no differences"
smoke: http://127.0.0.1:8200 is up and running 1.5.0
no differences
```

**Os dois dizem que são a versão 1.5.0**, e não rodam o mesmo código: para um pedido de R$ 198,00 até
Manaus, a homologação não cobra nada e a produção cobra R$ 30,00. O `/version` não vê a diferença,
porque o carimbo vem do artefato e a edição veio depois dele. Comparar as duas árvores implantadas vê:
o `diff` nomeia o arquivo e a linha. Implantar o artefato de novo **pelo pipeline** devolve a
homologação ao normal, e a mesma comparação então não acha diferença nenhuma.

## Por que o desvio é perigoso

O desvio é invisível de fora, como mostram as respostas idênticas de `/version`. Uma equipe que testa
na homologação e encontra um comportamento diferente na produção começa a depurar o código, quando o
código é justamente a única coisa igual. Pior, a edição à mão se perde na próxima vez que alguém
implanta, então uma correção de que alguém dependia some sem um commit para dizer que ela existiu.

## Como as equipes evitam e acham

- **Fazer do pipeline o único jeito de mudar um ambiente.** Os arquivos implantados não deveriam ser
  graváveis por pessoas; em plataformas de contêiner, a imagem é somente leitura por construção.
- **Reconstruir em vez de consertar.** Um ambiente que pode ser recriado a partir da definição em
  minutos pode ser recriado sempre que houver suspeita de desvio.
- **Comparar com a definição, como rotina.** O `diff` acima é a ideia; ferramentas de infraestrutura
  como código fazem o mesmo em escala, relatando o que difere do que está declarado. Na trilha
  `devops`, `iac` e `gitops` se apoiam exatamente nisso.
- **Informar mais que a versão.** Um programa implantado pode informar o hash do próprio artefato além
  da tag, para dois ambientes que dizem ter a mesma versão poderem ser conferidos quanto aos mesmos
  bytes.
