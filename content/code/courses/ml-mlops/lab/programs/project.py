"""project.py: where the project's files are, named in full, whatever directory runs it."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SHOP = ROOT / "shop.db"
DATA = ROOT / "data"
MODELS = ROOT / "models"
LABEL_DAYS = 90
