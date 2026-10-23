"""Lesson 2: the two kinds of evidence on either side of the line."""
from figures import Fig, T, figure


@figure('l02-evidence', 2)
def evidence():
    f = Fig('l02-evidence', 720, 330, T(
        'The shared responsibility line, with the evidence available on each side. Above the line, '
        'the customer\'s settings: who holds a working key, whether a bucket is encrypted or may be '
        'made public, which ports are open. The evidence for them is a request to the API, and the '
        'answer is about your account, as of now. Below the line, the provider\'s work: the '
        'hypervisor, the buildings, the physical network, its own staff\'s access. The evidence for '
        'it is an auditor\'s report, which is about every customer, over a period in the past.',
        'A linha da responsabilidade compartilhada, com a prova disponível de cada lado. Acima da '
        'linha, as configurações do cliente: quem tem uma chave que funciona, se um bucket é '
        'criptografado ou pode ficar público, quais portas estão abertas. A prova delas é uma '
        'requisição à API, e a resposta é sobre a sua conta, agora. Abaixo da linha, o trabalho do '
        'provedor: o hipervisor, os prédios, a rede física, o acesso da própria equipe dele. A prova '
        'disso é o relatório de um auditor, que fala de todos os clientes, num período passado.'))
    # the two halves
    f.rect(30, 30, 330, 125, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(46, 50, T('yours: settings in your account', 'seu: configurações na sua conta'),
           size=11, anchor='start', weight='600', fill='--phosphor')
    for i, s in enumerate([T('who holds a key that still works', 'quem tem uma chave que ainda funciona'),
                           T('is the bucket encrypted, can it go public', 'o bucket é criptografado, pode ficar público'),
                           T('which ports are open to the internet', 'quais portas estão abertas para a internet')]):
        f.text(56, 80 + i * 24, s, size=10, anchor='start')
    f.line(18, 172, 372, 172, stroke='--amber', width=2, dash='5 4')
    f.text(195, 186, T('the line', 'a linha'), size=9.5, fill='--amber')
    f.rect(30, 200, 330, 110, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(46, 220, T("the provider's: its own work", 'do provedor: o trabalho dele'),
           size=11, anchor='start', weight='600', fill='--paper-dim')
    for i, s in enumerate([T('hypervisor, buildings, physical network', 'hipervisor, prédios, rede física'),
                           T("its own engineers' access", 'o acesso dos próprios engenheiros'),
                           T('the same for every customer', 'o mesmo para todo cliente')]):
        f.text(56, 248 + i * 22, s, size=10, anchor='start')
    # the evidence
    f.arrow([(364, 92), (436, 92)], stroke='--phosphor')
    f.rect(440, 50, 250, 85, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(565, 72, T('ask the API', 'perguntar à API'), size=11, weight='600', fill='--phosphor')
    f.text(565, 96, T('about your account', 'sobre a sua conta'), size=10)
    f.text(565, 116, T('as of now', 'agora'), size=10)
    f.arrow([(364, 255), (436, 255)], stroke='--paper-dim')
    f.rect(440, 212, 250, 85, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(565, 234, T("read an auditor's report", 'ler o relatório de um auditor'), size=11, weight='600',
           fill='--paper-dim')
    f.text(565, 258, T('about every customer', 'sobre todos os clientes'), size=10)
    f.text(565, 278, T('over a period in the past', 'num período passado'), size=10)
    return f, T('The line splits the evidence as well as the work. Only the evidence above it is about '
                'your account, and only you can collect it.',
                'A linha divide a prova além do trabalho. Só a prova acima dela é sobre a sua conta, e só '
                'você pode reuni-la.')
