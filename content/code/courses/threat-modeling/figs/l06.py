"""Lesson 6: attack surface mapping."""
from figures import Fig, T, figure


@figure('l06-surface', 6)
def surface():
    f = Fig('l06-surface', 720, 330, T(
        'The portal’s attack surface. In the middle, everything Vereda runs: the portal, the staff '
        'console, the reminder worker and the two data stores. Around it, the outsiders. Five '
        'entry points arrive: sign in and book, and upload exam PDF, from the patient; the payment '
        'webhook from the gateway; manage the agenda from clinic staff; and the staff sign-in page '
        'from anyone on the internet, drawn dashed because lesson 2’s drawing did not have it. '
        'Three exit points leave: pages to the patient, charges to the gateway and reminders to '
        'the SMS provider.',
        'A superfície de ataque do portal. No meio, tudo o que a Vereda roda: o portal, o console '
        'da equipe, o worker de lembretes e os dois repositórios. Em volta, os de fora. Cinco '
        'pontos de entrada chegam: entrar e agendar, e enviar PDF do exame, do paciente; o webhook '
        'de pagamento, do gateway; cuidar da agenda, da equipe; e a página de login da equipe, de '
        'qualquer um na internet, desenhada tracejada porque o desenho da aula 2 não a tinha. Três '
        'pontos de saída partem: páginas para o paciente, cobranças para o gateway e lembretes para '
        'o provedor de SMS.'))
    f.zone(240, 40, 240, 250, T('what Vereda runs', 'o que a Vereda roda'))
    f.process(310, 100, 34, [T('Portal', 'Portal')], size=9.5)
    f.process(310, 230, 34, [T('Console', 'Console')], size=9.5)
    f.process(420, 230, 30, [T('Worker', 'Worker')], size=9)
    f.store(420, 120, 90, [T('Records', 'Prontuários')], size=9)
    f.store(420, 170, 90, [T('Exams', 'Exames')], size=9)
    f.entity(90, 90, 120, 36, [T('Patient', 'Paciente')], size=10)
    f.entity(90, 200, 120, 36, [T('Clinic staff', 'Equipe')], size=10)
    f.entity(90, 280, 120, 36, [T('Anyone online', 'Qualquer um online')], size=10)
    f.entity(630, 90, 140, 36, [T('Payment gateway', 'Gateway')], size=10)
    f.entity(630, 230, 140, 36, [T('SMS provider', 'Provedor de SMS')], size=10)
    IN = dict(stroke='--phosphor', width=1.8)
    OUT = dict(stroke='--amber', width=1.8)
    f.arrow([(150, 82), (276, 92)], **IN)
    f.arrow([(150, 98), (276, 104)], **IN)
    f.arrow([(560, 82), (342, 90)], **IN)
    f.arrow([(150, 205), (277, 224)], **IN)
    f.arrow([(150, 280), (285, 252)], dash='5 4', **IN)
    f.arrow([(278, 116), (150, 112)], **OUT)
    f.arrow([(344, 108), (560, 100)], **OUT)
    f.arrow([(450, 230), (560, 230)], **OUT)
    f.rect(500, 285, 12, 4, stroke=None, fill='--phosphor', rx=0)
    f.text(518, 287, T('5 entry points', '5 pontos de entrada'), size=10, anchor='start', weight='600', fill='--phosphor')
    f.rect(500, 305, 12, 4, stroke=None, fill='--amber', rx=0)
    f.text(518, 307, T('3 exit points', '3 pontos de saída'), size=10, anchor='start', weight='600', fill='--amber')
    return f, T('The surface is measured at the edge of what you run. The dashed arrow is the one the drawing of lesson 2 left out.',
                'A superfície se mede na borda do que você roda. A seta tracejada é a que o desenho da aula 2 deixou de fora.')


@figure('l06-dependencies', 6)
def dependencies():
    f = Fig('l06-dependencies', 720, 270, T(
        'Four rings of what the portal depends on. Code Vereda wrote: the portal, the console, the '
        'worker. Code Vereda imports: a web framework, a PDF library, the gateway’s client '
        'library, and everything those import in turn. Services Vereda calls: the cloud provider, '
        'DNS, the SMS provider, the payment gateway. And what builds and ships it: the git host, '
        'the CI runner, the package registries.',
        'Quatro anéis do que o portal depende. Código que a Vereda escreveu: o portal, o console, '
        'o worker. Código que a Vereda importa: um framework web, uma biblioteca de PDF, a '
        'biblioteca cliente do gateway, e tudo o que essas importam por sua vez. Serviços que a '
        'Vereda chama: o provedor de nuvem, o DNS, o provedor de SMS, o gateway de pagamento. E o '
        'que constrói e entrega: o host do git, o executor de CI, os registros de pacotes.'))
    rings = [
        (T('what Vereda wrote', 'o que a Vereda escreveu'), [T('the portal,', 'o portal,'), T('the console,', 'o console,'), T('the worker', 'o worker')], '--phosphor'),
        (T('what it imports', 'o que ela importa'), [T('a web framework,', 'um framework web,'), T('a PDF library,', 'uma biblioteca de PDF,'), T('the gateway client,', 'o cliente do gateway,'), T('and what they import', 'e o que eles importam')], '--paper-dim'),
        (T('what it calls', 'o que ela chama'), [T('the cloud provider,', 'o provedor de nuvem,'), T('DNS, the SMS provider,', 'o DNS, o provedor de SMS,'), T('the payment gateway', 'o gateway de pagamento')], '--paper-dim'),
        (T('what builds and ships it', 'o que constrói e entrega'), [T('the git host,', 'o host do git,'), T('the CI runner,', 'o executor de CI,'), T('package registries', 'registros de pacotes')], '--amber'),
    ]
    for i, (name, rows, c) in enumerate(rings):
        x = 20 + i * 172
        f.rect(x, 40, 160, 120, stroke=c, fill='--panel', width=1.5)
        f.text(x + 80, 62, name, size=10, weight='600', fill=c if c != '--paper-dim' else '--paper')
        f.lines(x + 80, 108, rows, size=9.5)
        if i < 3:
            f.line(x + 160, 100, x + 172, 100, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(360, 195, T('Each ring runs with the trust of the one before it, and you reviewed the first one only.',
                       'Cada anel roda com a confiança do anterior, e você revisou só o primeiro.'),
           size=10.5, fill='--paper')
    f.text(360, 222, T('This workspace alone: 1 package installed on purpose, 5 more that came with it.',
                       'Só este ambiente: 1 pacote instalado de propósito, mais 5 que vieram junto.'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('The surface includes everything that runs with your trust. Most of it you did not write.',
                'A superfície inclui tudo o que roda com a sua confiança. A maior parte disso você não escreveu.')


@figure('l06-shrinking', 6)
def shrinking():
    f = Fig('l06-shrinking', 720, 250, T(
        'Entry points by who can use them without a credential, in three states. As drawn in '
        'lesson 2: four entry points, two open to anyone, the sign-in form and the webhook, and two '
        'that need a credential. As it is, with the console answering the internet: five, three '
        'open to anyone. After two changes, the webhook signature and the console on the clinic '
        'network only: four, one open to anyone, the patient sign-in form.',
        'Pontos de entrada por quem consegue usá-los sem credencial, em três estados. Como '
        'desenhado na aula 2: quatro pontos de entrada, dois abertos a qualquer um, o formulário de '
        'login e o webhook, e dois que pedem credencial. Como está, com o console respondendo à '
        'internet: cinco, três abertos a qualquer um. Depois de duas mudanças, a assinatura do '
        'webhook e o console só na rede da clínica: quatro, um aberto a qualquer um, o formulário '
        'de login do paciente.'))
    states = [(T('as drawn in lesson 2', 'como desenhado na aula 2'), 2, 2),
              (T('as it is', 'como está'), 3, 2),
              (T('after two changes', 'depois de duas mudanças'), 1, 3)]
    unit = 55
    for i, (label, anyone, cred) in enumerate(states):
        y = 30 + i * 56
        f.text(200, y + 16, label, size=10.5, anchor='end', weight='600')
        f.rect(212, y, anyone * unit, 32, stroke=None, fill='--amber', rx=2)
        f.rect(212 + anyone * unit, y, cred * unit, 32, stroke=None, fill='--phosphor-dim', rx=2)
        for k in range(1, anyone + cred):
            f.line(212 + k * unit, y, 212 + k * unit, y + 32, stroke='--ink', width=2)
        f.text(212 + (anyone + cred) * unit + 10, y + 16,
               T(f'{anyone + cred} entries, {anyone} open to anyone', f'{anyone + cred} entradas, {anyone} abertas a qualquer um'),
               size=9.5, anchor='start')
    f.rect(212, 214, 14, 10, stroke=None, fill='--amber', rx=1)
    f.text(232, 219, T('anyone can send it', 'qualquer um consegue mandar'), size=9.5, anchor='start')
    f.rect(420, 214, 14, 10, stroke=None, fill='--phosphor-dim', rx=1)
    f.text(440, 219, T('needs a credential', 'exige credencial'), size=9.5, anchor='start')
    return f, T('Counting entry points is a start. Counting the ones a stranger can use is the number that moves when the surface really shrinks.',
                'Contar pontos de entrada é um começo. Contar os que um desconhecido consegue usar é o número que se mexe quando a superfície encolhe de verdade.')


@figure('l06-three-sets', 6)
def three_sets():
    f = Fig('l06-three-sets', 720, 200, T(
        'Manadhata and Wing’s three sets that make up an attack surface, with an example of each at '
        'the portal. Entry and exit points: the webhook handler. Channels: HTTPS from the vendors. '
        'Untrusted data items: an uploaded PDF.',
        'Os três conjuntos de Manadhata e Wing que formam uma superfície de ataque, com um exemplo '
        'de cada no portal. Pontos de entrada e saída: o tratador do webhook. Canais: HTTPS vindo dos '
        'fornecedores. Itens de dado não confiáveis: um PDF enviado.'))
    sets = [(T('entry and exit points', 'pontos de entrada e saída'), T('the webhook handler', 'o tratador do webhook')),
            (T('channels', 'canais'), T('HTTPS from the vendors', 'HTTPS dos fornecedores')),
            (T('untrusted data items', 'itens de dado não confiáveis'), T('an uploaded PDF', 'um PDF enviado'))]
    for i, (name, ex) in enumerate(sets):
        x = 20 + i * 235
        f.rect(x, 30, 210, 100, stroke='--phosphor', fill='--panel', width=1.4)
        f.text(x + 105, 60, name, size=10.5, weight='600')
        f.text(x + 105, 100, ex, size=10, fill='--paper-dim')
    f.text(360, 170, T('all three are already in the DFD: flows across a boundary, their transport, their data', 'os três já estão no DFD: fluxos que cruzam uma fronteira, o transporte, os dados'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('The definition is three lists, and a data flow diagram already holds all of them.',
                'A definição são três listas, e um diagrama de fluxo de dados já guarda todas.')


@figure('l06-two-inputs', 6)
def two_inputs():
    rows = [(T('reach without a credential?', 'alcance sem credencial?'), T('anyone', 'qualquer um'), T('patients after sign-in', 'pacientes após o login')),
            (T('what does it change?', 'o que muda?'), T('money: a booking paid', 'dinheiro: um agendamento pago'), T('the patient’s exams, storage', 'os exames do paciente, armazenamento')),
            (T('what parses it?', 'o que interpreta?'), T('a body that is trusted', 'um corpo em que se confia'), T('a PDF library (T14)', 'uma biblioteca de PDF (T14)')),
            (T('how large, how often?', 'tamanho, frequência?'), T('nothing limits the calls', 'nada limita as chamadas'), T('no size limit (T10)', 'sem limite de tamanho (T10)'))]
    f = Fig('l06-two-inputs', 720, 260, T(
        'Two inputs through the four questions. The payment webhook: anyone can reach it, it changes '
        'money, its body is trusted, and nothing limits how often it is called. The exam upload: '
        'patients reach it after signing in, it changes the patient’s exams and the storage, a PDF '
        'library parses it, which is T14, and it has no size limit, which is T10.',
        'Duas entradas pelas quatro perguntas. O webhook de pagamento: qualquer um o alcança, ele '
        'muda dinheiro, o corpo dele é confiável, e nada limita quantas vezes é chamado. O upload de '
        'exame: pacientes o alcançam depois do login, ele muda os exames do paciente e o '
        'armazenamento, uma biblioteca de PDF o interpreta, que é a T14, e não tem limite de tamanho, '
        'que é a T10.'))
    f.text(355, 18, T('payment webhook', 'webhook de pagamento'), size=10.5, weight='600')
    f.text(585, 18, T('exam upload', 'upload de exame'), size=10.5, weight='600')
    for i, (q, a, b) in enumerate(rows):
        y = 35 + i * 52
        f.rect(20, y, 220, 42, stroke='--wire', fill='--panel', width=1)
        f.text(32, y + 21, q, size=10, anchor='start')
        f.rect(250, y, 210, 42, stroke='--amber', fill='--panel', width=1.3)
        f.text(355, y + 21, a, size=10)
        f.rect(470, y, 230, 42, stroke='--amber' if i >= 2 else '--paper-dim', fill='--panel', width=1.3)
        f.text(585, y + 21, b, size=10)
    f.text(360, 250, T('amber: the answer that puts an input near the top of the list', 'âmbar: a resposta que põe uma entrada perto do topo da lista'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('The webhook answers all four questions badly, which is why it tops the list before any detailed analysis.',
                'O webhook responde mal às quatro perguntas, e é por isso que fica no topo da lista antes de qualquer análise detalhada.')


@figure('l06-reach-change', 6)
def reach_change():
    f = Fig('l06-reach-change', 720, 280, T(
        'The portal’s five entry points placed by who can reach them without a credential, across, '
        'and by what they change, up. The payment webhook: anyone who knows the address, and it '
        'changes whether a booking is paid. Sign in and book: anyone, and it changes the patient’s '
        'bookings. The staff sign-in page: anyone, and it changes nothing by itself but guards every '
        'patient’s record. Upload exam PDF: patients only, the patient’s exams. Manage the agenda: '
        'staff only, every patient’s record.',
        'As cinco entradas do portal posicionadas por quem as alcança sem credencial, na horizontal, '
        'e pelo que mudam, na vertical. O webhook de pagamento: qualquer um que saiba o endereço, e '
        'muda se um agendamento está pago. Entrar e agendar: qualquer um, e muda os agendamentos do '
        'paciente. A página de login da equipe: qualquer um, e não muda nada sozinha, mas guarda '
        'todo prontuário. Upload de exame: só pacientes, os exames do paciente. Gerenciar a agenda: '
        'só a equipe, todo prontuário.'))
    f.line(120, 240, 700, 240, arrow=True)
    f.line(120, 240, 120, 20, arrow=True)
    for x, lab in ((210, T('anyone', 'qualquer um')), (420, T('patients', 'pacientes')), (620, T('staff', 'equipe'))):
        f.text(x, 258, lab, size=10, fill='--paper-dim')
    for y, lab in ((200, T('own data', 'dado próprio')), (130, T('money', 'dinheiro')), (60, T('everyone’s data', 'dado de todos'))):
        f.text(112, y, lab, size=9.5, anchor='end', fill='--paper-dim')
    pts = [(210, 130, T('payment webhook', 'webhook de pagamento'), '--amber'),
           (210, 200, T('sign in and book', 'entrar e agendar'), '--paper-dim'),
           (210, 60, T('staff sign-in page (guards it)', 'login da equipe (guarda)'), '--amber'),
           (420, 200, T('upload exam PDF', 'upload de exame'), '--paper-dim'),
           (620, 60, T('manage the agenda', 'gerenciar a agenda'), '--paper-dim')]
    for x, y, lab, c in pts:
        f.circle(x, y, 7, fill=c)
        f.text(x + 12, y - 12, lab, size=9.5, anchor='start')
    f.text(410, 275, T('top left is where to look first', 'em cima à esquerda é onde olhar primeiro'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('Two questions rank the entries better than their number: who reaches it with nothing, and what they can change.',
                'Duas perguntas ordenam as entradas melhor que a quantidade delas: quem chega sem nada, e o que consegue mudar.')


@figure('l06-minimise', 6)
def minimise():
    f = Fig('l06-minimise', 720, 220, T(
        'Two outputs, each carrying one item more than it needs. The charge sent to the gateway '
        'carries the amount, the booking id, the name and the CPF; the CPF is the item it does not '
        'need. The reminder sent to the SMS provider carries the phone, the first name, the time and '
        'the clinic; the clinic’s name is the item that discloses treatment, T08.',
        'Duas saídas, cada uma levando um item a mais do que precisa. A cobrança mandada ao gateway '
        'leva o valor, o id do agendamento, o nome e o CPF; o CPF é o item de que ela não precisa. O '
        'lembrete mandado ao provedor de SMS leva o telefone, o primeiro nome, o horário e a clínica; '
        'o nome da clínica é o item que revela o tratamento, a T08.'))
    outs = [(T('charge to the gateway', 'cobrança ao gateway'), [T('amount', 'valor'), T('booking id', 'id do agendamento'), T('name', 'nome')], 'CPF'),
            (T('reminder to the SMS provider', 'lembrete ao provedor de SMS'), [T('phone', 'telefone'), T('first name', 'primeiro nome'), T('time', 'horário')], T('clinic (T08)', 'clínica (T08)'))]
    for i, (name, keep, drop) in enumerate(outs):
        y = 25 + i * 95
        f.text(20, y + 10, name, size=10.5, anchor='start', weight='600')
        for j, item in enumerate(keep):
            x = 20 + j * 150
            f.rect(x, y + 25, 140, 36, stroke='--phosphor', fill='--panel', width=1.2)
            f.text(x + 70, y + 43, item, size=10)
        x = 20 + 3 * 150
        f.rect(x, y + 25, 140, 36, stroke='--amber', fill='--panel', width=1.2, dash='4 3')
        f.text(x + 70, y + 43, drop, size=10, fill='--amber')
        f.text(x + 150, y + 43, T('not needed', 'não precisa'), size=9.5, anchor='start', fill='--amber', italic=True)
    f.text(360, 210, T('send the least that does the job', 'mandar o mínimo que faz o trabalho'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('Every item beyond what the job needs is surface that buys nothing, and in a clinic it is usually personal data.',
                'Todo item além do que o trabalho pede é superfície que não compra nada, e numa clínica normalmente é dado pessoal.')
