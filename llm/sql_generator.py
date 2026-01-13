import os
import google.generativeai as genai
from .prompt_templates import get_system_message, FEW_SHOT_EXAMPLES

class SQLGenerator:
    def __init__(self, schema_context):
        self.system_message = get_system_message(schema_context)
        self.api_key = os.getenv("GEMINI_API_KEY")
        self.model = None
        
        if self.api_key:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(
                'models/gemini-2.5-flash',
                system_instruction=self.system_message
            )
        
    def generate_sql(self, user_question):
        """
        Generates SQL from user question using Gemini.
        """
        if not self.model:
             return "ERROR: GEMINI_API_KEY not found in environment variables."

        # Build History from Few-Shot Examples
        history = []
        for example in FEW_SHOT_EXAMPLES:
            history.append({"role": "user", "parts": [example['user']]})
            history.append({"role": "model", "parts": [example['sql']]})

        try:
            chat = self.model.start_chat(history=history)
            response = chat.send_message(
                user_question,
                generation_config=genai.types.GenerationConfig(
                    candidate_count=1,
                    max_output_tokens=500,
                    temperature=0.0
                )
            )
            
            sql = response.text.strip()
            
            # Clean up potential markdown formatting
            sql = sql.replace("```sql", "").replace("```", "")
            return sql
        except Exception as e:
            return f"Error calling LLM: {str(e)}"
