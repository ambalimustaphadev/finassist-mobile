# FinAssist

**AI-powered personal financial assistant built with Flutter.**

FinAssist is a mobile application designed to help users understand and manage their personal finances through an AI-powered conversational experience.

Users can securely authenticate, upload financial statements, manage financial information, and interact with an AI assistant about their finances.

> 🚧 **Status:** Active development

## ✨ Features

* 🔐 JWT-based authentication
* 💬 AI-powered financial chat
* 📄 Financial statement uploads
* ☁️ Cloudflare R2 document storage
* 📊 Financial dashboard and insights
* 👤 User profile and financial data
* 📱 Cross-platform Flutter application

## 🛠️ Tech Stack

* **Flutter / Dart** — Mobile application
* **Riverpod** — State management
* **GoRouter** — Navigation
* **Flask** — Backend API
* **SQLAlchemy** — Database ORM
* **Flask-Migrate** — Database migrations
* **JWT** — Authentication
* **Cloudflare R2** — File storage
* **OpenAI** — AI capabilities

## 🏗️ Architecture

FinAssist uses a feature-oriented Flutter architecture with separated presentation, state management, repositories, services, and models.

```text
Flutter App
    │
    ▼
FinAssist Flask API
    │
    ├── Authentication
    ├── AI Chat
    ├── Financial Data
    └── File Uploads
            │
            ▼
       Cloudflare R2
```

The Flutter application never communicates directly with Cloudflare R2 or OpenAI using secret credentials. Protected operations go through the backend.

## 📄 Financial Documents

Users can upload financial documents from the application.

Current supported formats include:

* PDF
* CSV
* XLS
* XLSX
* JPG / JPEG
* PNG

The upload flow is:

```text
Flutter
   ↓
Flask API
   ↓
Cloudflare R2
   ↓
Database
```

Document processing and transaction extraction are currently being developed.

## 🚀 Getting Started

Clone the repository:

```bash
git clone https://github.com/ambalimustaphadev/finassist-mobile.git
cd finassist
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Check the project:

```bash
flutter analyze
flutter test
```

## 🔗 Backend

The Flutter application communicates with the separate FinAssist Flask backend.

**Backend:** https://github.com/ambalimustaphadev/finassist-backend

For local physical-device testing, configure the API to point to your Mac's local network address, for example:

```text
http://192.168.1.23:5002
```

Run Flask with:

```bash
uv run flask run --host=0.0.0.0 --port=5002
```

## 🗺️ Roadmap

* [x] Authentication
* [x] AI chat foundation
* [x] Financial dashboard
* [x] File upload
* [x] Cloudflare R2 storage
* [ ] Unified chat and statement uploads
* [ ] Document processing
* [ ] Transaction extraction
* [ ] Financial transaction database
* [ ] AI-powered financial analysis
* [ ] Advanced financial insights

## 👨‍💻 Author

**Mustapha Ambali Adewole**

Flutter Developer

[Portfolio](https://ambalimustapha.dev) · [GitHub](https://github.com/ambalimustaphadev)
