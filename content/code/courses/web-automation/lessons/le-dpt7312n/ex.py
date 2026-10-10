import sys; sys.path.insert(0, '/tmp/lab/bin')
from exlib import *
X = []

# ---- architecture
X.append(quiz('ex-f1jc4p33', 'architecture', 'easy',
  ("Where does the code of a Playwright test run?",
   "Onde roda o código de um teste de Playwright?"),
  [("In a Node process outside the browser", "Num processo Node fora do navegador", 1,
    "Right. The test stays in Node and reaches the browser over one connection.",
    "Certo. O teste fica no Node e chega ao navegador por uma conexão."),
   ("Inside the page, beside the shop's own scripts", "Dentro da página, ao lado dos scripts da própria loja", 0,
    "That is Cypress's arrangement, from lesson 9; Playwright keeps the test out of the page.",
    "Esse é o arranjo do Cypress, da aula 9; o Playwright mantém o teste fora da página."),
   ("In a driver program such as chromedriver", "Num programa driver como o chromedriver", 0,
    "A driver program is Selenium's middle step, from lesson 8; Playwright has none.",
    "O programa driver é o passo do meio do Selenium, da aula 8; o Playwright não tem nenhum."),
   ("On a Playwright server on the internet", "Num servidor do Playwright na internet", 0,
    "Nothing leaves your machine: the test, the browser and the shop all run on it.",
    "Nada sai da sua máquina: o teste, o navegador e a loja rodam todos nela.")]))

X.append(quiz('ex-dhshhmrt', 'architecture', 'medium',
  ("`look.mjs` printed every response the moment it arrived, without asking the browser in a loop. What in Playwright's design makes that possible?",
   "O `look.mjs` imprimia cada resposta no momento em que chegava, sem perguntar ao navegador em loop. O que no projeto do Playwright torna isso possível?"),
  [("The browser sends events up the connection unasked", "O navegador manda eventos pela conexão sem que perguntem", 1,
    "Right. Commands go down and events come up on the same open connection.",
    "Certo. Comandos descem e eventos sobem pela mesma conexão aberta."),
   ("Playwright polls the page every few milliseconds", "O Playwright consulta a página a cada poucos milissegundos", 0,
    "Polling is what a one-way protocol forces on a tool; the connection here is two-way.",
    "Consultar sem parar é o que um protocolo de mão única impõe; a conexão aqui é de mão dupla."),
   ("The test runs inside the page and sees each request", "O teste roda dentro da página e vê cada requisição", 0,
    "The test runs in Node, outside the page.", "O teste roda no Node, fora da página."),
   ("The shop logs each request to Playwright", "A loja registra cada requisição para o Playwright", 0,
    "The shop's log goes to its own terminal; it knows nothing about Playwright.",
    "O registro da loja vai para o terminal dela; ela não sabe nada do Playwright.")]))

X.append(matching('ex-8w4mch6m', 'architecture', 'medium',
  ("Match each tool, or browser, to how a test reaches it.",
   "Ligue cada ferramenta, ou navegador, a como um teste chega até ela."),
  [("Selenium WebDriver", "Selenium WebDriver", "One HTTP request per command, to a driver", "Uma requisição HTTP por comando, a um driver"),
   ("Cypress", "Cypress", "The test is loaded into the browser itself", "O teste é carregado no próprio navegador"),
   ("Playwright with Chromium", "Playwright com Chromium", "One open connection speaking CDP", "Uma conexão aberta falando CDP"),
   ("Playwright with Firefox", "Playwright com Firefox", "A patched build with its own protocol", "Uma build modificada com protocolo próprio")]))

# ---- browsers
X.append(numeric('ex-4zdbqk87', 'browsers', 'medium',
  ("`tests/contexts.spec.js` holds four tests. How many test runs does `npx playwright test --config browsers.config.js tests/contexts.spec.js` start, with all three browsers installed?",
   "O `tests/contexts.spec.js` tem quatro testes. Quantas execuções de teste `npx playwright test --config browsers.config.js tests/contexts.spec.js` inicia, com os três navegadores instalados?"),
  12, ("runs", "execuções"),
  hint=("Every project runs every test.", "Todo projeto roda todos os testes.")))

X.append(quiz('ex-d56vqk9r', 'browsers', 'medium',
  ("`npx playwright test --config browsers.config.js --project chromium tests/smoke.spec.js` answers `Project(s) \"tests/smoke.spec.js\" not found`. What is wrong?",
   "`npx playwright test --config browsers.config.js --project chromium tests/smoke.spec.js` responde `Project(s) \"tests/smoke.spec.js\" not found`. O que está errado?"),
  [("The file is missing from `tests/`", "O arquivo não está em `tests/`", 0,
    "The message is about a project name, and the name it quotes is the file.",
    "A mensagem é sobre um nome de projeto, e o nome que ela cita é o arquivo."),
   ("`--project` swallowed the file name as a second project", "O `--project` engoliu o nome do arquivo como um segundo projeto", 1,
    "Right. Write `--project=chromium`, or put the files before the option.",
    "Certo. Escreva `--project=chromium`, ou ponha os arquivos antes da opção."),
   ("`browsers.config.js` has no project called chromium", "O `browsers.config.js` não tem projeto chamado chromium", 0,
    "The same message lists the available projects, and chromium is the first.",
    "A mesma mensagem lista os projetos disponíveis, e chromium é o primeiro."),
   ("A separate config cannot be combined with --project", "Uma configuração separada não combina com --project", 0,
    "It can; the run with `--project=chromium` worked with the same config.",
    "Combina; a execução com `--project=chromium` funcionou com a mesma configuração.")]))

X.append(quiz('ex-t8bm93sy', 'browsers', 'hard',
  ("A team's users all browse with Google Chrome, and a defect appears only there. Which project setting puts that browser under the tests?",
   "Os usuários de uma equipe navegam todos com o Google Chrome, e um defeito só aparece lá. Que opção de projeto põe esse navegador sob os testes?"),
  [("`devices['Desktop Chrome']`", "`devices['Desktop Chrome']`", 0,
    "That describes a window and a user agent and still runs Playwright's own Chromium.",
    "Isso descreve uma janela e um user agent e ainda roda o Chromium do próprio Playwright."),
   ("`channel: 'chrome'`", "`channel: 'chrome'`", 1,
    "Right. A channel runs the branded browser installed on the computer.",
    "Certo. Um channel roda o navegador de marca instalado no computador."),
   ("`npx playwright install firefox`", "`npx playwright install firefox`", 0,
    "That downloads Playwright's patched Firefox, which is not Chrome at all.",
    "Isso baixa o Firefox modificado do Playwright, que nem é o Chrome."),
   ("Nothing: Chromium and Chrome are one program", "Nada: Chromium e Chrome são o mesmo programa", 0,
    "They share an engine and differ in what Google adds, which is where such a defect can live.",
    "Dividem um motor e diferem no que o Google acrescenta, e é ali que um defeito assim pode morar.")]))

# ---- contexts
X.append(quiz('ex-zvqw0pjw', 'contexts', 'easy',
  ("What is a browser context?", "O que é um contexto de navegador?"),
  [("A fresh profile inside one browser", "Um perfil novo dentro de um navegador", 1,
    "Right. Its own cookies, storage and cache, like a private window.",
    "Certo. Cookies, storage e cache próprios, como uma janela anônima."),
   ("A second browser process started for each test", "Um segundo processo de navegador iniciado para cada teste", 0,
    "The browser is started once per worker; contexts are made inside it in milliseconds.",
    "O navegador é iniciado uma vez por worker; os contextos são criados dentro dele em milissegundos."),
   ("Another name for a tab", "Outro nome para uma aba", 0,
    "A tab is a page, and a context can hold several pages.", "Uma aba é uma página, e um contexto pode ter várias páginas."),
   ("The settings in `playwright.config.js`", "As configurações do `playwright.config.js`", 0,
    "The configuration supplies options to contexts; it is not one.", "A configuração fornece opções aos contextos; não é um.")]))

X.append(quiz('ex-ezttp0tg', 'contexts', 'medium',
  ("Ana and Bia each have a context of their own. Bia opens the shop having added nothing, and her basket says 1. Why?",
   "Ana e Bia têm cada uma o seu contexto. A Bia abre a loja sem ter posto nada, e a cesta dela diz 1. Por quê?"),
  [("Bia's context shares Ana's localStorage", "O contexto da Bia divide o localStorage da Ana", 0,
    "The first test showed the opposite: Bia's page read `null`.", "O primeiro teste mostrou o contrário: a página da Bia leu `null`."),
   ("The shop keeps one basket on the server for everybody", "A loja guarda uma cesta no servidor para todo mundo", 1,
    "Right. A context isolates what the browser keeps, and the basket is not in the browser.",
    "Certo. Um contexto isola o que o navegador guarda, e a cesta não está no navegador."),
   ("A cookie from Ana's context leaked to Bia", "Um cookie do contexto da Ana vazou para a Bia", 0,
    "Both printed `[]`: the shop sets no cookie at all.", "As duas imprimiram `[]`: a loja não define cookie nenhum."),
   ("The reset in `beforeEach` did not run", "O reset do `beforeEach` não rodou", 0,
    "It ran; the banana was added after it, by Ana, in the same test.",
    "Rodou; a banana foi posta depois dele, pela Ana, no mesmo teste.")]))

X.append(quiz('ex-krpzk7vf', 'contexts', 'easy',
  ("A test writes a value into `localStorage` through the `page` fixture. The next test in the file reads it. What does it get?",
   "Um teste grava um valor no `localStorage` pelo fixture `page`. O teste seguinte do arquivo o lê. O que recebe?"),
  [("The value, because the browser is the same", "O valor, porque o navegador é o mesmo", 0,
    "The browser is the same; the context is not, and storage belongs to the context.",
    "O navegador é o mesmo; o contexto não, e o storage pertence ao contexto."),
   ("`null`, because each test gets its own context", "`null`, porque cada teste ganha o seu contexto", 1,
    "Right. That is Playwright's default, and the last test of the file shows it.",
    "Certo. Esse é o padrão do Playwright, e o último teste do arquivo mostra isso."),
   ("An error, because storage is cleared by force", "Um erro, porque o storage é apagado à força", 0,
    "Nothing is cleared; the new context simply never had the value.",
    "Nada é apagado; o contexto novo simplesmente nunca teve o valor."),
   ("The value, unless the tests run in two workers", "O valor, a não ser que os testes rodem em dois workers", 0,
    "Even in one worker each test has a new context.", "Mesmo num worker, cada teste tem um contexto novo.")]))

X.append(quiz('ex-j133swnz', 'contexts', 'medium',
  ("Which of these does a new browser context start without? Choose all that apply.",
   "Com quais destes um contexto de navegador novo começa sem? Marque todos os que se aplicam."),
  [("The cookies another context received", "Os cookies que outro contexto recebeu", 1,
    "Right. Cookies belong to the context that received them.", "Certo. Cookies pertencem ao contexto que os recebeu."),
   ("Values written to `localStorage` in another context", "Valores gravados no `localStorage` em outro contexto", 1,
    "Right. Bia's page read `null` where Ana's read `ana`.", "Certo. A página da Bia leu `null` onde a da Ana leu `ana`."),
   ("Lines added to the shop's basket by another context", "Linhas postas na cesta da loja por outro contexto", 0,
    "The basket is on the server, and every context sees the same one.", "A cesta está no servidor, e todo contexto vê a mesma."),
   ("Files cached by another context", "Arquivos guardados em cache por outro contexto", 1,
    "Right. The cache is part of the profile a context isolates.", "Certo. O cache faz parte do perfil que o contexto isola.")],
  multi=True))

X.append(ordering('ex-t1xs599s', 'contexts', 'easy',
  ("Order these from the one that holds the others to the one held.",
   "Ordene do que contém os outros para o que é contido."),
  [("browser", "navegador"), ("context", "contexto"), ("page", "página")],
  trap=("A context is inside a browser, not the other way round: one browser holds many contexts.",
        "Um contexto fica dentro de um navegador, e não o contrário: um navegador contém muitos contextos.")))

# ---- auto-waiting
X.append(quiz('ex-enjq142y', 'auto-waiting', 'medium',
  ("Straight after clicking Add to basket, `await count.textContent()` returned `0`, and `await expect(count).toHaveText('1')` then passed. Why did they disagree?",
   "Logo depois de clicar em Add to basket, `await count.textContent()` devolveu `0`, e `await expect(count).toHaveText('1')` em seguida passou. Por que discordaram?"),
  [("The click failed the first time and was retried", "O clique falhou da primeira vez e foi repetido", 0,
    "One click, one request; only the reading differed.", "Um clique, uma requisição; só a leitura diferiu."),
   ("`textContent()` reads the page once; the assertion reads until it matches", "O `textContent()` lê a página uma vez; a asserção lê até bater", 1,
    "Right. The snapshot came before the shop's answer; the assertion waited for it.",
    "Certo. A foto veio antes da resposta da loja; a asserção esperou por ela."),
   ("The count is drawn inside a frame that a plain read of the page cannot reach", "A contagem é desenhada dentro de um frame que uma leitura simples da página não alcança", 0,
    "There is no frame; the read reached the element and got its text at that instant.",
    "Não há frame; a leitura alcançou o elemento e pegou o texto daquele instante."),
   ("`toHaveText` ignores digits", "O `toHaveText` ignora dígitos", 0,
    "It compared `1` with `1`; the earlier failing run shows it comparing digits exactly.",
    "Ele comparou `1` com `1`; a execução que falhou mostra ele comparando dígitos exatamente.")]))

X.append(cloze('ex-0m93vrvt', 'auto-waiting', 'easy',
  ("With the configuration this course uses, an assertion on a locator gives up after ___ seconds, and a whole test after ___ seconds.",
   "Com a configuração que este curso usa, uma asserção sobre um localizador desiste depois de ___ segundos, e um teste inteiro depois de ___ segundos."),
  [(["5", "five"], ["5", "cinco"]), (["30", "thirty"], ["30", "trinta"])]))

X.append(quiz('ex-fqzatjb2', 'auto-waiting', 'hard',
  ("A click fails with `Test timeout of 30000ms exceeded` and a call log that only ever says `waiting for getByRole('button', { name: 'Checkout' })`. What is the first thing to suspect?",
   "Um clique falha com `Test timeout of 30000ms exceeded` e um registro de chamadas que só diz `waiting for getByRole('button', { name: 'Checkout' })`. Qual a primeira suspeita?"),
  [("The locator matches nothing on the page", "O localizador não casa com nada na página", 1,
    "Right. It never resolved; a button that existed but was covered or disabled would have been found first.",
    "Certo. Ele nunca resolveu; um botão que existisse, coberto ou desabilitado, teria sido achado antes."),
   ("The action timeout of five seconds is too short", "O timeout de ação de cinco segundos é curto demais", 0,
    "Five seconds is the assertion's clock; the click waited thirty, the whole test.",
    "Cinco segundos é o relógio da asserção; o clique esperou trinta, o teste inteiro."),
   ("The button was found but held the wrong text", "O botão foi achado, mas tinha o texto errado", 0,
    "A found element shows as `locator resolved to` in the call log.", "Um elemento achado aparece como `locator resolved to` no registro."),
   ("The browser crashed during the test", "O navegador quebrou durante o teste", 0,
    "A crashed browser fails with a different message, not a call log still waiting.",
    "Um navegador que quebra falha com outra mensagem, não com um registro ainda esperando.")]))

# ---- tracing
X.append(quiz('ex-ygyn2p3v', 'tracing', 'easy',
  ("After `npx playwright test --trace on`, where is each test's trace?",
   "Depois de `npx playwright test --trace on`, onde fica o rastro de cada teste?"),
  [("Printed in the terminal, in the summary at the end of the run", "Impresso no terminal, no resumo ao fim da execução", 0,
    "The run's output does not mention the trace at all.", "A saída da execução nem menciona o rastro."),
   ("In `playwright-report/`, inside the HTML report", "Em `playwright-report/`, dentro do relatório HTML", 0,
    "That folder is written by the HTML reporter; traces go elsewhere.", "Essa pasta é escrita pelo reporter HTML; os rastros vão para outro lugar."),
   ("A `trace.zip` in a folder per test, in `test-results/`", "Um `trace.zip` numa pasta por teste, em `test-results/`", 1,
    "Right. Each folder is named after the file and the test.", "Certo. Cada pasta tem o nome do arquivo e do teste."),
   ("On Playwright's website", "No site do Playwright", 0,
    "Nothing is uploaded; the trace is a file on your disk.", "Nada é enviado; o rastro é um arquivo no seu disco.")]))

X.append(ordering('ex-xyb0djyh', 'tracing', 'medium',
  ("Put the steps of reading a failing test's trace in order.",
   "Ponha em ordem os passos para ler o rastro de um teste que falhou."),
  [("Run the test with `--trace on`", "Rodar o teste com `--trace on`"),
   ("Find its folder in `test-results/`", "Achar a pasta dele em `test-results/`"),
   ("Open its `trace.zip` with `npx playwright show-trace`", "Abrir o `trace.zip` dele com `npx playwright show-trace`")],
  trap=("There is nothing to open before a run has recorded it.", "Não há o que abrir antes de uma execução gravar.")))

X.append(quiz('ex-4ae3fz5h', 'tracing', 'medium',
  ("Recording a trace of every test costs disk and time. What does Playwright's documentation suggest for a suite that runs on a build server?",
   "Gravar o rastro de todo teste custa disco e tempo. O que a documentação do Playwright sugere para uma suíte que roda num servidor de build?"),
  [("Never record traces on a server", "Nunca gravar rastros num servidor", 0,
    "The server is where nobody watches, so it is where a trace earns its place.",
    "O servidor é onde ninguém olha, e por isso é onde o rastro se paga."),
   ("`trace: 'on-first-retry'`, recording when a failed test is retried", "`trace: 'on-first-retry'`, gravando quando um teste que falhou é repetido", 1,
    "Right. Passing tests cost nothing, and a failure leaves its evidence.",
    "Certo. Testes que passam não custam nada, e uma falha deixa a evidência."),
   ("Screenshots only", "Só capturas de tela", 0,
    "A trace holds screenshots and also the actions, requests and console, which is why it is worth more.",
    "Um rastro guarda capturas e também ações, requisições e console, e por isso vale mais."),
   ("`--trace on` for every run", "`--trace on` em toda execução", 0,
    "That is the costly setting the question starts from.", "Essa é a opção cara de que a pergunta parte.")]))

# ---- drill
X.append(quiz('ex-b1eyxnf0', 'drill', 'hard',
  ("Two tests in different files each add a banana and expect the count to read 1. Alone, each passes. With two workers, one fails reading 2. Which change would make both pass?",
   "Dois testes em arquivos diferentes põem cada um uma banana e esperam que a contagem diga 1. Sozinho, cada um passa. Com dois workers, um falha lendo 2. Que mudança faria os dois passarem?"),
  [("Give each test its own browser context", "Dar a cada teste o seu contexto de navegador", 0,
    "They already have one each; the basket is on the server, out of a context's reach.",
    "Eles já têm um cada; a cesta está no servidor, fora do alcance de um contexto."),
   ("Run them one at a time, with one worker", "Rodá-los um de cada vez, com um worker", 1,
    "Right, for now: the shared basket is the cause, and lessons 15 and 19 deal with it properly.",
    "Certo, por enquanto: a cesta única é a causa, e as aulas 15 e 19 tratam dela de verdade."),
   ("Raise the assertion timeout to thirty seconds", "Subir o timeout da asserção para trinta segundos", 0,
    "Waiting longer does not turn a 2 into a 1.", "Esperar mais não transforma um 2 num 1."),
   ("Run them in Firefox as well", "Rodá-los no Firefox também", 0,
    "A second engine runs the same tests against the same basket.", "Um segundo motor roda os mesmos testes contra a mesma cesta.")]))

X.append(quiz('ex-dscz9v9f', 'drill', 'hard',
  ("A test passes in the chromium project and fails in webkit on a teammate's machine. Your machine has only Chromium. What is the most useful next step?",
   "Um teste passa no projeto chromium e falha no webkit na máquina de um colega. A sua máquina só tem o Chromium. Qual o próximo passo mais útil?"),
  [("Delete the webkit project, since Chromium passes", "Apagar o projeto webkit, já que o Chromium passa", 0,
    "That hides the one finding the project exists to make.", "Isso esconde o único achado para o qual o projeto existe."),
   ("Ask for the trace of the failing webkit run", "Pedir o rastro da execução webkit que falhou", 1,
    "Right. The trace holds the actions, the page and the network of that run, and opening it needs no WebKit.",
    "Certo. O rastro guarda as ações, a página e a rede daquela execução, e abri-lo não exige WebKit."),
   ("Run the chromium project again until it fails", "Rodar o projeto chromium de novo até falhar", 0,
    "The failure is in another engine; repeating this one measures nothing new.",
    "A falha está em outro motor; repetir este não mede nada novo."),
   ("Change `devices['Desktop Safari']` to `devices['Desktop Chrome']`", "Trocar `devices['Desktop Safari']` por `devices['Desktop Chrome']`", 0,
    "That turns the webkit project into a second Chromium run.", "Isso transforma o projeto webkit numa segunda execução do Chromium.")]))

L = '/home/user/schooling/content/code/courses/web-automation/lessons/le-dpt7312n'
write(L, X)
