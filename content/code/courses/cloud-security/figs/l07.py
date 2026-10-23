"""Lesson 7: rotating an access key with two keys and no outage."""
from figures import Fig, T, figure


@figure('l07-rotation', 7)
def rotation():
    f = Fig('l07-rotation', 720, 270, T(
        'Rotating an access key without an outage, as a timeline of two keys. Step 1: the old key is '
        'active and the application uses it. Step 2: a second key is created; both are active. Step 3: '
        'the application is switched to the new key. Step 4: the old key is deactivated and its last '
        'use is watched for a while. Step 5: the old key is deleted. At every moment the application '
        'holds a key that works.',
        'Rotação de uma chave de acesso sem interrupção, como uma linha do tempo de duas chaves. Passo '
        '1: a chave antiga está ativa e a aplicação a usa. Passo 2: uma segunda chave é criada; as duas '
        'estão ativas. Passo 3: a aplicação passa para a chave nova. Passo 4: a chave antiga é '
        'desativada e o último uso dela é observado por um tempo. Passo 5: a chave antiga é apagada. A '
        'todo momento a aplicação tem uma chave que funciona.'))
    xs = [150, 260, 370, 480, 590]
    steps = [T('create', 'criar'), T('switch', 'trocar'), T('deactivate', 'desativar'), T('delete', 'apagar')]
    f.text(70, 76, T('old key', 'chave antiga'), size=10.5, anchor='end')
    f.text(70, 136, T('new key', 'chave nova'), size=10.5, anchor='end')
    # old key: active until step 4, inactive until step 5
    f.rect(80, 60, xs[3] - 80, 32, stroke='--amber', fill='--scan')
    f.text(xs[2] - 60, 76, T('active', 'ativa'), size=10, fill='--paper-dim')
    f.rect(xs[3], 60, xs[4] - xs[3], 32, stroke='--paper-dim', fill='--panel', dash='4 3')
    f.text((xs[3] + xs[4]) / 2, 76, T('inactive', 'inativa'), size=10, fill='--paper-dim')
    # new key: from step 2 onwards
    f.rect(xs[1], 120, 680 - xs[1], 32, stroke='--phosphor', fill='--scan')
    f.text((xs[3] + 680) / 2, 136, T('active', 'ativa'), size=10, fill='--paper-dim')
    # the application, in a lane of its own below the keys
    f.text(70, 186, T('application', 'aplicação'), size=10.5, anchor='end')
    f.line(80, 186, xs[2], 186, stroke='--amber', width=3)
    f.line(xs[2], 186, 680, 186, stroke='--phosphor', width=3)
    f.text((80 + xs[2]) / 2, 172, T('uses the old key', 'usa a chave antiga'), size=9.5, fill='--paper-dim')
    f.text((xs[2] + 680) / 2, 172, T('uses the new key', 'usa a chave nova'), size=9.5, fill='--paper-dim')
    for i, (x, st) in enumerate(zip(xs[1:], steps)):
        f.line(x, 40, x, 56, stroke='--wire', dash='3 3')
        f.line(x, 96, x, 116, stroke='--wire', dash='3 3')
        f.line(x, 156, x, 196, stroke='--wire', dash='3 3')
        f.text(x, 32, f'{i + 2}. {st}', size=10, weight='600')
    f.text(80, 32, T('1. old key only', '1. só a antiga'), size=10, weight='600', anchor='start')
    f.text(360, 230, T('at every moment the application holds a key that works',
                       'a todo momento a aplicação tem uma chave que funciona'), size=11, fill='--phosphor')
    f.text(360, 252, T('two keys per user is the limit: step 5 makes room for the next rotation',
                       'duas chaves por usuário é o limite: o passo 5 abre espaço para a próxima rotação'),
           size=9.5, fill='--paper-dim')
    return f, T('The five steps in time. Deleting first and creating second would leave a gap where the '
                'application holds nothing that works.',
                'Os cinco passos no tempo. Apagar primeiro e criar depois deixaria um intervalo em que a '
                'aplicação não tem nada que funcione.')
