#!/bin/bash
cat > README.md << 'README_END'
<div dir="rtl" align="right">

# 📖 sound-make-book

**تبدیل هوشمند متن به کتاب صوتی با قابلیت تقلید صدای شخص**

[![GitHub release](https://img.shields.io/github/v/release/tetrashop/sound-make-book)](https://github.com/tetrashop/sound-make-book/releases)
[![Android](https://img.shields.io/badge/Android-APK-green)](https://github.com/tetrashop/sound-make-book/releases)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

---

## چکیده

**sound-make-book** پلتفرمی متن‌باز برای تبدیل متن به گفتار (TTS) بدون نیاز به اینترنت است. با استفاده از موتور eSpeak و معماری صف پردازش هوشمند، امکان تولید کتاب صوتی با کیفیت قابل قبول را فراهم می‌کند.

**قابلیت‌های کلیدی:**
- ✅ آفلاین و بدون نیاز به اینترنت
- ✅ تقلید صدای شخص (Voice Cloning)
- ✅ تولید انبوه کتاب چندبخشی
- ✅ رابط کاربری وب با ۵ تب
- ✅ استقرار روی Termux، Docker، Vercel

---

## تاریخچه نسخه‌ها

### نسخه 1.0 (پایه)
- سرور HTTP ساده با Node.js
- پیش‌نمایش صدا با Web Speech API
- ذخیره پروژه در localStorage

### نسخه 2.0 (طلایی)
- صف تولید هوشمند با EventEmitter
- API تولید انبوه کتاب چندبخشی
- ابزار خط فرمان (CLI)
- گیت‌هاب اکشن برای ساخت APK

### نسخه 2.0.3 (صدای متنوع)
- ۵ نوع صدا (معمولی، بم، زیر، سریع، آهسته)
- تب مجزا «صدای متنوع»

### نسخه 2.0.4 (تقلید صدای شخص)
- تحلیل Pitch نمونه صدا با sox
- آپلود و ذخیره پروفایل صدا
- تولید گفتار با پارامترهای شخصی
- تب «Clone صدا»

---

## خطاها و راه‌حل‌ها

| خطا | راه‌حل |
|-----|--------|
| `EADDRINUSE: پورت 3000 اشغال` | `pkill node` یا `PORT=3001 node api/index.js` |
| `Cannot find module 'cors'` | `npm install cors express` |
| `SSL connection failed` در Termux | `termux-change-repo` و انتخاب mirror چینی |
| `git push: Connection reset` | `git remote set-url origin git@github.com:tetrashop/sound-make-book.git` |

---

## دستاوردهای فنی

1. **صف پردازش هوشمند** - مدیریت درخواست‌های همزمان
2. **تحلیل صوت بدون API** - استخراج Pitch با sox
3. **CI/CD کامل** - ساخت خودکار APK در هر تگ
4. **استقرار چندمنظوره** - Termux، Docker، Vercel

---

## مسیر پیش رو

### کوتاه مدت (۱-۲ ماه)
- تقلید صدای واقعی با XTTS-v2
- تبدیل به PWA
- خروجی M4A/OGG

### میان مدت (۳-۶ ماه)
- ضبط مستقیم صدا در مرورگر
- کتابخانه ۱۰۰+ صدای آماده
- پشتیبانی از عربی، ترکی، کردی

### بلند مدت (۶-۱۲ ماه)
- مدل TTS عصبی فارسی
- همگام‌سازی ابری
- نسخه دسکتاپ Electron

---

## نصب و اجرا

### Termux (اندروید)
```bash
pkg update && pkg install nodejs git espeak
git clone https://github.com/tetrashop/sound-make-book.git
cd sound-make-book
npm install
node api/index.js
# باز کردن http://localhost:3000
```

Docker

```bash
docker build -t sound-make-book .
docker run -d -p 3000:3000 sound-make-book
```

Vercel

```bash
npm i -g vercel
vercel --prod
```

---

API Reference

مسیر متد توضیحات
/api/synthesize POST تبدیل متن به گفتار
/api/bulk-projects POST تولید کتاب چندبخشی
/api/upload-voice-profile POST آپلود نمونه صدا
/api/synthesize-with-profile POST تولید با صدای شخصی
/api/queue-status GET وضعیت صف

---

ساختار پروژه

```
sound-make-book/
├── api/                 # سرور و ماژول‌ها
├── public/              # Frontend (HTML/CSS/JS)
├── android-app/         # کد اندروید
├── audio-cache/         # کش فایل صوتی
├── data/                # پروفایل صدا
├── package.json         # وابستگی‌ها
├── Dockerfile           # Docker
└── vercel.json          # Vercel
```

---

لایسنس

MIT License - استفاده آزاد با ذکر نام نویسنده

توسعه‌دهنده: رامین اجلال (@tetrashop)

آخرین بروزرسانی: اردیبهشت ۱۴۰۴ | نسخه 2.0.4

</div>
README_END
echo "✅ README.md ایجاد شد!"
