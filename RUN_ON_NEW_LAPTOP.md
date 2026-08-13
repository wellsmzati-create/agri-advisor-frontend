# Run On New Laptop

This project is now configured to use this backend URL by default:

`http://10.69.27.128:8000/api/v1`

That is the fastest setup because it uses Laravel's built-in server instead of depending on Laragon Apache virtual hosts.

## 1. Put both projects on the new laptop

- Flutter app: `C:\farmer_app`
- Backend: `C:\laragon\www\agri-advisor-backend`

If you prefer a different backend folder, that is fine. Only the commands need to be run from that backend folder.

## 2. Make sure both devices are on the same Wi-Fi

- New laptop IP: `10.69.27.128`
- Your Android phone must be on the same network

## 3. Backend setup

Open a terminal in the backend folder:

```powershell
cd C:\laragon\www\agri-advisor-backend
```

Install PHP dependencies if needed:

```powershell
composer install
```

## 4. Update backend `.env`

In `C:\laragon\www\agri-advisor-backend\.env`, make sure this line is:

```env
APP_URL=http://10.69.27.128:8000
```

If you are moving your real data from the old laptop, export your MySQL database from the old laptop and import it into the new laptop before logging in.

If you are starting fresh, create the database and run:

```powershell
C:\laragon\bin\php\php-8.4.12-nts-Win32-vs17-x64\php.exe artisan migrate --seed
```

Seeded demo login accounts:

- Advisor: `advisor@agri.local`
- Farmer: `farmer@agri.local`
- Password: `password`

## 5. Clear Laravel config cache

```powershell
C:\laragon\bin\php\php-8.4.12-nts-Win32-vs17-x64\php.exe artisan config:clear
C:\laragon\bin\php\php-8.4.12-nts-Win32-vs17-x64\php.exe artisan cache:clear
```

## 6. Start the backend API

Fastest option:

```powershell
C:\laragon\bin\php\php-8.4.12-nts-Win32-vs17-x64\php.exe artisan serve --host=0.0.0.0 --port=8000
```

Leave that terminal open.

## 7. Start the queue worker

Open a second terminal in the backend folder and run:

```powershell
C:\laragon\bin\php\php-8.4.12-nts-Win32-vs17-x64\php.exe artisan queue:work
```

Leave this terminal open too.

This is required for AI-generated recommendations to move from `pending` to `generated`.

## 8. Run the web dashboard

Open a terminal in the Flutter app folder:

```powershell
cd C:\farmer_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://10.69.27.128:8000/api/v1
```

## 9. Run the Android app on your phone

Connect the Android phone to the same Wi-Fi, then run:

```powershell
cd C:\farmer_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.69.27.128:8000/api/v1
```

If more than one device is connected:

```powershell
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.69.27.128:8000/api/v1
```

## 10. Build an APK

```powershell
cd C:\farmer_app
flutter build apk --release --dart-define=API_BASE_URL=http://10.69.27.128:8000/api/v1
```

The APK will be at:

`C:\farmer_app\build\app\outputs\flutter-apk\app-release.apk`

## 11. If the phone cannot connect

Check these in order:

1. The backend terminal must still be running.
2. The queue worker terminal must still be running.
3. The phone and laptop must be on the same Wi-Fi.
4. Open `http://10.69.27.128:8000` in the phone browser.
5. Allow `php.exe` through Windows Firewall on Private networks.
6. If port `8000` is blocked, allow inbound TCP `8000`.

## 12. Important note

The app now defaults to `http://10.69.27.128:8000/api/v1`, but you can still override it any time with:

```powershell
--dart-define=API_BASE_URL=http://your-ip:8000/api/v1
```

That means if your laptop IP changes again, you usually will not need another code edit.
