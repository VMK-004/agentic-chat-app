from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from agent import Agent  # import the wrapper
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import fitz  # PyMuPDF
from PyPDF2 import PdfReader
from fastapi.staticfiles import StaticFiles
from sentence_transformers import SentenceTransformer
from langchain.text_splitter import CharacterTextSplitter
import faiss
import pickle



app = FastAPI()
agent = Agent()

embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
index = None  # FAISS index
doc_chunks = []  # To store original chunks

INDEX_DIR = "vector_indexes"
os.makedirs(INDEX_DIR, exist_ok=True)

# ✅ Define first
UPLOAD_DIR = "uploaded_files"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ✅ Then mount
app.mount("/files", StaticFiles(directory=UPLOAD_DIR), name="files")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL = "http://localhost:11434/api/generate"

class PromptRequest(BaseModel):
    prompt: str

@app.post("/chat")
async def chat_with_ai(data: PromptRequest):
    response = await agent.get_response(data.prompt)
    return {"response": response}


@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    file_location = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    download_url = f"http://10.0.2.2:8001/files/{file.filename}"
    return {
        "message": f"File '{file.filename}' uploaded successfully!",
        "file_url": download_url,
        "filename": file.filename
    }


class FileSummaryRequest(BaseModel):
    filename: str


@app.post("/summarize_file")
async def summarize_file(data: FileSummaryRequest):
    file_path = os.path.join(UPLOAD_DIR, data.filename)

    try:
        reader = PdfReader(file_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() or ""

        content = text.strip().replace("\n", " ")
        if not content:
            return {"summary": "File has no readable text."}

        short_summary = content[:600] + "..." if len(content) > 600 else content
        return {"summary": f"Summary of {data.filename}: {short_summary}"}

    except Exception as e:
        return {"error": str(e)}

class FileQueryRequest(BaseModel):
    query: str
    filename: str

@app.post("/query_file")
async def query_file(data: FileQueryRequest):
    global index, doc_chunks

    file_path = os.path.join(UPLOAD_DIR, data.filename)

    try:
        # Step 1: Extract text
        reader = PdfReader(file_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() or ""

        if not text.strip():
            return {"answer": "No readable content in the file."}

        # Step 2: Split into chunks
        splitter = CharacterTextSplitter(chunk_size=500, chunk_overlap=50)
        doc_chunks = splitter.split_text(text)

        # Step 3: Embed chunks
        vectors = embedding_model.encode(doc_chunks, show_progress_bar=True)

        # Step 4: Create FAISS index
        index = faiss.IndexFlatL2(vectors.shape[1])
        index.add(vectors)

        # Step 5: Embed the query
        query_embedding = embedding_model.encode([data.query])
        D, I = index.search(query_embedding, k=5)

        # Step 6: Get top relevant chunks
        retrieved_chunks = [doc_chunks[i] for i in I[0]]
        context = "\n".join(retrieved_chunks)

        prompt = f"""Use the following context to answer the question:\n\n{context}\n\nQuestion: {data.query}"""

        # Step 7: Call Ollama through agent
        response = await agent.get_response(prompt)

        return {"answer": response}

    except Exception as e:
        return {"error": str(e)}


@app.post("/embed_file")
async def embed_uploaded_file(data: FileSummaryRequest):
    file_path = os.path.join(UPLOAD_DIR, data.filename)
    try:
        reader = PdfReader(file_path)
        full_text = ""
        for page in reader.pages:
            full_text += page.extract_text() or ""

        # Simple chunking
        chunks = [full_text[i:i+500] for i in range(0, len(full_text), 500)]
        if not chunks:
            return {"error": "No readable content found"}

        # Generate embeddings
        embeddings = embedding_model.encode(chunks)

        # Create FAISS index
        dim = embeddings[0].shape[0]
        index = faiss.IndexFlatL2(dim)
        index.add(embeddings)

        # Save index and metadata
        faiss.write_index(index, os.path.join(INDEX_DIR, f"{data.filename}.index"))
        with open(os.path.join(INDEX_DIR, f"{data.filename}_chunks.pkl"), "wb") as f:
            pickle.dump(chunks, f)

        return {"message": f"Embedded {len(chunks)} chunks from {data.filename}."}
    except Exception as e:
        return {"error": str(e)}