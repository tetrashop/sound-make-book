#!/bin/bash

# رنگ‌ها
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

set -e

echo -e "${GREEN}🚀 آغاز انتشار نسخه اندروید در GitHub...${NC}"

# 1. به‌روزرسانی کدها در GitHub
echo -e "${YELLOW}📦 افزودن تغییرات به Git...${NC}"
git add .
read -p "پیام commit: " commit_msg
git commit -m "$commit_msg" || echo "هیچ تغییری وجود ندارد"
git push origin main

# 2. دریافت آخرین tag
latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
echo -e "${YELLOW}آخرین tag: $latest_tag${NC}"

# 3. تولید نسخه جدید (افزایش patch number)
if [[ $latest_tag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    patch=${BASH_REMATCH[3]}
    new_patch=$((patch + 1))
    new_tag="v$major.$minor.$new_patch"
else
    new_tag="v2.0.1"  # fallback
fi

echo -e "${GREEN}نسخه جدید: $new_tag${NC}"

# 4. ساخت tag و push
git tag "$new_tag"
git push origin "$new_tag"

# 5. بررسی وجود فایل APK
APK_PATH="android-app/app/build/outputs/apk/release/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ فایل APK در مسیر $APK_PATH یافت نشد!${NC}"
    echo "لطفاً ابتدا APK را با دستور زیر بسازید:"
    echo "  cd android-app && ./gradlew assembleRelease"
    exit 1
fi

# 6. انتشار در GitHub Release با استفاده از gh
echo -e "${YELLOW}📡 ایجاد Release در GitHub...${NC}"
gh release create "$new_tag" \
    --title "نسخه اندروید $new_tag" \
    --notes "آخرین به‌روزرسانی خودکار شامل تغییرات commit: $commit_msg" \
    "$APK_PATH"

echo -e "${GREEN}✅ انتشار با موفقیت انجام شد!${NC}"
echo "مشاهده Release: https://github.com/tetrashop/sound-make-book/releases/tag/$new_tag"
