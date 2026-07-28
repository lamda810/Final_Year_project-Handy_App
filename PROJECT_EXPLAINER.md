# Handy Go — Final Year Project Explainer
### (For explaining the project to evaluators, in simple terms)

---

## 1. What problem does this app solve?

In Pakistan, finding a trustworthy plumber, electrician, or cleaner is usually done by asking neighbors or calling random numbers from a signboard. There's no way to check if the person is verified, no fair pricing, and no record of what happened if something goes wrong.

**Handy Go** is an "Uber for home services" — it connects **Customers** who need a household job done (plumbing, electrical work, cleaning, etc.) with **Workers** (handymen) who are verified and available nearby.

---

## 2. Who are the users?

There are three types of people who use the system:

| User | What they do |
|---|---|
| **Customer** | Posts a job ("my tap is leaking"), gets matched with a nearby worker, negotiates a price, tracks the job, pays, and rates the worker. |
| **Worker** | Signs up, uploads their CNIC (national ID card) for verification, gets matched to nearby jobs, negotiates price with the customer, and completes the job. |
| **Admin** | Reviews and approves/rejects worker ID documents, monitors the platform through an analytics dashboard, and handles emergency (SOS) reports. |

---

## 3. The main user journey (step by step)

This is the story you should be able to tell an evaluator in one breath:

1. **Signup/Login** — Both customers and workers sign up using their **phone number** and verify it with an **OTP (one-time code)**, instead of a traditional email/password only flow.
2. **Worker verification** — A new worker must upload their **CNIC (front & back)** and a profile photo. These sit in a `pending` state until an **Admin manually reviews and approves them** in the Admin Panel. A worker who isn't verified **cannot be matched with jobs** — this is enforced in the backend, not just hidden in the UI.
3. **Customer posts a job** — The customer describes their problem in plain text (e.g. "my kitchen sink is leaking"), picks a location, and can mark it urgent.
4. **AI-assisted understanding** — A backend AI module (using OpenAI) reads the customer's problem description and automatically figures out which service category it belongs to (plumbing, electrical, etc.) and how urgent it is — the customer doesn't have to pick a category manually if they don't want to.
5. **Price prediction** — Before a worker is even assigned, the system estimates a fair price range for the job, based on the service type and job complexity (using baseline price data, not a guess).
6. **Worker matching** — The system looks at nearby available workers (using GPS/geolocation), and ranks them using a **matching score** that considers distance, rating, trust score, and skill match — similar in spirit to how ride-hailing apps match drivers.
7. **Price negotiation (chat)** — Customer and worker can chat inside the app. Either side can send a **price offer**, the other side can **counter-offer**, and once one side accepts, the price is locked in for the job. This is implemented as special chat message types (`PRICE_OFFER`, `PRICE_COUNTER`, `PRICE_ACCEPTED`, `PRICE_REJECTED`), not just plain text.
8. **Job starts — OTP verification** — This is a key anti-fraud feature: the worker **cannot mark the job as "started" without the customer reading out an OTP code sent to their phone**. This proves the worker is physically at the customer's location and stops workers from falsely claiming a job happened.
9. **Job ends — OTP verification again** — Same idea: the worker can't mark the job "completed" without another OTP confirmation from the customer. This protects the customer from being charged for unfinished work, and protects the worker by creating proof that the job was actually finished with the customer's confirmation.
10. **Payment & final price** — The final price (after any negotiation) is recorded, along with a platform fee, and the payment status is tracked (cash-based currently).
11. **Rating & review** — After the job, the customer rates the worker (1–5 stars + review), which feeds back into the worker's trust score.
12. **Trust score** — Every worker has a computed **trust score** based on their rating, job completion rate, on-time rate, and complaint history — this score influences how highly they're ranked in future job matching.
13. **SOS / Emergency** — If something goes wrong during a job (safety issue, dispute, etc.), either the customer or worker can raise an SOS alert with their location and evidence (photos/audio), which goes to the Admin for urgent handling.

---

## 4. What makes this project non-trivial (talking points for evaluators)

These are the parts worth highlighting because they show real engineering thought, not just a CRUD app:

- **OTP-gated job start/end** — a simple but effective fraud-prevention mechanism: a worker cannot fake "I did the job" without the customer's real-time confirmation.
- **CNIC-gated matching** — unverified workers are structurally excluded from the matching pool at the database/query level, not just hidden in the UI. Verification isn't cosmetic.
- **In-chat price negotiation as structured data** — instead of "just chat and figure it out," offers/counter-offers/acceptance are modeled as distinct, trackable message types with status (`PENDING`, `ACCEPTED`, `REJECTED`, `SUPERSEDED`).
- **A basic "AI" layer** — an OpenAI-powered problem analyzer (turns free text into a service category + urgency level), a price predictor, and a support chatbot. This shows the app doesn't just take rigid form input — it interprets natural language.
- **Trust score system** — a computed reputation score (not just a raw star average) combining rating, completion rate, punctuality, and complaints — used to rank workers, which is a more defensible "matching algorithm" than pure distance.
- **Microservices architecture** — the backend isn't one big monolith; it's split into independent services (auth, users, bookings, matching, notifications, SOS), each with its own routes/controllers, talking through a single API Gateway. This mirrors how real production systems (and companies like Uber) are structured.
- **Geospatial matching** — worker location is stored as a real GeoJSON point with a MongoDB `2dsphere` index, enabling proper "find workers near me" queries rather than manual distance math.

---

## 5. Technology stack (what to say if asked "what did you build this with?")

| Layer | Technology |
|---|---|
| Customer mobile app | Flutter (Dart), using the BLoC pattern for state management |
| Worker mobile app | Flutter (Dart), same BLoC pattern |
| Admin web dashboard | React 19 + Vite |
| Backend | Node.js + Express, written in TypeScript |
| Backend architecture | Microservices: separate Auth, User, Booking, Matching, Notification, and SOS services, all behind one API Gateway |
| Database | MongoDB (via Mongoose), including geospatial (`2dsphere`) indexes for location search |
| Authentication | Phone number + OTP verification, JWT tokens for session auth |
| AI/NLP | OpenAI API — used for understanding job descriptions, urgency detection, and a support chatbot |
| Image storage | Cloudinary (for CNIC images, profile photos, before/after job photos) |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Networking (mobile) | Dio (HTTP client) talking to the REST API Gateway |

---

## 6. The main data models (what's stored in the database)

Think of these as the "nouns" of the system:

- **User** — the base account: phone number, password (hashed), role (customer/worker/admin), verification state.
- **Customer** — customer-specific profile info linked to a User.
- **Worker** — worker profile: CNIC number + images (with individual approve/reject status per document), skills + hourly rates, current GPS location, service radius, availability schedule, rating, **trust score**, total jobs completed, bank details for payouts.
- **Booking** — the central "job" record: problem description, AI-detected service category, address, scheduled time, status (pending → accepted → in progress → completed), pricing breakdown (estimated/negotiated/final price + platform fee), a timeline log of status changes, worker's location history during the job, before/after photos, payment status, and the customer's rating/review.
- **ChatMessage** — messages tied to a booking, including the special price-negotiation message types described above.
- **OTP** — short-lived one-time codes tied to a phone number and a *purpose* (e.g. signup, `JOB_START`, `JOB_END`), with attempt counting and expiry.
- **SOS** — emergency reports: who raised it, priority (including an AI-assessed priority), location, evidence, resolution notes from the admin.
- **Notification** — push/in-app notifications sent to users.
- **Review** — feedback tied to completed bookings, feeding into worker trust scores.

---

## 7. What the Admin Panel does

The Admin Panel (a separate React web app) is where the platform operator manages the system:

- **Worker document review** — see pending CNIC/profile photo uploads and approve or reject them individually, with notes.
- **Analytics dashboard** — high-level stats about platform activity (bookings, users, etc.).
- **SOS handling** — view and resolve emergency reports raised by customers or workers.

---

## 8. Simple one-paragraph summary (elevator pitch)

> "Handy Go is a two-sided mobile marketplace, like Uber but for home repair services. Customers describe a problem in plain language, and the app uses AI to figure out the service type and a fair price estimate. It then matches them with a nearby, ID-verified worker based on distance, rating, and a computed trust score. Before any money changes hands, both sides can negotiate the price directly inside an in-app chat. To prevent fraud, the worker must get an OTP confirmation from the customer both when starting and finishing the job — so there's no way to fake having done the work. The whole backend is built as a set of independent microservices, and an admin panel lets the platform operator verify worker identities and monitor the system."

---

## 9. Anticipated evaluator questions (with short answers)

**Q: Why phone OTP instead of email/password only?**
A: In Pakistan, phone numbers are more universal and trusted than email for this kind of local service app, and OTP verification confirms the person actually owns that number — useful both at signup and, more importantly, at job start/end.

**Q: How do you prevent a worker from lying about finishing a job?**
A: The `completeJob` endpoint refuses to mark a booking as completed unless the correct `JOB_END` OTP (sent to the customer's phone) is supplied. Same mechanism protects `startJob`.

**Q: How is the price decided?**
A: There's an initial AI/baseline-driven estimate when the booking is created, but the actual price can be renegotiated by either party through structured price-offer messages in chat before the job starts; the final agreed price is what gets billed.

**Q: Is the "AI" real or just marketing?**
A: It's a real integration with the OpenAI API for two things: (1) turning a customer's free-text problem description into a structured service category + urgency level, and (2) a support chatbot. There's also a separate rule/data-driven price predictor and a trust-score calculator, which are more traditional weighted-scoring algorithms, not LLM calls.

**Q: Why microservices instead of one backend?**
A: To mirror real-world scalable system design — each concern (auth, bookings, matching, notifications, SOS) is isolated, can be developed/tested/scaled independently, and all traffic is routed through a single API Gateway so the mobile apps only ever talk to one entry point.
