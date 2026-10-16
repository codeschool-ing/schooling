# The course exam: about ten questions a lesson, drawn twenty at a time.
# python3 lab/tools/exb.py lab/exercises/exam.py . --exam -v

# ---- lesson 1
Q("ex-m8rddqjb", 1, "easy",
  "What makes a program a learned model rather than a rule somebody wrote?",
  "O que faz de um programa um modelo aprendido e não uma regra que alguém escreveu?",
  [("It runs on a GPU", "Roda numa GPU", False, "Hardware is not the difference.", "O hardware não é a diferença."),
   ("Its rule was fitted from examples", "A regra dele foi ajustada a partir de exemplos", True,
    "Right. Nobody wrote the threshold; the data set it.", "Isso. Ninguém escreveu o limiar; os dados o definiram."),
   ("It is written in Python", "É escrito em Python", False, "A rule in Python is still a rule.", "Uma regra em Python continua sendo regra."),
   ("It never makes a mistake", "Nunca erra", False, "Learned models make mistakes, measurably.", "Modelos aprendidos erram, de forma mensurável.")])

P("ex-s3qrqapp", 1, "easy",
  "Match each kind of learning to what it learns from.",
  "Associe cada tipo de aprendizado ao que ele usa para aprender.",
  [("supervised", "supervisionado", "answers already known", "respostas já conhecidas"),
   ("unsupervised", "não supervisionado", "the data alone, with no answer", "só os dados, sem resposta"),
   ("reinforcement", "por reforço", "the result of its own actions", "o resultado das próprias ações")],
  [("a rule written by an analyst", "uma regra escrita por um analista")])

Q("ex-vceg08ay", 1, "medium",
  "Marketing wants to know which members will stop buying. Which kind of learning fits?",
  "O marketing quer saber quais membros vão parar de comprar. Que tipo de aprendizado serve?",
  [("Unsupervised, because nobody has labelled the members", "Não supervisionado, porque ninguém rotulou os membros", False,
    "The past already labels them: who stopped and who did not.", "O passado já os rotula: quem parou e quem não parou."),
   ("Supervised, from known outcomes", "Supervisionado, por desfechos conhecidos", True,
    "Right. History provides the answers.", "Isso. O histórico fornece as respostas."),
   ("Reinforcement, sending vouchers until it works", "Por reforço, mandando cupons até funcionar", False,
    "That answers a different question, which offer works.", "Isso responde outra pergunta, qual oferta funciona."),
   ("None: a fixed rule is always enough", "Nenhum: uma regra fixa sempre basta", False,
    "Sometimes a rule is enough, not always.", "Às vezes uma regra basta, nem sempre.")])

Q("ex-w27k4gp7", 1, "medium",
  "Why does the course draw the shop with generate.py and a fixed seed?",
  "Por que o curso desenha a loja com o generate.py e uma semente fixa?",
  [("Real data would be too large to download", "Dados reais seriam grandes demais para baixar", False,
    "Size is not the reason.", "Tamanho não é o motivo."),
   ("So every copy is identical", "Para toda cópia ser idêntica", True,
    "Right. The numbers in the lessons are the numbers on your machine.", "Isso. Os números das lições são os da sua máquina."),
   ("A seed makes the model more accurate", "Uma semente deixa o modelo mais preciso", False,
    "The seed decides the data, not the accuracy.", "A semente decide os dados, não a precisão."),
   ("SQLite requires a seed", "O SQLite exige uma semente", False,
    "SQLite knows nothing of seeds.", "O SQLite não sabe nada de sementes.")])

Q("ex-h9s1ytdq", 1, "easy",
  "Where does the course recommend running the lab?",
  "Onde o curso recomenda rodar o laboratório?",
  [("On the student's own computer", "No computador do próprio aluno", True,
    "Right. Installed directly, with a VM or an online machine as the other paths.",
    "Isso. Instalado direto, com VM ou máquina online como os outros caminhos."),
   ("On a paid cloud cluster", "Num cluster pago na nuvem", False,
    "Nothing in the course needs one.", "Nada no curso precisa de um."),
   ("On a shared university server", "Num servidor compartilhado de universidade", False,
    "The course assumes no such server.", "O curso não supõe esse servidor."),
   ("Inside the browser only", "Só dentro do navegador", False,
    "The lab runs Python and SQLite locally.", "O laboratório roda Python e SQLite localmente.")])

N("ex-znmnmfx0", 1, "easy",
  "How many members does the shop drawn by generate.py hold on 28 February 2026?",
  "Quantos membros tem a loja desenhada pelo generate.py em 28 de fevereiro de 2026?",
  4558, 0, "members", "membros")

Q("ex-9pwanarx", 1, "hard",
  "Which question needs no model at all?",
  "Qual pergunta não precisa de modelo nenhum?",
  [("Which members are likely to lapse next quarter", "Quais membros devem se afastar no próximo trimestre", False,
    "That is a prediction from history.", "Isso é uma predição a partir do histórico."),
   ("How many books were sold last month", "Quantos livros foram vendidos no mês passado", True,
    "Right. A query counts it exactly.", "Isso. Uma consulta conta isso com exatidão."),
   ("Which groups of members behave alike", "Que grupos de membros se comportam parecido", False,
    "That is clustering.", "Isso é agrupamento."),
   ("Which book to suggest next", "Que livro sugerir em seguida", False,
    "That is recommendation.", "Isso é recomendação.")])

M("ex-498pjff6", 1, "medium",
  "Which of these does the course install in the student's environment? Choose every one that applies.",
  "Quais destes o curso instala no ambiente do aluno? Escolha todos os que se aplicam.",
  [("scikit-learn", "scikit-learn", True, "Right. From lesson 1.", "Isso. Desde a lição 1."),
   ("MLflow", "MLflow", True, "Right. From lesson 7.", "Isso. Desde a lição 7."),
   ("FastAPI", "FastAPI", True, "Right. From lesson 8.", "Isso. Desde a lição 8."),
   ("a paid cloud SDK", "um SDK pago de nuvem", False, "Nothing paid is needed.", "Nada pago é necessário.")])

# ---- lesson 2
Q("ex-zjy7gn7e", 2, "easy",
  "Predicting how much a member will spend next quarter is which task?",
  "Prever quanto um membro vai gastar no próximo trimestre é que tarefa?",
  [("Classification", "Classificação", False, "The answer is an amount, not a class.", "A resposta é um valor, não uma classe."),
   ("Clustering", "Agrupamento", False, "There is a known answer to learn.", "Há uma resposta conhecida para aprender."),
   ("Regression", "Regressão", True, "Right. An amount.", "Isso. Um valor."),
   ("Recommendation", "Recomendação", False, "Nothing is being suggested.", "Nada está sendo sugerido.")])

Q("ex-ptq012kd", 2, "medium",
  "Why does every score in lesson 2 come with a baseline beside it?",
  "Por que toda nota da lição 2 vem com uma linha de base ao lado?",
  [("A score alone means little", "Uma nota sozinha diz pouco", True,
    "Right. 179.49 is only good next to 213.76.", "Isso. 179,49 só é bom ao lado de 213,76."),
   ("Baselines are required by scikit-learn", "O scikit-learn exige linhas de base", False,
    "The library requires nothing of the kind.", "A biblioteca não exige nada disso."),
   ("Baselines make the model faster", "Linhas de base deixam o modelo mais rápido", False,
    "They change no model.", "Elas não mudam modelo nenhum."),
   ("The baseline is the model used in production", "A linha de base é o modelo de produção", False,
    "It is the thing to beat, not the thing to ship.", "É o que se deve vencer, não o que se publica.")])

N("ex-ns1txt66", 2, "medium",
  "What mean absolute error, in reais, did the regression reach on next quarter's spend?",
  "Que erro absoluto médio, em reais, a regressão atingiu no gasto do próximo trimestre?",
  179.49, 0.01, "R$", "R$")

Q("ex-paj4cj73", 2, "medium",
  "How does the course choose how many groups k-means should make?",
  "Como o curso escolhe quantos grupos o k-means deve fazer?",
  [("It asks marketing", "Pergunta ao marketing", False, "It measures first.", "Ele mede primeiro."),
   ("The number that maximises the silhouette", "O número que maximiza a silhueta", True,
    "Right. It peaked at eight groups.", "Isso. Ela chegou ao máximo em oito grupos."),
   ("Always the square root of the members", "Sempre a raiz quadrada dos membros", False,
    "No fixed formula is used.", "Nenhuma fórmula fixa é usada."),
   ("The number with the lowest inertia", "O número com menor inércia", False,
    "Inertia always falls as k grows.", "A inércia sempre cai quando k cresce.")])

Q("ex-dd5av3b1", 2, "hard",
  "One-hot encoding turns a shop name into what?",
  "A codificação one-hot transforma o nome de uma loja em quê?",
  [("A number from 1 to 7, one per shop", "Um número de 1 a 7, um por loja", False,
    "That would invent an order between shops.", "Isso inventaria uma ordem entre lojas."),
   ("The shop's average spend", "O gasto médio da loja", False,
    "That is target encoding, not one-hot.", "Isso é codificação pelo alvo, não one-hot."),
   ("A column per shop, 1 in its own", "Uma coluna por loja, 1 na sua", True,
    "Right. No order is invented.", "Isso. Nenhuma ordem é inventada."),
   ("A hash of the shop's name", "Um hash do nome da loja", False,
    "Hashing is another technique.", "Hash é outra técnica.")])

N("ex-h54kj52f", 2, "medium",
  "What hit rate, in percent, did the co-purchase recommender reach?",
  "Que taxa de acerto, em porcentagem, o recomendador por compras conjuntas atingiu?",
  67.1, 0.1, "%", "%")

Q("ex-h55m6hqs", 2, "medium",
  "What does a classifier's probability give the platform that its yes-or-no answer does not?",
  "O que a probabilidade de um classificador dá à plataforma que o sim ou não não dá?",
  [("A ranking, cut later", "Uma ordem, cortada depois", True,
    "Right. Lesson 4 picks the threshold from costs.", "Isso. A lição 4 escolhe o limiar pelos custos."),
   ("A guarantee the answer is right", "Uma garantia de que acertou", False,
    "A probability guarantees nothing.", "Uma probabilidade não garante nada."),
   ("A faster prediction", "Uma predição mais rápida", False, "Speed is the same.", "A velocidade é a mesma."),
   ("Nothing; they are the same", "Nada; são iguais", False, "The probability carries more.", "A probabilidade carrega mais.")])

O("ex-8m5958dj", 2, "medium",
  "Order the lesson's recommendation methods from the weakest hit rate to the strongest.",
  "Ordene os métodos de recomendação da lição da menor taxa de acerto para a maior.",
  [("random titles", "títulos aleatórios"), ("the bestsellers", "os mais vendidos"),
   ("co-purchase", "compras conjuntas")])

# ---- lesson 3
Q("ex-yj16xgkh", 3, "easy",
  "What is data leakage?",
  "O que é vazamento de dados?",
  [("A breach that exposes members' data", "Uma invasão que expõe dados dos membros", False,
    "That is a security incident, another subject.", "Isso é incidente de segurança, outro assunto."),
   ("Training on the future", "Treinar com o futuro", True,
    "Right. The model then scores well on paper and badly in production.",
    "Isso. Aí o modelo vai bem no papel e mal em produção."),
   ("Losing rows during a join", "Perder linhas numa junção", False, "That is a bug, not leakage.", "Isso é bug, não vazamento."),
   ("Overfitting to noise", "Sobreajustar ao ruído", False, "Related, but a different failure.", "Relacionado, mas outra falha.")])

N("ex-4k5993z3", 3, "medium",
  "What test AUC did the leaky model that used recency from today's summary table reach?",
  "Que AUC de teste o modelo com vazamento, que usou a recência da tabela de hoje, atingiu?",
  0.994, 0, "", "")

Q("ex-qzbgjjx9", 3, "medium",
  "Why does lesson 3 keep three sets, not two?",
  "Por que a lição 3 mantém três conjuntos, e não dois?",
  [("A score used to choose is not a test", "Uma nota usada para escolher não é teste", True,
    "Right. Validation chooses; the test is touched once.", "Isso. A validação escolhe; o teste é tocado uma vez."),
   ("Three sets train faster", "Três conjuntos treinam mais rápido", False, "Speed is not the reason.", "Velocidade não é o motivo."),
   ("scikit-learn needs three", "O scikit-learn precisa de três", False, "It needs nothing of the kind.", "Não precisa disso."),
   ("To have more training data", "Para ter mais dados de treino", False, "A third set takes data away from training.", "Um terceiro conjunto tira dados do treino.")])

Q("ex-mxy13cbk", 3, "hard",
  "A model predicts lapse over 90 days and is deployed on 30 November. What is the newest training cutoff it may use?",
  "Um modelo prevê afastamento em 90 dias e entra em produção em 30 de novembro. Qual o corte de treino mais novo que ele pode usar?",
  [("29 November", "29 de novembro", False, "Its label would still be open for 89 days.", "O rótulo dele ainda ficaria aberto por 89 dias."),
   ("31 October", "31 de outubro", False, "Its label closes on 29 January.", "O rótulo dele fecha em 29 de janeiro."),
   ("About 31 August", "Por volta de 31 de agosto", True,
    "Right. Ninety days before deployment, so every label has closed.", "Isso. Noventa dias antes, para todo rótulo ter fechado."),
   ("Any day, if the model is retrained nightly", "Qualquer dia, se o modelo for retreinado toda noite", False,
    "Nightly retraining uses unfinished labels.", "Retreinar toda noite usa rótulos inacabados.")])

Q("ex-0j7eyyhh", 3, "medium",
  "Why is a scaler fitted on all the rows before the split a leak?",
  "Por que um escalonador ajustado em todas as linhas antes da divisão é um vazamento?",
  [("Scaling changes the labels", "Escalonar muda os rótulos", False, "Labels are untouched.", "Os rótulos não são tocados."),
   ("Test rows shaped training", "O teste moldou o treino", True,
    "Right. Their mean and spread leaked in.", "Isso. A média e a dispersão delas vazaram."),
   ("Scalers cannot handle categories", "Escalonadores não lidam com categorias", False, "True, but not the leak.", "Verdade, mas não é o vazamento."),
   ("It makes training slower", "Deixa o treino mais lento", False, "Speed is not the issue.", "Velocidade não é a questão.")])

C("ex-bwm9mz95", 3, "medium",
  "A model that fits the training noise so closely that it fails on new data is said to ___.",
  "Um modelo que se ajusta tanto ao ruído do treino que falha em dados novos sofre ___.",
  ["overfit", "overfits"], ["sobreajuste", "overfitting"])

Q("ex-xbt31f7c", 3, "medium",
  "The same member appears as of two cutoffs, one in training and one in test. Why is that acceptable here?",
  "O mesmo membro aparece em dois cortes, um no treino e um no teste. Por que isso é aceitável aqui?",
  [("Members never change", "Membros nunca mudam", False, "They change constantly.", "Eles mudam o tempo todo."),
   ("A label window separates them", "Uma janela de rótulo os separa", True,
    "Right. The training label closed before the test cutoff.", "Isso. O rótulo do treino fechou antes do corte de teste."),
   ("The model does not see member ids", "O modelo não vê os ids dos membros", False,
    "True, but not why it is acceptable.", "Verdade, mas não é o porquê."),
   ("It is not acceptable", "Não é aceitável", False, "It is, with the gap.", "É, com o intervalo.")])

N("ex-850e9c59", 3, "medium",
  "What test AUC did lesson 3 report for the chosen depth, the number to report?",
  "Que AUC de teste a lição 3 relatou para a profundidade escolhida, o número a relatar?",
  0.769, 0, "", "")

# ---- lesson 4
Q("ex-qd2j127v", 4, "easy",
  "The lapse model scores 86.0% accuracy. Why is that weak evidence?",
  "O modelo de afastamento tem 86,0% de acurácia. Por que isso é evidência fraca?",
  [("Saying nobody lapses already scores 83.1%", "Dizer que ninguém se afasta já dá 83,1%", True,
    "Right. Accuracy on an imbalanced class flatters.", "Isso. Acurácia com classe desbalanceada engana."),
   ("86% is too low for any model", "86% é baixo demais para qualquer modelo", False,
    "No fixed bar exists.", "Não existe régua fixa."),
   ("Accuracy cannot be computed for probabilities", "Acurácia não se calcula para probabilidades", False,
    "It is computed after a cut.", "Ela é calculada depois de um corte."),
   ("The test set was too small", "O teste era pequeno demais", False, "Three thousand members is enough.", "Três mil membros bastam.")])

P("ex-h7h2as6d", 4, "medium",
  "Match each confusion-matrix cell to its meaning for the lapse model.",
  "Associe cada célula da matriz de confusão ao que ela significa para o modelo de afastamento.",
  [("true positive", "verdadeiro positivo", "flagged, and lapsed", "apontado, e se afastou"),
   ("false positive", "falso positivo", "flagged, and stayed", "apontado, e ficou"),
   ("false negative", "falso negativo", "not flagged, and lapsed", "não apontado, e se afastou")],
  [("not scored at all", "nem pontuado")])

Q("ex-s87ekdwh", 4, "medium",
  "Precision answers which question?",
  "A precisão responde a que pergunta?",
  [("Of the members who lapsed, how many were flagged", "Dos que se afastaram, quantos foram apontados", False,
    "That is recall.", "Isso é revocação."),
   ("Of the members flagged, how many lapsed", "Dos apontados, quantos se afastaram", True,
    "Right. How often a voucher went where it was needed.", "Isso. Quantas vezes o cupom foi para quem precisava."),
   ("How many members were scored", "Quantos membros foram pontuados", False, "That is a count.", "Isso é contagem."),
   ("How close the probabilities are to the rates", "Quão perto as probabilidades estão das taxas", False,
    "That is calibration.", "Isso é calibração.")])

N("ex-g5t5hkhf", 4, "medium",
  "At the best threshold, what net value in reais did acting on the model give?",
  "No melhor limiar, que valor líquido em reais agir pelo modelo deu?",
  11900, 0, "R$", "R$")

Q("ex-fdcy712d", 4, "hard",
  "Why does the course pick the threshold from what things cost, not from 0.5?",
  "Por que o curso escolhe o limiar pelos custos, e não em 0,5?",
  [("0.5 is undefined for logistic regression", "0,5 não é definido na regressão logística", False,
    "It is defined, just arbitrary.", "É definido, só é arbitrário."),
   ("The two errors cost differently", "Os dois erros custam diferente", True,
    "Right. The best cut came out at 0.2.", "Isso. O melhor corte saiu em 0,2."),
   ("Thresholds must be below the base rate", "Limiares devem ficar abaixo da taxa base", False,
    "No such rule.", "Não há essa regra."),
   ("Marketing asked for 0.2", "O marketing pediu 0,2", False, "It came from the arithmetic.", "Veio da conta.")])

Q("ex-r10anaf5", 4, "medium",
  "A model says 0.3 for a group of members. When is it calibrated?",
  "Um modelo diz 0,3 para um grupo de membros. Quando ele está calibrado?",
  [("When about 30% of them lapse", "Quando uns 30% deles se afastam", True,
    "Right. Said matches happened.", "Isso. O dito bate com o acontecido."),
   ("When its AUC is above 0.5", "Quando a AUC passa de 0,5", False, "AUC is about ranking.", "AUC é sobre ordenação."),
   ("When 0.3 is the threshold", "Quando 0,3 é o limiar", False, "A threshold is a decision.", "Limiar é uma decisão."),
   ("When none of them lapse", "Quando nenhum se afasta", False, "That would be badly calibrated.", "Isso seria mal calibrado.")])

M("ex-mjj6a1xj", 4, "medium",
  "Which scores describe a ranking rather than a single cut? Choose every one that applies.",
  "Quais notas descrevem uma ordenação e não um corte único? Escolha todas as que se aplicam.",
  [("ROC AUC", "ROC AUC", True, "Right. Over every threshold.", "Isso. Sobre todos os limiares."),
   ("average precision", "precisão média", True, "Right. Over the whole list.", "Isso. Sobre a lista toda."),
   ("accuracy at 0.5", "acurácia em 0,5", False, "One cut.", "Um corte."),
   ("recall at 0.2", "revocação em 0,2", False, "One cut.", "Um corte.")])

Q("ex-wrfjzqak", 4, "medium",
  "For the spend regression, why might a team report MAE rather than RMSE?",
  "Na regressão de gasto, por que uma equipe relataria MAE em vez de RMSE?",
  [("MAE reads as reais off per member", "MAE se lê como reais de erro por membro", True,
    "Right. RMSE weights the big misses more.", "Isso. O RMSE pesa mais os grandes erros."),
   ("RMSE cannot be computed for amounts", "RMSE não se calcula para valores", False, "It can.", "Pode."),
   ("MAE is always smaller, so it looks better", "MAE é sempre menor, então parece melhor", False,
    "Choosing by looks is the wrong reason.", "Escolher pela aparência é o motivo errado."),
   ("RMSE needs a baseline", "RMSE precisa de linha de base", False, "Both do.", "Os dois precisam.")])

# ---- lesson 5
O("ex-wph8c38p", 5, "easy",
  "Put the pipeline's steps in order.",
  "Coloque os passos do pipeline em ordem.",
  [("build the dataset", "montar o conjunto de dados"), ("validate it", "validá-lo"),
   ("train", "treinar"), ("evaluate", "avaliar")])

Q("ex-jx41tt63", 5, "medium",
  "What does build_dataset.py do when a cutoff's labels have not closed?",
  "O que o build_dataset.py faz quando os rótulos de um corte ainda não fecharam?",
  [("Fills the missing labels with zeros", "Preenche os rótulos que faltam com zeros", False,
    "A zero would be a false 'stayed'.", "Um zero seria um falso 'ficou'."),
   ("Refuses, naming the dates", "Recusa, dizendo as datas", True,
    "Right. Unfinished labels are not used.", "Isso. Rótulos inacabados não são usados."),
   ("Uses the newest labels it has", "Usa os rótulos mais novos que tiver", False, "Those are unfinished.", "Esses estão inacabados."),
   ("Skips the members it cannot label", "Pula os membros que não consegue rotular", False,
    "That would bias the set silently.", "Isso enviesaria o conjunto em silêncio.")])

Q("ex-djqjqpc3", 5, "medium",
  "What is a data contract in lesson 5?",
  "O que é um contrato de dados na lição 5?",
  [("A legal agreement with the shop", "Um acordo jurídico com a loja", False, "It is code, not law.", "É código, não lei."),
   ("Checks the data must pass", "Checagens que os dados passam", True,
    "Right. validate.py refuses a set that breaks them.", "Isso. O validate.py recusa um conjunto que as quebra."),
   ("The schema of the MLflow database", "O esquema do banco do MLflow", False, "MLflow is later.", "O MLflow vem depois."),
   ("A promise about model accuracy", "Uma promessa sobre a precisão do modelo", False,
    "It is about the data.", "É sobre os dados.")])

Q("ex-fmpz7ktt", 5, "hard",
  "What is training-serving skew?",
  "O que é o desvio entre treino e produção?",
  [("A model trained on one cutoff and tested on another", "Um modelo treinado num corte e testado noutro", False,
    "That is the split, done on purpose.", "Isso é a divisão, feita de propósito."),
   ("Two ways of computing one feature", "Dois jeitos de calcular um atributo", True,
    "Right. The model meets inputs it was never trained on.", "Isso. O modelo encontra entradas com que nunca treinou."),
   ("A slow production service", "Um serviço de produção lento", False, "That is latency.", "Isso é latência."),
   ("Training on more data than production has", "Treinar com mais dados do que a produção tem", False,
    "Volume is not the issue.", "Volume não é a questão.")])

N("ex-h4szgwbs", 5, "medium",
  "How many members did the pipeline's training set hold, as of 31 August 2025?",
  "Quantos membros o conjunto de treino do pipeline tinha, em 31 de agosto de 2025?",
  2863, 0, "members", "membros")

Q("ex-36cx2st6", 5, "medium",
  "Why does train.py write a record beside the model file?",
  "Por que o train.py grava um registro ao lado do arquivo do modelo?",
  [("So the model can be loaded faster", "Para o modelo carregar mais rápido", False, "Loading ignores it.", "A carga o ignora."),
   ("To say what data and settings made it", "Para dizer que dados e ajustes o fizeram", True,
    "Right. Including the data's fingerprint.", "Isso. Inclusive a impressão digital dos dados."),
   ("joblib requires one", "O joblib exige um", False, "It requires nothing.", "Não exige nada."),
   ("For marketing to read the scores", "Para o marketing ler as notas", False, "Scores are elsewhere.", "As notas ficam em outro lugar.")])

C("ex-hec45c50", 5, "easy",
  "The person who keeps the data a model depends on correct and on time is the data ___.",
  "Quem mantém corretos e em dia os insumos de que um modelo depende é o engenheiro de ___.",
  ["engineer"], ["dados"])

# ---- lesson 6
Q("ex-1tjw7v6m", 6, "easy",
  "What two problems does a feature store solve with one design?",
  "Que dois problemas uma feature store resolve com um só desenho?",
  [("Slow training and slow serving", "Treino lento e serviço lento", False,
    "Speed is a side effect.", "Velocidade é efeito colateral."),
   ("Duplicate work and wrong days", "Trabalho em dobro e dias errados", True,
    "Right. One computation, kept with its day.", "Isso. Um cálculo, guardado com o seu dia."),
   ("Missing labels and unbalanced classes", "Rótulos faltando e classes desbalanceadas", False,
    "A feature store holds no labels.", "Uma feature store não guarda rótulos."),
   ("Model versioning and rollback", "Versionamento de modelo e reversão", False,
    "That is the registry's job.", "Esse é o trabalho do registro.")])

Q("ex-273rr0mf", 6, "medium",
  "Why does featurestore.py never store the lapsed column in a snapshot?",
  "Por que o featurestore.py nunca guarda a coluna lapsed numa fotografia?",
  [("SQLite cannot store booleans", "O SQLite não guarda booleanos", False, "It stores integers fine.", "Ele guarda inteiros sem problema."),
   ("Nobody knows it yet", "Ninguém o sabe ainda", True,
    "Right. A store holding it would offer the future to whoever reads it.",
    "Isso. Um armazenamento com ele ofereceria o futuro a quem o lesse."),
   ("It would make the store too large", "Deixaria o armazenamento grande demais", False, "One column is small.", "Uma coluna é pequena."),
   ("The service does not need it", "O serviço não precisa dela", False,
    "True, but the reason is that it does not exist yet.", "Verdade, mas o motivo é que ela ainda não existe.")])

Q("ex-979qt8fk", 6, "medium",
  "An as-of join asks for a member's features on a Thursday between two weekly snapshots. Which does it return?",
  "Uma junção as-of pede os atributos de um membro numa quinta entre duas fotografias semanais. Qual ela devolve?",
  [("The next snapshot, the Sunday after", "A próxima fotografia, o domingo seguinte", False,
    "That is the future relative to the question.", "Isso é o futuro em relação à pergunta."),
   ("The newest snapshot up to that Thursday", "A fotografia mais nova até aquela quinta", True,
    "Right. Never one after the moment asked about.", "Isso. Nunca uma depois do momento perguntado."),
   ("The average of the two", "A média das duas", False, "Nothing is averaged.", "Nada é calculado em média."),
   ("Nothing, since no snapshot falls on that day", "Nada, já que não há fotografia naquele dia", False,
    "It takes the latest before, within the age limit.", "Ela pega a mais recente antes, dentro do limite de idade.")])

N("ex-m05xjpyd", 6, "medium",
  "How many members did the online store leave out as too old to serve?",
  "Quantos membros o armazenamento online deixou de fora por velhos demais para servir?",
  466, 0, "members", "membros")

Q("ex-psm68mqh", 6, "medium",
  "What does the online store hold that the offline store does not?",
  "O que o armazenamento online guarda que o offline não guarda?",
  [("Every snapshot ever taken", "Todas as fotografias já tiradas", False, "That is the offline store.", "Esse é o offline."),
   ("Each member's latest fresh row", "A linha fresca mais recente", True,
    "Right. One indexed row a service can read in milliseconds.", "Isso. Uma linha indexada que um serviço lê em milissegundos."),
   ("The labels for training", "Os rótulos para treino", False, "No store holds labels.", "Nenhum armazenamento guarda rótulos."),
   ("The model's predictions", "As predições do modelo", False, "Those go to lapse_scores.", "Essas vão para lapse_scores.")])

M("ex-rq62y8f4", 6, "hard",
  "When might a team go without a feature store? Choose every one that applies.",
  "Quando uma equipe pode ficar sem feature store? Escolha todos os que se aplicam.",
  [("one batch model whose features come from one query", "um modelo de lote cujos atributos saem de uma consulta", True,
    "Right. There is nothing to share or serve.", "Isso. Não há nada a compartilhar ou servir."),
   ("a single model scored nightly, never served live", "um único modelo pontuado à noite, nunca servido ao vivo", True,
    "Right. No online store is needed.", "Isso. Nenhum armazenamento online é preciso."),
   ("several models sharing features, one served live", "vários modelos compartilhando atributos, um servido ao vivo", False,
    "That is exactly what a store is for.", "É exatamente para isso que serve uma."),
   ("training and serving computing features in different code", "treino e serviço calculando atributos em códigos diferentes", False,
    "That is skew waiting to happen.", "Isso é desvio esperando acontecer.")])

N("ex-39bd4n7a", 6, "easy",
  "How many weekly snapshots did the backfill write, from June 2025 to February 2026?",
  "Quantas fotografias semanais o preenchimento retroativo gravou, de junho de 2025 a fevereiro de 2026?",
  39, 0, "snapshots", "fotografias")

Q("ex-v28b88d1", 6, "hard",
  "Training rebuilt from the offline store reproduced lesson 5's test exactly. What did that prove?",
  "O treino refeito a partir do armazenamento offline reproduziu exatamente o teste da lição 5. O que isso provou?",
  [("That the model has no leakage", "Que o modelo não tem vazamento", False, "It proves the rows are the same.", "Prova que as linhas são as mesmas."),
   ("That the rows are the same", "Que as linhas são as mesmas", True,
    "Right. Reproducible means the same rows every time.", "Isso. Reprodutível quer dizer as mesmas linhas sempre."),
   ("That SQLite is deterministic", "Que o SQLite é determinístico", False, "Not the point.", "Não é o ponto."),
   ("That the model needs no retraining", "Que o modelo dispensa retreino", False, "Nothing about the future.", "Nada sobre o futuro.")])

# ---- lesson 7
P("ex-0ge7dwpw", 7, "easy",
  "Match each input of a model version to what keeps it.",
  "Associe cada entrada de uma versão de modelo ao que a guarda.",
  [("code", "código", "Git", "Git"), ("data", "dados", "DVC", "DVC"),
   ("the environment", "o ambiente", "pinned pip versions", "versões fixadas do pip")],
  [("a spreadsheet of results", "uma planilha de resultados")])

Q("ex-wmb09mmk", 7, "medium",
  "What does dvc repro do when only model.py changed?",
  "O que o dvc repro faz quando só o model.py mudou?",
  [("Reruns every stage from scratch", "Roda de novo todos os estágios do zero", False,
    "It skips what did not change.", "Ele pula o que não mudou."),
   ("Reruns train and evaluate", "Roda train e evaluate", True,
    "Right. Nothing dataset depends on changed.", "Isso. Nada de que dataset depende mudou."),
   ("Nothing, until the data changes", "Nada, até os dados mudarem", False, "Code is a dependency too.", "Código também é dependência."),
   ("Only reruns evaluate", "Só roda evaluate de novo", False, "train depends on model.py.", "train depende do model.py.")])

Q("ex-bsf479vk", 7, "medium",
  "In the MLflow registry, what is the champion alias?",
  "No registro do MLflow, o que é o apelido champion?",
  [("A copy of the best model", "Uma cópia do melhor modelo", False, "Nothing is copied.", "Nada é copiado."),
   ("A name that points at one version", "Um nome que aponta para uma versão", True,
    "Right. Moving it is promotion; moving it back is rollback.", "Isso. Movê-lo é promover; voltar é reverter."),
   ("The newest version, automatically", "A versão mais nova, automaticamente", False, "It moves only when told.", "Só se move quando mandado."),
   ("A Git tag", "Uma tag do Git", False, "Git tags are separate.", "Tags do Git são outra coisa.")])

Q("ex-b8e19h5a", 7, "hard",
  "Version 2 ranked members as well as version 1 but was not promoted. Why?",
  "A versão 2 ordenava os membros tão bem quanto a 1, mas não foi promovida. Por quê?",
  [("Its calibration broke", "A calibração dela quebrou", True,
    "Right. Balanced weights broke calibration.", "Isso. Pesos balanceados quebraram a calibração."),
   ("It was trained on older data", "Foi treinada com dados mais velhos", False, "Same data.", "Mesmos dados."),
   ("Its file was too large", "O arquivo era grande demais", False, "Size was not compared.", "Tamanho não foi comparado."),
   ("MLflow refused to register it", "O MLflow recusou registrá-la", False, "It was registered.", "Foi registrada.")])

Q("ex-jw50ycc3", 7, "medium",
  "Why does log_run.py refuse to run with uncommitted changes?",
  "Por que o log_run.py se recusa a rodar com mudanças não commitadas?",
  [("MLflow cannot read uncommitted files", "O MLflow não lê arquivos não commitados", False, "It reads anything.", "Ele lê qualquer coisa."),
   ("The run must name its code", "A execução precisa nomear o código", True,
    "Right. A commit hash is that name.", "Isso. Um hash de commit é esse nome."),
   ("DVC locks the working tree", "O DVC trava a árvore de trabalho", False, "It does not.", "Não trava."),
   ("To save disk space", "Para economizar disco", False, "Disk is not the reason.", "Disco não é o motivo.")])

O("ex-67tve6bx", 7, "medium",
  "Put the steps of getting version 1 back in order.",
  "Coloque em ordem os passos para recuperar a versão 1.",
  [("git checkout v1", "git checkout v1"), ("dvc checkout", "dvc checkout"),
   ("check the model's MD5 against dvc.lock", "conferir o MD5 do modelo contra o dvc.lock")])

C("ex-cbkq4ymx", 7, "easy",
  "DVC keeps a large file's bytes in its cache and puts a small file in Git, a ___, that names them.",
  "O DVC guarda os bytes de um arquivo grande no cache e põe no Git um pequeno arquivo, um ___, que os nomeia.",
  ["pointer"], ["ponteiro"])

Q("ex-fp3d1v4x", 7, "medium",
  "What does the MLflow server cost on a laptop when started with one worker and job execution off?",
  "Quanto o servidor do MLflow custa num notebook quando iniciado com um worker e sem execução de jobs?",
  [("About 480 MB of memory", "Uns 480 MB de memória", True,
    "Right. Against over 2 GB with the defaults.", "Isso. Contra mais de 2 GB com os padrões."),
   ("Nothing measurable", "Nada mensurável", False, "Two processes of about 240 MB each.", "Dois processos de uns 240 MB cada."),
   ("A paid licence", "Uma licença paga", False, "MLflow is free software.", "O MLflow é software livre."),
   ("A GPU", "Uma GPU", False, "It needs none.", "Não precisa.")])

# ---- lesson 8
Q("ex-gcn98mxk", 8, "easy",
  "Which deployment is the default the course recommends?",
  "Qual implantação é o padrão que o curso recomenda?",
  [("Real time, for freshness", "Tempo real, pelo frescor", False,
    "Freshness costs an always-on service.", "Frescor custa um serviço sempre no ar."),
   ("Batch, on a schedule", "Lote, numa agenda", True, "Right. Move only when a decision needs fresher answers.", "Isso. Mude só quando uma decisão pedir respostas mais frescas."),
   ("The edge, for speed", "A borda, pela velocidade", False, "The hardest to update.", "A mais difícil de atualizar."),
   ("All three at once", "As três ao mesmo tempo", False, "Each costs something to keep.", "Cada uma custa algo para manter.")])

Q("ex-met2wdjp", 8, "medium",
  "Why does a rerun of score_batch.py not double the night's scores?",
  "Por que refazer o score_batch.py não dobra as notas da noite?",
  [("It replaces the night", "Ele substitui a noite", True,
    "Right. The job is idempotent.", "Isso. O job é idempotente."),
   ("SQLite ignores duplicate rows", "O SQLite ignora linhas duplicadas", False, "Without the delete it would refuse or double.", "Sem o delete ele recusaria ou dobraria."),
   ("The champion alias prevents it", "O apelido champion impede", False, "The alias picks a model, not rows.", "O apelido escolhe modelo, não linhas."),
   ("It only scores new members", "Só pontua membros novos", False, "It scores every active member.", "Pontua todos os ativos.")])

Q("ex-98fdx7fy", 8, "medium",
  "The service answers 404 for a member. What does that mean here?",
  "O serviço responde 404 para um membro. O que isso quer dizer aqui?",
  [("The service is down", "O serviço caiu", False, "A down service answers nothing.", "Um serviço caído não responde nada."),
   ("Nothing fresh to score from", "Nada fresco para pontuar", True,
    "Right. A refusal with a reason.", "Isso. Uma recusa com motivo."),
   ("The model rejected the member", "O modelo rejeitou o membro", False, "The model never ran.", "O modelo nem rodou."),
   ("The URL was malformed", "A URL estava malformada", False, "That is a 422.", "Isso é 422.")])

N("ex-0vrrvs6y", 8, "easy",
  "How many bytes was the champion exported as ONNX?",
  "Quantos bytes tinha o campeão exportado em ONNX?",
  1803, 0, "bytes", "bytes")

Q("ex-vfzfq3nj", 8, "medium",
  "Why does the canary split by a hash of the member id?",
  "Por que o canário divide por um hash do id do membro?",
  [("Stable groups nobody picks", "Grupos estáveis que ninguém escolhe", True,
    "Right. Both rules of a trustworthy canary.", "Isso. As duas regras de um canário confiável."),
   ("Hashes are faster than random numbers", "Hashes são mais rápidos que números aleatórios", False, "Speed is not the point.", "Velocidade não é o ponto."),
   ("So the canary gets the riskiest members", "Para o canário pegar os membros mais arriscados", False,
    "That would be choosing who is in it.", "Isso seria escolher quem entra."),
   ("Because member ids are secret", "Porque ids de membros são secretos", False, "They are not.", "Não são.")])

Q("ex-a984by3a", 8, "hard",
  "What did the canary compare to stop version 2 without any labels?",
  "O que o canário comparou para parar a versão 2 sem rótulo nenhum?",
  [("The accuracy of each group", "A acurácia de cada grupo", False, "Accuracy needs outcomes.", "Acurácia precisa de desfechos."),
   ("What each version said", "O que cada versão disse", True,
    "Right. Same members by hash, so the difference is the model's.", "Isso. Mesmos membros pelo hash, então a diferença é do modelo."),
   ("The speed of each version", "A velocidade de cada versão", False, "No service ran.", "Nenhum serviço rodou."),
   ("The size of each file", "O tamanho de cada arquivo", False, "Size says nothing.", "Tamanho não diz nada.")])

M("ex-c2wdact9", 8, "hard",
  "What does moving a model onto a device make harder? Choose every one that applies.",
  "O que levar um modelo para um aparelho torna mais difícil? Escolha todos os que se aplicam.",
  [("computing its features", "calcular os atributos", True, "Right. A second implementation.", "Isso. Uma segunda implementação."),
   ("changing its version", "trocar a versão", True, "Right. Many versions answer at once.", "Isso. Muitas versões respondem ao mesmo tempo."),
   ("collecting its answers", "coletar as respostas", True, "Right. They stay on the device.", "Isso. Ficam no aparelho."),
   ("fitting the file in memory", "caber o arquivo na memória", False, "1,803 bytes fits anywhere.", "1.803 bytes cabem em qualquer lugar.")])

C("ex-tgw0hpqk", 8, "medium",
  "A deployment where a new version scores every request but its answers are only logged is a ___ deployment.",
  "Uma implantação em que a versão nova pontua cada pedido mas as respostas só são registradas é uma implantação ___.",
  ["shadow"], ["sombra"])

# ---- lesson 9
Q("ex-ghzsk2gb", 9, "easy",
  "Which question about a model can only be answered once outcomes arrive?",
  "Que pergunta sobre um modelo só pode ser respondida quando os desfechos chegam?",
  [("Is it answering?", "Está respondendo?", False, "Status codes answer that.", "Os status respondem isso."),
   ("How fast is it?", "Quão rápido é?", False, "The log answers that.", "O log responde isso."),
   ("What is it saying?", "O que está dizendo?", False, "The watch answers that the next morning.", "O vigia responde isso na manhã seguinte."),
   ("Was it right?", "Acertou?", True, "Right. Ninety days later for this model.", "Isso. Noventa dias depois, neste modelo.")])

Q("ex-g10jkqr2", 9, "medium",
  "Why is p99 watched rather than the mean latency?",
  "Por que se observa o p99 e não a latência média?",
  [("The mean hides the slow ones", "A média esconde os lentos", True,
    "Right. And mixes refusals with answers.", "Isso. E mistura recusas com respostas."),
   ("p99 is cheaper to compute", "O p99 é mais barato de calcular", False, "Cost is not the reason.", "Custo não é o motivo."),
   ("The mean is always higher", "A média é sempre maior", False, "Here it was lower than the median.", "Aqui ela foi menor que a mediana."),
   ("FastAPI reports only p99", "O FastAPI só informa o p99", False, "The program computes it.", "O programa o calcula.")])

N("ex-exr4znr1", 9, "medium",
  "With sixteen requests at once, how many requests a second did the service answer?",
  "Com dezesseis pedidos por vez, quantos pedidos por segundo o serviço respondeu?",
  88, 0, "a second", "por segundo")

Q("ex-gkae7asz", 9, "medium",
  "Spend arrived multiplied by 100 and every step succeeded. What caught it?",
  "O gasto chegou multiplicado por 100 e todo passo deu certo. O que pegou o erro?",
  [("A type check in score_batch.py", "Uma checagem de tipo no score_batch.py", False, "The values were valid numbers.", "Os valores eram números válidos."),
   ("The nightly watch", "O vigia noturno", True,
    "Right. Mean probability 0.001 and spend's median a hundredfold.", "Isso. Probabilidade média 0,001 e mediana do gasto cem vezes maior."),
   ("The report card", "O boletim", False, "It would have taken 90 days.", "Levaria 90 dias."),
   ("A 500 from the service", "Um 500 do serviço", False, "Nothing errored.", "Nada deu erro.")])

Q("ex-nfngkr4x", 9, "hard",
  "The report card for 30 November matched lesson 5's test exactly. What did that check?",
  "O boletim de 30 de novembro bateu exatamente com o teste da lição 5. O que isso conferiu?",
  [("That the card itself computes correctly", "Que o próprio boletim calcula certo", True,
    "Right. Same night, so any disagreement would be a bug.", "Isso. Mesma noite, então qualquer discordância seria bug."),
   ("That the model has not drifted", "Que o modelo não derivou", False, "It is the night it was tested on.", "É a noite em que ele foi testado."),
   ("That version 2 is better", "Que a versão 2 é melhor", False, "Version 2 was not scored.", "A versão 2 não pontuou."),
   ("That the labels close in 90 days", "Que os rótulos fecham em 90 dias", False, "That is a definition.", "Isso é definição.")])

Q("ex-djz8sgdh", 9, "medium",
  "Why is a service's cost mostly paid when it is idle?",
  "Por que o custo de um serviço é pago quase todo quando ele está ocioso?",
  [("It is held all day", "Ele fica ocupado o dia todo", True,
    "Right. 330 MB per worker, 720 hours a month.", "Isso. 330 MB por worker, 720 horas por mês."),
   ("Idle processes use more memory", "Processos ociosos usam mais memória", False, "They use the same.", "Usam a mesma."),
   ("The provider charges extra for idle time", "O provedor cobra mais pelo tempo ocioso", False, "It charges by the hour, idle or not.", "Cobra por hora, ocioso ou não."),
   ("Batch jobs run during the idle hours", "Jobs de lote rodam nas horas ociosas", False, "Unrelated.", "Não tem relação.")])

O("ex-zda09dar", 9, "medium",
  "Order the four questions by how soon each is answered, soonest first.",
  "Ordene as quatro perguntas por quão cedo cada uma é respondida, a mais cedo primeiro.",
  [("is it answering?", "está respondendo?"), ("what is it saying?", "o que está dizendo?"),
   ("was it right?", "acertou?")])

C("ex-yhq86xhf", 9, "easy",
  "A promise such as \"99% of requests under 50 ms\" is a service level ___, an SLO.",
  "Uma promessa como \"99% dos pedidos abaixo de 50 ms\" é um service level ___, um SLO.",
  ["objective"], ["objective"])

# ---- lesson 10
Q("ex-yd9dqn8a", 10, "easy",
  "What separates data drift from concept drift?",
  "O que separa deriva de dados de deriva de conceito?",
  [("Inputs moving versus meaning moving", "Entradas mudando contra sentido mudando", True,
    "Right. The first shows in the inputs, the second in the outcomes.", "Isso. A primeira aparece nas entradas, a segunda nos desfechos."),
   ("Data drift is slow, concept drift is sudden", "A de dados é lenta, a de conceito súbita", False, "Either can be either.", "Qualquer uma pode ser qualquer uma."),
   ("Data drift only affects categories", "A de dados só afeta categorias", False, "online_share is a number.", "online_share é um número."),
   ("They are two names for one thing", "São dois nomes para a mesma coisa", False, "They need different evidence.", "Precisam de evidências diferentes.")])

N("ex-05g1jfh3", 10, "medium",
  "What PSI did online_share reach on 28 June 2026 against the training data?",
  "Que PSI o online_share atingiu em 28 de junho de 2026 contra os dados de treino?",
  0.602, 0, "", "")

Q("ex-26t7tfbv", 10, "medium",
  "Why did the nightly watch pass every night while online_share doubled?",
  "Por que o vigia noturno passou em toda noite enquanto o online_share dobrava?",
  [("Its reference drifted too", "A referência derivou junto", True,
    "Right. Slow change needs a fixed reference.", "Isso. Mudança lenta pede referência fixa."),
   ("It does not read online_share", "Ele não lê o online_share", False, "It reads its median.", "Ele lê a mediana."),
   ("Its exit status was ignored", "O status de saída foi ignorado", False, "It was 0 every night.", "Foi 0 toda noite."),
   ("The batch never ran", "O lote nunca rodou", False, "Every night was scored.", "Toda noite foi pontuada.")])

Q("ex-fz7e9282", 10, "hard",
  "tenure_days drifted to a PSI of 0.259. Why does the lesson call it harmless?",
  "O tenure_days derivou até PSI 0,259. Por que a lição o chama de inofensivo?",
  [("Members simply aged", "Os membros só envelheceram", True,
    "Right. Drift is a reason to look, not a verdict.", "Isso. Deriva é motivo para olhar, não veredito."),
   ("PSI below 0.3 never matters", "PSI abaixo de 0,3 nunca importa", False, "No such rule.", "Não há essa regra."),
   ("The model ignores tenure", "O modelo ignora a antiguidade", False, "It is one of its inputs.", "É uma das entradas."),
   ("Tenure cannot drift", "Antiguidade não deriva", False, "It just did.", "Acabou de derivar.")])

Q("ex-xn53hejn", 10, "medium",
  "The split card showed the largest gaps for which members?",
  "O boletim dividido mostrou as maiores diferenças para quais membros?",
  [("Online members of every age", "Membros online de todas as idades", False, "Their gaps were small.", "As diferenças foram pequenas."),
   ("Young members of Paulista and Pinheiros", "Jovens de Paulista e Pinheiros", True, "Right. Where the rival opened.", "Isso. Onde o rival abriu."),
   ("Members of 35 and over", "Membros de 35 ou mais", False, "A few points either way.", "Alguns pontos para cada lado."),
   ("Members who joined through the app", "Membros que entraram pelo app", False, "The split was by shop and age.", "A divisão foi por loja e idade.")])

Q("ex-783ckfs8", 10, "hard",
  "On 30 June, why could the challenger not have learned the April change?",
  "Em 30 de junho, por que o desafiante não podia ter aprendido a mudança de abril?",
  [("Its training labels closed on 28 March", "Os rótulos de treino dele fecharam em 28 de março", True,
    "Right. Lesson 3's rule put its training night 90 days before the test night.",
    "Isso. A regra da lição 3 pôs a noite de treino 90 dias antes da de teste."),
   ("DVC could not read April's data", "O DVC não leu os dados de abril", False, "It read them.", "Leu."),
   ("Logistic regression cannot learn changes", "Regressão logística não aprende mudanças", False, "It learns what its labels contain.", "Aprende o que os rótulos contêm."),
   ("The rival opened in June", "O rival abriu em junho", False, "It opened on 1 April.", "Abriu em 1º de abril.")])

N("ex-ts387r67", 10, "medium",
  "What ROC AUC did the champion reach on 29 March 2026?",
  "Que ROC AUC o campeão atingiu em 29 de março de 2026?",
  0.747, 0, "", "")

M("ex-1aey2vx1", 10, "medium",
  "Which are retraining triggers the lesson discusses? Choose every one that applies.",
  "Quais são gatilhos de retreino que a lição discute? Escolha todos os que se aplicam.",
  [("a schedule", "uma agenda", True, "Right. Simple, and blind to change.", "Isso. Simples, e cego para mudanças."),
   ("input drift past a threshold", "deriva de entrada além de um limite", True, "Right. Drift is not always damage.", "Isso. Deriva nem sempre é dano."),
   ("a falling report card", "um boletim caindo", True, "Right. Ninety days late.", "Isso. Noventa dias atrasado."),
   ("a new library release", "uma versão nova de biblioteca", False, "That is maintenance, not retraining.", "Isso é manutenção, não retreino.")])

Q("ex-5pzc97ct", 10, "medium",
  "Why does the policy forbid promoting a model retrained after its test?",
  "Por que a política proíbe promover um modelo retreinado depois do teste?",
  [("It would be unmeasured", "Ele seria um modelo não medido", True,
    "Right. Only the tested model has evidence.", "Isso. Só o modelo testado tem evidência."),
   ("MLflow allows one version per day", "O MLflow permite uma versão por dia", False, "No such limit.", "Não há esse limite."),
   ("Retraining deletes the test set", "Retreinar apaga o teste", False, "Nothing is deleted.", "Nada é apagado."),
   ("The alias cannot move twice", "O apelido não se move duas vezes", False, "It moves whenever told.", "Ele se move quando mandado.")])

# ---- twenty more, two a lesson
Q("ex-et0wwxjb", 1, "medium",
  "The bandit in lesson 1 kept trying the offers that looked worse. Why?",
  "O bandido da lição 1 continuou testando as ofertas que pareciam piores. Por quê?",
  [("A bug in its random numbers", "Um bug nos números aleatórios dele", False, "It was deliberate.", "Era proposital."),
   ("An early lead is not proof", "Liderar cedo não prova nada", True,
    "Right. Exploring a little is how it corrects a wrong early leader.", "Isso. Explorar um pouco corrige um líder errado do começo."),
   ("Marketing told it to treat every offer equally", "O marketing mandou tratar toda oferta igual", False,
    "It treated them unequally, on purpose.", "Ele as tratou de forma desigual, de propósito."),
   ("The worse offers were cheaper to send", "As ofertas piores eram mais baratas de mandar", False, "Cost was not the reason.", "Custo não era o motivo.")])

Q("ex-b26gccd7", 1, "easy",
  "What should a student do when the setup fails?",
  "O que o aluno deve fazer quando a instalação falha?",
  [("Skip the lesson's commands and read on", "Pular os comandos da lição e seguir lendo", False,
    "The lessons build on what runs.", "As lições se apoiam no que roda."),
   ("Follow the course's setup-failure section", "Seguir a seção do curso sobre falhas de instalação", True,
    "Right. It lists the usual failures and their fixes.", "Isso. Ela lista as falhas comuns e as correções."),
   ("Buy a faster computer", "Comprar um computador mais rápido", False, "Speed is rarely the cause.", "Velocidade raramente é a causa."),
   ("Disable certificate checks in pip", "Desativar a checagem de certificados no pip", False,
    "That trades a setup problem for a security one.", "Isso troca um problema de instalação por um de segurança.")])

Q("ex-pk28dyyx", 2, "medium",
  "Which task has no right answer to learn from in the data?",
  "Que tarefa não tem resposta certa nos dados para aprender?",
  [("Classification of lapsers", "Classificação de quem se afasta", False, "History labels them.", "O histórico os rotula."),
   ("Regression of spend", "Regressão do gasto", False, "Next quarter's spend is known later.", "O gasto do próximo trimestre se sabe depois."),
   ("Clustering", "Agrupamento", True, "Right. Nobody labelled the groups.", "Isso. Ninguém rotulou os grupos."),
   ("Recommendation scored by later purchases", "Recomendação avaliada por compras posteriores", False,
    "Later purchases are the answer it is scored on.", "As compras posteriores são a resposta usada para avaliá-la.")])

Q("ex-ymew1k0p", 2, "hard",
  "What does lesson 2 say each task asks of the data platform?",
  "O que a lição 2 diz que cada tarefa pede da plataforma de dados?",
  [("Only more rows", "Só mais linhas", False, "Rows are the least of it.", "Linhas são o de menos."),
   ("Features as of a moment, and outcomes kept", "Atributos num momento, e desfechos guardados", True,
    "Right. The rest of the course builds both.", "Isso. O resto do curso constrói os dois."),
   ("A GPU for every model in production", "Uma GPU para cada modelo em produção", False, "None of these models needs one.", "Nenhum desses modelos precisa."),
   ("A separate database for each model", "Um banco separado para cada modelo", False, "Sharing is the point.", "Compartilhar é o ponto.")])

Q("ex-kgnzy7gv", 3, "medium",
  "A score is reported from the test set after twenty models were compared on it. What is wrong?",
  "Uma nota é relatada do teste depois de vinte modelos comparados nele. O que está errado?",
  [("Twenty models is too few", "Vinte modelos é pouco", False, "The number is not the problem.", "O número não é o problema."),
   ("The test was used to choose", "O teste foi usado para escolher", True,
    "Right. Choosing belongs to validation.", "Isso. Escolher é papel da validação."),
   ("Nothing, if the test set is large", "Nada, se o teste for grande", False, "Size does not undo the choice.", "Tamanho não desfaz a escolha."),
   ("The models should be trained on the test set", "Os modelos deveriam treinar no teste", False, "That is worse.", "Isso é pior.")])

O("ex-sxj70z41", 3, "medium",
  "Order the cutoffs of a correct backtest, earliest first.",
  "Ordene os cortes de um backtest correto, do mais antigo para o mais novo.",
  [("training cutoff", "corte de treino"), ("training labels close", "rótulos de treino fecham"),
   ("test cutoff", "corte de teste"), ("test labels close", "rótulos de teste fecham")])

Q("ex-jxsj09cf", 4, "medium",
  "Of 300 vouchers sent to the top-scored members, 195 reached lapsers. What is that?",
  "Dos 300 cupons mandados aos membros de nota mais alta, 195 foram para quem se afastaria. O que é isso?",
  [("Recall at 300", "Revocação em 300", False, "Recall divides by all lapsers.", "Revocação divide por todos os afastados."),
   ("Precision at 300", "Precisão em 300", True, "Right. 195 of 300 sent.", "Isso. 195 de 300 enviados."),
   ("Accuracy", "Acurácia", False, "Accuracy counts every member.", "Acurácia conta todos os membros."),
   ("Calibration", "Calibração", False, "Calibration compares said and happened.", "Calibração compara dito e acontecido.")])

Q("ex-w2re3v61", 4, "easy",
  "Which score should marketing's voucher budget be argued with?",
  "Com que nota o orçamento de cupons do marketing deve ser discutido?",
  [("Accuracy", "Acurácia", False, "It ignores what errors cost.", "Ignora o custo dos erros."),
   ("Net value at the threshold", "Valor líquido no limiar", True, "Right. Money, in their units.", "Isso. Dinheiro, na unidade deles."),
   ("ROC AUC", "ROC AUC", False, "A ranking score, not a budget.", "Nota de ordenação, não orçamento."),
   ("Log loss", "Log loss", False, "Nobody budgets in log loss.", "Ninguém orça em log loss.")])

Q("ex-p3b6gc2d", 5, "medium",
  "What should a data engineer ask for before taking a model on?",
  "O que um engenheiro de dados deve pedir antes de assumir um modelo?",
  [("The modeller's notebook", "O notebook de quem modelou", False, "A notebook is not a pipeline.", "Notebook não é pipeline."),
   ("Steps, checks and a record", "Passos, checagens e um registro", True,
    "Right. What lesson 5 built.", "Isso. O que a lição 5 construiu."),
   ("A faster server", "Um servidor mais rápido", False, "Not the first need.", "Não é a primeira necessidade."),
   ("Only the model file", "Só o arquivo do modelo", False, "A file with no record cannot be rebuilt.", "Um arquivo sem registro não se refaz.")])

N("ex-7dfngx0m", 5, "hard",
  "In the skew demonstration, how many members' probabilities moved by more than 0.1 when the features were computed a second way?",
  "Na demonstração de desvio, quantos membros tiveram a probabilidade movida em mais de 0,1 quando os atributos foram calculados de outro jeito?",
  160, 0, "members", "membros")

Q("ex-8ya2hjdp", 6, "easy",
  "Which store does the web service of lesson 8 read?",
  "Qual armazenamento o serviço web da lição 8 lê?",
  [("The offline store", "O offline", False, "That is for training and batch.", "Esse é para treino e lote."),
   ("The online store", "O online", True, "Right. One row per member.", "Isso. Uma linha por membro."),
   ("shop.db directly", "O shop.db direto", False, "That would recompute features.", "Isso recalcularia atributos."),
   ("MLflow's database", "O banco do MLflow", False, "That holds models.", "Esse guarda modelos.")])

Q("ex-b00mm7ay", 6, "medium",
  "How much faster was one online lookup than computing the member's features from the shop?",
  "Quanto mais rápida foi uma busca online do que calcular os atributos do membro a partir da loja?",
  [("About twice", "Umas duas vezes", False, "Far more.", "Muito mais."),
   ("Hundreds of times", "Centenas de vezes", True, "Right. About 0.17 ms against 0.06 s.", "Isso. Uns 0,17 ms contra 0,06 s."),
   ("The same", "Igual", False, "Not close.", "Nem perto."),
   ("Slower", "Mais lenta", False, "It was faster.", "Foi mais rápida.")])

Q("ex-jj2zdwg4", 7, "easy",
  "Which tool answers which commit and data made a registered model?",
  "Que ferramenta responde que commit e que dados fizeram um modelo registrado?",
  [("pip", "pip", False, "pip installs libraries.", "O pip instala bibliotecas."),
   ("MLflow", "MLflow", True,
    "Right. log_run.py records both.", "Isso. O log_run.py registra os dois."),
   ("SQLite", "SQLite", False, "It stores rows, not provenance.", "Guarda linhas, não proveniência."),
   ("cron", "cron", False, "cron schedules.", "O cron agenda.")])

Q("ex-rphag7kb", 7, "medium",
  "dvc metrics diff compares what?",
  "O dvc metrics diff compara o quê?",
  [("Two models' files byte for byte", "Os arquivos de dois modelos, byte a byte", False, "That is md5.", "Isso é md5."),
   ("The metrics files of two commits", "Os arquivos de métricas de dois commits", True,
    "Right. Meaningful only if both tested the same night.", "Isso. Só faz sentido se os dois testaram a mesma noite."),
   ("Two Git branches' code", "O código de dois ramos do Git", False, "That is git diff.", "Isso é git diff."),
   ("Two MLflow servers", "Dois servidores do MLflow", False, "Not related.", "Sem relação.")])

Q("ex-rnexrdm4", 8, "medium",
  "When is a real-time service worth what it costs?",
  "Quando um serviço em tempo real vale o que custa?",
  [("When the request decides the answer", "Quando o pedido decide a resposta", True,
    "Right. The basket now, the payment now.", "Isso. A cesta agora, o pagamento agora."),
   ("Whenever a page shows a score", "Sempre que uma página mostra uma nota", False,
    "Last night's row usually serves.", "A linha de ontem costuma servir."),
   ("When the model is large", "Quando o modelo é grande", False, "Size argues the other way.", "O tamanho argumenta ao contrário."),
   ("When marketing asks for it", "Quando o marketing pede", False, "A request is not a reason.", "Pedido não é motivo.")])

Q("ex-3w70yy6g", 8, "hard",
  "The alias moves while the service runs. When does the service use the new version?",
  "O apelido muda com o serviço rodando. Quando o serviço usa a versão nova?",
  [("On the next request", "No próximo pedido", False, "It read the alias at start-up.", "Leu o apelido na partida."),
   ("After a restart", "Depois de um reinício", True, "Right. Pinned at start-up.", "Isso. Fixado na partida."),
   ("At midnight", "À meia-noite", False, "No schedule is involved.", "Nenhuma agenda envolvida."),
   ("Never", "Nunca", False, "A restart picks it up.", "Um reinício a pega.")])

Q("ex-baw5wbm0", 9, "medium",
  "Why does the cron line run the watch after the batch and before anybody reads?",
  "Por que a linha do cron roda o vigia depois do lote e antes de alguém ler?",
  [("So a bad night is stopped before it is used", "Para uma noite ruim ser parada antes do uso", True,
    "Right. A non-zero exit stops the chain.", "Isso. Uma saída diferente de zero para a cadeia."),
   ("Because cron runs commands alphabetically", "Porque o cron roda comandos em ordem alfabética", False, "It runs them as written.", "Roda como escrito."),
   ("The watch needs the service running", "O vigia precisa do serviço rodando", False, "It reads tables.", "Ele lê tabelas."),
   ("To save memory", "Para economizar memória", False, "Not the reason.", "Não é o motivo.")])

Q("ex-6twd940b", 9, "easy",
  "Which of these should page somebody at night for a monthly voucher model?",
  "Qual destes deveria acordar alguém de madrugada num modelo de cupons mensal?",
  [("A watch alarm", "Um alarme do vigia", False, "It can wait for the morning.", "Pode esperar a manhã."),
   ("A slipping report card", "Um boletim escorregando", False, "A ticket.", "Um chamado."),
   ("The service failing requests", "O serviço falhando pedidos", True, "Right. Members feel it now.", "Isso. Os membros sentem agora."),
   ("A new member", "Um membro novo", False, "Normal traffic.", "Tráfego normal.")])

Q("ex-nw8h7f8m", 10, "medium",
  "drift.py reports PSI and the KS statistic. Why not the KS p-value?",
  "O drift.py relata PSI e a estatística KS. Por que não o valor-p do KS?",
  [("It is always tiny here", "Ele é sempre minúsculo aqui", True,
    "Right. A test that always fires says nothing.", "Isso. Um teste que sempre dispara não diz nada."),
   ("SciPy does not return one", "O SciPy não devolve um", False, "It does.", "Devolve."),
   ("p-values only work for categories", "Valores-p só servem para categorias", False, "No.", "Não."),
   ("It equals the PSI", "Ele é igual ao PSI", False, "Different measures.", "Medidas diferentes.")])

Q("ex-0pyafa4m", 10, "medium",
  "With no challenger shown better on 30 June, what does the team do about the young São Paulo members?",
  "Sem desafiante comprovadamente melhor em 30 de junho, o que a equipe faz sobre os jovens de São Paulo?",
  [("Promote the newest untested model", "Promove o modelo mais novo sem teste", False, "The policy forbids it.", "A política proíbe."),
   ("Takes the split card to marketing", "Leva o boletim dividido ao marketing", True,
    "Right. A business answer, while labels mature.", "Isso. Uma resposta de negócio, enquanto os rótulos amadurecem."),
   ("Deletes their rows", "Apaga as linhas deles", False, "That hides the problem.", "Isso esconde o problema."),
   ("Stops scoring São Paulo", "Para de pontuar São Paulo", False, "That helps nobody.", "Isso não ajuda ninguém.")])
