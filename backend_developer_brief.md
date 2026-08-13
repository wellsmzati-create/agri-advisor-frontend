# AgriAdvisor Laravel Backend Developer Brief

## Purpose

This brief is for backend developers building the Laravel API that serves the existing Flutter frontend in `farmer_app`.

The backend must support:
- Farmer mobile app
- Advisor web dashboard in `lib/web/advisor_web_app.dart`
- EPA officer web dashboard in `lib/epa/epa_app.dart`

## Frontend context

The Flutter app currently uses:
- `lib/models/models.dart` for core domain classes
- `lib/data/mock_data.dart`, `lib/epa/epa_mock_data.dart`, and `lib/web/web_mock_data.dart` for sample data
- `lib/screens/auth/login_screen.dart` and `lib/screens/auth/register_screen.dart` for mock auth flow
- no dedicated state management package yet

## Frontend model mapping

The backend should align to these frontend mock shapes:
- `Farmer` — farmer profile, location, contact, farm size
- `CropRecommendation` — recommendation with crop name, reason, soil type, season, rainfall, steps, date, status
- `Crop` — crop catalog entry with name, category, description, soil/climate requirements, planting steps, maintenance tips
- `FarmingTip` — published advisory content with category, season, author, and published date
- `ChatMessage` — advisor/farmer chat messages
- `Advisor` — advisor profile and rating metadata
- `AppNotification` — notifications delivered to farmers
- `EpaOfficer`, `ExtensionWorker`, `OutbreakSignal`, `FarmerReport`, `EpaNotification`, `ResponseAction` — EPA/dashboard domain models
- `AdvisorProfile`, `WebFarmer`, `SeasonalNotice`, `FarmRecord` — dashboard/admin mock models

## Backend goal

Build a Laravel REST API with:
- normalized relational models
- UUID primary keys and UTC timestamps
- role-based access (`farmer`, `advisor`, `epa`, `admin`)
- Laravel Sanctum authentication
- Spatie Permission role enforcement
- server-side AI integration via an external paid API key

## Required entities

Minimum backend models:
- User (`role`: farmer | advisor | epa | admin)
- FarmerProfile
- AdvisorProfile
- EpaProfile
- Farm
- FarmRecord / SoilTest
- Crop
- CropRecommendation
- FarmingTip / SeasonalNotice
- Conversation
- ChatMessage
- Notification
- OutbreakSignal
- FarmerReport
- ResponseAction
- AuditLog

## Data model relationships

### User
- hasOne FarmerProfile
- hasOne AdvisorProfile
- hasOne EpaProfile
- hasMany ChatMessages
- hasMany Notifications

### FarmerProfile
- belongsTo User
- hasMany Farms
- hasMany CropRecommendations
- hasMany FarmerReports

### AdvisorProfile
- belongsTo User
- hasMany CropRecommendations
- hasMany FarmingTips

### EpaProfile
- belongsTo User
- hasMany OutbreakSignals
- hasMany ResponseActions

### Farm
- belongsTo FarmerProfile
- hasMany FarmRecords
- hasMany CropRecommendations

### FarmRecord
- belongsTo Farm
- belongsTo FarmerProfile

### CropRecommendation
- belongsTo FarmerProfile
- belongsTo Farm
- belongsTo Crop (nullable)
- belongsTo AdvisorProfile

### Conversation
- belongsToMany Users
- hasMany ChatMessages

### ChatMessage
- belongsTo Conversation
- belongsTo User

### OutbreakSignal
- belongsTo User (reporter)
- belongsTo(User, 'verified_by') optional
- hasMany ResponseActions

### ResponseAction
- belongsTo OutbreakSignal
- belongsTo User

## API contract

This is the endpoint structure the frontend expects. Backend developers should validate these routes with frontend integration.

### Auth
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/logout`

### Farmer
- `GET /api/v1/farmer/profile`
- `PUT /api/v1/farmer/profile`
- `GET /api/v1/farmer/farms`
- `POST /api/v1/farmer/farms`
- `PUT /api/v1/farmer/farms/{farm}`
- `DELETE /api/v1/farmer/farms/{farm}`
- `GET /api/v1/farmer/recommendations`
- `GET /api/v1/farmer/recommendations/{recommendation}`
- `GET /api/v1/farmer/tips`
- `GET /api/v1/farmer/conversations`
- `GET /api/v1/farmer/conversations/{conversation}/messages`
- `POST /api/v1/farmer/conversations/{conversation}/messages`
- `GET /api/v1/farmer/notifications`
- `POST /api/v1/farmer/notifications/{notification}/read`

### Advisor
- `GET /api/v1/advisor/dashboard`
- `GET /api/v1/advisor/farmers`
- `GET /api/v1/advisor/farmers/{farmer}`
- `GET /api/v1/advisor/recommendations`
- `POST /api/v1/advisor/recommendations`
- `PUT /api/v1/advisor/recommendations/{recommendation}`
- `GET /api/v1/advisor/recommendations/{recommendation}`
- `GET /api/v1/advisor/crops`
- `POST /api/v1/advisor/crops`
- `PUT /api/v1/advisor/crops/{crop}`
- `GET /api/v1/advisor/tips`
- `POST /api/v1/advisor/tips`
- `PUT /api/v1/advisor/tips/{tip}`
- `DELETE /api/v1/advisor/tips/{tip}`
- `GET /api/v1/advisor/outbreaks`
- `POST /api/v1/advisor/outbreaks`
- `GET /api/v1/advisor/outbreaks/{outbreak}`
- `POST /api/v1/advisor/notifications/broadcast`

### EPA
- `GET /api/v1/epa/dashboard`
- `GET /api/v1/epa/users`
- `PUT /api/v1/epa/users/{user}/status`
- `PUT /api/v1/epa/users/{user}/role`
- `GET /api/v1/epa/reports`
- `GET /api/v1/epa/reports/{report}`
- `GET /api/v1/epa/outbreaks`
- `GET /api/v1/epa/outbreaks/{outbreak}`
- `POST /api/v1/epa/outbreaks/{outbreak}/validate`
- `GET /api/v1/epa/activity`
- `POST /api/v1/epa/notifications/broadcast`

## Controller logic examples

### AuthController
```php
public function register(RegisterFarmerRequest $request)
{
    $user = User::create($request->validated());
    $user->assignRole('farmer');
    FarmerProfile::create([...
        'user_id' => $user->id,
        ...
    ]);
    $token = $user->createToken('api-token')->plainTextToken;
    return response()->json(['user' => $user, 'token' => $token]);
}

public function login(LoginRequest $request)
{
    if (!Auth::attempt($request->validated())) {
        return response()->json(['message' => 'Invalid credentials'], 401);
    }
    $user = Auth::user();
    $token = $user->createToken('api-token')->plainTextToken;
    return response()->json(['user' => $user, 'token' => $token]);
}
```

### Farmer FarmController
```php
public function store(StoreFarmRequest $request)
{
    $farm = auth()->user()->farmerProfile->farms()->create($request->validated());
    return response()->json($farm, 201);
}

public function update(StoreFarmRequest $request, Farm $farm)
{
    $this->authorize('update', $farm);
    $farm->update($request->validated());
    return response()->json($farm);
}
```

### Advisor RecommendationController
```php
public function store(StoreRecommendationRequest $request)
{
    $advisor = auth()->user();
    $payload = $request->validated();
    $recommendation = CropRecommendation::create([...]);
    GenerateRecommendationJob::dispatch($recommendation->id, $payload);
    return response()->json($recommendation, 201);
}

public function show(CropRecommendation $recommendation)
{
    $this->authorize('view', $recommendation);
    return response()->json($recommendation);
}
```

### AiEngineService
```php
public function generateRecommendation(array $payload): array
{
    $response = Http::withToken(config('services.ai.key'))
        ->post(config('services.ai.endpoint'), [
            'model' => config('services.ai.model'),
            'input' => $this->buildPrompt($payload),
        ]);

    return [
        'crop_name' => data_get($response, 'choices.0.message.content.crop_name'),
        'reason' => data_get($response, 'choices.0.message.content.reason'),
        'steps' => data_get($response, 'choices.0.message.content.steps'),
    ];
}
```

## Example payloads

### Register
```json
{
  "name": "Austin Libwathi",
  "email": "austin.libwathi@farm.mw",
  "phone": "+233245678901",
  "password": "password123",
  "role": "farmer",
  "location": "Kumasi, Ashanti",
  "farm_size_acres": 12
}
```

### Create farm record
```json
{
  "name": "Kumasi Farm",
  "location_text": "Kumasi, Ashanti",
  "lat": 6.6885,
  "lng": -1.6244,
  "size_acres": 12,
  "soil_type": "Loamy",
  "soil_ph": 6.5,
  "nitrogen": "Medium",
  "phosphorus": "High",
  "potassium": "Medium",
  "rainfall": "850mm",
  "temperature": "27°C"
}
```

### Generate recommendation
```json
{
  "farm_id": "uuid",
  "advisor_id": "uuid",
  "soil_type": "Loamy",
  "season": "Major Rainy Season",
  "rainfall": "800mm",
  "temperature": "27°C",
  "current_crops": ["Maize"],
  "notes": "Farmer wants to plant tomatoes next season"
}
```

## Notes
- Keep the AI key secret and use the backend to call the external AI provider.
- Use FormRequest classes for validation and policies for authorization.
- Use Sanctum for API token authentication.
- Use Spatie roles/permissions for route access.
- Map frontend mock models directly to backend entities, and ensure responses include the fields the mobile/web apps expect.

## Purpose of this brief

This file is the shared API contract and implementation checklist the backend team should use to verify they are on the same page with the front-end.
