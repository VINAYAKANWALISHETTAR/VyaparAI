from fastapi import FastAPI

app = FastAPI(
    title="VyaparAI API",
    description="AI Financial Copilot for Small Businesses",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "message": "VyaparAI Backend is running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }