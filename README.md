# 📖 sound-make-book نسخه ۲.۰.۵ (طلایی)

**تبدیل هوشمند متن به کتاب صوتی با قابلیت تقلید صدای شخص – بدون نیاز به اینترنت**

[![GitHub release](https://img.shields.io/github/v/release/tetrashop/sound-make-book)](https://github.com/tetrashop/sound-make-book/releases)
[![Android](https://img.shields.io/badge/Android-APK-green)](https://github.com/tetrashop/sound-make-book/releases)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

---

## 🧩 نیازمندی‌های هر قسمت

### ۱. Backend (سرور Node.js)
- **Node.js** ≥ 18.x
- **npm** یا **yarn**
- **eSpeak-ng** (برای سنتز صدای آفلاین در سمت سرور) – نصب:
  - لینوکس: `sudo apt install espeak-ng`
  - Termux (اندروید): `pkg install espeak-ng`
  - macOS: `brew install espeak-ng`
  - Windows: از [espeak-ng.org](https://espeak-ng.org) دانلود کنید
- **اختیاری**: `sox` برای تحلیل Pitch (تقلید صدا) – نصب: `pkg install sox` (Termux) یا `apt install sox`
- **اختیاری**: `ffmpeg` برای تبدیل فرمت صوتی

> ✅ اگر `espeak-ng` نصب نباشد، برنامه به‌طور خودکار از **Web Speech API** مرورگر استفاده می‌کند (فقط در نسخه وب).

### ۲. Frontend (رابط کاربری وب – public/)
- **هر مرورگر مدرن** (Chrome، Firefox، Edge، Safari)
- **اتصال به سرور محلی** (یا فایل استاتیک)
- **ساپورت Web Speech API** (برای تبدیل متن به گفتار مستقیم در مرورگر)
- **فعال بودن موتور TTS فارسی** در سیستم‌عامل (مثلاً Google Text-to-Speech روی اندروید)

### ۳. اپلیکیشن اندروید (android-app/)
- **Android Studio** (یا خط فرمان با Gradle)
- **Java JDK** 11 یا 17
- **Android SDK** (minSdk 26, targetSdk 34)
- **Gradle** (wrapper همراه پروژه است)
- **فایل keystore** برای ساخت نسخه Release (اختیاری)

### ۴. تقلید صدای شخص (Voice Cloning)
- **سخت‌افزار**: میکروفون برای ضبط نمونه صدا
- **نرم‌افزار**:
  - در نسخه وب: مرورگر با پشتیبانی از `MediaRecorder` (تشخیص خودکار)
  - در نسخه آفلاین سمت سرور: نیاز به `sox` برای استخراج ویژگی‌های صدا
- ذخیره‌سازی: `localStorage` (وب) یا فایل JSON (سرور)

---

## 📦 نصب و اجرا

### 🐧 Termux (اندروید) – اجرای سرور کامل
```bash
pkg update && pkg upgrade -y
pkg install nodejs git espeak-ng sox   # sox اختیاری
git clone https://github.com/tetrashop/sound-make-book.git
cd sound-make-book
npm install
node simple-server.cjs
# سپس در مرورگر localhost:3000 را باز کنید
```

🌐 اجرای فقط Frontend (بدون سرور Node)

فایل public/index.html را مستقیماً در مرورگر باز کنید.

Web Speech API بدون نیاز به بک‌اند کار می‌کند.

🐳 Docker

```bash
docker build -t sound-make-book .
docker run -d -p 3000:3000 sound-make-book
```

📱 ساخت APK اندروید

1. پوشه android-app را در Android Studio باز کنید.
2. Build > Build Bundle(s) / APK > Build APK.
3. فایل app-debug.apk در android-app/app/build/outputs/apk/debug/ قرار می‌گیرد.

---

🧪 تست عملکرد

· متن ساده: یک جمله فارسی بنویسید و دکمه «پیش‌نمایش» را بزنید. صدا باید پخش شود.
· سرعت و زیروبمی: اسلایدرها را تغییر دهید و دوباره تست کنید.
· پروژه: نام و متن را ذخیره کنید، سپس بارگذاری کنید.
· تقلید صدا: یک فایل صوتی کوتاه (۳-۱۰ ثانیه) آپلود کنید و «تولید با صدای شخص» را امتحان کنید.

---

⚠️ عیب‌یابی سریع

مشکل راه‌حل
EADDRINUSE: port 3000 already in use pkill -9 node یا سرور را روی پورت دیگر اجرا کنید
Cannot find module '...' npm install را دوباره اجرا کنید
در Termux خطای SSL connection failed termux-change-repo و انتخاب mirror (مثلاً清华)
صدا پخش نمی‌شود (مرورگر) تنظیمات موتور TTS گوشی را بررسی کنید (Google Text-to-Speech)
espeak-ng: command not found طبق نیازمندی‌ها نصب کنید – یا از Web Speech API استفاده کنید

---

📂 ساختار پروژه (نسخه 2.0.5)

```
sound-make-book/
├── android-app/          # کد اندروید (Android Studio)
├── api/                  # ماژول‌های سرور (مستقل)
├── public/               # فایل‌های استاتیک وب (HTML/CSS/JS)
│   ├── index.html
│   ├── styles/main.css
│   └── scripts/main.js
├── audio-cache/          # کش فایل‌های صوتی تولید شده
├── data/                 # پروفایل‌های صدا و تنظیمات
├── projects/             # پروژه‌های ذخیره شده (JSON)
├── simple-server.cjs     # سرور ساده (بدون وابستگی اضافی)
├── server-fixed.js       # سرور جایگزین (فقط فایل‌های استاتیک)
├── package.json          # وابستگی‌های Node.js
├── Dockerfile
└── vercel.json
```

---

📜 تاریخچه نسخه‌ها

· v2.0.5 (طلایی) – بهبود رابط کاربری، رفع باگ‌ها، پشتیبانی از Web Speech API به عنوان fallback
· v2.0.4 – تقلید صدای شخص (Voice Cloning) با تحلیل Pitch
· v2.0.3 – پنج نوع صدای متنوع (معمولی، بم، زیر، سریع، آهسته)
· v2.0.0 – صف تولید هوشمند، API تولید انبوه، CLI

---

📜 لایسنس

MIT License – استفاده آزاد با ذکر نام نویسنده

توسعه‌دهنده: رامین اجلال (@tetrashop)

آخرین بروزرسانی: اردیبهشت ۱۴۰۴ | نسخه 2.0.5

