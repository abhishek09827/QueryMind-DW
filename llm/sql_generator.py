from __future__ import annotations

import json
import os
import re
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

try:
    import google.generativeai as genai
except Exception:  # pragma: no cover - optional fallback
    genai = None

from .prompt_templates import FEW_SHOT_EXAMPLES, get_system_message


DEFAULT_OPENROUTER_MODELS = [
    "openrouter/free",
    "tencent/hy3-preview:free",
    "qwen/qwen3-coder:free",
    "google/gemma-4-31b-it:free",
    "deepseek/deepseek-chat-v3-0324",
]
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


class SQLGenerator:
    def __init__(self, schema_context: list[dict[str, Any]]):
        self.system_message = get_system_message(schema_context)
        self.openrouter_key = os.getenv("OPENROUTER_KEY") or os.getenv("OPENROUTER_API_KEY")
        models_env = os.getenv("OPENROUTER_MODELS")
        if models_env:
            self.openrouter_models = [item.strip() for item in models_env.split(",") if item.strip()]
        else:
            self.openrouter_models = list(DEFAULT_OPENROUTER_MODELS)
        self.gemini_key = os.getenv("GEMINI_API_KEY")
        self.backend = None
        self.model = None
        self.last_model_used = None

        if self.openrouter_key:
            self.backend = "openrouter"
            return

        if self.gemini_key and genai is not None:
            self.backend = "gemini"
            genai.configure(api_key=self.gemini_key)
            self.model = genai.GenerativeModel(
                "models/gemini-2.5-flash",
                system_instruction=self.system_message,
            )

    def _build_history(self, compact: bool = False, examples: list[dict[str, str]] | None = None) -> list[dict[str, str]]:
        if compact:
            return []
        history: list[dict[str, str]] = []
        for example in examples or FEW_SHOT_EXAMPLES:
            history.append({"role": "user", "content": example["user"]})
            history.append({"role": "assistant", "content": example["sql"].strip()})
        return history

    @staticmethod
    def _clean_sql(text: str) -> str:
        cleaned = text.strip().replace("```sql", "").replace("```", "").strip()
        cleaned = re.sub(r"\bmain\.", "", cleaned)
        cleaned = cleaned.rstrip(";").strip()
        if cleaned.startswith("SELECT") or cleaned.startswith("WITH"):
            return cleaned

        match = re.search(r"(SELECT|WITH)\b.*", cleaned, flags=re.IGNORECASE | re.DOTALL)
        if match:
            return re.sub(r"\bmain\.", "", match.group(0).strip()).rstrip(";").strip()
        return cleaned

    def _generate_openrouter_sql(self, user_question: str, compact: bool = False, examples: list[dict[str, str]] | None = None) -> str:
        payload = {
            "model": None,
            "messages": [
                {"role": "system", "content": self.system_message},
                *self._build_history(compact=compact, examples=examples),
                {"role": "user", "content": user_question},
            ],
            "temperature": 0.0,
            "max_tokens": 200 if compact else 520,
        }

        headers = {
            "Authorization": f"Bearer {self.openrouter_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/abhishek09827/QueryMind-DW",
            "X-Title": "QueryMind-DW Benchmark",
        }

        last_error = None
        for model_name in self.openrouter_models:
            payload["model"] = model_name
            request = Request(
                OPENROUTER_URL,
                data=json.dumps(payload).encode("utf-8"),
                headers=headers,
                method="POST",
            )
            try:
                with urlopen(request, timeout=120) as response:
                    data = json.loads(response.read().decode("utf-8"))
                content = data["choices"][0]["message"]["content"]
                sql = self._clean_sql(content)
                if sql.startswith("SELECT") or sql.startswith("WITH"):
                    self.last_model_used = model_name
                    return sql
                last_error = f"Non-SQL response from {model_name}"
            except HTTPError as exc:
                last_error = f"{model_name}: HTTP {exc.code}"
                if exc.code not in {429, 500, 502, 503, 504}:
                    break
            except URLError as exc:
                last_error = f"{model_name}: {exc}"
            except Exception as exc:
                last_error = f"{model_name}: {exc}"

            time.sleep(0.5)

        return f"Error calling OpenRouter after fallbacks: {last_error}"

    def _generate_gemini_sql(self, user_question: str, compact: bool = False, examples: list[dict[str, str]] | None = None) -> str:
        if not self.model:
            return "ERROR: OPENROUTER_KEY or GEMINI_API_KEY not found in environment variables."

        try:
            chat = self.model.start_chat(history=self._build_history(compact=compact, examples=examples))
            response = chat.send_message(
                user_question,
                generation_config=genai.types.GenerationConfig(
                    candidate_count=1,
                    max_output_tokens=200 if compact else 520,
                    temperature=0.0,
                ),
            )
            sql = self._clean_sql(response.text)
            self.last_model_used = "gemini-2.5-flash"
            return sql
        except Exception as exc:
            return f"Error calling Gemini: {exc}"

    def generate_sql(self, user_question: str, compact: bool = False, examples: list[dict[str, str]] | None = None) -> str:
        """
        Generates SQL from user question using OpenRouter first, then Gemini fallback.
        """
        if self.backend == "openrouter":
            return self._generate_openrouter_sql(user_question, compact=compact, examples=examples)
        return self._generate_gemini_sql(user_question, compact=compact, examples=examples)
