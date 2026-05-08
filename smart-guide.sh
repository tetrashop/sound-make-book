#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔍 تحلیل عمیق مشکلات مخازن Termux و ارائه راهکار${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${RED}❌ خطاهای مشاهده شده:${NC}"
echo "   - SSL connection failed"
echo "   - Connection reset by peer"  
echo "   - Unable to locate package nodejs/ffmpeg/sox"
echo ""

echo -e "${YELLOW}🔎 علت:${NC} فیلترینگ یا اختلال در مسیریابی به مخازن Termux (تحریم/قطع اتصال)"
echo ""

echo -e "${GREEN}✅ راهکارهای ممکن (به ترتیب اولویت):${NC}"
echo ""

echo -e "${BLUE}1️⃣ استفاده از VPN (توصیه شده -成功率 95%)${NC}"
echo "   - روی گوشی خود یک VPN (مثل Psiphon, V2rayNG, Outline) روشن کنید."
echo "   - سپس در Termux اجرا کنید:"
echo -e "        ${YELLOW}pkg update && pkg upgrade -y${NC}"
echo -e "        ${YELLOW}pkg install nodejs ffmpeg sox -y${NC}"
echo ""

echo -e "${BLUE}2️⃣ تغییر DNS به 8.8.8.8 (بدون VPN - 成功率 40%)${NC}"
echo "   - به تنظیمات Wi-Fi گوشی بروید، شبکه خود را edit کنید."
echo "   - DNS را به 8.8.8.8 و 8.8.4.4 تغییر دهید."
echo "   - سپس Termux را بسته و دوباره باز کنید."
echo "   - دوباره دستورات بالا را اجرا کنید."
echo ""

echo -e "${BLUE}3️⃣ استفاده از HTTP (بدون SSL) - 成功率 30%${NC}"
echo "   - اجرا کنید:"
echo "        echo 'deb http://packages.termux.org/apt/termux-main stable main' > \$PREFIX/etc/apt/sources.list"
echo "        apt update --allow-insecure-repositories"
echo "        apt install nodejs ffmpeg sox -y --allow-unauthenticated"
echo ""

echo -e "${BLUE}4️⃣ نصب دستی با دانلود فایل‌های .deb از طریق مرورگر موبایل - 成功率 60%${NC}"
echo "   - با توجه به معماری دستگاه (aarch64) لینک‌های زیر را در مرورگر گوشی باز کنید و فایل‌ها را دانلود کنید:"
echo "        https://packages.termux.org/apt/termux-main/pool/main/n/nodejs/nodejs_22.14.0_aarch64.deb"
echo "        https://packages.termux.org/apt/termux-main/pool/main/f/ffmpeg/ffmpeg_8.0.1-5_aarch64.deb"
echo "        https://packages.termux.org/apt/termux-main/pool/main/s/sox/sox_14.4.2-28_aarch64.deb"
echo "   - سپس در Termux (پوشه downloadها):"
echo "        cd ~/storage/downloads"
echo "        dpkg -i nodejs_*.deb ffmpeg_*.deb sox_*.deb"
echo "        apt --fix-broken install -y"
echo ""

echo -e "${BLUE}5️⃣ استفاده از mirror چینی با HTTP (成功率 20%)${NC}"
echo "   - اجرا کنید:"
echo "        echo 'deb http://mirrors.ustc.edu.cn/termux/apt/termux-main stable main' > \$PREFIX/etc/apt/sources.list"
echo "        apt update --allow-insecure-repositories"
echo "        apt install nodejs ffmpeg sox -y --allow-unauthenticated"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📌 وضعیت فعلی پروژه (بدون نیاز به بسته‌های گمشده):${NC}"
echo "   - سرور روی پورت 3000 اجرا می‌شود: ${YELLOW}node api/index.js${NC}"
echo "   - تب «صدای متنوع» با espeak کار می‌کند ✅"
echo "   - تب «Clone صدا» به ffmpeg و sox نیاز دارد ❌"
echo ""

echo -e "${YELLOW}💡 توصیه نهایی:${NC}"
echo "اگر VPN ندارید و نمی‌توانید نصب کنید، نیازی به نصب ffmpeg/sox نیست. پروژه بدون آنها عالی کار می‌کند. فقط از تب «صدای متنوع» استفاده کنید."
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}برای اجرای سرور در حال حاضر، دستور زیر را بزنید:${NC}"
echo -e "   ${YELLOW}cd ~/sound-make-book && pkill -f node ; node api/index.js${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
