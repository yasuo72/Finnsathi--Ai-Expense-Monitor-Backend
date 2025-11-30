# FinSathi Viva Notes (Hinglish)

> Ye notes aise likhe gaye hain ki tum viva mein almost script ki tarah bol sako.
> Sections clear rakhe gaye hain: overview, architecture, tech stack, routes, features, challenges, integrations, etc.

---

## 1. Project Overview

**Short intro (2–3 lines):**

> "Sir, mera project hai **FinSathi – AI powered personal finance & expense manager**.  
> Isme main **Flutter mobile app**, **Node.js + Express backend**, **MongoDB Atlas database**,  
> saath hi **OCR receipt scanning**, **AI/ML models**, **voice assistant** aur **shop management / food ordering system** use kiya hai.  
> Goal yeh hai ki user apne expenses track kare, bills scan kare, AI se insights le aur ek smooth financial management experience mile."

Points to mention:
- **Personal finance management**: expenses, incomes, budgets, savings goals
- **AI + ML**: expense prediction, anomaly detection, recommendations
- **OCR**: receipt scanning se automatic expense entry
- **Voice assistant**: voice se expenses/income add karo, queries pucho
- **Shop & food ordering**: integrated shop management system

---

## 2. High-Level Architecture & Hierarchy

Explain overall structure:

- **Mobile App (Flutter)**
  - All user-facing screens: Sign In, Home, Add Expense/Income, Budgets, Savings Goals, Gamification, Voice Assistant, Receipt Scanner, Shop pages, etc.
  - Handles **UI, navigation, local state**, and **API calls** to backend.

- **Main Backend (FinSathi API – Node.js + Express)**
  - Modules for:
    - **Auth** (email/password + Google Sign-In)
    - **User / Profile** (profile data, profile photo)
    - **Transactions** (expenses & incomes)
    - **Budgets & Savings Goals**
    - **Gamification / Challenges**
    - **Shop Orders integration** (bridge to shop backend)
  - Exposes **REST APIs** that Flutter app call karti hai.

- **Shop Management Backend (Node.js + Express)**
  - **Shop Owners** ke liye:
    - Shop create/update, menus manage, orders dekhna, status update, analytics
  - **Normal Users** ke liye:
    - Shops list, details, menu items, order place, order tracking, reviews
  - Same **MongoDB Atlas** database use karta hai, but **alag collections**.

- **OCR & ML Services (Python)**
  - `OCR-for-receipt/` module:
    - Advanced OCR scanner + `enhanced_extractor.py` for intelligent parsing
  - `ml-models/` folder:
    - Expense prediction, anomaly detection, recommendations, time-series, segmentation
  - Inko backend se **HTTP API** ya standalone scripts ke through integrate kiya ja sakta hai.

- **Database – MongoDB Atlas**
  - Hosted cluster, database: `finnsathi`
  - Collections (examples): `users`, `transactions`, `budgets`, `savingsGoals`, `challenges`, `shops`, `menuItems`, `orders`, `reviews`, etc.

- **Deployment**
  - **Backends**: Railway pe deploy
  - **Shop web dashboard**: React + Tailwind frontend (Vercel-ready)
  - **Mobile app**: Flutter Android APK / app bundle

**One-liner architecture flow:**
> "Overall flow hai: **Flutter app → Node.js/Express APIs → MongoDB Atlas**, plus side modules **Python OCR/ML services** and **separate shop backend**."

---

## 3. Technology Stack Overview

### 3.1 Mobile App (Flutter)

- **Language**: Dart
- **Framework**: Flutter
- **Key Areas**:
  - Multiple screens & navigations
  - Dark/light theme
  - Voice assistant screen
  - OCR receipt scanning UI
  - Home screen with AI assistant / quick actions

(You can mention important packages if asked: `google_sign_in`, `speech_to_text`, `text_to_speech`, `permission_handler`, `http`/`dio` etc. – depending on actual usage.)

---

### 3.2 Main Backend (FinSathi API)

- **Language**: JavaScript (Node.js)
- **Framework**: Express.js
- **Database driver/ODM**: Mongoose (MongoDB)
- **Auth**:
  - JWT (JSON Web Token)
  - Password hashing
- **Other tech**:
  - `cors` middleware for CORS handling
  - `dotenv` for environment variables
  - Cloudinary SDK for profile image upload (via URL)

**Main responsibility**: Secure REST APIs for finance features + user management + integration layer for shops and ML/OCR.

---

### 3.3 Shop Management System

**Backend (shop-management-backend/):**
- Node.js + Express
- MongoDB (same Atlas cluster, different collections)
- Models: ShopOwner, Shop, MenuItem, ShopOrder, Review, etc.
- JWT auth for shop owners, public routes for users.

**Frontend (shop-management-frontend/):**
- **React** for UI
- **Tailwind CSS** for styling
- **Zustand** for state management (auth store)
- Build system: standard React toolchain (e.g., Vite/CRA depending on setup)

Ye pura system FinSathi ke andar **food ordering / restaurant module** add karta hai.

---

### 3.4 Database Layer – MongoDB Atlas

- Cloud-hosted NoSQL database
- Collections logically separated by feature module
- Indexing on important fields (like userId, dates, shopId, orderId) for performance
- Connection string stored in `.env` (not in code), example:
  - `mongodb+srv://<username>:<password>@cluster0.../finnsathi?...`

---

## 4. OCR Receipt Scanner – Technology Stack & Working

Folder: `OCR-for-receipt/`

### 4.1 Tech Stack (from requirements_enhanced.txt)

- **Language**: Python
- **Core OCR & Image Processing**:
  - `pytesseract==0.3.10` – Tesseract OCR wrapper
  - `opencv-python-headless==4.8.1.78` – image preprocessing (resize, threshold, denoise, etc.)
  - `Pillow==10.0.1` – image loading & basic transformations
- **Numerical / Data**:
  - `numpy==1.24.4`
- **Text & Date Parsing**:
  - `python-dateutil==2.8.2`
- **Web Framework**:
  - `flask==2.3.3` – simple API server
  - `flask-cors==4.0.0` – CORS support from other apps
  - `werkzeug==2.3.7`
- **Utilities**:
  - `requests==2.31.0` – HTTP client for any external/internal calls

### 4.2 Enhanced Extractor (enhanced_extractor.py)

- Class: `EnhancedReceiptExtractor`
- Major responsibilities:
  - **Text cleaning**: remove noise, fix common OCR mistakes
  - **Merchant extraction**:
    - Patterns for Indian stores (D-Mart, Big Bazaar, Reliance, etc.)
    - Regex-based merchant name detection
  - **Date extraction**:
    - Multiple Indian/international formats
    - Uses `dateutil.parser` with `dayfirst=True`
  - **Amount extraction**:
    - Detects **total, subtotal, tax**
    - Indian currency patterns (`₹`, `Rs`, `INR`)
  - **Item extraction**:
    - Identifies items table section
    - Parses lines into: name, quantity, unit_price, total_price
  - **GST & Tax**:
    - CGST, SGST, IGST regex patterns
  - **Payment method**:
    - Detects cash/card/UPI/wallet/net banking
  - **Confidence scoring**:
    - Score based on merchant/date/total/items found

### 4.3 OCR Working Flow (How to explain in viva)

> "User bill ka photo upload karta hai → Python Flask OCR API ko image milta hai → image preprocessing hoti hai (grayscale, threshold, denoise, perspective correction) → `pytesseract` se raw text aata hai → `EnhancedReceiptExtractor` us text ko parse karke **structured JSON** banata hai (merchant, date, total, items, tax, etc.) → ye JSON hamare main backend/app ko jata hai jisse hum **automatic expense entry** create kar sakte hain."

---

## 5. Voice Assistant – Technology Stack & Working

### 5.1 Tech Stack (Flutter side)

- **Language/Framework**: Dart + Flutter
- **Packages** (as implemented in voice assistant feature):
  - `speech_to_text` – speech-to-text (STT) for capturing user voice commands
  - `text_to_speech` – text-to-speech (TTS) for audio feedback
  - `permission_handler` – microphone permissions
- **Platform Configuration**:
  - **Android**: `RECORD_AUDIO`, `INTERNET` permissions in `AndroidManifest.xml`
  - **iOS**: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` in `Info.plist`

### 5.2 Voice Assistant Working

High-level flow:

1. **Initialize & Permissions**
   - App checks mic permission using `permission_handler`.
   - If not granted, prompt user.

2. **Listening Phase**
   - Press mic button → `speech_to_text` start listening.
   - Real-time recognized text UI pe show hota hai.

3. **Command Parsing**
   - Example commands:
     - "Add expense 500 for food"
     - "Add income 10000 salary"
     - "Spent 200 on transport"
   - System:
     - Amount detect karta hai (₹500, 500 rs, 500 rupees, etc.).
     - Category keywords se (food, transport, shopping, etc.).
     - Description generate karta hai.

4. **Backend / Local Action**
   - Parsed command ko **transaction create** karne ke liye use karta hai.
   - API call backend par ja sakti hai ya local storage update hota hai.

5. **Feedback (TTS)**
   - `text_to_speech` se feedback deta hai:  
     "500 rupees ka food expense add ho gaya hai."

Isko viva mein is tarah se explain karo:

> "Sir, voice assistant basically speech-to-text + command parser + text-to-speech combination hai. User sirf bolta hai, aur app automatically expense ya income create kar deta hai."

---

## 6. AI / ML & Chatbot / Recommendation Layer

Ye part mainly **Python ML models** aur unki **integration design** cover karta hai.

### 6.1 ML Models (ml-models/ folder)

Conceptually implemented models:

- **Expense Prediction**
  - Linear Regression / Random Forest type model
  - Input: past monthly expenses, categories, income
  - Output: next month ka estimated kharcha

- **Trend Analysis**
  - Time-series style analysis (e.g., ARIMA / Random Forest on time features)
  - Detects upward/downward spending trend

- **Anomaly Detection**
  - Isolation Forest type model
  - High or abnormal expenses detect karta hai

- **Personalized Recommendations**
  - Cosine similarity based recommendation
  - Similar users ke spending pattern dekh ke suggestions deta hai

- **User Segmentation**
  - K-Means clustering
  - Users ko segments mein divide karta hai (e.g., saver, spender, balanced)

**Tech Stack (typical Python ML stack):**
- Python 3.x
- `numpy`, `pandas` – data processing
- `scikit-learn` – regression, random forest, isolation forest, k-means
- `statsmodels` – time-series / ARIMA (if used)

### 6.2 Chatbot / AI Assistant Concept

Abhi design level par yeh module is tarah socha hai:

- User app mein **AI assistant / chatbot** se questions puch sakta hai:
  - "Mera iss month ka kharcha kaisa hai?"
  - "Main kis category mein zyada spend kar raha hoon?"
  - "Mujhe next month budget kaise set karna chahiye?"
- System flow:
  1. Backend user ke **transactions, budgets, ML model outputs** fetch karta hai.
  2. Ye data summarize/aggregate karta hai (totals, trends, anomalies).
  3. Is summary ko kisi **LLM-based API** (e.g., OpenAI ya koi other model) ko de sakte hain.
  4. LLM natural language mein understandable answer return karega.

Viva ke time pe aise bolo:

> "Chatbot layer basically hamare **ML outputs + LLM** ka combination hai. ML models numbers aur patterns nikalte hain, aur LLM unko simple understandable language mein explain kar sakta hai. Project currently main focus ML models aur architecture pe hai, chatbot integration easy banane ke liye design ready hai."  

Isse tum bata sakte ho ki tumne **future-ready architecture** design kiya hai.

---

## 7. Backend Routes & Functions (High-Level)

Explain that you divided backend into **modular routes**:

- **Auth Routes**
  - `POST /auth/register` – new user
  - `POST /auth/login` – login
  - `POST /auth/google` – Google Sign-In
  - Returns JWT token, basic profile data

- **User/Profile Routes**
  - `GET /user/me` – logged-in user info
  - `PUT /user/me` – update profile
  - `POST /user/profile-picture` – upload to Cloudinary, store URL

- **Transaction Routes**
  - `POST /transactions` – create expense/income
  - `GET /transactions` – list/filter
  - `PUT /transactions/:id`, `DELETE /transactions/:id`

- **Budget & Savings Routes**
  - `POST /budgets` / `GET /budgets`
  - `POST /savings-goals` / `GET /savings-goals`

- **Gamification Routes**
  - `GET /challenges` – available challenges
  - `POST /challenges/progress` – update progress

- **Shop / Order Routes (Main Backend side)**
  - Acts as **API gateway** to shop-management-backend.
  - Eg. `GET /shop-orders/shops`, `GET /shop-orders/shops/:id/menu`, `POST /shop-orders/orders`

- **Shop Backend Routes (shop-management-backend)**
  - **Public**: list shops, get menu, place order, track order
  - **Protected (owner)**: manage shops, manage menu items, update order status

- **OCR / ML Integration Routes (if exposed)**
  - Eg. `POST /ocr/scan` – image upload, forwards to OCR service, returns structured data
  - Eg. `/ml/predict-expense`, `/ml/anomaly-check` (depending on how they’re wired)

Viva tip: har route ke liye **input–processing–output** samjhao.

---

## 8. Typical Working Flows (Use-cases to Explain)

### 8.1 Login Flow (with Google Sign-In)

1. User presses **Google Sign-In** button in Flutter app.
2. Flutter `google_sign_in` se **accessToken/idToken** leta hai.
3. App backend ko `POST /auth/google` call karti hai.
4. Backend token validate karke:
   - Agar user pehli baar hai → user create
   - Agar existing hai → simply login
5. Backend **JWT** generate karke frontend ko bhejta hai.
6. Flutter JWT ko local storage me save karta hai, future API calls me `Authorization: Bearer <token>` bhejta hai.

### 8.2 Add Expense (Manual)

1. User amount, category, description fill karta hai.
2. Flutter `POST /transactions` call karta hai.
3. Backend data validate karta hai, MongoDB me document save karta hai.
4. Response me updated list / success status.
5. UI refresh ho jata hai.

### 8.3 Scan Receipt (OCR Flow)

1. User bill ki photo capture / select karta hai.
2. App image ko OCR API ko send karti hai (Flask server).
3. OCR + `EnhancedReceiptExtractor` text parse karta hai.
4. JSON response aata hai: merchant, total, date, items, tax, etc.
5. App user ko preview dikhata hai, fir confirm pe **expense auto-create** ho jata hai.

### 8.4 Voice Command "Add expense 500 for food"

1. User mic press karta hai, voice assistant **listen** mode me jata hai.
2. `speech_to_text` command ko text me convert karta hai.
3. Command parser **amount** (500) aur **category** (food) nikalta hai.
4. App backend ko transaction create request bhejta hai.
5. `text_to_speech` bolta hai: "500 rupees ka food expense add ho gaya."

### 8.5 Place Food Order (Shop Module)

1. User shop list dekh kar ek shop select karta hai.
2. `GET /shop-orders/shops` + `GET /shop-orders/shops/:id/menu` se data load.
3. User cart banata hai, **place order** pe `POST /shop-orders/orders`.
4. Main backend ye request **shop backend** ko forward karta hai.
5. Shop owner admin panel pe order dekh ke status update karta hai.
6. User app par `GET /shop-orders/orders/:id` se live status dekh sakta hai.

---

## 9. CORS & Security Explanation

**CORS (Cross-Origin Resource Sharing):**

> "Sir, CORS ek browser security policy hai jo different domains/ports ke beech requests ko restrict karta hai. Hamara frontend (Flutter web/React admin) aur backend alag origins pe run hote hain, isliye mujhe CORS configure karna pada."

- Backend me **`cors` middleware** use kiya:
  - Allowed origins: hamara frontend domain / localhost
  - Allowed methods: GET, POST, PUT, DELETE
  - Allowed headers: `Content-Type`, `Authorization`, etc.
- Isse browser hamari **cross-origin API calls** allow karta hai.

**Other security points:**
- JWT-based authentication
- Password hashing on server side
- Sensitive data (.env) me rakha, repository me nahi

---

## 10. Integrations (DB, Cloud, Third-Party)

- **MongoDB Atlas** – remote database, secure connection string via env vars
- **Google Sign-In** – OAuth-based auth without Firebase
- **Cloudinary** – profile picture upload & CDN delivery
- **Railway** – Node.js backends deployment
- **Vercel (or similar)** – shop management frontend deployment
- **Python OCR & ML services** – integrated through HTTP/REST or batch scripts

Viva tip: har integration ke saath **kyun use kiya** aur **alternatives** bhi mention karo (e.g., Firebase, MySQL, local Mongo, etc.).

---

## 11. Major Challenges & How You Solved Them

Ye section examiner ko impress karega. Clear, honest points bolo.

- **1. Backend URL & CORS Issues**
  - Problem: Wrong Railway URL / `/api` prefix issues → 404 & "no application found" errors.
  - Fix: Correct base URL set kiya, frontend config update ki, backend me proper CORS middleware configure kiya.

- **2. Google Sign-In Problems**
  - Tokens, SHA-1 fingerprint, `google-services.json` confusion.
  - Fix: Flutter side pe simpler `google_sign_in` config use ki; backend ko `accessToken` bhi accept karaya; endpoint path fix kiya (duplicate `/api` hataaya).

- **3. MongoDB & Deployment Errors**
  - Atlas connection string me database name missing, Railway build issues.
  - Fix: Proper connection string (`.../finnsathi`) use kiya; `legacy-peer-deps` use karke Node dependencies resolve ki; `.env` use kiya, config files se secrets hata diye.

- **4. Docker / Nixpacks Confusion**
  - Railway pe Nixpacks vs Docker config ke chakkar me builds fail hote the.
  - Fix: Approach simplify kiya – ya to proper Dockerfile, ya simple Railway config – aur extra configs hata diye.

- **5. OCR Accuracy on Indian Receipts**
  - Single OCR engine se accuracy low, especially noisy bills / different formats.
  - Fix:
    - Advanced preprocessing (contrast, denoise, sharpen, perspective correction).
    - Strong regex-based extractor for GST, totals, dates.
    - Multiple strategies for merchant, items, tax extraction.

- **6. UI / Splash & System UI Bugs**
  - Default Flutter splash screen, navigation bar color mismatch.
  - Fix: `flutter_native_splash` + custom icons, launch screen XMLs, system UI overlay configs.

- **7. ML Integration & Dependencies**
  - Python ML libraries + environment setup tricky tha.
  - Fix: Separate `requirements` files, `run_all_models.bat`, detailed documentation; manual setup instructions.

---

## 12. New / Advanced Features to Highlight

- **Voice Assistant for Finance**
  - Voice commands → automatic expense/income entries
  - Indian English phrasing, flexible amount formats

- **Enhanced OCR for Indian Bills**
  - Indian retail formats (D-Mart, Big Bazaar, etc.)
  - GST (CGST/SGST/IGST) extraction
  - Confidence scoring & error handling

- **Advanced ML Features**
  - Expense prediction, anomaly detection
  - Personalized recommendations
  - Time-series trends & segmentation

- **Shop Management + Food Ordering**
  - Separate microservice-style backend
  - Owner dashboard + user-facing ordering
  - Real-time order status & analytics

---

## 13. Future Scope (Agar poochhen to bolo)

- Real-time push notifications (budget cross, large expense, order status)
- Direct UPI / payment integration
- More advanced chatbot with full LLM integration
- Cross-platform deployment (iOS, Web) with more optimizations
- Better analytics dashboard with graphs & visualizations

---

## 14. How to Use This File for Viva

- Har section ka **heading padh ke** short 2–3 lines yaad kar lo.
- Architecture + tech stack + challenges pe sabse zyada focus rakho.
- Apne words use karo, but **flow yehi rakho**:
  1. Project intro
  2. Architecture
  3. Tech stack
  4. Features
  5. Routes & API flows
  6. CORS & security
  7. OCR, Voice, ML details
  8. Challenges & solutions
  9. Future scope

All the best for your viva! 👌
