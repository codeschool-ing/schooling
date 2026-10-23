"""Lesson 11: envelope encryption."""
from figures import Fig, T, figure


@figure('l11-envelope', 11)
def envelope():
    f = Fig('l11-envelope', 720, 330, T(
        'Envelope encryption. On the left, inside KMS, the KMS key, which never leaves. KMS generates a '
        'data key and returns it twice: in plain text, and encrypted under the KMS key. In the middle, '
        'the service encrypts the data with the plain data key, using AES, and then erases the plain '
        'key. On the right, what is stored: the encrypted data with the encrypted data key beside it, '
        'like a letter in its envelope. To read it back, only the encrypted data key goes to KMS, which '
        'checks the caller\'s permission before returning the plain key.',
        'Criptografia de envelope. À esquerda, dentro do KMS, a chave do KMS, que nunca sai. O KMS gera '
        'uma chave de dados e a devolve duas vezes: em texto claro e cifrada com a chave do KMS. No meio, '
        'o serviço cifra os dados com a chave de dados em claro, usando AES, e depois apaga a chave em '
        'claro. À direita, o que fica guardado: os dados cifrados com a chave de dados cifrada ao lado, '
        'como uma carta no envelope. Para ler de volta, só a chave de dados cifrada vai ao KMS, que '
        'verifica a permissão de quem pede antes de devolver a chave em claro.'))
    # KMS
    f.rect(20, 40, 180, 240, stroke='--paper-dim', fill='--panel', dash='5 4')
    f.text(110, 60, 'KMS', size=12, weight='600', fill='--paper-dim')
    f.rect(40, 90, 140, 50, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(110, 108, T('KMS key', 'chave do KMS'), size=10.5, weight='600', fill='--phosphor')
    f.text(110, 126, T('never leaves', 'nunca sai'), size=9.5, fill='--paper-dim', italic=True)
    f.lines(110, 200, [T('generates a', 'gera uma'), T('data key and', 'chave de dados'),
                       T('returns it twice', 'e a devolve 2 vezes')], size=10, fill='--paper')
    # middle: the service
    f.rect(250, 40, 210, 240, stroke='--wire', fill='--panel')
    f.text(355, 60, T('the service', 'o serviço'), size=12, weight='600')
    f.rect(270, 82, 170, 34, stroke='--amber', fill='--scan')
    f.text(355, 99, T('plain data key', 'chave de dados em claro'), size=10, fill='--amber')
    f.rect(270, 128, 170, 34, stroke='--wire', fill='--scan')
    f.text(355, 145, T('encrypted data key', 'chave de dados cifrada'), size=10)
    f.text(355, 186, T('AES with the plain key', 'AES com a chave em claro'), size=10)
    f.text(355, 206, T('encrypts the data', 'cifra os dados'), size=10)
    f.text(355, 246, T('then erases the plain key', 'depois apaga a chave em claro'), size=10, fill='--amber')
    f.arrow([(200, 105), (268, 99)], stroke='--paper-dim')
    f.arrow([(200, 125), (268, 145)], stroke='--paper-dim')
    # right: storage
    f.rect(510, 40, 190, 240, stroke='--phosphor', fill='--panel')
    f.text(605, 60, T('what is stored', 'o que fica guardado'), size=12, weight='600')
    f.rect(530, 90, 150, 100, stroke='--wire', fill='--scan')
    f.text(605, 140, T('encrypted data', 'dados cifrados'), size=10.5)
    f.rect(530, 202, 150, 34, stroke='--wire', fill='--scan')
    f.text(605, 219, T('encrypted data key', 'chave de dados cifrada'), size=10)
    f.arrow([(460, 145), (528, 140)], stroke='--paper-dim')
    f.arrow([(460, 150), (528, 214)], stroke='--paper-dim')
    f.path('M605 282 L605 306 L110 306 L110 282', stroke='--phosphor', dash='4 3', arrow=True)
    f.text(357, 296, T('to read: only the encrypted data key goes back to KMS, which checks the caller',
                       'para ler: só a chave cifrada volta ao KMS, que verifica quem pede'),
           size=9.5, fill='--phosphor')
    return f, T('KMS holds one key and never sees the data; each object carries its own data key, locked '
                'under it. Every read asks KMS again, with the caller\'s identity on the request.',
                'O KMS guarda uma chave e nunca vê os dados; cada objeto carrega a própria chave de dados, '
                'trancada sob ela. Toda leitura pergunta de novo ao KMS, com a identidade de quem pede na '
                'requisição.')
