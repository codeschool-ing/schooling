import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import Q, N, C, O, M

T, F = True, False
qs = [
Q("ex-60phjq4d", "privacy-manifest", "medium",
  ("Since 1 May 2024, what does App Store Connect do with an app that uses a required-reason API without describing the reason in its manifest?", "Desde 1º de maio de 2024, o que o App Store Connect faz com um app que usa uma API de motivo obrigatório sem descrever o motivo no manifesto?"),
  ("Apple's page on required reason API states it.", "A página da Apple sobre APIs de motivo obrigatório diz."),
  [(F, ("Accepts it and shows a warning to testers", "Aceita e mostra um aviso aos testadores"), ("Testers see nothing of the kind.", "Testadores não veem nada disso.")),
   (T, ("Does not accept it", "Não o aceita"), ("Right, in the page's words: such apps aren't accepted.", "Isso, nas palavras da página: esses apps não são aceitos.")),
   (F, ("Adds the reason automatically from the code", "Acrescenta o motivo sozinho, a partir do código"), ("Nothing infers a reason; the developer declares it.", "Nada deduz um motivo; o desenvolvedor o declara.")),
   (F, ("Lets it through but removes `UserDefaults` from the build", "Deixa passar, mas tira o `UserDefaults` do build"), ("App Store Connect does not edit a build.", "O App Store Connect não edita um build."))], drill=False),
Q("ex-549w22we", "camera-photos", "medium",
  ("Guideline 5.1.1(iii) prefers which way to get one photo from the library?", "A diretriz 5.1.1(iii) prefere qual forma de pegar uma foto da biblioteca?"),
  ("Data minimisation.", "Minimização de dados."),
  [(F, ("Full library access, asked once at launch", "Acesso total à biblioteca, pedido uma vez na abertura"), ("Full access is what the guideline asks apps to avoid where possible.", "Acesso total é o que a diretriz pede para evitar quando possível.")),
   (F, ("Copying photos to the app's server first", "Copiar as fotos para o servidor do app antes"), ("That collects more, not less.", "Isso coleta mais, não menos.")),
   (T, ("The out-of-process picker", "O seletor fora do processo"), ("Right: the app sees only what is picked.", "Isso: o app só vê o que é escolhido.")),
   (F, ("The camera, so the library is not touched at all", "A câmera, para nem tocar na biblioteca"), ("That needs a permission of its own and does not pick an existing photo.", "Isso pede uma permissão própria e não escolhe uma foto existente."))], drill=False),
Q("ex-v0zzmack", "tracking", "hard",
  ("The planner's manifest says `NSPrivacyTracking` is false. Which change would make that false statement a problem?", "O manifesto do planner diz que `NSPrivacyTracking` é falso. Qual mudança tornaria essa afirmação um problema?"),
  ("Tracking means linking with other companies' data for advertising.", "Rastrear é ligar a dados de outras empresas para publicidade."),
  [(F, ("Syncing the plan to the planner's server", "Sincronizar o plano com o servidor do planner"), ("Your own server holding your own users' plans is not tracking.", "O seu servidor com os planos dos seus usuários não é rastreamento.")),
   (T, ("Adding an ad SDK that shares an identifier with an ad network", "Acrescentar um SDK de anúncios que manda um identificador a uma rede"), ("Right: that is tracking, and the app answers for its SDKs.", "Isso: é rastreamento, e o app responde pelos seus SDKs.")),
   (F, ("Adding a camera photo to sessions", "Acrescentar foto da câmera às sessões"), ("That needs a usage string, not tracking.", "Isso pede frase de uso, não rastreamento.")),
   (F, ("Reading the free disk space", "Ler o espaço livre em disco"), ("That is a required-reason API, declared with a reason.", "Isso é uma API de motivo obrigatório, declarada com um motivo."))], drill=False),
C("ex-fst09a3d", "location", "easy",
  ("The location level that delivers updates only while someone uses the app is called When In ___.", "O nível de localização que entrega atualizações só enquanto alguém usa o app se chama When In ___."),
  ("Two levels: this one and Always.", "Dois níveis: este e o Always."),
  ["Use"], ["Use"], drill=False),
Q("ex-ywck674w", "the-denied-path", "medium",
  ("Why does a `.restricted` camera get no Settings button?", "Por que uma câmera `.restricted` não ganha botão de Ajustes?"),
  ("Who set it?", "Quem definiu?"),
  [(F, ("Settings has no camera switch on iOS", "Os Ajustes não têm chave de câmera no iOS"), ("They do, per app; it is the restriction that locks it.", "Têm, por app; é a restrição que a trava.")),
   (T, ("Somebody else set it, and the person cannot undo it", "Outra pessoa definiu, e a pessoa não desfaz"), ("Right: a Settings button would be a dead end.", "Isso: um botão de Ajustes seria um beco sem saída.")),
   (F, ("Apple forbids linking to Settings from an app", "A Apple proíbe abrir os Ajustes a partir de um app"), ("`openSettingsURLString` exists for exactly that.", "O `openSettingsURLString` existe exatamente para isso.")),
   (F, ("A restricted app is removed from the phone", "Um app restrito é tirado do telefone"), ("Only the camera is restricted; the app keeps working.", "Só a câmera é restrita; o app continua funcionando."))], drill=False),
]
