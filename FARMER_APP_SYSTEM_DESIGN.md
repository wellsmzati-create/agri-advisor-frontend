# Farmer App System Design Document

## 1. Document Purpose

This document explains the `farmer_app` system in business and technical terms so that a reader can understand how it works without reading the source code.

It is intended for:
- project owners
- testers
- supervisors
- new developers
- stakeholders reviewing the system scope

Verified against the current application and backend state on June 14, 2026.

## 2. System Summary

AgriAdvisor is a role-based digital agriculture platform with three intended user groups:
- Farmer users on mobile
- Advisor users on the web dashboard
- EPA users on a separate web-oriented interface

The current working integration focus is:
- Farmer mobile app connected to backend APIs
- Advisor web dashboard connected to backend APIs
- Backend authentication, role-based routing, farm data, recommendations, tips, conversations, and notifications

The system uses:
- Flutter for the frontend
- Laravel for the backend API
- Laravel Sanctum for token authentication
- Spatie Permission for role control
- a queued job for crop recommendation generation
- an external AI service when configured, with a safe fallback when it is unavailable

## 3. Business Goal

The platform is designed to help farmers receive practical crop guidance and connect with agricultural advisors, while allowing advisors to manage farmers and issue crop recommendations through a web dashboard.

At a high level:
- Farmers log in, view farms, receive recommendations, read tips, see notifications, and communicate with advisors
- Advisors log in through the web interface, monitor farmers, review recommendation history, and create new recommendations
- EPA users are part of the larger system design, but were not the main verified integration target in this phase

## 4. Supported User Roles

| Role | Platform | Main Purpose | Current State |
|---|---|---|---|
| Farmer | Android/mobile Flutter app | View own farming data and receive support | Verified in current integration scope |
| Advisor | Flutter web dashboard | Manage farmers and recommendations | Verified in current integration scope |
| EPA | Flutter EPA surface | Oversight and outbreak/report workflows | Exists in architecture, not fully re-validated in this pass |
| Admin | Backend role | System administration | Backend role exists |

## 5. Platform Structure

### 5.1 Farmer Mobile App

The farmer experience is the default mobile experience. After login, a farmer is routed to the mobile shell and can access:
- dashboard
- farms
- crop recommendations
- farming tips
- notifications
- advisor conversations and messages

### 5.2 Advisor Web Dashboard

The advisor experience is the main web experience currently validated against the backend. The advisor dashboard currently focuses on:
- Dashboard
- Farmers
- Recommendations

This dashboard was simplified to emphasize backend-backed functionality instead of mock-only screens.

### 5.3 EPA Interface

The EPA interface is part of the application routing and backend route structure. It supports the broader system design, but it was not the main target of the latest end-to-end validation.

## 6. High-Level Architecture

| Layer | Technology | Responsibility |
|---|---|---|
| Frontend | Flutter | Mobile app, web dashboard, role-based UI |
| State/Auth | Flutter providers | Session restore, login state, logout handling |
| API Layer | Flutter service layer | Sends authenticated requests to Laravel API |
| Backend | Laravel | Business logic, role-based endpoints, persistence |
| Auth | Laravel Sanctum | Token issuance and protected API access |
| Authorization | Spatie Permission | Role checks for farmer, advisor, EPA, admin |
| Background Jobs | Laravel queue | Recommendation generation workflow |
| AI Integration | External AI endpoint | Generates recommendation content when configured |
| Data Store | Relational database | Users, profiles, farms, recommendations, messages, notifications |

## 7. System Flow

### 7.1 Startup and Authentication

1. The app opens on a splash screen.
2. The frontend tries to restore a saved session token.
3. The frontend calls the backend `auth/me` endpoint if a token exists.
4. If authentication succeeds, the user is routed by role:
   - farmer -> mobile shell
   - advisor -> web shell
   - EPA -> EPA shell
5. If authentication fails or no token exists, the user is sent to the login screen.

### 7.2 Farmer Flow

1. Farmer logs in on the mobile app.
2. Backend returns the user profile and token.
3. Farmer dashboard data is assembled from backend endpoints for:
   - farms
   - recommendations
   - notifications
   - tips
4. Farmer can read conversations and messages with advisors.
5. Farmer can mark notifications as read.

### 7.3 Advisor Flow

1. Advisor logs in through the web login screen.
2. Advisor is routed to the web dashboard shell.
3. Advisor dashboard loads summary data from the backend.
4. Advisor can view farmer records from the backend.
5. Advisor can create a recommendation for a selected farm.
6. Recommendation status moves through backend processing and can become `generated`.

### 7.4 Recommendation Generation Flow

1. Advisor submits recommendation input for a farm.
2. Backend creates a recommendation record.
3. Backend dispatches a job to generate recommendation content.
4. If the external AI service is configured and reachable, the recommendation uses that response.
5. If the AI service is unavailable or not configured, the backend now creates a safe baseline recommendation instead of crashing.
6. The recommendation status is updated to `generated`.

## 8. Main Data Concepts

| Entity | Purpose |
|---|---|
| User | Base identity record with role |
| FarmerProfile | Farmer-specific profile information |
| AdvisorProfile | Advisor-specific profile information |
| EpaProfile | EPA-specific profile information |
| Farm | Physical farm record linked to a farmer |
| CropRecommendation | Generated or pending crop advice for a farm |
| FarmingTip | Published advisory information |
| Conversation | Chat thread between users |
| ChatMessage | Individual message in a conversation |
| Notification | Alert sent to a user |
| OutbreakSignal | EPA/advisory monitoring record |
| FarmerReport | Report submitted for review |

## 9. Backend API Scope

The backend is organized under `/api/v1` and uses protected role-based route groups.

### 9.1 Authentication

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/logout`

### 9.2 Farmer API Scope

- profile management
- farm CRUD
- recommendation list and detail
- farming tips
- conversations and messages
- notifications
- dashboard summary

### 9.3 Advisor API Scope

- dashboard summary
- farmer list and detail
- recommendation CRUD
- crop management
- tips management
- outbreak reporting
- notification broadcasting

### 9.4 EPA API Scope

- dashboard
- user management
- reports
- outbreaks
- activity
- notification broadcasting

## 10. Current Verified Functional State

The following statements reflect the current verified state of the system.

### 10.1 Working and Verified

- Farmer and advisor authentication are working against the backend
- Session restore and role-based routing are working
- Farmer mobile data loading is wired to backend endpoints
- Advisor web dashboard is using backend data for dashboard, farmers, and recommendations
- Backend login and registration issues were fixed
- Backend recommendation creation no longer fails when the AI endpoint is missing
- Flutter analysis completed without compile errors
- Flutter smoke test passed
- Laravel backend test suite passed

### 10.2 Important Operational Requirement

Recommendation generation depends on the Laravel queue system.

If the queue worker is not running:
- recommendation records can remain pending longer than expected
- the advisor may not see generated outputs immediately

## 11. Deployment and Runtime Requirements

For the integrated system to work in real testing:

- the Laravel backend must be running
- the backend must be reachable from the Android phone and from the browser
- the configured API base URL in the Flutter app must point to the reachable backend host
- the phone and backend machine should be on the same network when using a local IP
- the Laravel queue worker should be running
- the database should contain the required roles and seeded test users

## 12. Test Accounts

The current seeded test accounts used for validation are:

| Role | Email | Password |
|---|---|---|
| Farmer | `farmer@agri.local` | `password` |
| Advisor | `advisor@agri.local` | `password` |

These accounts are intended for development and testing only.

## 13. Non-Functional Notes

### 13.1 Reliability

The system is more reliable than the earlier mock-based prototype because key user flows now depend on backend truth instead of placeholder data.

### 13.2 Security

Authentication uses token-based access with Sanctum.

This is suitable for application-level session management, but production security still depends on:
- HTTPS
- protected secrets
- secure deployment configuration
- hardened environment variables
- proper server access control

### 13.3 Scalability

The design supports growth better than a mock-only prototype because:
- logic is centralized in the backend
- roles are enforced server-side
- background jobs can be scaled independently
- recommendation generation is separated from the request-response cycle

## 14. Known Limitations and Honest Boundaries

- EPA flows exist in the architecture but were not fully re-tested in the latest validation cycle
- Some older project documents still describe the app as mock-data-only and are now out of date
- Recommendation quality depends on AI service configuration when live AI output is desired
- The fallback recommendation prevents failure, but it is simpler than a real AI-generated recommendation
- Local-network testing can still fail if the backend IP changes or the device cannot reach the host

## 15. Recommended Use of This Document

This file can be used as:
- a system context handover document
- a stakeholder-facing design summary
- onboarding material for testers and new developers
- a high-level explanation during demos or reviews

If a more formal document is needed next, the best follow-up artifact would be one of these:
- a Software Requirements Specification (SRS)
- a database schema document aligned to the live backend
- a project report with scope, work completed, and remaining gaps

## 16. Conclusion

AgriAdvisor has moved beyond a frontend-only prototype for its farmer and advisor flows.

The current integrated system now supports:
- backend authentication
- role-based routing
- farmer mobile backend data
- advisor web backend data
- safe recommendation generation behavior

The system is appropriate for controlled testing on an Android device and through the web dashboard, provided the backend server and queue worker are running.
