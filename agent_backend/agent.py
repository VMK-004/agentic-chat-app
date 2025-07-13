import httpx

class Agent:
    def __init__(self, model="qwen3:0.6b", base_url="http://localhost:11434/api/generate"):
        self.model = model
        self.base_url = base_url

    async def get_response(self, prompt: str) -> str:
        async with httpx.AsyncClient(timeout=180.0) as client:  # Increased timeout from 70 to 180
            try:
                response = await client.post(self.base_url, json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False
                })
                response.raise_for_status()  # <-- Raise exception for non-200 errors
                return response.json().get("response", "No response from LLM.")
            except httpx.HTTPError as e:
                return f"HTTP error: {str(e)}"
            except Exception as e:
                return f"Unexpected error: {str(e)}"
