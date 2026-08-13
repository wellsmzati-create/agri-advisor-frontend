# Backend Models and Schemas

This document lists the backend models inferred from the app's dummy data, a normalized relational schema (tables + fields), Firestore/JSON document examples, enums, and brief notes for implementation.

## Summary
- Source: frontend model classes in `lib/models/models.dart` and mock datasets in `lib/data/mock_data.dart`, `lib/epa/epa_mock_data.dart`, `lib/web/web_mock_data.dart`.
- Goal: provide backend model list and DB schema to make the prototype functional.

## Core Models (logical)
- User / Farmer
- Farm (and optional Field)
- Advisor / ExtensionWorker / EpaOfficer (staff)
- Crop (catalog)
- CropRecommendation
- FarmingTip / SeasonalNotice
- Conversation + ChatMessage
- Attachment / Media
- Notification
- FarmerReport / Incident
- OutbreakSignal / OutbreakReport
- ResponseAction / Intervention
- SoilTestResult / FarmRecord
- AuthSession / AccessToken
- Role / Permission
- AuditLog / RecommendationAudit

## Relational Schema (normalized)
Notes: use UUID strings for ids, timestamps as UTC.

Tables:

- users
  - id PK uuid
  - email varchar unique
  - phone varchar
  - password_hash varchar (nullable if OAuth)
  - name varchar
  - role varchar (farmer|advisor|epa|admin)
  - avatar_initials varchar(8)
  - created_at timestamptz
  - updated_at timestamptz
  - status varchar

- farms
  - id PK uuid
  - owner_id FK -> users(id)
  - name varchar
  - location_text varchar
  - geo json (point or polygon)
  - lat double, lng double (optional)
  - size_acres int
  - soil_type varchar
  - created_at timestamptz

- fields (optional)
  - id PK uuid
  - farm_id FK -> farms(id)
  - name varchar
  - polygon geojson
  - area float
  - current_crop_id FK -> crops(id)

- staff (advisors / extension workers / epa officers)
  - id PK uuid
  - user_id FK -> users(id) (optional)
  - name, email, region, specialization, role
  - rating numeric(2,1)
  - years_experience int
  - active boolean
  - last_active timestamptz

- crops
  - id PK uuid
  - name varchar
  - category varchar
  - description text
  - soil_type varchar
  - climate varchar
  - growth_days int
  - rainfall varchar
  - temperature varchar
  - image_ref varchar
  - created_at timestamptz

- crop_recommendations
  - id PK uuid
  - farmer_id FK -> users(id)
  - advisor_id FK -> staff(id)
  - crop_id FK -> crops(id) (nullable)
  - crop_name varchar
  - reason text
  - soil_type varchar
  - season varchar
  - rainfall varchar
  - steps jsonb (array of strings)
  - date timestamptz
  - status varchar
  - created_at timestamptz

- farming_tips
  - id PK uuid
  - title varchar
  - body text
  - category varchar
  - season varchar
  - author_id FK -> staff(id)
  - published_at timestamptz
  - status varchar

- conversations
  - id PK uuid
  - participants jsonb (list of user ids)
  - last_message text
  - unread_counts jsonb
  - updated_at timestamptz

- chat_messages
  - id PK uuid
  - conversation_id FK -> conversations(id)
  - sender_id FK -> users(id) or staff(id)
  - content text
  - timestamp timestamptz
  - is_from_farmer boolean
  - attachments jsonb

- attachments
  - id PK uuid
  - owner_id FK -> users(id)
  - url varchar
  - type varchar
  - mime varchar
  - size int
  - created_at timestamptz

- notifications
  - id PK uuid
  - user_id FK -> users(id) (nullable for broadcasts)
  - title varchar
  - body text
  - type varchar
  - priority varchar
  - is_read boolean
  - timestamp timestamptz

- farmer_reports
  - id PK uuid
  - farmer_id FK -> users(id)
  - title varchar
  - issue text
  - category varchar
  - region varchar
  - status varchar
  - severity varchar
  - advisor_assigned_id FK -> staff(id)
  - submitted_at timestamptz
  - attachments jsonb

- outbreaks
  - id PK uuid
  - reporter_id FK -> users(id) or staff(id)
  - title varchar
  - crop_affected varchar
  - location_text varchar
  - region varchar
  - severity varchar
  - status varchar
  - description text
  - reported_at timestamptz
  - affected_farms int
  - validation_history jsonb

- response_actions
  - id PK uuid
  - title varchar
  - description text
  - type varchar
  - status varchar
  - target_region varchar
  - created_by FK -> staff(id)
  - created_at timestamptz
  - priority varchar
  - related_outbreak_id FK -> outbreaks(id)

- soil_tests
  - id PK uuid
  - farm_id FK -> farms(id)
  - farmer_id FK -> users(id)
  - ph numeric
  - nitrogen varchar
  - phosphorus varchar
  - potassium varchar
  - micronutrients jsonb
  - recorded_at timestamptz
  - notes text

- audit_logs
  - id PK
  - entity_type varchar
  - entity_id uuid
  - action varchar
  - performed_by uuid
  - performed_at timestamptz
  - details jsonb

- roles & permissions (standard tables)

## Firestore / JSON document examples
Use collections: users, farms, crops, recommendations, conversations, messages, attachments, reports, outbreaks, responses, soil_tests, notifications, audit_logs.

Example `users/{userId}` (Farmer)
{
  "id": "wf001",
  "name": "Austin Libwathi",
  "email": "austin.libwathi@farm.mw",
  "phone": "+233245678901",
  "role": "farmer",
  "avatarInitials": "AL",
  "status": "active",
  "createdAt": "2024-03-10T00:00:00Z"
}

Example `farms/{farmId}`
{
  "id": "farm_001",
  "ownerId": "wf001",
  "location": "Kumasi, Ashanti",
  "lat": 6.6885,
  "lng": -1.6244,
  "sizeAcres": 12,
  "soilType": "Loamy",
  "createdAt": "2025-03-15T00:00:00Z"
}

Example `recommendations/{recId}`
{
  "id": "r001",
  "farmerId": "wf001",
  "advisorId": "a001",
  "cropId": "c001",
  "cropName": "Maize",
  "reason": "Based on your soil analysis...",
  "steps": ["Prepare land...", "Plant seeds..."],
  "date": "2025-06-10T00:00:00Z",
  "status": "active"
}

Example `conversations/{convId}` + `messages/{messageId}` subcollection
`conversations/conv_123`:
{
  "id": "conv_123",
  "participants": ["wf001","a001"],
  "updatedAt": "2025-06-14T10:15:00Z"
}

`conversations/conv_123/messages/msg_1`:
{
  "id":"m001",
  "senderId":"wf001",
  "content":"Good morning...",
  "timestamp":"2025-06-14T09:30:00Z",
  "isFromFarmer":true
}

## Enums / Domain Types
- RecommendationStatus: Draft, Active, Completed, Archived
- ReportStatus: Pending, InProgress, Resolved, Escalated
- OutbreakSeverity: Low, Medium, High, Critical
- NotificationType: recommendation, alert, message, tip, reminder, notice
- Priority: Low, Normal, High, Critical
- UserStatus: Active, Inactive, Pending

## Implementation Notes
- Normalize regions/districts into a `regions` table for efficient filtering.
- Use JSONB for flexible arrays (steps, attachments) if using Postgres.
- Store media in object storage (S3 / Cloud Storage) and save references in `attachments`.
- Design conversation indexing for fast retrieval (last_message, updated_at). Consider Firestore for realtime chat; use relational DB for stable transactional data.
- Add ACL checks: advisors should only access assigned farmers; EPA roles have elevated access to outbreaks and response actions.
- Provide audit logs for recommendations, validations, and status changes.

## Next steps
- Generate SQL DDL for your chosen RDBMS or a Firestore rules + sample import JSON. Ask which you'd prefer.

---
Generated from frontend mocks in `lib/models/models.dart`, `lib/data/mock_data.dart`, `lib/epa/epa_mock_data.dart`, `lib/web/web_mock_data.dart`.
