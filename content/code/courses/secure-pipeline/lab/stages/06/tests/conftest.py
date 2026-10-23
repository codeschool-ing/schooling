import os

# The application refuses to start without a token. The tests bring one of
# their own, which opens nothing anywhere else.
os.environ.setdefault("LINKBOX_TOKEN", "a-token-for-the-tests-only")
