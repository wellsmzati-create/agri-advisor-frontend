# Laravel Backend Implementation Prompt for AgriAdvisor

You are an expert Laravel backend developer. The goal is to create a complete Laravel backend implementation plan for the existing Flutter prototype in `farmer_app`.

The backend must support:
- Mobile farmer app on Flutter
- Web advisor dashboard in `lib/web/advisor_web_app.dart`
- Web EPA officer dashboard in `lib/epa/epa_app.dart`

This frontend currently uses:
- `lib/models/models.dart` for core domain classes
- `lib/data/mock_data.dart`, `lib/epa/epa_mock_data.dart`, and `lib/web/web_mock_data.dart` for sample data
- `lib/screens/auth/login_screen.dart` and `lib/screens/auth/register_screen.dart` for mock auth flow
- no dedicated state management package is installed yet

## Frontend model context

The backend should align with these frontend mock models and sample records:
- `Farmer` — farmer profile, location, contact, farm size
- `CropRecommendation` — advisor recommendation with crop name, reason, soil type, season, rainfall, steps, date, status
- `Crop` — crop catalog with name, category, description, soil/climate requirements, planting steps, maintenance tips
- `FarmingTip` — published advisory content with category, season, author, published date
- `ChatMessage` — advisor/farmer messages
- `Advisor` — advisor metadata and ratings
- `AppNotification` — notifications for farmers
- `EpaOfficer`, `ExtensionWorker`, `OutbreakSignal`, `FarmerReport`, `EpaNotification`, `ResponseAction` — EPA/dashboard domain models
- `AdvisorProfile`, `WebFarmer`, `SeasonalNotice`, `FarmRecord` — dashboard/admin mock models

The backend schema and APIs should preserve these shapes and allow the mobile app and web dashboards to consume the same core entities.

## Goal

Create a tightened Laravel backend prompt that asks for:
- model definitions and relationships
- migration schemas
- controller classes with actual method logic skeletons
- request validation and policies
- service classes for AI generation and notifications
- API route definitions
- example JSON payloads for core operations
- AI integration flow via an external paid API key

## Architecture notes

Use a single `users` table with role-based access and separate profile tables for farmer/advisor/epa if needed. Use UUID primary keys, UTC timestamps, and Laravel Sanctum authentication. Use Spatie Permission for role/permission enforcement.

## Required backend entities

The backend should include at least these models:
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

## Required controllers and routes

Define controllers under `app/Http/Controllers/Api/V1` grouped by role.

### Auth
- `AuthController`:
  - `register` (create user/farmer profile)
  - `login`
  - `me`
  - `logout`

### Farmer APIs
- `Farmer/ProfileController`:
  - `show`
  - `update`
- `Farmer/FarmController`:
  - `index`
  - `store`
  - `update`
  - `destroy`
- `Farmer/RecommendationController`:
  - `index`
  - `show`
- `Farmer/FarmingTipController`:
  - `index`
  - `show`
- `Farmer/ChatController`:
  - `conversations`
  - `messages`
  - `store`
- `Farmer/NotificationController`:
  - `index`
  - `markRead`
- `Farmer/DashboardController`:
  - `summary`

### Advisor APIs
- `Advisor/DashboardController`:
  - `summary`
- `Advisor/FarmerManagementController`:
  - `index`
  - `show`
- `Advisor/RecommendationController`:
  - `store` (capture farm data + generate AI recommendation)
  - `show`
  - `update` (publish/edit)
  - `history`
- `Advisor/CropManagementController`:
  - `index`
  - `show`
  - `store`
  - `update`
- `Advisor/FarmingTipController`:
  - `index`
  - `store`
  - `update`
  - `destroy`
- `Advisor/OutbreakController`:
  - `store`
  - `index`
  - `show`
- `Advisor/NotificationController`:
  - `broadcast`

### EPA APIs
- `Epa/DashboardController`:
  - `summary`
  - `activityMetrics`
- `Epa/UserManagementController`:
  - `index`
  - `updateStatus`
  - `assignRole`
- `Epa/FarmerReportsController`:
  - `index`
  - `show`
- `Epa/OutbreakController`:
  - `index`
  - `validate`
  - `show`
- `Epa/ActivityLogController`:
  - `index`
- `Epa/NotificationController`:
  - `broadcast`

## Route structure

Use `routes/api.php` with `api/v1` prefix and middleware.

Example:
```php
Route::prefix('v1')->group(function () {
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('auth/me', [AuthController::class, 'me']);
        Route::post('auth/logout', [AuthController::class, 'logout']);

        Route::middleware('role:farmer')->group(function () {
            Route::apiResource('farmer/profile', FarmerProfileController::class)->only(['show', 'update']);
            Route::apiResource('farmer/farms', FarmController::class);
            Route::apiResource('farmer/recommendations', RecommendationController::class)->only(['index', 'show']);
            Route::get('farmer/tips', [FarmingTipController::class, 'index']);
            Route::get('farmer/conversations', [ChatController::class, 'conversations']);
            Route::get('farmer/conversations/{conversation}/messages', [ChatController::class, 'messages']);
            Route::post('farmer/conversations/{conversation}/messages', [ChatController::class, 'store']);
            Route::get('farmer/notifications', [NotificationController::class, 'index']);
        });

        Route::middleware('role:advisor')->group(function () {
            Route::get('advisor/dashboard', [AdvisorDashboardController::class, 'summary']);
            Route::apiResource('advisor/farmers', FarmerManagementController::class)->only(['index', 'show']);
            Route::apiResource('advisor/recommendations', RecommendationController::class);
            Route::apiResource('advisor/crops', CropManagementController::class);
            Route::apiResource('advisor/tips', FarmingTipController::class);
            Route::apiResource('advisor/outbreaks', OutbreakController::class)->only(['index', 'store', 'show']);
            Route::post('advisor/notifications/broadcast', [NotificationController::class, 'broadcast']);
        });

        Route::middleware('role:epa')->group(function () {
            Route::get('epa/dashboard', [EpaDashboardController::class, 'summary']);
            Route::apiResource('epa/users', UserManagementController::class)->only(['index', 'update']);
            Route::apiResource('epa/reports', FarmerReportsController::class)->only(['index', 'show']);
            Route::apiResource('epa/outbreaks', OutbreakController::class)->only(['index', 'show']);
            Route::post('epa/outbreaks/{outbreak}/validate', [OutbreakController::class, 'validate']);
            Route::get('epa/activity', [ActivityLogController::class, 'index']);
            Route::post('epa/notifications/broadcast', [NotificationController::class, 'broadcast']);
        });
    });
});
```

## Example controller logic skeletons

### AuthController
```php
public function register(RegisterFarmerRequest $request)
{
    $user = User::create([...]);
    $user->assignRole('farmer');
    FarmerProfile::create([...]);
    $token = $user->createToken('api-token')->plainTextToken;
    return response()->json(['user' => $user, 'token' => $token]);
}

public function login(LoginRequest $request)
{
    $credentials = $request->validated();
    if (!Auth::attempt($credentials)) {
        return response()->json(['message' => 'Invalid credentials'], 401);
    }
    $user = Auth::user();
    $token = $user->createToken('api-token')->plainTextToken;
    return response()->json(['user' => $user, 'token' => $token]);
}
```

### Farmer/FarmController
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

### Advisor/RecommendationController
```php
public function store(StoreRecommendationRequest $request)
{
    $advisor = auth()->user();
    $data = $request->validated();
    $recommendation = CropRecommendation::create([...]);
    GenerateRecommendationJob::dispatch($recommendation->id, $data);
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
            'model' => 'gpt-4.1',
            'input' => $this->buildPrompt($payload),
        ]);
    return [
        'crop_name' => $response['choices'][0]['message']['content']['crop_name'],
        'reason' => $response['choices'][0]['message']['content']['reason'],
        'steps' => $response['choices'][0]['message']['content']['steps'],
    ];
}
```

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

### Farm
- belongsTo FarmerProfile
- hasMany FarmRecords
- hasMany CropRecommendations

### CropRecommendation
- belongsTo FarmerProfile
- belongsTo Farm
- belongsTo Crop (optional)
- belongsTo AdvisorProfile

### ChatConversation
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

## Example JSON payloads

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

## Deliverable instructions

Produce a Laravel backend implementation plan with:
1. model definitions and migration schemas,
2. controller methods with real skeleton logic,
3. route definitions,ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
4. service classes,
5. example payloads,
6. AI integration flow.

This prompt is intended for a backend developer or AI-assisted code generation tool.