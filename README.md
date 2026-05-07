# SWS Document Manager

A mobile document management app built with Flutter + FastAPI.

## Backend Setup
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Mobile Setup
```bash
cd mobile/sws_mobile
flutter pub get
flutter run
```

## Environment
- Change `baseUrl` in `lib/api/api_service.dart` to your machine's IP for physical devices.
- Android emulator: use `10.0.2.2:8000`

## Features
- ✅ File upload (single & bulk) with per-file progress
- ✅ Bulk upload banner for 4+ files
- ✅ Real-time WebSocket notifications
- ✅ Notification center with unread badge
- ✅ Document library with delete
