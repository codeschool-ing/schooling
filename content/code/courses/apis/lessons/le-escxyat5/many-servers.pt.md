---
title: Mais de um servidor
version: 1
---

**Todo contador do `limits.py` é um dicionário na memória de um processo, e isso está certo para
exatamente um processo.** Uma API de verdade roda várias cópias de si atrás de um balanceador de carga,
para que uma possa falhar ou ser trocada sem a API cair. Cada cópia então tem o próprio `LIMITS`, e
cada uma aplica o limite à parte das requisições do cliente que por acaso chega até ela.

Duas cópias do `limits.py` mostram isso. Deixe a primeira rodando na porta 8000 e inicie uma segunda
num terceiro terminal, na porta 8001:

```sh
cd ~/shelf && python3 limits.py bucket 8001
```

Vinte requisições com a chave free, todas para a primeira cópia, e depois, passados dez segundos para o
balde dela encher de novo, mais vinte alternando entre as duas portas do jeito que um balanceador
round-robin as mandaria:

```
ana@api:~/shelf$ for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code} ' -H 'X-API-Key: demo-bia' localhost:8000/books; done; echo
200 200 200 200 200 200 200 200 200 200 429 429 429 429 429 429 429 429 429 429 
ana@api:~/shelf$ sleep 10; for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code} ' -H 'X-API-Key: demo-bia' localhost:$((8000 + i % 2))/books; done; echo
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
```

Uma cópia sozinha permitiu dez, o balde dela. Duas cópias permitiram as vinte: cada uma viu dez
requisições e tinha dez fichas para elas. **Com N cópias, um cliente recebe N vezes o limite**, e nada
na visão de nenhuma cópia parece errado. Fica mais estranho quando o balanceador não é round-robin: um
cliente cujas requisições caem quase todas numa cópia é recusado ali enquanto o balde dele na outra
cópia está cheio.

Reiniciar tem a mesma raiz. `Ctrl+C` e inicie de novo, e todo balde do processo está cheio outra vez;
toda implantação de uma versão nova dá a cada cliente uma cota zerada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Em cima: um cliente envia vinte requisições por um balanceador de carga para duas cópias do limits.py, cada uma com seu próprio balde de dez na memória; cada cópia aceita dez, então as vinte são aceitas. Embaixo: as duas cópias guardam o contador num armazenamento compartilhado, então o cliente tem um só balde de dez e dez são aceitas.\"><defs><marker id=\"l12-lb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"90\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><text x=\"65.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20 requisições</text><rect x=\"150\" y=\"50\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">balanceador</text><line x1=\"110\" y1=\"70\" x2=\"148\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"25\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia 1</text><text x=\"370.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">balde próprio de 10</text><line x1=\"260\" y1=\"70\" x2=\"308\" y2=\"43\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"80\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia 2</text><text x=\"370.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">balde próprio de 10</text><line x1=\"260\" y1=\"70\" x2=\"308\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><text x=\"560\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">20 aceitas:</text><text x=\"560\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o dobro do limite</text><rect x=\"20\" y=\"180\" width=\"90\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><text x=\"65.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20 requisições</text><rect x=\"150\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">balanceador</text><line x1=\"110\" y1=\"200\" x2=\"148\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"155\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia 1</text><text x=\"370.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem contadores</text><line x1=\"260\" y1=\"200\" x2=\"308\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"310\" y=\"210\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia 2</text><text x=\"370.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem contadores</text><line x1=\"260\" y1=\"200\" x2=\"308\" y2=\"228\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><rect x=\"480\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">armazenamento</text><text x=\"535.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um balde de 10</text><line x1=\"430\" y1=\"173\" x2=\"478\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><line x1=\"430\" y1=\"228\" x2=\"478\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-lb-ah)\"></line><text x=\"650\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">10 aceitas</text></svg>", "caption": "Contadores em cada cópia somam N vezes o limite; um armazenamento compartilhado o mantém em um."}
```

## Um armazenamento que todas as cópias dividem

A correção é guardar os contadores fora das cópias, num armazenamento que todas consultam. Na prática
esse armazenamento é quase sempre o **Redis**, um banco de dados em memória feito para valores pequenos
que muitos clientes mudam ao mesmo tempo, e o `servers-cache`, o próximo curso, é onde ele é instalado e
usado. O que importa aqui é o que o limitador precisa de um armazenamento assim, porque é o mesmo
qualquer que seja ele:

- **A verificação e a atualização têm de ser uma operação só.** Duas cópias que leem "uma ficha
  sobrando" e depois gravam "zero" atenderam, as duas, uma requisição com a mesma ficha. Na memória é
  isso que o `LOCK` impede; entre máquinas, o armazenamento tem de fazê-lo, executando a leitura e a
  escrita num único passo.
- **Cada contador expira sozinho.** Um cliente que nunca volta não deve manter um balde no
  armazenamento para sempre; o armazenamento apaga a chave depois que a janela dela passou.
- **Uma ida e volta em toda requisição.** O limitador agora consulta outra máquina antes de cada
  resposta. É rápido, e nunca é de graça, e um armazenamento fora do ar deixa uma decisão a tomar:
  recusar tudo, o que transforma uma queda do cache numa queda da API, ou permitir tudo, o que a
  transforma em limite nenhum. A maioria das APIs escolhe permitir, e registrar isso em alto e bom som.

## Exato ou aproximado

Um armazenamento compartilhado torna o limite exato e faz toda requisição passar por um lugar só. A
alternativa é deixar cada cópia manter os próprios contadores com **o limite dividido pelo número de
cópias**, duas cópias com cinco fichas cada, e aceitar o erro. Não precisa de armazenamento e sobrevive
a perdê-lo, e erra exatamente quando o tráfego é desigual entre as cópias: um cliente cujas requisições
caem todas numa cópia recebe metade do limite. Entre os dois ficam esquemas em que cada cópia conta
localmente e informa o armazenamento compartilhado de tempos em tempos, trocando alguns segundos de
excesso por muito menos idas e voltas.

**Para um limite que protege o serviço, aproximado costuma bastar**: o objetivo é impedir o cliente de
mandar mil por segundo, e se ele foi parado em 100 ou em 110 não importa. **Para uma cota que um
cliente paga, o exato vale a ida e volta**, porque o número da fatura e o número da recusa têm de
concordar.
