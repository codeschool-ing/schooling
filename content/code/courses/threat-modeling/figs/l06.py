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
