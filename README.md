# **Vitalia: A Healthcare Management System**

**Vitalia** is a comprehensive healthcare management application built using Flutter. The app allows users to:

- Locate nearby hospitals and specialists.
- Book, reschedule, and cancel appointments with healthcare providers.
- Find pharmacies, order medicines, and track deliveries.
- Locate diagnostic centers and book medical tests.
- Store and manage health records securely.
- Interact with an AI medical chatbot, **VitalAI**, powered by **Gemini**.

---

## **Features**

- **Hospital and Specialist Locator**: Search and find nearby hospitals and specialists using the **Google Maps API**, with ratings and distance details.
- **Appointment Scheduling**: Book, reschedule, and cancel appointments using **Firebase**.
- **Pharmacy Locator & Medicine Ordering**: Find nearby pharmacies, order medicines, and track the delivery process.
- **Diagnostic Center Finder**: Locate diagnostic centers and schedule tests.
- **Health Record Management**: Access, update, and securely store health records using the **Google Healthcare API**.
- **AI Chatbot - VitalAI**: Interact with **VitalAI**, an AI-powered medical chatbot built using **Gemini**, to get medical advice and information.
- **Prescription and Bill Tracking**: Upload prescriptions and bills to keep track of them and manage your health records.

---

## **Getting Started**

Follow the steps below to set up and run the **Vitalia** app on your local machine.

### **Prerequisites**

Make sure you have the following installed:

1. **Flutter**: Install Flutter by following the official guide [here](https://docs.flutter.dev/get-started/install).
2. **Android Studio** (or Xcode for macOS users): For emulating Android or iOS devices.
3. **Firebase**: Set up Firebase for user authentication and storing appointments. Follow this [guide](https://firebase.flutter.dev/docs/overview) for integrating Firebase with Flutter.

### **Clone the Repository**

Clone the **Vitalia** repository to your local machine:

```bash
git clone https://github.com/username/vitalia.git
```
## **Navigate to Project Directory**
Navigate into the project directory:
```bash
cd Vitalia
```
### **Install Dependencies**
Run the following command to install all required Flutter dependencies:
```bash
flutter pub get
```
### **Set Up Firebase**

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new Firebase project.
2. Add Firebase to your Flutter app:
   - **For Android**: Download the `google-services.json` file and place it in the `android/app` directory.
   - **For iOS**: Download the `GoogleService-Info.plist` file and place it in the `ios/Runner` directory.
3. Enable **Firebase Authentication** and **Firestore** in the Firebase Console.

### **Configure APIs**

#### **Google Maps API**

1. Enable the **Google Maps API** and **Places API** from the [Google Cloud Console](https://console.cloud.google.com/).
2. Add the API key:
   - **For Android**: Add the API key to the `AndroidManifest.xml` file.
   - **For iOS**: Add the API key to the `Info.plist` file.

#### **Google Healthcare API**

1. Enable the **Google Healthcare API** from the [Google Cloud Console](https://console.cloud.google.com/).
2. Use the API key to configure health data storage and retrieval.

### **Set Up Android Virtual Device (AVD)**

To run your Flutter app on an emulator, you'll need to set up an Android Virtual Device (AVD). Follow these steps:

1. **Install Android Studio**: Make sure you have **Android Studio** installed. If not, you can download it from the official [Android Studio website](https://developer.android.com/studio).

2. **Open Android Studio**: After installation, open **Android Studio**.

3. **Open AVD Manager**:
   - From the **Welcome Screen**, click on **Configure** at the bottom right and then select **AVD Manager**.
   - If you're inside a project, click on **Tools** in the top menu bar and then select **AVD Manager**.

4. **Create a New Virtual Device**:
   - Click **Create Virtual Device**.
   - Select a hardware profile (e.g., Pixel 4) and click **Next**.

5. **Select a System Image**:
   - Choose the system image you want to use (e.g., a version of Android like Pie, Oreo, etc.).
   - If the system image is not downloaded yet, click the **Download** button next to it.
   - Click **Next** once the system image is downloaded.

6. **Configure AVD**:
   - Set the AVD's name, and choose the **Orientation** and **Scale** options.
   - Click **Finish** once the configuration is done.

7. **Run the AVD**:
   - Once the AVD is created, you will see it in the AVD Manager.
   - Click on the **Play** button next to the AVD to launch the emulator.

## **Run Flutter App**
- Once the emulator is running, go back to your terminal or Android Studio and use the following command to run your Flutter app:

   ```bash
   flutter run
   ```

### **Demo Video**

Watch the demo video of the **Vitalia** app on YouTube:  
[Vitalia Demo Video](https://youtu.be/JjiYOb3D-3A)

## **APK Download**

If you want to install the app directly on your Android device, you can download the APK from the following link:

- [Download Vitalia APK](https://storage.googleapis.com/vitalia1/app-release.apk)

Follow the **Installation Instructions** to install the APK.

---

## **Installation Instructions**

To install the app on your Android device:

### **Enable Installation from Unknown Sources**:
1. Open your device's **Settings**.
2. Go to **Security** or **Privacy** and enable **Install from Unknown Sources**.

### **Download the APK**:
1. Click the link above to download the APK file.

### **Install the APK**:
1. Open the **Downloads** folder and tap the `vitalia-app-release.apk` file.
2. Follow the on-screen instructions to install the app.

### **Launch the App**:
1. Once the installation is complete, you can find the app in your device's app drawer.






