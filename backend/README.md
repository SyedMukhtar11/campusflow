# CampusFlow Backend API

A robust, modular, and performant REST API built with **Node.js**, **Express.js**, and **MongoDB (Mongoose)** for the CampusFlow Flutter application.

---

## 📁 Architecture & Project Structure

The backend follows a clean **Controller-Service-Repository/Model** pattern with distinct layers of concern:

```
backend/
├── app.js                   # Express application setup, middleware, and route mounting
├── index.js                 # Server entry point, DB bootstrap & graceful shutdown
├── openapi.yaml             # Full OpenAPI 3.0 API specification
├── package.json             # NPM dependencies & test/dev scripts
├── .env.example             # Example environment variables template
├── .env                     # Local environment configuration
│
├── config/                  # Configuration modules
│   └── db.js                # Resilient MongoDB connection with auto-fallback
│
├── controller/              # Route controllers (business logic & HTTP response handling)
│   ├── authController.js    # User signup, login, profile retrieval & update
│   ├── programController.js # Program listing, category filtering, search, and details
│   ├── registrationController.js # Event registration, cancellation, and user registrations
│   ├── notificationController.js # User notifications, read/unread state management
│   └── feedbackController.js     # User ratings and program feedback submission
│
├── middleware/              # Express middlewares
│   ├── authMiddleware.js    # JWT verification and route protection
│   ├── errorHandler.js      # Centralized error handler and validation formatting
│   └── requestLogger.js     # Colorized request timing and status logging
│
├── models/                  # Mongoose data schemas
│   ├── userSchema.js        # User model with bcrypt password hashing
│   ├── programSchema.js     # Campus program/event model
│   ├── registrationSchema.js# User-to-program registrations (unique composite index)
│   ├── notificationSchema.js# User notification records with relative timeAgo
│   └── feedbackSchema.js    # Program feedback entries with rating validation
│
├── routes/                  # Express route definitions
│   ├── authRoutes.js        # /auth endpoints
│   ├── programRoutes.js     # /programs endpoints
│   ├── registrationRoutes.js# /registrations endpoints
│   └── notificationRoutes.js# /notifications endpoints
│
├── seed/                    # Initial database seeders
│   └── seedPrograms.js      # Seeds default programs from data/programs.json
│
├── services/                # Reusable business services
│   ├── tokenService.js      # JWT signing utility
│   └── notificationService.js# Helper to trigger registration & welcome notifications
│
├── test/                    # Automated integration tests
│   └── api.test.js          # Node test runner suite verifying all endpoints
│
└── utils/                   # Shared utility functions
    ├── asyncHandler.js      # Async/await wrapper eliminating repetitive try-catch
    ├── timeAgo.js           # Human-readable relative time formatting
    └── userPayload.js       # Safe user JSON projection (omits password)
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Node.js 18+ (tested on Node.js 20 & 22)
- MongoDB instance (MongoDB Atlas or local `mongodb://127.0.0.1:27017`)

### 2. Environment Setup
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Configure your environment variables:
```env
PORT=3000
MONGODB_URI=mongodb://127.0.0.1:27017/CampusFlow
JWT_SECRET=your-secure-jwt-secret-here
JWT_EXPIRES_IN=7d
```

> **Smart Database Fallback**: If the configured Atlas connection is unreachable (e.g., due to an IP whitelist restriction), the database manager automatically falls back to local MongoDB (`mongodb://127.0.0.1:27017/CampusFlow`) so local development never breaks.

### 3. Installation
```bash
npm install
```

### 4. Running the Server
```bash
# Production mode
npm start

# Development mode (with file-watching)
npm run dev
```

- **Deployed Production Service**: `https://campusflow-nq50.onrender.com`
- **Local Development**: The server binds to `0.0.0.0:3000`, making it accessible to Android emulators (`10.0.2.2:3000`), iOS simulators (`localhost:3000`), desktop builds, and physical devices on the local Wi-Fi.

### 5. Running Tests
```bash
npm test
```

---

## 📡 API Reference

### Health & Root
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/` | Public | Service metadata and version |
| `GET` | `/health` | Public | Health status, uptime, and database connection state |

---

### Authentication (`/auth`)
| Method | Endpoint | Access | Body / Params | Description |
|---|---|---|---|---|
| `POST` | `/auth/signup` | Public | `{ name, email, password }` | Creates user, seeds notifications, returns JWT token & user |
| `POST` | `/auth/login` | Public | `{ email, password }` | Authenticates user and returns JWT token & user profile |
| `GET` | `/auth/me` | Private | Header: `Bearer <token>` | Fetches current user profile |
| `PUT` | `/auth/me` | Private | `{ name?, email? }` | Updates profile fields |
| `DELETE` | `/auth/me` | Private | Header: `Bearer <token>` | Deletes current user account |

---

### Programs (`/programs`)
| Method | Endpoint | Access | Query / Params | Description |
|---|---|---|---|---|
| `GET` | `/programs` | Public | `category`, `q` | Lists programs with optional category filtering & search |
| `GET` | `/programs/:id` | Public | `:id` | Fetches single program details |
| `POST` | `/programs/:id/register` | Private | `:id` | Atomically registers user, checks capacity, increments seats |
| `DELETE` | `/programs/:id/register` | Private | `:id` | Cancels registration and decrements seats |
| `POST` | `/programs/:id/feedback` | Private | `{ rating, category, email, comment }` | Submits 1-5 star feedback |
| `GET` | `/programs/:id/feedback` | Public | `:id` | Lists all feedback entries for a program |

---

### Registrations & Learning Progress (`/registrations`)
| Method | Endpoint | Access | Params | Description |
|---|---|---|---|---|
| `GET` | `/registrations` | Private | None | Lists all registered programs with progress, completed modules, and status (`ongoing` / `completed`) |
| `GET` | `/registrations/:programId` | Private | `:programId` | Fetches registration progress and module status for a specific program |
| `PATCH` | `/registrations/:programId/modules/:moduleIndex/toggle` | Private | `:programId`, `:moduleIndex` | Toggles module completion ("Mark as complete" / unmark), calculates progress percentage, and completes program at 100% |
| `DELETE` | `/registrations/:programId` | Private | `:programId` | Cancels registration by program ID |

---

### Notifications (`/notifications`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/notifications` | Private | Returns user's notifications and `unreadCount` |
| `PATCH` | `/notifications/:id/read` | Private | Marks a single notification as read |
| `PATCH` | `/notifications/read-all` | Private | Marks all notifications as read |
| `DELETE` | `/notifications/:id` | Private | Deletes a notification |
| `DELETE` | `/notifications` | Private | Clears all notifications for the user |

---

## 🛡️ Reliability & Security Highlights
- **Atomic Concurrency Protection**: Event registration uses MongoDB atomic `$expr` conditions and `$inc` to guarantee that capacity limits cannot be exceeded during concurrent registration bursts.
- **Graceful Process Handling**: Listens to `SIGINT` and `SIGTERM` signals to cleanly drain active HTTP connections and safely disconnect MongoDB before exit.
- **Deprecation Clean**: Fully compliant with Mongoose 8/9 standards using `{ returnDocument: 'after' }`.
- **Standardized Error Handling**: Central error handler formats validation errors, duplicate key violations, and JWT expirations into consistent, human-readable error JSON.
