import hashlib
import hmac


def end_user_id(account, key):
    digest = hmac.new(key, account.encode(), hashlib.sha256).hexdigest()
    return "eu-" + digest[:20]


def naive_id(email):
    return hashlib.sha256(email.strip().lower().encode()).hexdigest()
