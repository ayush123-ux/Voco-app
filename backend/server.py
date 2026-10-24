#!/usr/bin/env python3
"""
VoCo Gemini AI Backend Service
--------------------------------------------------
Provides secure conversational intelligence, natural language command interpretation,
and multilingual support for VoCo iOS client.

Security:
- Reads GEMINI_API_KEY from environment or .env file.
- Never returns or exposes the API key to clients.
- Sanitizes incoming messages to remove passwords, tokens, or credential fields.
- Implements request limits and conversation history bounds to prevent runaway quota usage.
"""

import http.server
import json
import os
import re
import socketserver
import sys
import urllib.error
import urllib.request

# Load .env file if present in the same directory
def load_dotenv():
    env_path = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(env_path):
        try:
            with open(env_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        k = k.strip()
                        v = v.strip().strip("'\"")
                        if k and k not in os.environ:
                            os.environ[k] = v
        except Exception as e:
            print(f"[Warning] Failed to read .env: {e}", file=sys.stderr)

load_dotenv()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "").strip()
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash").strip()
HOST = os.environ.get("HOST", "0.0.0.0")
PORT = int(os.environ.get("PORT", "8080"))

# Sanitization regex to prevent leaking passwords or credentials
SENSITIVE_PATTERNS = [
    re.compile(r"(?i)\bpassword\s*[:=]\s*\S+"),
    re.compile(r"(?i)\bsecret\s*[:=]\s*\S+"),
    re.compile(r"(?i)\btoken\s*[:=]\s*\S+"),
    re.compile(r"(?i)\bapi[_-]?key\s*[:=]\s*\S+"),
]

def sanitize_text(text: str) -> str:
    """Removes sensitive credential fragments before forwarding to external AI."""
    cleaned = text
    for pattern in SENSITIVE_PATTERNS:
        cleaned = pattern.sub("[REDACTED_CREDENTIAL]", cleaned)
    return cleaned

def clean_tts_markdown(text: str) -> str:
    """Strips markdown asterisks, hashes, and bullet symbols so speech synthesis sounds natural."""
    t = text.replace("**", "").replace("*", "").replace("#", "")
    t = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", t)  # replace markdown links
    t = re.sub(r"`([^`]+)`", r"\1", t)               # replace code backticks
    return t.strip()

def call_gemini_api(contents, system_instruction=None, max_output_tokens=300):
    """Directly calls the official Google Gemini v1beta endpoint with API key header."""
    if not GEMINI_API_KEY or GEMINI_API_KEY == "YOUR_GEMINI_API_KEY_HERE":
        raise ValueError("GEMINI_API_KEY is not configured on the backend server.")

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY
    }

    body = {
        "contents": contents,
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": max_output_tokens,
        }
    }
    if system_instruction:
        body["systemInstruction"] = {
            "parts": [{"text": system_instruction}]
        }

    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            raw = resp.read().decode("utf-8")
            res_json = json.loads(raw)
            try:
                candidates = res_json.get("candidates", [])
                if candidates:
                    parts = candidates[0].get("content", {}).get("parts", [])
                    if parts:
                        return parts[0].get("text", "")
            except Exception as e:
                print(f"[Error] Parsing Gemini candidates: {e}")
            return ""
    except urllib.error.HTTPError as e:
        error_content = e.read().decode("utf-8", errors="ignore")
        print(f"[HTTPError {e.code}] {error_content}", file=sys.stderr)
        if e.code == 400:
            raise RuntimeError(f"Bad Request to Gemini API: {e.code}")
        elif e.code == 401 or e.code == 403:
            raise RuntimeError("Gemini API key is invalid or has insufficient permissions.")
        elif e.code == 429:
            raise RuntimeError("Gemini API rate limit or quota exceeded. Please wait a moment.")
        else:
            raise RuntimeError(f"Gemini API returned HTTP {e.code}")
    except urllib.error.URLError as e:
        raise RuntimeError(f"Cannot reach Google Gemini API: {e.reason}")
    except socketserver.socket.timeout:
        raise RuntimeError("Request to Gemini API timed out after 10 seconds.")


class VoCoRequestHandler(http.server.BaseHTTPRequestHandler):
    def _send_json(self, status_code, data):
        payload = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_GET(self):
        if self.path == "/health" or self.path == "/":
            key_configured = bool(GEMINI_API_KEY and GEMINI_API_KEY != "YOUR_GEMINI_API_KEY_HERE")
            self._send_json(200, {
                "status": "healthy",
                "service": "VoCo Gemini AI Backend",
                "geminiConfigured": key_configured,
                "model": GEMINI_MODEL,
                "supportedLanguages": [
                    "English", "Hindi", "Hinglish", "Bengali", "Tamil",
                    "Telugu", "Marathi", "Gujarati", "Kannada", "Malayalam",
                    "Punjabi", "Odia", "Assamese", "Urdu", "Spanish", "French", "German"
                ]
            })
        else:
            self._send_json(404, {"error": "Not found"})

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length > 65536: # 64KB safety limit
            self._send_json(413, {"error": "Request entity too large"})
            return

        body_raw = self.rfile.read(content_length).decode("utf-8", errors="ignore")
        try:
            req_data = json.loads(body_raw) if body_raw else {}
        except Exception:
            self._send_json(400, {"error": "Malformed JSON payload"})
            return

        if self.path == "/api/chat":
            self.handle_chat(req_data)
        elif self.path == "/api/interpret_command":
            self.handle_interpret_command(req_data)
        else:
            self._send_json(404, {"error": "Endpoint not found"})

    def handle_chat(self, data):
        user_message = data.get("message", "").strip()
        if not user_message:
            self._send_json(400, {"error": "Empty message parameter"})
            return

        user_message = sanitize_text(user_message)
        language = data.get("language", "English")
        raw_history = data.get("history", [])

        # Bound history to last 6 items for speed and cost control
        bounded_history = raw_history[-6:] if isinstance(raw_history, list) else []

        gemini_contents = []
        for item in bounded_history:
            role = "user" if item.get("role") == "user" else "model"
            text = sanitize_text(item.get("text", ""))
            if text:
                gemini_contents.append({
                    "role": role,
                    "parts": [{"text": text}]
                })

        gemini_contents.append({
            "role": "user",
            "parts": [{"text": user_message}]
        })

        system_prompt = (
            f"You are VoCo, a concise, conversational voice-first AI educational tutor designed "
            f"for visually impaired students. Your goal is to explain concepts clearly, simply, and warmly.\n"
            f"- Current language: {language}.\n"
            f"- If the language is Hindi or Hinglish, speak natural, conversational Hindi/Hinglish.\n"
            f"- Spoken rules: Keep your answer to 1 to 3 short sentences by default unless the user explicitly asks for detail.\n"
            f"- Never use markdown formatting like asterisks, bullet points, hashes, or tables because this text will be read aloud by text-to-speech.\n"
            f"- Never mention passwords, credentials, or private details."
        )

        try:
            reply_text = call_gemini_api(gemini_contents, system_instruction=system_prompt)
            clean_reply = clean_tts_markdown(reply_text)
            if not clean_reply:
                clean_reply = "I understand your question. Let me know if you would like me to explain further."
            self._send_json(200, {
                "reply": clean_reply,
                "language": language,
                "status": "success",
                "source": "gemini"
            })
        except Exception as e:
            err_msg = str(e)
            print(f"[Chat Error] {err_msg}", file=sys.stderr)
            # Local fallback response when Gemini is unconfigured or network is unavailable
            fallback = self.local_fallback_chat(user_message, language)
            self._send_json(200, {
                "reply": fallback,
                "language": language,
                "status": "fallback",
                "source": "local",
                "warning": err_msg
            })

    def handle_interpret_command(self, data):
        phrase = data.get("phrase", "").strip()
        current_screen = data.get("currentScreen", "dashboard")
        language = data.get("language", "English")

        if not phrase:
            self._send_json(400, {"error": "Empty phrase parameter"})
            return

        phrase = sanitize_text(phrase)

        system_prompt = (
            "You are the VoCo Intent Classifier for a voice-first educational iOS app.\n"
            "Map the user's spoken phrase and context to one of the following exact actions:\n"
            "- openPronunciation\n"
            "- openTalkWithVoCo\n"
            "- openVoCoGyan\n"
            "- openTechnicalCourses\n"
            "- openNonTechnicalCourses\n"
            "- openQuiz\n"
            "- openGames\n"
            "- openStories\n"
            "- goHome\n"
            "- goBack\n"
            "- repeat\n"
            "- help\n"
            "- pauseListening\n"
            "- resumeListening\n"
            "- answerTrue\n"
            "- answerFalse\n"
            "- nextQuestion\n"
            "- openCourseTopic (param: topicId e.g. 'topic-dsa', 'topic-interview', 'topic-communication')\n"
            "- generalChat (param: query - if user is asking an educational or conversational question)\n"
            "- unknown\n\n"
            "Return ONLY a valid JSON object with keys: 'action' (string), 'parameters' (object), 'confidence' (float 0.0-1.0).\n"
            "Example: {\"action\": \"openTechnicalCourses\", \"parameters\": {}, \"confidence\": 0.95}"
        )

        user_content = f"Spoken phrase: '{phrase}'. Current Screen: '{current_screen}'. Language: '{language}'."

        try:
            gemini_response = call_gemini_api(
                [{"role": "user", "parts": [{"text": user_content}]}],
                system_instruction=system_prompt,
                max_output_tokens=150
            )
            # Extract JSON from response
            match = re.search(r"\{.*\}", gemini_response, re.DOTALL)
            if match:
                parsed = json.loads(match.group(0))
                self._send_json(200, parsed)
                return
        except Exception as e:
            print(f"[Command Interpret Error] {e}", file=sys.stderr)

        # Fallback to local heuristic matching if Gemini fails or is offline
        local_result = self.local_heuristic_intent(phrase, current_screen)
        self._send_json(200, local_result)

    def local_fallback_chat(self, query: str, language: str) -> str:
        q = query.lower()
        is_hindi = language.lower() in ["hindi", "hinglish"]
        is_marathi = language.lower() in ["marathi", "mr", "mr-in"]

        if "binary search" in q or "बायनरी" in q:
            if is_marathi:
                return "बायनरी सर्च ही एक कार्यक्षम अल्गोरिदम आहे जी सॉर्ट केलेल्या यादीत घटकांचा शोध घेते."
            elif is_hindi:
                return "बाइनरी सर्च एक सॉर्टेड लिस्ट में आधे-आधे हिस्से को छांटकर किसी एलिमेंट को बहुत तेजी से ढूंढता है।"
            else:
                return "Binary search is an efficient search algorithm that finds an item in a sorted list by repeatedly dividing the search interval in half."
        elif "linked list" in q or "लिंक्ड" in q:
            if is_marathi:
                return "लिंक्ड लिस्ट ही एक डेटा रचना आहे ज्यामध्ये प्रत्येक नोड पुढील नोडचा पत्ता साठवतो."
            elif is_hindi:
                return "लिंक्ड लिस्ट एक लीनियर डेटा स्ट्रक्चर है जिसमें हर नोड अगले नोड का एड्रेस स्टोर करता है।"
            else:
                return "A linked list is a linear data structure where elements are not stored in contiguous memory, but each node points to the next node."
        elif "vowel" in q or "स्वर" in q:
            if is_marathi:
                return "इंग्रजीमध्ये पाच मुख्य स्वर आहेत: A, E, I, O आणि U."
            elif is_hindi:
                return "अंग्रेजी में पांच मुख्य स्वर होते हैं: ए, ई, आई, ओ, और यू। इनका उच्चारण करते समय मुंह खुला रखें।"
            else:
                return "The five pure vowels are A, E, I, O, and U. Practice opening your mouth cleanly to resonate each sound."
        elif is_marathi:
            return "नमस्कार! मी व्होको आहे. तुम्ही मला तांत्रिक कोर्सेस, उच्चार किंवा क्विझबद्दल काहीही विचारू शकता."
        elif is_hindi:
            return "नमस्ते! मैं वोको हूँ। आप मुझसे उच्चारण, तकनीकी कोर्सेस, या क्विज़ के बारे में कुछ भी पूछ सकते हैं।"
        else:
            return "Hello! I am VoCo. You can ask me to explain concepts, practice pronunciation, or navigate courses."

    def local_heuristic_intent(self, phrase: str, current_screen: str) -> dict:
        p = phrase.lower().strip()
        if "non-tech" in p or "non technical" in p or "soft skills" in p or "अतांत्रिक" in p or "atantrik" in p:
            return {"action": "openNonTechnicalCourses", "parameters": {}, "confidence": 0.9}
        if "tech" in p or "technical" in p or "तांत्रिक" in p or "tantrik" in p:
            return {"action": "openTechnicalCourses", "parameters": {}, "confidence": 0.9}
        if "quiz" in p or "क्विझ" in p or "प्रश्नावली" in p:
            return {"action": "openQuiz", "parameters": {}, "confidence": 0.9}
        if "home" in p or "dashboard" in p or "मुख्यपृष्ठ" in p or "मुखपृष्ठ" in p or "घरी" in p:
            return {"action": "goHome", "parameters": {}, "confidence": 0.95}
        if "back" in p or "previous" in p or "मागे" in p or "परत" in p:
            return {"action": "goBack", "parameters": {}, "confidence": 0.95}
        if p in ["true", "sahi", "yes", "option 1", "option a", "बरोबर", "सत्य", "होय", "barobar"]:
            return {"action": "answerTrue", "parameters": {}, "confidence": 0.95}
        if p in ["false", "galat", "no", "option 2", "option b", "चूक", "असत्य", "नाही", "chook"]:
            return {"action": "answerFalse", "parameters": {}, "confidence": 0.95}
        return {"action": "generalChat", "parameters": {"query": phrase}, "confidence": 0.5}


def run_server():
    socketserver.TCPServer.allow_reuse_address = True
    server_address = (HOST, PORT)
    with socketserver.ThreadingTCPServer(server_address, VoCoRequestHandler) as httpd:
        print(f"============================================================")
        print(f"VoCo Gemini AI Backend Server")
        print(f"Listening on http://{HOST}:{PORT}")
        print(f"Gemini Model: {GEMINI_MODEL}")
        print(f"Gemini API Key Configured: {'YES' if GEMINI_API_KEY and GEMINI_API_KEY != 'YOUR_GEMINI_API_KEY_HERE' else 'NO (running in local fallback mode)'}")
        print(f"Health Check: http://localhost:{PORT}/health")
        print(f"============================================================")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down backend server.")

if __name__ == "__main__":
    run_server()
