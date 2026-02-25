#!/bin/bash
echo "🔨 شروع ساخت APK اندروید..."
cd android-app
./gradlew clean assembleRelease
cd ..
cp android-app/app/build/outputs/apk/release/app-release.apk sound-make-book-android-latest.apk
echo "✅ APK با موفقیت ساخته شد: sound-make-book-android-latest.apk"
