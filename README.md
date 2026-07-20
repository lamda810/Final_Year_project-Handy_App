# Handy Go 🔧

> **On-demand home services platform** - Connecting customers with skilled workers for plumbing, electrical, cleaning, and more.

## 🏗️ Project Architecture

```
handy-go/
├── apps/
│   ├── customer-app/          # Flutter - Customer Mobile App
│   ├── worker-app/            # Flutter - Worker Mobile App
│   └── admin-panel/           # React.js - Admin Web Dashboard
├── backend/
│   ├── api-gateway/           # Express.js - API Gateway (Port 3000)
│   ├── services/
│   │   ├── auth-service/      # Authentication & Authorization (Port 3001)
│   │   ├── user-service/      # User Management (Port 3002)
│   │   ├── booking-service/   # Booking Logic (Port 3003)
│   │   ├── matching-service/  # AI Worker Matching (Port 3004)
│   │   ├── payment-service/   # Payment Processing (Port 3005)
│   │   ├── notification-service/  # Push Notifications (Port 3006)
│   │   ├── sos-service/       # Emergency Handling (Port 3007)
│   │   └── analytics-service/ # Reports & Analytics (Port 3008)
│   └── shared/                # Shared utilities, models, constants
├── ai-models/
│   ├── problem-detection/     # NLP for problem categorization
│   ├── worker-matching/       # Smart matching algorithm
│   ├── price-prediction/      # Dynamic pricing model
│   └── duration-estimation/   # Job time prediction
├── infrastructure/
│   ├── docker/                # Docker configurations
│   ├── kubernetes/            # K8s deployment configs
│   └── terraform/             # Cloud infrastructure as code
├── docs/                      # Documentation
└── tests/                     # E2E and integration tests
```

## 🚀 Quick Start

### Prerequisites

- Node.js >= 20.0.0
- pnpm >= 8.0.0
- FVM
- Flutter `3.44.6` via FVM (for mobile apps)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd handy-go
   ```

2. **Install dependencies**
   ```bash
   pnpm install
   ```

3. **Install the pinned Flutter SDK with FVM**
   ```bash
   ./scripts/fvm use 3.44.6
   ```

   If the global `fvm` command is killed in your terminal, keep using `./scripts/fvm`.

4. **Setup environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Start the local backend**
   ```bash
   pnpm dev
   ```

   This starts the local no-Docker API gateway used by the admin panel and Flutter apps.

6. **Run Flutter apps through FVM**
   ```bash
   cd apps/customer-app
   ../../scripts/fvm flutter pub get
   ../../scripts/fvm flutter run
   ```

   Or:
   ```bash
   cd apps/worker-app
   fvm flutter pub get
   fvm flutter run
   ```

## 📦 Services

| Service | Port | Description |
|---------|------|-------------|
| API Gateway | 3000 | Single entry point for all client requests |
| Auth Service | 3001 | Authentication & Authorization |
| User Service | 3002 | User profile management |
| Booking Service | 3003 | Booking lifecycle management |
| Matching Service | 3004 | AI-powered worker matching |
| Payment Service | 3005 | Payment processing |
| Notification Service | 3006 | Push notifications & SMS |
| SOS Service | 3007 | Emergency handling |
| Analytics Service | 3008 | Reports & analytics |

## 🛠️ Tech Stack

### Backend
- **Runtime**: Node.js 20+
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Cache**: Redis
- **Authentication**: JWT
- **API Documentation**: Swagger/OpenAPI

### Mobile Apps
- **Framework**: Flutter via FVM (`3.44.6`)
- **State Management**: flutter_bloc
- **Local Storage**: Hive, Shared Preferences
- **Maps**: Google Maps

### Admin Panel
- **Framework**: Vite with React
- **UI**: MUI
- **State**: React Query

### Infrastructure
- **Local Development**: Node.js + Flutter via FVM
- **CI/CD**: GitHub Actions

## 📝 API Documentation

API documentation is available at `http://localhost:3000/api-docs` when running the development server.

## 🧪 Testing

```bash
# Run all tests
pnpm test

# Run tests with coverage
pnpm test:coverage

# Run specific service tests
pnpm --filter auth-service test
```

## 📄 License

This project is proprietary and confidential.

---

Built with ❤️ by Handy Go Team
