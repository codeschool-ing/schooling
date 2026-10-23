---
title: A varredura na execução noturna, e a varredura que não roda aqui
version: 1
---

A varredura funciona e o build a obedece. Falta decidir onde ela roda, e a aula 2 deixou a regra:
**uma checagem vai para todo push só se for rápida o bastante para ninguém esperar por ela.** O
estágio dinâmico não é. Ele precisa da imagem construída, de um contêiner no ar, do runtime Java do
ZAP de pé e de um spider que rastreia por até um minuto. Nesta máquina o estágio leva uns vinte
segundos contra um serviço de quatro URLs, e os testes levam um segundo.

Então o `dast` vai para a lista noturna, ao lado do rebuild da aula 2. Isso custa pouco aqui, porque
as três regras de cabeçalho têm um gêmeo rápido: o teste unitário da seção anterior falha em todo
push que remove um cabeçalho, e a varredura confirma toda noite que a imagem, construída e iniciada,
ainda os manda. Salve a lista como `ci/nightly`:

```
# The checks too slow to wait for on every push. They run once a day on
# main, after everything in ci/stages has passed.
rebuild
dast
```

### Commit, push e a execução noturna

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git status --short
M  app.py
A  ci/dast.sh
M  ci/nightly
A  ci/zap-rules.conf
M  tests/test_app.py
ana@vm:~/linkbox$ git commit -q -m "the security headers the baseline scan asked for, and the scan in the nightly run"
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 2034326        
remote: test: passed in 1s        
remote: sast: passed in 2s        
remote: build: passed in 1s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   3afa289..2034326  main -> main
```

O push rodou o `ci/stages`: testes, análise estática, build. O teste novo rodou com os outros, e
nenhuma varredura rodou. A lista noturna roda uma vez por dia na main; à mão, é o mesmo executor com
a lista como argumento:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/nightly
rebuild: passed in 11s
dast: passed in 20s
pipeline passed
ana@vm:~/linkbox$ grep -v ^PASS ci-logs/dast.log
2026-10-23 04:48:03,393 Unable to copy yaml file to /zap/wrk/zap.yaml [Errno 30] Read-only file system: '/zap/wrk/zap.yaml'
Using the Automation Framework
Total of 4 URLs
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-staging-8489-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
```

O rebuild levou onze segundos, construindo a imagem sem cache, e a varredura vinte. À mão, sem
`CI_COMMIT` definido, a varredura leu `linkbox:dev`, a imagem que o último build manual fez; no
servidor de CI ela lê `linkbox:<commit>`, a imagem que o push daquele commit construiu. O log dela
diz o que a execução à mão disse: um WARN, para o 10031, e 60 regras aprovadas.

### Varredura ativa: o que é

O ZAP tem um segundo modo, e é nele que as pessoas costumam pensar quando dizem "DAST". **Uma
varredura ativa manda requisições feitas para o aplicativo falhar.** Depois que o spider achou as
páginas, o scanner ativo pega cada parâmetro de cada requisição achada e manda variações dele:
valores que quebrariam uma consulta SQL, um template, um caminho de arquivo ou um comando de shell se
o aplicativo os pusesse ali sem proteção. Depois lê as respostas em busca dos sinais de cada falha,
como um erro de banco, uma demora ou o próprio valor refletido onde não deveria. O
`zap-full-scan.py` da mesma imagem é isso: o spider, depois a varredura ativa, depois o relatório.

Ela acha o que a baseline não acha, porque vai procurar. Também faz o que um atacante faz, menos a
intenção, e isso tem consequências para onde ela pode rodar:

- **Ela grava.** No linkbox ela enviaria todo formulário que alcançasse, então uma varredura com o
  token encheria o banco de links feitos de strings de teste. Num serviço real ela cria contas, manda
  e-mails, faz pedidos.
- **Ela pode derrubar o serviço.** Milhares de requisições malformadas em minutos parecem um
  incidente, estouram limites de taxa e, num endpoint frágil, derrubam o serviço.
- **Ela demora.** Manda muitas requisições para cada parâmetro que acha, então num aplicativo real
  roda por muito mais tempo que a baseline, e por isso é agendada e nunca é um estágio de push.

### Para onde uma varredura ativa pode apontar

**Só para um alvo seu, feito para isso: um staging montado para a execução, sem nada real dentro.**
O staging por execução desta aula é exatamente isso, e por isso vale a pena montá-lo mesmo para uma
varredura que só lê.

Nunca produção. Uma varredura ativa grava em dados reais, pode acionar quem estiver de plantão e
pode derrubar o serviço para usuários de verdade. E nunca o sistema de outra pessoa: varrer um
serviço que você não tem autorização por escrito para testar pode ser crime em muitos países, e é
sempre uma quebra de confiança, seja qual for o motivo. Isso inclui um serviço de terceiros que o seu
aplicativo chama, a implantação de um cliente e "só uma olhadinha" num concorrente.

Quando um time roda uma, ela vai para a lista noturna, contra o mesmo staging descartável que a
baseline usa, com um arquivo de regras próprio decidindo o que falha. **Este curso não roda varredura
ativa**: a lista noturna do linkbox roda só a baseline, e tudo o que está acima sobre o modo ativo
vem da documentação do ZAP, não de uma execução nesta máquina.

### O que nenhuma varredura daqui alcança

A baseline achou quatro URLs. `POST /links` não é uma delas, porque pede o token, e por isso nada
atrás do token foi varrido. O ZAP consegue se autenticar: um arquivo de contexto passado com `-n` e
um usuário indicado com `-U`, ou um cabeçalho acrescentado a toda requisição que ele manda. Este
pipeline não faz isso, e o curso não executa isso. Uma varredura autenticada vê o que um usuário
logado vê, e uma varredura ativa autenticada pode fazer o que um usuário logado pode fazer, inclusive
apagar. **Enquanto o scanner não consegue entrar, o que ele relata é só a superfície anônima**, e um
resultado limpo quer dizer "as páginas que um estranho alcança mandaram os cabeçalhos certos", e
nada além disso.
