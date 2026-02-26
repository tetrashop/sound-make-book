# 📥 راهنمای نصب بسته صوتی فارسی برای sound-make-book (پیشرفته)

این راهنما برای کاربرانی است که با **Termux** آشنایی دارند و می‌خواهند بسته صوتی فارسی را به‌صورت دستی نصب کنند. اگر به دنبال روش ساده‌تری هستید، به [README.md](README.md) مراجعه کنید.

## ✅ مراحل نصب

### ۱. دانلود بسته صوتی
آخرین نسخه بسته را از مخزن زیر دانلود کنید:
[https://github.com/tetrashop/tts-persian-packages/releases/latest](https://github.com/tetrashop/tts-persian-packages/releases/latest)

### ۲. انتقال به Termux
فایل دانلود شده (معمولاً `espeak-persian-data.tar.gz`) را در پوشه `~/downloads` گوشی قرار دهید. سپس در Termux:

```bash
cd ~/downloads
ls -la   # مطمئن شوید فایل وجود دارد
```

۳. کپی به خانه و استخراج

```bash
# اگر فایل با نام ساده است
cp espeak-persian-data.tar.gz ~/

# اگر فایل شامل پرانتز یا فاصله است (مثلاً "espeak-persian-data (1).tar.gz")
cp "espeak-persian-data (1).tar.gz" ~/espeak-persian-data.tar.gz

cd ~
tar -xzf espeak-persian-data.tar.gz
```

۴. بررسی محتویات

```bash
ls -la | grep -E 'espeak-ng-data|voices'
```

۵. کپی به مسیر اصلی

```bash
# اگر پوشه espeak-ng-data وجود دارد
if [ -d "espeak-ng-data" ]; then
    cp -r espeak-ng-data/* $PREFIX/share/espeak-ng-data/
fi

# اگر پوشه voices وجود دارد
if [ -d "voices" ]; then
    cp -r voices/* $PREFIX/share/espeak-ng-data/voices/ 2>/dev/null
fi
```

۶. تست نهایی

```bash
espeak -v fa "سلام، این یک تست است"
```

اگر صدا شنیدید، نصب موفق بوده است.

🐛 رفع مشکلات

· اگر فایل استخراج نشد، از دستور tar -tzf espeak-persian-data.tar.gz برای دیدن محتویات استفاده کنید.
· اگر مسیر $PREFIX/share/espeak-ng-data/voices/ وجود ندارد، ابتدا آن را ایجاد کنید: mkdir -p $PREFIX/share/espeak-ng-data/voices/.

---

توسعه‌دهنده: رامین اجلال (@tetrashop)
