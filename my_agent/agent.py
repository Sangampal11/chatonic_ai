from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
import os
from dotenv import load_dotenv
import json

load_dotenv()  # Loads GOOGLE_API_KEY from .env

# Very important: configure with your key
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

# Use a good, fast model
model = genai.GenerativeModel(
    model_name="gemini-2.5-flash",  # ya "gemini-2.0-flash" agar available ho
    generation_config=genai.types.GenerationConfig(
        temperature=0.4,            # Kam temperature = zyada deterministic/code accurate
        max_output_tokens=4000,     # Lamba code allow karne ke liye
    ),
    system_instruction="""You are an expert full-stack code generator. 
Always respond with clean, well-commented code.
Use markdown code blocks with correct language identifier.
Explain the code briefly before or after.
If user asks for a specific framework/language, use that.
Never refuse to generate code unless it's harmful/illegal."""
)

app = FastAPI(title="Chationc Backend - Simple Gemini")

# Allow Flutter web / any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    message: str

@app.post("/chat")
async def chat(request: ChatRequest):
    try:
        # Simple generation — Gemini answers directly
        response = model.generate_content(request.message)

        # Get the text response safely
        if not response.candidates or not response.candidates[0].content.parts:
            return {"response": "Sorry, I couldn't generate a response right now."}

        ai_text = response.candidates[0].content.parts[0].text.strip()

        return {"response": ai_text}

    except Exception as e:
        print(f"Gemini error: {str(e)}")   # ← important: look here in terminal
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "agent:app",                  # ← Change to this: "filename:app"
        host="0.0.0.0",
        port=8000,
        reload=True,                  # safe now
        # workers=1                   # optional - add only if you really need multiple workers
    )