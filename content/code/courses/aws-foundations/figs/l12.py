"""Lesson 12: access keys and their rotation."""
from figures import Fig, T, figure


@figure('l12-rotation', 12)
def rotation():
    f = Fig('l12-rotation', 720, 300, T(
        'The rotation of erp-sync\'s key as a timeline of five steps: create the second key, move '
        'the program to it, check that the old key went quiet, make the old key inactive, and after '
        'a wait delete it. The old key is active until the fourth step, inactive until the fifth, '
        'and gone after it. The new key is active from the first step on. The program signs with '
        'the old key until the second step and with the new one after. Every step is reversible '
        'except the deletion.',
        'A rotação da chave do erp-sync como uma linha do tempo de cinco passos: criar a segunda '
        'chave, mudar o programa para ela, conferir que a chave antiga ficou quieta, deixar a antiga '
        'inativa e, depois de uma espera, apagá-la. A chave antiga fica ativa até o quarto passo, '
        'inativa até o quinto, e some depois dele. A chave nova fica ativa do primeiro passo em '
        'diante. O programa assina com a chave antiga até o segundo passo e com a nova depois. Todo '
        'passo pode ser desfeito, menos a exclusão.'))
    steps = [(190, T('1 create', '1 criar'), T('the second', 'a segunda')),
             (290, T('2 move the', '2 mudar o'), T('program', 'programa')),
             (390, T('3 check', '3 conferir'), T('last used', 'último uso')),
             (490, T('4 make old', '4 antiga'), T('inactive', 'inativa')),
             (630, T('5 delete', '5 apagar'), T('the old key', 'a antiga'))]
    for x, a, b in steps:
        f.text(x, 30, a, size=10, weight='600')
        f.text(x, 45, b, size=10, fill='--paper-dim')
        f.line(x, 56, x, 70, stroke='--wire', width=1.2)
    f.text(560, 38, T('wait', 'espera'), size=9.5, fill='--paper-dim', italic=True)
    f.text(20, 90, T('old key', 'chave antiga'), size=10.5, anchor='start', weight='600')
    f.rect(110, 76, 380, 28, stroke='--phosphor', fill='--scan')
    f.text(300, 90, 'Active', size=10, mono=True)
    f.rect(490, 76, 140, 28, stroke='--amber', fill='--ink', dash='4 3')
    f.text(560, 90, 'Inactive', size=10, mono=True, fill='--amber')
    f.text(20, 140, T('new key', 'chave nova'), size=10.5, anchor='start', weight='600')
    f.rect(190, 126, 510, 28, stroke='--phosphor', fill='--scan')
    f.text(445, 140, 'Active', size=10, mono=True)
    f.text(20, 190, T('the program', 'o programa'), size=10.5, anchor='start', weight='600')
    f.rect(110, 178, 180, 24, stroke='--paper-dim', fill='--panel')
    f.text(200, 190, T('signs with the old', 'assina com a antiga'), size=9.5)
    f.rect(290, 178, 410, 24, stroke='--paper-dim', fill='--panel')
    f.text(495, 190, T('signs with the new', 'assina com a nova'), size=9.5)
    f.line(110, 245, 626, 245, stroke='--phosphor', width=1.4)
    f.text(368, 260, T('every step so far can be undone', 'todo passo até aqui pode ser desfeito'),
           size=10, fill='--phosphor')
    f.line(634, 245, 700, 245, stroke='--amber', width=1.4)
    f.text(667, 260, T('cannot', 'não pode'), size=10, fill='--amber')
    f.text(360, 288, T('two keys at once is the limit, which is why the old one must go',
                       'duas chaves ao mesmo tempo é o limite, por isso a antiga precisa sair'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('The old key is switched off before it is deleted, so that whatever still used it '
                'fails while the failure can be undone.',
                'A chave antiga é desligada antes de ser apagada, para que o que ainda a usava falhe '
                'enquanto a falha pode ser desfeita.')
