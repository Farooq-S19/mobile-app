# 🍅 TomatoXAI - Tomato Leaf Disease Detection

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![TensorFlow Lite](https://img.shields.io/badge/TensorFlow%20Lite-2.0+-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 📱 Overview

TomatoXAI is an AI-powered mobile application for real-time tomato leaf disease detection. Using deep learning and Grad-CAM++ visualization, it helps farmers identify diseases instantly with high accuracy.

### Key Features
- 🔍 **Real-time Disease Detection** - Instant classification of tomato leaf diseases
- 🧠 **Grad-CAM++ Visualization** - Heatmap overlay showing which regions influenced the prediction
- 📱 **Offline Support** - Works without internet connection using TensorFlow Lite
- 📊 **Scan History** - Save and review previous scans
- 📤 **Share Results** - Export analysis results with confidence scores
- 🎯 **10 Disease Classes** including Healthy, Bacterial Spot, Early/Late Blight, Leaf Mold, Septoria, Spider Mites, Target Spot, TMV, and TYLCV

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.0 or higher)
- **Android Studio** / **VS Code** with Flutter extensions
- **Java JDK 11** or higher
- **Android SDK** (API 21+)
- **Git**

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/tomatoXAI.git
cd tomatoXAI
Get dependencies

bash
flutter pub get
Download the model (if not included in repository)

bash
# Create models directory
mkdir -p assets/models

# Place your model.tflite file at: assets/models/model.tflite
Run the app

bash
# For debugging
flutter run

# Build APK
flutter build apk --release
📱 Installing APK
The APK will be located at:

text
build/app/outputs/flutter-apk/app-release.apk
🧠 Model Information
Architecture
Base Model: EfficientNet-B0

Custom Model: TomatoXNet

Input Size: 224x224 pixels

Normalization: ImageNet (mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225])

Output Classes: 10

Disease Classes
Disease Name	Severity
Healthy	-
Bacterial Spot	Moderate
Early Blight	Moderate
Late Blight	Dangerous
Leaf Mold	Mild
Septoria Leaf Spot	Moderate
Spider Mites	Mild
Target Spot	Moderate
Tomato Mosaic Virus	Moderate
Tomato Yellow Leaf Curl Virus	Dangerous
👨‍💻 Development Team
Name	Role	Responsibilities
S. Krishna Vamsi	Deep Learning & ML Engineer	Designing and implementing Deep Learning and Machine Learning models
R. Oshma	Mobile Application Developer	Developing and managing Mobile Application interface and integration
P. Charan Sai	Web & Backend Developer	Designing and implementing Web Application and backend functionalities
🛠️ Technologies Used
Category	Technologies
Frontend	Flutter, Dart, Lucide Icons, Google Fonts
ML/AI	TensorFlow Lite, PyTorch, EfficientNet-B0, Grad-CAM++
Storage	Shared Preferences
Image Processing	image_picker, camera, image
Utilities	uuid, share_plus, path_provider, permission_handler
📁 Project Structure
text
tomatoXAI/
├── lib/
│   ├── models/          # Data models
│   ├── screens/         # UI screens
│   ├── services/        # TFLite, Storage services
│   ├── data/            # Disease database
│   ├── widgets/         # Reusable widgets
│   └── core/            # Constants, themes
├── assets/
│   ├── images/          # Disease images
│   └── models/          # TFLite model
├── android/             # Android-specific files
├── ios/                 # iOS-specific files
├── pubspec.yaml         # Dependencies
└── README.md            # This file
🔧 Configuration
Changing App Name
Edit android/app/src/main/AndroidManifest.xml:

xml
android:label="Your App Name"
Changing App Icon
Replace assets/icon/app_icon.png (1024x1024)

Run: flutter pub run flutter_launcher_icons

Modifying Disease Database
Edit lib/data/disease_data.dart to add/modify diseases.

🚢 Deployment
Build APK
bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs by architecture
flutter build apk --split-per-abi
Build App Bundle (Google Play)
bash
flutter build appbundle
🤝 Contributing
Fork the repository

Create your feature branch (git checkout -b feature/AmazingFeature)

Commit changes (git commit -m 'Add AmazingFeature')

Push to branch (git push origin feature/AmazingFeature)

Open a Pull Request

📄 License
This project is licensed under the MIT License.

⚠️ Disclaimer
This app is for educational and research purposes. Always consult with agricultural experts for critical farming decisions.

📊 Performance Metrics
Metric	Value
Accuracy	99.69%
Precision	98.27%
Inference Time	<100ms
🔄 Version History
Version	Date	Changes
1.0.0	Jan 2025	Initial release with 10 disease classes and Grad-CAM++
Made with ❤️ for farmers and agriculture

text

Just copy and paste this entire code into your `README.md` file. Then update:
- `YOUR_USERNAME` with your actual GitHub username
- Add your screenshots if you want
- Add your email if you want

Then run:
```bash
git add README.md
git commit -m "Add README"
git push
