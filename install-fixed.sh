#!/bin/bash
echo "🔧 تنظیم mirror مخازن (USTC)..."
echo "deb https://mirrors.ustc.edu.cn/termux/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list
pkg update -y && pkg upgrade -y

echo "📦 نصب بسته‌های سیستمی..."
pkg install -y nodejs git espeak ffmpeg sox termux-tools procps lsof

echo "📚 نصب وابستگی‌های Node.js..."
cd ~/sound-make-book
npm install express cors multer franc tesseract.js axios nodemon @types/node json

echo "✅ تمام! اکنون سرور را با node api/index.js اجرا کنید."
