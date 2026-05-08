#!/bin/bash

# ============================================================
# git-health-check.sh
# تست سلامت مخزن گیت و تعمیر خودکار
# ============================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔍 بررسی سلامت مخزن گیت - sound-make-book${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"

cd ~/sound-make-book

# ============================================================
# 1. بررسی وجود مخزن گیت
# ============================================================
echo -e "\n${YELLOW}[1/8] بررسی وجود مخزن گیت...${NC}"
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ مخزن گیت وجود ندارد! در حال مقداردهی اولیه...${NC}"
    git init
    git remote add origin https://github.com/tetrashop/sound-make-book.git
    echo -e "${GREEN}✅ مخزن گیت مقداردهی شد.${NC}"
else
    echo -e "${GREEN}✅ مخزن گیت وجود دارد.${NC}"
fi

# ============================================================
# 2. بررسی تنظیمات کاربر
# ============================================================
echo -e "\n${YELLOW}[2/8] بررسی تنظیمات کاربر گیت...${NC}"
if ! git config user.name > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  user.name تنظیم نشده. در حال تنظیم...${NC}"
    git config --global user.name "ramin-edjlal"
fi
if ! git config user.email > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  user.email تنظیم نشده. در حال تنظیم...${NC}"
    git config --global user.email "ramin.edjlal1359@gmail.com"
fi
echo -e "${GREEN}✅ کاربر: $(git config user.name) <$(git config user.email)>${NC}"

# ============================================================
# 3. بررسی وضعیت فایل‌ها
# ============================================================
echo -e "\n${YELLOW}[3/8] بررسی وضعیت فایل‌ها...${NC}"
git status --short

# ============================================================
# 4. بررسی فایل‌های بزرگ و مشکوک
# ============================================================
echo -e "\n${YELLOW}[4/8] بررسی فایل‌های بزرگ (>10MB)...${NC}"
LARGE_FILES=$(find . -type f -size +10M -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./audio-cache/*" 2>/dev/null)
if [ -n "$LARGE_FILES" ]; then
    echo -e "${RED}⚠️  فایل‌های بزرگ زیر در مسیر ریشه هستند:${NC}"
    echo "$LARGE_FILES"
    echo -e "${YELLOW}پیشنهاد: این فایل‌ها را به .gitignore اضافه کنید.${NC}"
else
    echo -e "${GREEN}✅ فایل بزرگ مشکوکی یافت نشد.${NC}"
fi

# ============================================================
# 5. بررسی اتصال به ریموت
# ============================================================
echo -e "\n${YELLOW}[5/8] بررسی اتصال به ریموت...${NC}"
git remote -v
if ! git ls-remote origin HEAD > /dev/null 2>&1; then
    echo -e "${RED}❌ اتصال به ریموت برقرار نیست!${NC}"
    echo -e "${YELLOW}در حال تعمیر remote...${NC}"
    git remote set-url origin https://github.com/tetrashop/sound-make-book.git
    echo -e "${GREEN}✅ remote تنظیم شد.${NC}"
fi

# ============================================================
# 6. بررسی conflict و شاخه‌ها
# ============================================================
echo -e "\n${YELLOW}[6/8] بررسی وضعیت شاخه اصلی...${NC}"
CURRENT_BRANCH=$(git branch --show-current)
echo -e "شاخه فعلی: ${GREEN}$CURRENT_BRANCH${NC}"

if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}⚠️  در شاخه $CURRENT_BRANCH هستید. در حال تغییر به main...${NC}"
    git checkout main 2>/dev/null || git checkout -b main
fi

# ============================================================
# 7. تعمیر خودکار مشکلات رایج
# ============================================================
echo -e "\n${YELLOW}[7/8] تعمیر خودکار مشکلات...${NC}"

# حذف فایل‌های lock
if [ -f ".git/index.lock" ]; then
    echo -e "${YELLOW}🗑️  حذف فایل lock index...${NC}"
    rm -f .git/index.lock
fi

# بازگرداندن فایل‌های خراب index.html و main.js
for file in public/index.html public/scripts/main.js; do
    if [ -f "$file" ] && ! grep -q "sound-make-book" "$file" 2>/dev/null; then
        echo -e "${RED}❌ فایل $file خراب شده است!${NC}"
        echo -e "${YELLOW}در حال بازگردانی از گیت...${NC}"
        git checkout HEAD -- "$file" 2>/dev/null || echo "⚠️  نسخه پشتیبان در گیت وجود ندارد"
    fi
done

# ============================================================
# 8. جمع‌بندی نهایی
# ============================================================
echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ تست سلامت کامل شد!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# نمایش فایل‌هایی که باید اضافه شوند
echo -e "${YELLOW}📁 فایل‌های موجود در مسیر فعلی:${NC}"
ls -la --color=always | head -20

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 راهنمای اقدام مورد نیاز:${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# بررسی فایل‌های کلیدی
MISSING_FILES=()
[ ! -f "README.md" ] && MISSING_FILES+=("README.md")
[ ! -f "api/index.js" ] && MISSING_FILES+=("api/index.js")
[ ! -f "public/index.html" ] && MISSING_FILES+=("public/index.html")

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo -e "${RED}❌ فایل‌های زیر وجود ندارند:${NC}"
    for f in "${MISSING_FILES[@]}"; do
        echo "   - $f"
    done
    echo ""
    echo -e "${YELLOW}🔧 راه‌حل: این فایل‌ها را ایجاد کنید یا از پشتیبان بازیابی کنید.${NC}"
else
    echo -e "${GREEN}✅ تمام فایل‌های کلیدی وجود دارند.${NC}"
fi

# وضعیت گیت
if [ -n "$(git status --short)" ]; then
    echo -e "\n${YELLOW}📝 تغییرات انتظار برای commit:${NC}"
    git status --short
    echo ""
    echo -e "${GREEN}🔧 دستورات پیشنهادی برای ارسال:${NC}"
    echo "   git add ."
    echo "   git commit -m \"پیام شما\""
    echo "   git push origin main"
else
    echo -e "\n${GREEN}✅ هیچ تغییر pending ای وجود ندارد. گیت سالم است.${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}💡 سوال: چه چیزی را کجا بگذارم؟${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}ساختار صحیح فایل‌های پروژه:${NC}"
echo ""
echo "~/sound-make-book/"
echo "├── api/"
echo "│   ├── index.js           ← سرور اصلی Express"
echo "│   ├── advanced-tts.js    ← صف پردازش صدا"
echo "│   └── voice-profiler.js  ← تحلیل صدا برای Clone"
echo "├── public/"
echo "│   ├── index.html         ← صفحه اصلی وب"
echo "│   ├── scripts/"
echo "│   │   └── main.js        ← منطق جاوااسکریپت"
echo "│   └── styles/"
echo "│       └── main.css       ← استایل‌ها"
echo "├── data/"
echo "│   └── voice-profile.json ← پروفایل صدای شخص (اتومات)"
echo "├── audio-cache/           ← فایل‌های صوتی تولید شده (اتومات)"
echo "├── node_modules/          ← وابستگی‌ها (اتومات)"
echo "├── package.json           ← لیست وابستگی‌ها"
echo "├── README.md              ← مستندات پروژه"
echo "└── .gitignore             ← فایل‌های نادیده گرفته شده"
echo ""
echo -e "${YELLOW}اگر فایلی خارج از این ساختار دارید:${NC}"
echo "  - فایل‌های موقت (.tmp, .log) → حذف کنید"
echo "  - فایل‌های بزرگ (>10MB) → به .gitignore اضافه کنید"
echo "  - فایل‌های پشتیبان (.bak, .old) → حذف کنید"
echo ""

# پیشنهاد .gitignore
if [ ! -f ".gitignore" ]; then
    echo -e "${RED}⚠️  فایل .gitignore وجود ندارد! در حال ایجاد...${NC}"
    cat > .gitignore << 'EOF'
node_modules/
audio-cache/
temp_uploads/
data/voice-profile.json
*.log
*.tmp
*.bak
*.old
.DS_Store
.env
android-app/.gradle/
android-app/app/build/
android-app/local.properties
EOF
    echo -e "${GREEN}✅ فایل .gitignore ایجاد شد.${NC}"
fi

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎯 کار بعدی:${NC}"
echo "1. اگر گیت سالم است ← فقط git push origin main بزنید"
echo "2. اگر مشکل داشت ← دستورات بالا را اجرا کنید"
echo "3. برای ایجاد README کامل ← ./generate-complete-readme.sh"
echo ""
