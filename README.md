
# Ruwa (رُوى)

Ruwa is an Arabic Android application developed as a graduation project at King Saud University. It supports the selection of ornamental plants for outdoor home gardens in Riyadh. This repository contains the Flutter application and supporting services developed during the project.

## Prerequisites

- Flutter SDK with Dart 3.13 or later, Android Studio, and an Android emulator or device.
- Access to the project's Firebase configuration (Authentication, Cloud Firestore, and App Check).
- A Perenual API key for plant-information features.
- Python 3 and pip to run the FastAPI backend.
- Node.js 24, npm, and Firebase CLI for installing or deploying Firebase Cloud Functions.

## Setup and Run — Flutter

1. Clone the repository:

   ```bash
   git clone https://github.com/AmaniOun/2026-GP1-20.git
   cd 2026-GP1-20
   ```

2. Ensure that the Firebase project configuration is valid and that the Android emulator or device is authorized to access the project's Firebase services and App Check.

3. Create a file named `perenual.local.json` in the project root with the following content:

   ```json
   {
     "PERENUAL_API_KEY": "sk-l9TN6a047aee2e78317253"
   }
   ```

4. Install the Flutter dependencies:

   ```bash
   flutter pub get
   ```

5. Run the application:

   ```bash
   flutter run --dart-define-from-file=perenual.local.json
   ```

The Geoapify and OpenWeather integrations also require valid API credentials and location permissions where applicable.

## Setup and Run — Python Backend

The Ruwa backend uses Python and FastAPI to support server-side operations.


1. Open a terminal in the backend directory:

   ```bash
   cd Ruwa_Backend
   ```

2. Install the required Python packages:

   ```bash
   python -m pip install fastapi "uvicorn[standard]" pydantic firebase-admin pandas openpyxl
   ```

3. Configure Firebase Admin SDK using an authorized service-account file named `firebase-key.json` in the backend directory. Keep this credential private.

4. Start the backend server:

   ```bash
   python -m uvicorn main:app --reload
   ```

5. Open the following address to verify that the server is running:

   ```
   http://127.0.0.1:8000/
   ```

   API documentation is available at:

   ```
   http://127.0.0.1:8000/docs
   ```

The current Flutter application accesses Firebase directly for its existing garden and plant operations. The separate FastAPI backend is not required to launch the current Flutter application.

### Plant Dataset

The `import_plants.py` script imports plant records from `Ruwa_dataset.xlsx` into Cloud Firestore.

This script is intended for database administration and should not be executed during normal application startup, as it may remove existing plant records that are not included in the spreadsheet.

## Firebase Cloud Functions

The `functions/` directory contains the `translatePlantCare` function, which supports translating plant-care guidance into Arabic.

To install dependencies:

```bash
cd functions
npm install
```

To deploy the functions, configure Firebase CLI with the authorized Firebase project and run the following command from the repository root:

```bash
firebase deploy --only functions
```

Already deployed functions do not need to be redeployed each time the Flutter application starts.

## Project Team

**King Saud University**  
College of Computer and Information Sciences  
Department of Information Technology

### Team Members

- Amani Bin Oun
- Rama Aljoudi
- Leena Almojalli
- Monirah Aljulhum

### Project Supervisor

Dr. Majdah Alshehri
