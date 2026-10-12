from dataclasses import dataclass
import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[1] / ".env")


@dataclass(frozen=True)
class Settings:
    supabase_url: str
    publishable_key: str

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            supabase_url=os.getenv("SUPABASE_URL", "").rstrip("/"),
            publishable_key=os.getenv("SUPABASE_PUBLISHABLE_KEY", ""),
        )

    @property
    def configured(self) -> bool:
        return bool(self.supabase_url and self.publishable_key)
