# holder.py: a program holding a value in memory that it never writes anywhere
import os
import secrets
import time

token = "session-" + secrets.token_hex(8)  # made here, kept only in this process
print(os.getpid(), flush=True)
time.sleep(600)
