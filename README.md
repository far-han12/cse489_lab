# Bangladesh Landmarks
## 📱 Download Demo
You can download the latest compiled APK to test the application on your Android device:

[**⬇️ Download Bangladesh Landmarks APK **](https://drive.google.com/file/d/14cG7vRzx-KqtlGwThRfxpDnW3L3n6kEK/view?usp=sharing)

## App Summary
**Bangladesh Landmarks** is a Flutter-based Android application designed to manage and visualize geographical landmark records. The app communicates with a remote REST service to fetch, create, update, and delete landmark data. It features a modern tabbed interface that allows users to view landmarks on an interactive Google Map, browse them in a list format, and add new entries with automatic GPS detection and image handling.

The application includes robust offline capabilities, caching data locally using SQLite, and is secured via Google Authentication, ensuring only verified users can access the dashboard.

## Feature List

### 🔐 Authentication & Security (Bonus Part)
* **Google Sign-In:** Secure, one-tap login using Firebase Authentication.
* **Auth Gate:** The app automatically directs users to the Login screen if they are signed out and protects the main dashboard from unauthorized access.
* **Persistent Session:** Users remain logged in across app restarts until they explicitly log out.

### 🗺️ Map & Visualization
* **Interactive Map:** Google Maps integration centered on Bangladesh (23.6850°N, 90.3563°E).
* **Custom Markers:** Landmarks appear as color-coded markers (hues generated dynamically based on ID).
* **Dark Mode Support:** Includes a custom night-mode map style and a global app theme toggle (Light/Dark).

### 📍 Landmark Management
* **CRUD Operations:** Full support to **C**reate, **R**ead, **U**pdate, and **D**elete landmarks.
* **Auto-GPS Detection:** Automatically detects and fills the user's current Latitude and Longitude when creating a new entry.
* **Image Optimization:** Automatically resizes selected images to **800x600** resolution before uploading to ensure fast performance and server compliance.

### 💾 Offline Support (Bonus Part)
* **Local Caching:** Uses `sqflite` to store fetched landmarks locally.
* **Offline Mode:** Automatically falls back to the local database if the network request fails, displaying a banner to indicate offline status.

## Setup Instructions

1.  **Prerequisites**
    * Flutter SDK installed (Version 3.0.0 or higher recommended).
    * Android Studio or VS Code configured for Flutter development.
    * An active internet connection for the initial data fetch.

2.  **Firebase Configuration (Critical Step)**
    * **Register App:** Create a project in the [Firebase Console](https://console.firebase.google.com/) and register an Android app using the package name (e.g., `com.example.lab_mid`).
    * **SHA-1 Key:** You **must** generate your machine's SHA-1 key (run `gradlew signingReport` in the `android` folder) and add it to the Firebase Project Settings. Without this, Google Sign-In will fail.
    * **Config File:** Download the `google-services.json` file from Firebase and place it in:
        `android/app/google-services.json`

3.  **Installation**
    * Extract the project files to your local machine.
    * Open the project folder in your terminal or IDE.
    * Install dependencies:
        ```bash
        flutter pub get
        ```

4.  **Google Maps Configuration (Secure Key)**
    * Open the `local.properties` file located in the `android/` directory.
    * Add your Google Maps API Key in the following format:
        ```properties
        GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE
        ```
    * The app is configured to automatically inject this key into the `AndroidManifest.xml` during the build process.

5.  **Running the App**
    * Connect an Android device or start an emulator.
    * Run the command:
        ```bash
        flutter run
        ```

## Known Limitations

* **Image Updates via API:** Due to backend limitations with standard `PUT` requests for multipart data, updating a landmark *with a new image* is handled by creating a new entry and deleting the old one automatically.
* **Offline Mode is Read-Only:** While users can view cached landmarks offline, creating, updating, or deleting records requires an active internet connection.
* **Google Login:** Authentication requires an active internet connection; users cannot sign in while offline.
* **Map Markers:** If a large number of landmarks are loaded, map rendering performance may vary depending on the device's hardware.
