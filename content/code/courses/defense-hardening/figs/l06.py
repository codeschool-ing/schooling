"""Lesson 6: filesystem access control lists."""
from figures import Fig, T, figure


@figure('l06-resolve', 6)
def resolve():
    f = Fig('l06-resolve', 720, 300, T(
        'How Linux resolves a POSIX ACL, as four questions asked in order, stopping at the first yes. '
        'One: does the user own the file? Then the owner entry decides. Two: is there a named entry '
        'for the user? Then that entry, limited by the mask, decides. Three: is the owning group or '
        'a named group one of the user\'s groups? Then access is granted if any matching group entry, '
        'limited by the mask, allows it, and refused otherwise. Four: otherwise the other entry '
        'decides. The example: the auditor, in the writing group but with a named entry for read, '
        'stops at question two and gets read only.',
        'Como o Linux resolve uma ACL POSIX, em quatro perguntas feitas em ordem, parando no primeiro '
        'sim. Um: o usuário é dono do arquivo? Então a entrada do dono decide. Dois: há uma entrada '
        'com o nome do usuário? Então essa entrada, limitada pela máscara, decide. Três: o grupo dono '
        'ou um grupo nomeado é um dos grupos do usuário? Então o acesso é dado se alguma entrada de '
        'grupo que casa, limitada pela máscara, permitir, e recusado caso contrário. Quatro: senão, a '
        'entrada other decide. O exemplo: a auditora, no grupo que grava mas com uma entrada nomeada '
        'de leitura, para na pergunta dois e fica só com leitura.'))
    qs = [(T('1  owner?', '1  dono?'), 'user::'),
          (T('2  named user?', '2  usuário nomeado?'), 'user:auditoria:r--'),
          (T('3  one of my groups?', '3  um dos meus grupos?'), 'group::rw-'),
          (T('4  everybody else', '4  todos os outros'), 'other::---')]
    for i, (q, e) in enumerate(qs):
        y = 30 + i * 62
        hit = i == 1
        f.rect(20, y, 250, 44, stroke='--phosphor' if hit else '--wire', fill='--panel', width=1.5, rx=3)
        f.text(36, y + 22, q, size=10.5, anchor='start', weight='600')
        f.text(300, y + 22, e, size=10, anchor='start', mono=True, fill='--phosphor' if hit else '--paper-dim')
        if i < 3:
            f.line(145, y + 44, 145, y + 62, stroke='--paper-dim', width=1.2, arrow=True)
            f.text(155, y + 53, T('no', 'não'), size=9, anchor='start', fill='--paper-dim')
    f.rect(470, 80, 230, 70, stroke='--phosphor', fill='--scan', width=1.2, rx=3)
    f.text(585, 100, T('the auditor asks to write', 'a auditora pede para gravar'), size=10)
    f.text(585, 122, T('stops at 2: read only', 'para no 2: só leitura'), size=10.5, weight='600', fill='--phosphor')
    f.text(585, 140, T('step 3 is never asked', 'o passo 3 nem é perguntado'), size=9.5, fill='--paper-dim')
    f.line(470, 115, 440, 115, stroke='--phosphor', width=1.2, arrow=True)
    f.text(360, 282, T('steps 2 and 3 are limited by the mask', 'os passos 2 e 3 são limitados pela máscara'),
           size=9.5, fill='--paper-dim')
    return f, T('The first class that applies decides. Entries are never added up.',
                'A primeira classe que se aplica decide. As entradas nunca são somadas.')


@figure('l06-mask', 6)
def mask():
    f = Fig('l06-mask', 720, 240, T(
        'The mask as a ceiling. Before chmod 640, the entries for portal and for the group say rw and '
        'the mask is rw, so each gets rw. After chmod 640, the mask is r, so portal and the group each '
        'get only r, although their own entries still say rw. The owner and other are outside the '
        'mask and are unchanged.',
        'A máscara como teto. Antes do chmod 640, as entradas do portal e do grupo dizem rw e a '
        'máscara é rw, então cada um fica com rw. Depois do chmod 640, a máscara é r, então o portal e o '
        'grupo ficam só com r, embora as próprias entradas ainda digam rw. O dono e o other ficam fora '
        'da máscara e não mudam.'))
    for x, title, m in [(20, T('before chmod 640', 'antes do chmod 640'), 'rw-'),
                        (380, T('after chmod 640', 'depois do chmod 640'), 'r--')]:
        f.text(x + 160, 24, title, size=10.5, weight='600', fill='--paper-dim')
        f.rect(x, 40, 320, 34, stroke='--amber', fill='--scan', width=1.2, rx=2)
        f.text(x + 12, 57, 'mask::' + m, size=10.5, anchor='start', mono=True, fill='--amber')
        f.text(x + 308, 57, T('ceiling', 'teto'), size=9.5, anchor='end', fill='--amber')
        for i, who in enumerate(['user:portal:rw-', 'group::rw-']):
            y = 100 + i * 46
            f.rect(x, y, 320, 34, stroke='--wire', fill='--panel', width=1.2, rx=2)
            f.text(x + 12, y + 17, who, size=10, anchor='start', mono=True)
            eff = 'rw-' if m == 'rw-' else 'r--'
            f.text(x + 308, y + 17, T('effective ', 'efetivo ') + eff, size=9.5, anchor='end',
                   fill='--phosphor' if eff == 'rw-' else '--amber')
    f.text(360, 218, T('the owner and other are outside the mask', 'o dono e o other ficam fora da máscara'),
           size=9.5, fill='--paper-dim')
    return f, T('chmod on a file with an ACL rewrites the mask, and every entry under it shrinks.',
                'O chmod num arquivo com ACL reescreve a máscara, e toda entrada abaixo dela encolhe.')
