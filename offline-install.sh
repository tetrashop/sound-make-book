#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📦 نصب بسته‌های گمشده (روش آفلاین)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# تشخیص معماری
ARCH=$(dpkg --print-architecture)
echo -e "معماری دستگاه: ${YELLOW}$ARCH${NC}"

# لینک‌های مستقیم بسته‌ها
NODEJS_URL="https://packages.termux.org/apt/termux-main/pool/main/n/nodejs/nodejs_22.14.0_${ARCH}.deb"
FFMPEG_URL="https://packages.termux.org/apt/termux-main/pool/main/f/ffmpeg/ffmpeg_8.0.1-5_${ARCH}.deb"
SOX_URL="https://packages.termux.org/apt/termux-main/pool/main/s/sox/sox_14.4.2-28_${ARCH}.deb"

# پوشه دانلود در Termux (دسترسی به حافظه مشترک)
DOWNLOAD_DIR="$HOME/storage/downloads"

# بررسی وجود دسترسی به storage
if [ ! -d "$HOME/storage" ]; then
    echo -e "${YELLOW}در حال اعطای دسترسی به حافظه...${NC}"
    termux-setup-storage
    sleep 2
fi

if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo -e "${RED}پوشه دانلود یافت نشد. لطفاً ابتدا Termux را ببندید و دوباره باز کنید.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}مرحله 1: دانلود فایل‌های مورد نیاز${NC}"
echo -e "${YELLOW}لطفاً لینک‌های زیر را در مرورگر گوشی باز کنید و فایل‌ها را دانلود کنید:${NC}"
echo ""
echo -e "1️⃣ ${GREEN}nodejs${NC}:"
echo "   $NODEJS_URL"
echo ""
echo -e "2️⃣ ${GREEN}ffmpeg${NC}:"
echo "   $FFMPEG_URL"
echo ""
echo -e "3️⃣ ${GREEN}sox${NC}:"
echo "   $SOX_URL"
echo ""
echo -e "${YELLOW}پس از دانلود، فایل‌ها را در پوشه ${BLUE}Download${NC} گوشی خود قرار دهید.${NC}"
echo ""
read -p "✅ پس از اتمام دانلود و انتقال فایل‌ها، اینتر را بزنید..." 

# جستجوی فایل‌های دانلود شده
cd "$DOWNLOAD_DIR"
NODE_DEB=$(ls nodejs_*.deb 2>/dev/null | head -1)
FFMPEG_DEB=$(ls ffmpeg_*.deb 2>/dev/null | head -1)
SOX_DEB=$(ls sox_*.deb 2>/dev/null | head -1)

if [ -z "$NODE_DEB" ] || [ -z "$FFMPEG_DEB" ] || [ -z "$SOX_DEB" ]; then
    echo -e "${RED}❌ همه فایل‌ها یافت نشدند. لطفاً دانلود را کامل کنید.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ همه فایل‌ها پیدا شدند. در حال نصب...${NC}"

# نصب با dpkg
dpkg -i "$NODE_DEB" "$FFMPEG_DEB" "$SOX_DEB" 2>/dev/null || {
    echo -e "${YELLOW}نصب با وابستگی‌ها انجام شد، در حال رفع وابستگی...${NC}"
    apt --fix-broken install -y
}

# بررسی نصب
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "وضعیت نصب:"
command -v node && echo -e "${GREEN}✅ nodejs نصب شد${NC}" || echo -e "${RED}❌ nodejs نصب نشد${NC}"
command -v ffmpeg && echo -e "${GREEN}✅ ffmpeg نصب شد${NC}" || echo -e "${RED}❌ ffmpeg نصب نشد${NC}"
command -v sox && echo -e "${GREEN}✅ sox نصب شد${NC}" || echo -e "${RED}❌ sox نصب نشد${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# پاکسازی فایل‌های deb
rm -f "$NODE_DEB" "$FFMPEG_DEB" "$SOX_DEB"
echo -e "${GREEN}فایل‌های موقت پاک شدند.${NC}"
