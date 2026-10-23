---
title: Três casos de dependência, decididos
version: 1
---

Três situações que todo time com dependências encontra no primeiro mês de análise de composição. Cada
uma é um branch enviado ao seu servidor de CI, e cada uma termina numa decisão argumentada a partir da
regra da primeira seção: **quebrar só pelo que quem quebrou consegue corrigir, agora.**

### Caso 1: um aviso com correção, numa dependência direta

Sai um aviso de segurança contra uma versão que você fixa, e o aviso aponta uma versão corrigida. Na
sua máquina, o jeito de simular "publicado hoje de manhã" é voltar um pin para uma versão que tem avisos
com correção. O Jinja2 3.1.4 tem três:

```
ana@vm:~/linkbox$ git switch -q -c jinja-3.1.4
ana@vm:~/linkbox$ sed -i s/jinja2==3.1.6/jinja2==3.1.4/ requirements.txt
ana@vm:~/linkbox$ git commit -q -am "jinja2 back to 3.1.4"
9:28AM INF 0 commits scanned.
9:28AM INF scanned ~14 bytes (14 bytes) in 312ms
9:28AM INF no leaks found
ana@vm:~/linkbox$ git push ci jinja-3.1.4
remote: run 2: jinja-3.1.4 at 74ee9a1        
remote: secrets: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: FAILED in 9s, the end of sca.log:        
remote:   Found 6 known vulnerabilities in 1 package        
remote:   BREAKS: jinja2 3.1.4 PYSEC-2026-1475, fixed in 3.1.5        
remote:   BREAKS: jinja2 3.1.4 PYSEC-2026-1472, fixed in 3.1.5        
remote:   BREAKS: jinja2 3.1.4 PYSEC-2026-1471, fixed in 3.1.6        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      jinja-3.1.4 -> jinja-3.1.4
```

**Decisão: quebrar.** O pin é uma linha num arquivo que o desenvolvedor controla, a versão corrigida
está escrita no log, e trocá-la é uma mudança de uma linha mais uma rodada dos testes. Nada disso está
fora do alcance dele, então a regra diz quebrar, e o build quebrou.

O gate nunca leu uma severidade, e isso é deliberado, não esquecimento. O JSON do pip-audit não traz
nota. O motivo mais forte é que a severidade não muda o passo: um crítico com correção e um baixo com
correção estão ambos a um pin de distância. Um gate que deixasse os baixos passarem acumularia
correções de uma linha que ninguém agenda. A severidade importa quando a correção é cara, que é o
terceiro caso.

### Caso 2: um aviso que ninguém consegue corrigir

Um branch acrescenta um pacote para verificar as assinaturas dos webhooks recebidos, na versão mais
recente:

```
ana@vm:~/linkbox$ git switch -q main && git switch -q -c ecdsa
ana@vm:~/linkbox$ echo ecdsa==0.19.2 >>requirements.txt
ana@vm:~/linkbox$ git commit -q -am "ecdsa, to check the signatures of incoming webhooks"
9:28AM INF 0 commits scanned.
9:28AM INF scanned ~14 bytes (14 bytes) in 207ms
9:28AM INF no leaks found
ana@vm:~/linkbox$ git push ci ecdsa
remote: run 3: ecdsa at 17d63ac        
remote: secrets: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: WARNING in 10s, the end of sca.log:        
remote:   Found 2 known vulnerabilities in 1 package        
remote:   warns: ecdsa 0.19.2 PYSEC-2026-1325, no fixed version yet        
remote: build: passed in 1s        
remote: pipeline passed with 1 warning(s)        
remote: run 3: passed        
To /home/ana/ci/linkbox.git
 * [new branch]      ecdsa -> ecdsa
```

**Decisão: alertar.** Não existe versão para onde ir, então quebrar o build pararia todo push do
projeto até outra pessoa publicar uma versão, o que talvez nunca aconteça. O alerta é impresso com o
fim do log e contado na última linha, então não é uma aprovação.

Um alerta ainda precisa de uma pessoa que leia o aviso e decida se ele se aplica. O texto:

```
ana@vm:~/linkbox$ pip-audit -r requirements.txt -f json 2>/dev/null | jq -r ".dependencies[] | select(.name == \"ecdsa\") | .vulns[0].description"
python-ecdsa has been found to be subject to a Minerva timing attack on the P-256 curve. Using the `ecdsa.SigningKey.sign_digest()` API function and timing signatures an attacker can leak the internal nonce which may allow for private key discovery. Both ECDSA signatures, key generation, and ECDH operations are affected. ECDSA signature verification is unaffected. The python-ecdsa project considers side channel attacks out of scope for the project and there is no planned fix.
```

As duas últimas frases resolvem a leitura. A falha está na assinatura, um canal lateral pelo qual o
tempo das assinaturas vaza a chave privada, e **a verificação não é afetada** ("signature verification
is unaffected"). Um serviço que só confere assinaturas feitas por outros não tem chave privada a vazar.
Essa decisão fica escrita junto com o alerta, por quem é o dono dele, e é revista quando o aviso mudar.
A outra metade do aviso, de que o projeto considera canais laterais fora do escopo e não planeja
correção, é um fato sobre o pacote e não sobre este branch, e a aula 15 a retoma como motivo para
substituir uma dependência.

### Caso 3: uma correção que não pode entrar hoje

De volta ao Jinja2. Suponha que ir para a 3.1.6 quebrasse templates que o time precisa de duas semanas
para refazer. O build está quebrado por um achado que tem correção em princípio, mas não nesta semana.
Quebrar todo push por duas semanas faz o gate ser desligado; ignorar o aviso para sempre o esquece.
**Uma exceção é a terceira opção: o aviso, o último dia em que vale, e o porquê.** Acrescente uma linha
por aviso a `ci/exceptions.txt`, no branch:

```
ana@vm:~/linkbox$ git switch -q jinja-3.1.4
ana@vm:~/linkbox$ tail -n 3 ci/exceptions.txt
PYSEC-2026-1475 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
PYSEC-2026-1472 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
PYSEC-2026-1471 2026-11-20 templates need rework for 3.1.6; Ana, see issue 41
ana@vm:~/linkbox$ git commit -q -am "jinja2 3.1.4 excepted for four weeks, while the templates are reworked"
9:29AM INF 0 commits scanned.
9:29AM INF scanned ~234 bytes (234 bytes) in 295ms
9:29AM INF no leaks found
ana@vm:~/linkbox$ git push ci jinja-3.1.4
remote: run 4: jinja-3.1.4 at f7d51a9        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 8s        
remote: build: passed in 1s        
remote: pipeline passed with 0 warning(s)        
remote: run 4: passed        
To /home/ana/ci/linkbox.git
   74ee9a1..f7d51a9  jinja-3.1.4 -> jinja-3.1.4
ana@vm:~/linkbox$ cat ~/ci/runs/4/logs/sca.log
Found 6 known vulnerabilities in 1 package
excepted until 2026-11-20: jinja2 3.1.4 PYSEC-2026-1475
excepted until 2026-11-20: jinja2 3.1.4 PYSEC-2026-1472
excepted until 2026-11-20: jinja2 3.1.4 PYSEC-2026-1471
```

**Decisão: passar, até 20 de novembro.** O log diz *excepted until*, não *no advisories*, então o aviso
fica visível em toda execução. Cada linha nomeia um aviso e não o pacote: um quarto aviso publicado
contra o Jinja2 3.1.4 na semana que vem não está coberto, e quebra o build como qualquer outro.

Então o tempo passa. O gate alerta na última semana de uma exceção, para que a data seja vista antes de
chegar. Aqui está ela com a data movida para quatro dias depois da gravação:

```
ana@vm:~/linkbox$ sed -i 's/ 2026-11-20 / 2026-10-27 /' ci/exceptions.txt
ana@vm:~/linkbox$ bash ci/sca.sh; echo "exit $?"
Found 6 known vulnerabilities in 1 package
excepted until 2026-10-27: jinja2 3.1.4 PYSEC-2026-1475
excepted until 2026-10-27: jinja2 3.1.4 PYSEC-2026-1472
excepted until 2026-10-27: jinja2 3.1.4 PYSEC-2026-1471
exit 3
```

E no dia seguinte à data, a exceção é ignorada e o achado volta a quebrar o build, como se nunca tivesse
tido exceção:

```
ana@vm:~/linkbox$ sed -i 's/ 2026-10-27 / 2026-10-22 /' ci/exceptions.txt
ana@vm:~/linkbox$ bash ci/sca.sh; echo "exit $?"
Found 6 known vulnerabilities in 1 package
BREAKS: jinja2 3.1.4 PYSEC-2026-1475, fixed in 3.1.5
BREAKS: jinja2 3.1.4 PYSEC-2026-1472, fixed in 3.1.5
BREAKS: jinja2 3.1.4 PYSEC-2026-1471, fixed in 3.1.6
exit 1
ana@vm:~/linkbox$ git checkout -q ci/exceptions.txt
```

**Nada renova uma exceção a não ser um commit novo**: uma data nova e um motivo novo, lidos por quem
revisa como qualquer outra mudança. Essa é a propriedade que uma baseline, duas seções adiante, não
tem.
