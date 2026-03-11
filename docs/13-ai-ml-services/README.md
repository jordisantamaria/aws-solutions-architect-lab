# AWS Managed AI/ML Services

## Table of Contents

- [Key Concept](#key-concept)
- [Services by Category](#services-by-category)
- [Typical Pipeline: Call Center Analytics](#typical-pipeline-call-center-analytics)
- [Typical Pipeline: Document Processing](#typical-pipeline-document-processing)
- [Exam Cheat Sheet](#exam-cheat-sheet)
- [Frequently Confused Services](#frequently-confused-services)
- [Exam Tips](#exam-tips)

---

## Key Concept

AWS offers **fully managed** AI/ML services that don't require training or maintaining models. You just call an API and get the result. This is what the exam asks — you don't need to know ML, you need to know **which service to use for each case**.

```
"Without maintaining any ML model" → use managed services from this section
"Custom ML model" → SageMaker (separate section)
```

---

## Services by Category

### Audio / Voice

#### Amazon Transcribe
**Audio → Text** (Speech-to-Text)

- Converts audio/video recordings to text
- Supports multiple languages (English, Spanish, Japanese, Hindi, etc.)
- Automatic speaker identification (speaker diarization)
- Custom vocabulary (medical terms, technical terms, etc.)
- Content filtering (automatically redact PII)

Variants:
- **Transcribe**: general (call centers, subtitles, meeting transcription)
- **Transcribe Medical**: optimized for medical terminology

```
Use cases:
  - Transcribe call center calls
  - Automatic subtitles for videos
  - Medical documentation by voice
  - Automatic meeting minutes
```

#### Amazon Polly
**Text → Audio** (Text-to-Speech)

- Converts text to natural speech
- Multiple voices and languages
- SSML (Speech Synthesis Markup Language) to control pronunciation, pauses, emphasis
- Neural TTS: more natural voices
- Generates audio files (MP3, OGG, PCM)

```
Use cases:
  - Read articles/news aloud
  - Voice assistants
  - E-learning with automatic narration
  - Accessibility (read content for visually impaired people)
```

**Exam trick**: Polly and Transcribe are opposites. If you confuse which is which:
```
Polly = Polly wants a cracker (a parrot that TALKS) → text to audio
Transcribe = transcribe = write down what is said → audio to text
```

---

### Text / NLP (Natural Language Processing)

#### Amazon Comprehend
**Text Analysis**

- Sentiment analysis (positive, negative, neutral, mixed)
- Entity detection (people, places, dates, organizations)
- Language detection
- Key phrase extraction
- PII detection (personal information)
- Topic modeling (group documents by topic)

Variants:
- **Comprehend**: general
- **Comprehend Medical**: extracts medical information (diagnoses, medications, doses)

```
Use cases:
  - Analyze sentiment of customer reviews
  - Classify support tickets by topic
  - Extract entities from legal documents
  - Detect PII in documents for compliance
```

#### Amazon Translate
**Text Translation Between Languages**

- Real-time translation
- 75+ supported languages
- Custom Terminology: define specific translations for your domain
- Native integration with other services (Transcribe → Translate → Comprehend)

```
Use cases:
  - Automatically translate web content
  - Multilingual real-time chat
  - Application localization
  - Pipeline: Transcribe (audio→text) → Translate (Hindi→English) → Comprehend (sentiment)
```

---

### Images / Video

#### Amazon Rekognition
**Image and Video Analysis**

- Object and scene detection
- Facial recognition (comparison, search)
- Text detection in images (basic OCR)
- Inappropriate content detection (moderation)
- Celebrity detection
- Video analysis (people, activities, moving objects)
- PPE Detection (detect if wearing helmets, goggles, etc.)

```
Use cases:
  - Content moderation (detect inappropriate images)
  - Identity verification (compare selfie with ID photo)
  - Security: detect people in surveillance cameras
  - PPE detection in factories
  - Count people in a space
```

**Don't confuse with Textract**: Rekognition detects basic text in images. Textract extracts structured data from documents.

---

### Documents

#### Amazon Textract
**Text and Data Extraction from Documents**

- Advanced OCR (beyond just reading text)
- Extracts data from forms (key-value pairs)
- Extracts data from tables
- Processes invoices and receipts automatically
- Processes identity documents (passports, IDs)

```
Example:

  Invoice PDF:
    ┌─────────────────────┐
    │ Invoice #12345      │
    │ Client: Ana Lopez   │
    │ Total: $1,500       │
    │ Date: 2026-02-17    │
    └─────────────────────┘

  Textract extracts:
    {
      "invoice_number": "12345",
      "client": "Ana Lopez",
      "total": "$1,500",
      "date": "2026-02-17"
    }
```

```
Use cases:
  - Process invoices automatically
  - Digitize paper forms
  - Extract data from contracts
  - Automate data entry from documents
```

**Textract vs Rekognition**:
```
Rekognition: "there is text in this photo" (basic detection)
Textract:    "this form has these fields with these values" (structured extraction)
```

---

### Chatbots / Conversation

#### Amazon Lex
**Chatbot Engine** (same technology as Alexa)

- Intent recognition
- Slot extraction (conversation parameters)
- Integration with Lambda for business logic
- Supports voice and text
- Multi-language

```
Example:

  User: "I want to book a hotel in Tokyo for 3 nights"

  Lex identifies:
    Intent: BookHotel
    Slots:
      - city: Tokyo
      - nights: 3

  → Calls Lambda → searches hotels → responds
```

```
Use cases:
  - Customer service chatbot
  - Booking assistant
  - Automated FAQ
  - IVR (intelligent phone menu) for call centers
```

**For the exam**: if it says "chatbot" → Lex. If it says "transcribe audio" → Transcribe (NOT Lex).

---

### Search

#### Amazon Kendra
**Intelligent Search with ML**

- Semantic search (understands the question, not just keywords)
- Connects to multiple data sources (S3, SharePoint, Salesforce, RDS, etc.)
- Answers questions directly (not just provides links)
- Automatic FAQ from documents

```
Example:

  Traditional search: "vacation policy"
    → Gives you 50 documents containing those words

  Kendra: "How many vacation days do I have?"
    → "According to the HR policy, you have 20 business days per year"
    → Direct answer extracted from the correct document
```

```
Use cases:
  - Internal company search engine (documents, wikis, policies)
  - Support portal (search across all documentation)
  - Compliance (search through regulations)
```

---

### Recommendations / Personalization

#### Amazon Personalize
**Recommendation Engine** (same technology as Amazon.com)

- Real-time personalized recommendations
- No ML experience needed
- Feed with interaction data (clicks, purchases, views)
- Generates recommendations automatically

```
Use cases:
  - "Customers who bought this also bought..."
  - Movie/series recommendations
  - Homepage personalization per user
  - Personalized product ranking
```

#### Amazon Forecast
**Time Series Prediction**

- Demand, inventory, resource prediction
- No ML knowledge needed
- Feed with historical data → generates prediction

```
Use cases:
  - Predict product demand (how much stock do I need)
  - Predict web traffic (how many servers will I need)
  - Predict future revenue
  - Capacity planning
```

---

### Fraud / Anomaly Detection

#### Amazon Fraud Detector
**Online Fraud Detection**

- Detects fake registrations, fraudulent payments, stolen accounts
- Pre-trained models + your data
- Real-time API (evaluate transaction before processing it)

```
Use cases:
  - Evaluate if a credit card payment is fraudulent
  - Detect fake accounts during registration
  - Prevent promotion abuse
```

---

### GenAI / LLMs

#### Amazon Bedrock
**Managed LLM Access** (Claude, Titan, Llama, etc.)

- Multiple foundation models
- Unified API for all models
- Knowledge Bases: RAG on your documents
- Agents: agents that execute actions
- Fine-tuning without managing infra
- Guardrails: content filters

```
Use cases:
  - Intelligent chatbot on your documentation
  - Content generation (emails, summaries, reports)
  - Document analysis with AI
  - Agents that automate tasks
```

#### Amazon SageMaker
**Complete ML Platform** (train, deploy, manage custom models)

- For when you need to train YOUR OWN model
- Built-in algorithms (XGBoost, Linear Learner, etc.)
- Managed Jupyter notebooks
- Training jobs with GPU
- Endpoints for inference
- SageMaker Canvas: no-code ML (visual)

```
For the exam:
  "Train custom model" → SageMaker
  "Use ML without training anything" → managed services (Comprehend, Transcribe, etc.)
  "Managed LLMs" → Bedrock
```

---

## Typical Pipeline: Call Center Analytics

```
Customer call
    │
    ▼
Amazon Transcribe (audio → text)
    │
    ▼
Amazon Translate (Hindi → English, if needed)
    │
    ▼
Amazon Comprehend (sentiment analysis)
    │
    ▼
Result: "Dissatisfied customer. Topics: billing, wait time"
    │
    ▼
S3 (store) → QuickSight (dashboard)
```

## Typical Pipeline: Document Processing

```
Scanned document (PDF/image)
    │
    ▼
Amazon Textract (extract structured data)
    │
    ▼
Amazon Comprehend (detect PII, classify)
    │
    ▼
Amazon Translate (translate if needed)
    │
    ▼
Database (RDS/DynamoDB)
```

---

## Exam Cheat Sheet

| If the question says... | Answer |
|---|---|
| "Audio to text", "transcribe", "speech-to-text" | **Transcribe** |
| "Text to audio", "text-to-speech", "read aloud" | **Polly** |
| "Sentiment", "text analysis" | **Comprehend** |
| "Translate languages" | **Translate** |
| "Images", "faces", "objects in photo", "moderation" | **Rekognition** |
| "Extract data from documents", "OCR", "invoices" | **Textract** |
| "Chatbot", "conversational" | **Lex** |
| "Intelligent search in internal documents" | **Kendra** |
| "Personalized recommendations" | **Personalize** |
| "Predict demand", "forecast" | **Forecast** |
| "Fraud", "fraudulent transactions" | **Fraud Detector** |
| "LLMs", "GenAI", "foundation models" | **Bedrock** |
| "Train custom model" | **SageMaker** |
| "Without maintaining ML model" | Managed services (NOT SageMaker) |
| "Text in image" (basic) | **Rekognition** |
| "Data from forms/tables in document" | **Textract** |
| "Medical terms" | **Comprehend Medical** or **Transcribe Medical** |

## Frequently Confused Services

### Transcribe vs Polly
```
Transcribe: listens to audio, writes text (audio → text)
Polly:      reads text, generates audio (text → audio)
They are opposites.
```

### Rekognition vs Textract
```
Rekognition: "There is a cat and text 'STOP' in this photo"  (what's in the image)
Textract:    "This form says Name: Ana, ID: 12345" (extracts structured data)
```

### Comprehend vs Kendra
```
Comprehend: analyzes ONE text (sentiment, entities, language)
Kendra:     searches ACROSS MANY texts (intelligent search engine over documentation)
```

### Lex vs Transcribe
```
Lex:        chatbot that understands intent and responds
Transcribe: converts audio to text, doesn't understand or respond to anything
```

### Bedrock vs SageMaker
```
Bedrock:    uses already-trained models (Claude, Titan) → no ML knowledge needed
SageMaker:  trains your own models → need to know ML
```

---

## Exam Tips

1. **"Without maintaining any ML model"** → never SageMaker. Always managed services (Transcribe, Comprehend, Translate, etc.)

2. **Multilingual audio pipeline** = Transcribe → Translate → Comprehend. This combination appears frequently.

3. **Content moderation** (inappropriate images) = Rekognition. Not Comprehend (which is for text).

4. **Scanned documents** = Textract. Not Rekognition (which only detects text, doesn't extract structure).

5. **Medical** variants: Transcribe Medical (medical voice), Comprehend Medical (medical text). If the question mentions healthcare, look for the Medical variant.

6. **Kendra** appears when there is "intelligent search in internal company documentation". It's not translation or sentiment analysis.

7. **Incorrect options** often mix services absurdly (Polly for transcription, Rekognition for translation, Detective for sentiment). If a service is outside its domain, discard it.
