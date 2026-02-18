# Servicios AI/ML Managed de AWS

## Tabla de Contenidos

- [Concepto clave](#concepto-clave)
- [Servicios por categoría](#servicios-por-categoría)
- [Pipeline típico: call center analytics](#pipeline-típico-call-center-analytics)
- [Pipeline típico: procesamiento de documentos](#pipeline-típico-procesamiento-de-documentos)
- [Cheat sheet para el examen](#cheat-sheet-para-el-examen)
- [Servicios que se confunden frecuentemente](#servicios-que-se-confunden-frecuentemente)
- [Tips para el examen](#tips-para-el-examen)

---

## Concepto clave

AWS ofrece servicios de AI/ML **fully managed** que no requieren entrenar ni mantener modelos. Solo llamas a una API y obtienes el resultado. Esto es lo que pregunta el examen — no necesitas saber ML, necesitas saber **qué servicio usar para cada caso**.

```
"Without maintaining any ML model" → usa servicios managed de esta sección
"Custom ML model" → SageMaker (sección aparte)
```

---

## Servicios por categoría

### Audio / Voz

#### Amazon Transcribe
**Audio → Texto** (Speech-to-Text)

- Convierte grabaciones de audio/vídeo en texto
- Soporta múltiples idiomas (inglés, español, japonés, hindi, etc.)
- Identificación automática de hablantes (speaker diarization)
- Vocabulario custom (términos médicos, técnicos, etc.)
- Filtrado de contenido (redactar PII automáticamente)

Variantes:
- **Transcribe**: general (call centers, subtítulos, transcripción de reuniones)
- **Transcribe Medical**: optimizado para terminología médica

```
Casos de uso:
  - Transcribir llamadas de call center
  - Subtítulos automáticos para vídeos
  - Documentación médica por voz
  - Actas de reuniones automáticas
```

#### Amazon Polly
**Texto → Audio** (Text-to-Speech)

- Convierte texto en voz natural
- Múltiples voces e idiomas
- SSML (Speech Synthesis Markup Language) para controlar pronunciación, pausas, énfasis
- Neural TTS: voces más naturales
- Genera archivos de audio (MP3, OGG, PCM)

```
Casos de uso:
  - Leer artículos/noticias en voz alta
  - Asistentes de voz
  - E-learning con narración automática
  - Accesibilidad (leer contenido para personas con discapacidad visual)
```

**Truco para el examen**: Polly y Transcribe son opuestos. Si confundes cuál es cuál:
```
Polly = Polly quiere una galleta (un loro que HABLA) → texto a audio
Transcribe = transcribir = escribir lo que se dice → audio a texto
```

---

### Texto / NLP (Natural Language Processing)

#### Amazon Comprehend
**Análisis de texto**

- Sentiment analysis (positivo, negativo, neutro, mixto)
- Detección de entidades (personas, lugares, fechas, organizaciones)
- Detección de idioma
- Extracción de frases clave (key phrases)
- Detección de PII (información personal)
- Topic modeling (agrupar documentos por tema)

Variantes:
- **Comprehend**: general
- **Comprehend Medical**: extrae información médica (diagnósticos, medicamentos, dosis)

```
Casos de uso:
  - Analizar sentimiento de reseñas de clientes
  - Clasificar tickets de soporte por tema
  - Extraer entidades de documentos legales
  - Detectar PII en documentos para compliance
```

#### Amazon Translate
**Traducción de texto entre idiomas**

- Traducción en tiempo real
- 75+ idiomas soportados
- Custom Terminology: definir traducciones específicas para tu dominio
- Integración nativa con otros servicios (Transcribe → Translate → Comprehend)

```
Casos de uso:
  - Traducir contenido web automáticamente
  - Chat multilingüe en tiempo real
  - Localización de aplicaciones
  - Pipeline: Transcribe (audio→texto) → Translate (hindi→inglés) → Comprehend (sentimiento)
```

---

### Imágenes / Vídeo

#### Amazon Rekognition
**Análisis de imágenes y vídeo**

- Detección de objetos y escenas
- Reconocimiento facial (comparación, búsqueda)
- Detección de texto en imágenes (OCR básico)
- Detección de contenido inapropiado (moderación)
- Detección de celebridades
- Análisis de vídeo (personas, actividades, objetos en movimiento)
- PPE Detection (detectar si llevan casco, gafas, etc.)

```
Casos de uso:
  - Moderación de contenido (detectar imágenes inapropiadas)
  - Verificación de identidad (comparar selfie con foto de DNI)
  - Seguridad: detectar personas en cámaras de vigilancia
  - Detección de PPE en fábricas
  - Contar personas en un espacio
```

**No confundir con Textract**: Rekognition detecta texto básico en imágenes. Textract extrae datos estructurados de documentos.

---

### Documentos

#### Amazon Textract
**Extracción de texto y datos de documentos**

- OCR avanzado (más allá de solo leer texto)
- Extrae datos de formularios (key-value pairs)
- Extrae datos de tablas
- Procesa facturas y recibos automáticamente
- Procesa documentos de identidad (pasaportes, DNI)

```
Ejemplo:

  Factura PDF:
    ┌─────────────────────┐
    │ Factura #12345      │
    │ Cliente: Ana López  │
    │ Total: $1,500       │
    │ Fecha: 2026-02-17   │
    └─────────────────────┘

  Textract extrae:
    {
      "invoice_number": "12345",
      "client": "Ana López",
      "total": "$1,500",
      "date": "2026-02-17"
    }
```

```
Casos de uso:
  - Procesar facturas automáticamente
  - Digitalizar formularios en papel
  - Extraer datos de contratos
  - Automatizar entrada de datos de documentos
```

**Textract vs Rekognition**:
```
Rekognition: "hay texto en esta foto" (detección básica)
Textract:    "este formulario tiene estos campos con estos valores" (extracción estructurada)
```

---

### Chatbots / Conversación

#### Amazon Lex
**Motor de chatbots** (misma tecnología que Alexa)

- Reconocimiento de intención (intent)
- Extracción de slots (parámetros de la conversación)
- Integración con Lambda para lógica de negocio
- Soporta voz y texto
- Multi-idioma

```
Ejemplo:

  Usuario: "Quiero reservar un hotel en Tokyo para 3 noches"

  Lex identifica:
    Intent: ReservarHotel
    Slots:
      - ciudad: Tokyo
      - noches: 3

  → Llama a Lambda → busca hoteles → responde
```

```
Casos de uso:
  - Chatbot de atención al cliente
  - Asistente de reservas
  - FAQ automático
  - IVR (menú telefónico inteligente) para call centers
```

**Para el examen**: si dice "chatbot" → Lex. Si dice "transcribir audio" → Transcribe (NO Lex).

---

### Búsqueda

#### Amazon Kendra
**Búsqueda inteligente con ML**

- Búsqueda semántica (entiende la pregunta, no solo keywords)
- Conecta a múltiples fuentes de datos (S3, SharePoint, Salesforce, RDS, etc.)
- Responde preguntas directamente (no solo da links)
- FAQ automático desde documentos

```
Ejemplo:

  Búsqueda tradicional: "política vacaciones"
    → Te da 50 documentos que contienen esas palabras

  Kendra: "¿Cuántos días de vacaciones tengo?"
    → "Según la política de RRHH, tienes 20 días laborables al año"
    → Respuesta directa extraída del documento correcto
```

```
Casos de uso:
  - Buscador interno de la empresa (documentos, wikis, políticas)
  - Portal de soporte (buscar en toda la documentación)
  - Compliance (buscar en regulaciones)
```

---

### Recomendaciones / Personalización

#### Amazon Personalize
**Motor de recomendaciones** (misma tecnología que Amazon.com)

- Recomendaciones personalizadas en tiempo real
- No necesitas experiencia en ML
- Alimentas con datos de interacciones (clicks, compras, views)
- Genera recomendaciones automáticamente

```
Casos de uso:
  - "Clientes que compraron esto también compraron..."
  - Recomendaciones de películas/series
  - Personalización de homepage por usuario
  - Ranking personalizado de productos
```

#### Amazon Forecast
**Predicción de series temporales**

- Predicción de demanda, inventario, recursos
- No necesitas saber ML
- Alimentas con datos históricos → genera predicción

```
Casos de uso:
  - Predecir demanda de productos (cuánto stock necesito)
  - Predecir tráfico web (cuántos servidores necesitaré)
  - Predecir ingresos futuros
  - Planificación de capacidad
```

---

### Detección de fraude / anomalías

#### Amazon Fraud Detector
**Detección de fraude online**

- Detecta registros falsos, pagos fraudulentos, cuentas robadas
- Modelos preentrenados + tus datos
- API en tiempo real (evaluar transacción antes de procesarla)

```
Casos de uso:
  - Evaluar si un pago con tarjeta es fraudulento
  - Detectar cuentas falsas en registro
  - Prevenir abuso de promociones
```

---

### GenAI / LLMs

#### Amazon Bedrock
**Acceso a LLMs managed** (Claude, Titan, Llama, etc.)

- Múltiples modelos fundacionales (Foundation Models)
- API unificada para todos los modelos
- Knowledge Bases: RAG sobre tus documentos
- Agents: agentes que ejecutan acciones
- Fine-tuning sin gestionar infra
- Guardrails: filtros de contenido

```
Casos de uso:
  - Chatbot inteligente sobre tu documentación
  - Generación de contenido (emails, resúmenes, reportes)
  - Análisis de documentos con IA
  - Agentes que automatizan tareas
```

#### Amazon SageMaker
**Plataforma completa de ML** (entrenar, desplegar, gestionar modelos custom)

- Para cuando necesitas entrenar TU PROPIO modelo
- Built-in algorithms (XGBoost, Linear Learner, etc.)
- Jupyter notebooks managed
- Training jobs con GPU
- Endpoints para inference
- SageMaker Canvas: ML sin código (visual)

```
Para el examen:
  "Entrenar modelo custom" → SageMaker
  "Usar ML sin entrenar nada" → servicios managed (Comprehend, Transcribe, etc.)
  "LLMs managed" → Bedrock
```

---

## Pipeline típico: call center analytics

```
Llamada de cliente
    │
    ▼
Amazon Transcribe (audio → texto)
    │
    ▼
Amazon Translate (hindi → inglés, si hace falta)
    │
    ▼
Amazon Comprehend (sentiment analysis)
    │
    ▼
Resultado: "Cliente insatisfecho. Temas: facturación, espera"
    │
    ▼
S3 (guardar) → QuickSight (dashboard)
```

## Pipeline típico: procesamiento de documentos

```
Documento escaneado (PDF/imagen)
    │
    ▼
Amazon Textract (extraer datos estructurados)
    │
    ▼
Amazon Comprehend (detectar PII, clasificar)
    │
    ▼
Amazon Translate (traducir si es necesario)
    │
    ▼
Base de datos (RDS/DynamoDB)
```

---

## Cheat sheet para el examen

| Si la pregunta dice... | Respuesta |
|---|---|
| "Audio a texto", "transcribir", "speech-to-text" | **Transcribe** |
| "Texto a audio", "text-to-speech", "leer en voz alta" | **Polly** |
| "Sentimiento", "sentiment", "análisis de texto" | **Comprehend** |
| "Traducir idiomas" | **Translate** |
| "Imágenes", "faces", "objetos en foto", "moderación" | **Rekognition** |
| "Extraer datos de documentos", "OCR", "facturas" | **Textract** |
| "Chatbot", "conversacional" | **Lex** |
| "Búsqueda inteligente en documentos internos" | **Kendra** |
| "Recomendaciones personalizadas" | **Personalize** |
| "Predecir demanda", "forecast" | **Forecast** |
| "Fraude", "transacciones fraudulentas" | **Fraud Detector** |
| "LLMs", "GenAI", "foundation models" | **Bedrock** |
| "Entrenar modelo custom" | **SageMaker** |
| "Sin mantener modelo ML" | Servicios managed (NO SageMaker) |
| "Texto en imagen" (básico) | **Rekognition** |
| "Datos de formularios/tablas en documento" | **Textract** |
| "Términos médicos" | **Comprehend Medical** o **Transcribe Medical** |

## Servicios que se confunden frecuentemente

### Transcribe vs Polly
```
Transcribe: 🎤→📝 (escucha audio, escribe texto)
Polly:      📝→🔊 (lee texto, genera audio)
Son opuestos.
```

### Rekognition vs Textract
```
Rekognition: "Hay un gato y texto 'STOP' en esta foto"  (qué hay en la imagen)
Textract:    "Este formulario dice Nombre: Ana, DNI: 12345" (extrae datos estructurados)
```

### Comprehend vs Kendra
```
Comprehend: analiza UN texto (sentimiento, entidades, idioma)
Kendra:     busca EN MUCHOS textos (buscador inteligente sobre documentación)
```

### Lex vs Transcribe
```
Lex:        chatbot que entiende intención y responde
Transcribe: convierte audio a texto, no entiende ni responde nada
```

### Bedrock vs SageMaker
```
Bedrock:    usa modelos ya entrenados (Claude, Titan) → sin ML knowledge
SageMaker:  entrena tus propios modelos → necesitas saber ML
```

---

## Tips para el examen

1. **"Without maintaining any ML model"** → nunca SageMaker. Siempre servicios managed (Transcribe, Comprehend, Translate, etc.)

2. **Pipeline de audio multilingüe** = Transcribe → Translate → Comprehend. Esta combinación aparece frecuentemente.

3. **Moderación de contenido** (imágenes inapropiadas) = Rekognition. No Comprehend (que es para texto).

4. **Documentos escaneados** = Textract. No Rekognition (que solo detecta texto, no extrae estructura).

5. **Medical** variants: Transcribe Medical (voz médica), Comprehend Medical (texto médico). Si la pregunta menciona healthcare, busca la variante Medical.

6. **Kendra** aparece cuando hay "búsqueda inteligente en documentación interna de la empresa". No es traducción ni análisis de sentimiento.

7. **Las opciones incorrectas** suelen mezclar servicios de forma absurda (Polly para transcribir, Rekognition para traducir, Detective para sentimiento). Si un servicio está fuera de su dominio, descártalo.
