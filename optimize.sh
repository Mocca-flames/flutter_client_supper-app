#!/bin/bash

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    case $color in
        "green") echo -e "\033[1;32m$message\033[0m" ;;
        "red") echo -e "\033[1;31m$message\033[0m" ;;
        *) echo -e "$message" ;;
    esac
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_message "red" "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Check if in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    print_message "red" "❌ Not in a Flutter project directory. Run this script inside your Flutter project."
    exit 1
fi

print_message "green" "🚀 Starting Flutter Android Optimization..."

# Step 1: Remove non-Android platform folders
print_message "green" "🗑️ Removing iOS, Web, macOS, Linux, and Windows folders..."
rm -rf ios/ web/ macos/ linux/ windows/ 2> /dev/null

# Step 2: Update pubspec.yaml to target Android only
print_message "green" "📝 Updating pubspec.yaml for Android-only..."
if ! grep -q "platforms:" pubspec.yaml; then
    echo -e "\nflutter:\n  platforms:\n    android:" >> pubspec.yaml
else
    sed -i '/flutter:/,/^[^ ]/ s/platforms:.*/platforms:\n    android:/' pubspec.yaml
fi

# Step 3: Optimize Android build.gradle
print_message "green" "⚙️ Optimizing android/app/build.gradle..."
GRADLE_FILE="android/app/build.gradle"

if [ -f "$GRADLE_FILE" ]; then
    # Enable ProGuard/R8 and shrink resources
    sed -i '/buildTypes {/,/}/ s/minifyEnabled false/minifyEnabled true/' "$GRADLE_FILE"
    sed -i '/buildTypes {/,/}/ s/shrinkResources false/shrinkResources true/' "$GRADLE_FILE"

    # Set modern Android SDK versions
    sed -i 's/compileSdkVersion [0-9]*/compileSdkVersion 34/' "$GRADLE_FILE"
    sed -i 's/minSdkVersion [0-9]*/minSdkVersion 21/' "$GRADLE_FILE"
    sed -i 's/targetSdkVersion [0-9]*/targetSdkVersion 34/' "$GRADLE_FILE"

    # Enable multiDex if not already set
    if ! grep -q "multiDexEnabled true" "$GRADLE_FILE"; then
        sed -i '/defaultConfig {/a \        multiDexEnabled true' "$GRADLE_FILE"
    fi
else
    print_message "red" "⚠️ android/app/build.gradle not found. Skipping..."
fi

# Step 4: Clean and rebuild
print_message "green" "🧹 Cleaning Flutter project..."
flutter clean

print_message "green" "🔧 Running flutter pub get..."
flutter pub get

print_message "green" "✅ Optimization complete! Your Flutter project is now Android-only optimized."

# Suggest next steps
echo -e "\n\033[1;33mNext steps:\033[0m"
echo "1. Test your app on an Android device/emulator:"
echo "   \033[1;36mflutter run --release\033[0m"
echo "2. Build an optimized APK:"
echo "   \033[1;36mflutter build apk --release --split-per-abi\033[0m"
echo "3. (Optional) Generate an App Bundle:"
echo "   \033[1;36mflutter build appbundle\033[0m"