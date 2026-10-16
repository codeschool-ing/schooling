"""Lesson 19: the Top 10 from 2021 to 2025, and the parts of a log line."""
from figures import Fig, T, figure


@figure('l19-changes', 19)
def changes():
    f = Fig('l19-changes', 720, 345, T(
        'Two columns of ten categories, the OWASP Top 10 of 2021 on the left and of 2025 on the '
        'right, with a line from each old category to where it went. Broken Access Control stays '
        'A01, and 2021\'s A10, server-side request forgery, joins it there. Cryptographic Failures '
        'moves from A02 to A04, Injection from A03 to A05, Insecure Design from A04 to A06, Security '
        'Misconfiguration from A05 up to A02. Vulnerable and Outdated Components, A06, becomes the '
        'wider A03, Software Supply Chain Failures. Authentication, integrity and logging keep A07, '
        'A08 and A09 under new names. A10 of 2025, Mishandling of Exceptional Conditions, has no '
        'line into it: it is new.',
        'Duas colunas de dez categorias, o OWASP Top 10 de 2021 à esquerda e o de 2025 à direita, '
        'com uma linha de cada categoria antiga até onde ela foi. Broken Access Control continua '
        'A01, e o A10 de 2021, a falsificação de requisição do lado do servidor, entra nela. '
        'Cryptographic Failures passa de A02 para A04, Injection de A03 para A05, Insecure Design de '
        'A04 para A06, Security Misconfiguration sobe de A05 para A02. Vulnerable and Outdated '
        'Components, A06, vira a A03, mais ampla, Software Supply Chain Failures. Autenticação, '
        'integridade e log mantêm A07, A08 e A09 com nomes novos. O A10 de 2025, Mishandling of '
        'Exceptional Conditions, não recebe linha nenhuma: é nova.'))
    old = ['Broken Access Control', 'Cryptographic Failures', 'Injection', 'Insecure Design',
           'Security Misconfiguration', 'Vulnerable and Outdated Components',
           'Identification and Authentication Failures', 'Software and Data Integrity Failures',
           'Security Logging and Monitoring Failures', 'Server-Side Request Forgery']
    new = ['Broken Access Control', 'Security Misconfiguration', 'Software Supply Chain Failures',
           'Cryptographic Failures', 'Injection', 'Insecure Design', 'Authentication Failures',
           'Software or Data Integrity Failures', 'Security Logging and Alerting Failures',
           'Mishandling of Exceptional Conditions']
    goes = [0, 3, 4, 5, 1, 2, 6, 7, 8, 0]
    f.text(150, 20, '2021', size=11, weight='600', fill='--paper-dim', mono=True)
    f.text(570, 20, '2025', size=11, weight='600', fill='--paper-dim', mono=True)
    y0, gap = 50, 27
    for i, name in enumerate(old):
        y = y0 + i * gap
        f.rect(8, y - 10, 272, 20, stroke='--wire', fill='--panel', width=1)
        f.text(16, y, f'A{i + 1:02d}', size=9.5, anchor='start', mono=True, fill='--paper-dim')
        f.text(48, y, name, size=9.5, anchor='start')
    for i, name in enumerate(new):
        y = y0 + i * gap
        hot = i in (2, 9)
        f.rect(430, y - 10, 282, 20, stroke='--amber' if hot else '--wire', fill='--panel',
               width=1.4 if hot else 1)
        f.text(438, y, f'A{i + 1:02d}', size=9.5, anchor='start', mono=True, fill='--paper-dim')
        f.text(470, y, name, size=9.5, anchor='start')
    for i, j in enumerate(goes):
        ya, yb = y0 + i * gap, y0 + j * gap
        same = i == j
        f.path(f'M280 {ya:.1f} C355 {ya:.1f} 355 {yb:.1f} 426 {yb:.1f}',
               stroke='--paper-dim' if same else '--phosphor', width=1.2, arrow=True,
               dash='4 3' if i == 9 else None)
    f.text(704, y0 + 2 * gap, T('wider', 'mais ampla'), size=9.5, anchor='end', fill='--amber')
    f.text(704, y0 + 9 * gap, T('new', 'nova'), size=9.5, anchor='end', fill='--amber')
    f.text(570, y0 + 10 * gap + 6, T('A10 is new: nothing leads into it', 'A10 é nova: nada chega a ela'),
           size=10, fill='--amber')
    f.text(150, y0 + 10 * gap + 6, T('SSRF joins A01', 'SSRF entra na A01'), size=10, fill='--phosphor')
    return f, T('From 2021 to 2025: most categories moved, SSRF joined access control, and two '
                'categories are new or wider.',
                'De 2021 para 2025: a maioria das categorias mudou de lugar, a SSRF entrou no controle '
                'de acesso, e duas categorias são novas ou mais amplas.')


@figure('l19-logline', 19)
def logline():
    f = Fig('l19-logline', 720, 230, T(
        'One line from account.py\'s log, cut into its parts: 2026-10-15 21:39:57,464 is when, '
        'WARNING is the severity, refused is the outcome, GET /staff/bookings is what was asked, '
        'account 1 is who asked, and staff only is why it was refused. Below, the things a line '
        'never carries: a password, a session token, a cookie, an API key.',
        'Uma linha do log do account.py, cortada nas suas partes: 2026-10-15 21:39:57,464 é quando, '
        'WARNING é a gravidade, refused é o resultado, GET /staff/bookings é o que foi pedido, '
        'account 1 é quem pediu, e staff only é o motivo da recusa. Embaixo, o que uma linha nunca '
        'carrega: uma senha, um token de sessão, um cookie, uma chave de API.'))
    f.text(360, 20, T('a line somebody can read tomorrow', 'uma linha que alguém consegue ler amanhã'),
           size=11, weight='600', fill='--paper-dim')
    cw, x0, y = 6.3, 96, 70
    parts = [('2026-10-15 21:39:57,464', T('when', 'quando')),
             (' ', None), ('WARNING', T('severity', 'gravidade')), (' ', None),
             ('refused', T('outcome', 'resultado')), (' ', None),
             ('GET /staff/bookings', T('what', 'o quê')), (' to ', None),
             ('account 1', T('who', 'quem')), (': ', None), ('staff only', T('why', 'por quê'))]
    f.rect(x0 - 12, y - 18, len(''.join(p for p, _ in parts)) * cw + 24, 36, stroke='--wire',
           fill='--ink', width=1.2)
    x = x0
    for i, (s, label) in enumerate(parts):
        w = len(s) * cw
        if s.strip():
            lead = (len(s) - len(s.lstrip())) * cw
            f.text(x + lead, y, s.strip(), size=10.5, anchor='start', mono=True,
                   fill='--paper' if label else '--paper-dim')
        if label:
            f.line(x + 1, y + 24, x + w - 1, y + 24, stroke='--phosphor', width=1.4)
            ly = y + 40 if i % 4 == 0 else y + 56
            f.line(x + w / 2, y + 24, x + w / 2, ly - 8, stroke='--phosphor', width=1)
            f.text(x + w / 2, ly, label, size=10, weight='600', fill='--phosphor')
        x += w
    f.rect(150, 170, 420, 40, stroke='--amber', fill='--panel', width=1.4, dash='5 4')
    f.text(360, 182, T('never in a line', 'nunca numa linha'), size=10, weight='600', fill='--amber')
    f.text(360, 199, T('a password · a session token · a cookie · an API key',
                       'uma senha · um token de sessão · um cookie · uma chave de API'), size=10)
    return f, T('When, who, what and the outcome, and no secret: the refusal line already has all of '
                'it.',
                'Quando, quem, o quê e o resultado, e nenhum segredo: a linha da recusa já tem tudo isso.')
