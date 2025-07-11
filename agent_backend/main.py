from fastapi import FastAPI
from pydantic import BaseModel
from agent import Agent  # import the wrapper

app = FastAPI()
agent = Agent()

OLLAMA_URL = "http://localhost:11434/api/generate"

class PromptRequest(BaseModel):
    prompt: str

@app.post("/chat")
async def chat_with_ai(data: PromptRequest):
    response = await agent.get_response(data.prompt)
    return {"response": response}
