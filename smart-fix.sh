#!/bin/bash

# ============================================================
# smart-fix.sh - نصب هوشمند بسته‌های گمشده برای sound-make-book
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🧠 اسکریپت هوشمند نصب بسته‌های گمشده${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# ------------------------------------------------------------
# تابع بررسی موفقیت نصب
# ------------------------------------------------------------
check_installed() {
    command -v $1 &>/dev/null && echo "✅ $1 نصب شد" || echo "❌ $1 نصب نشد"
}

# ------------------------------------------------------------
# روش اول: استفاده از HTTP (بدون SSL)
# ------------------------------------------------------------
echo -e "\n${YELLOW}[1/3] تلاش با پروتکل HTTP...${NC}"
BACKUP_SOURCE="$PREFIX/etc/apt/sources.list"
cp "$BACKUP_SOURCE" "${BACKUP_SOURCE}.bak" 2>/dev/null

echo "deb http://packages.termux.org/apt/termux-main stable main" > "$BACKUP_SOURCE"
apt update 2>&1 | head -3

if apt install nodejs ffmpeg sox -y --allow-unauthenticated 2>&1 | grep -q "is already the newest\|Setting up\|Unpacking"; then
    echo -e "${GREEN}✅ بسته‌ها با موفقیت نصب شدند (روش HTTP)${NC}"
    check_installed node
    check_installed ffmpeg
    check_installed sox
    exit 0
fi

# ------------------------------------------------------------
# روش دوم: دانلود مستقیم .deb برای aarch64
# ------------------------------------------------------------
echo -e "\n${YELLOW}[2/3] روش دوم: دانلود مستقیم فایل‌های .deb...${NC}"
cd ~
ARCH="aarch64"
BASE_URL="https://packages.termux.org/apt/termux-main/pool/main"

# لیست بسته‌ها با آخرین نسخه‌های شناخته شده
declare -A PACKAGES=(
    ["nodejs"]="n/nodejs/nodejs_22.14.0_${ARCH}.deb"
    ["ffmpeg"]="f/ffmpeg/ffmpeg_8.0.1-5_${ARCH}.deb"
    ["sox"]="s/sox/sox_14.4.2-28_${ARCH}.deb"
)

INSTALL_OK=true
for pkg in nodejs ffmpeg sox; do
    if command -v $pkg &>/dev/null; then
        echo -e "${GREEN}✅ $pkg از قبل نصب است${NC}"
        continue
    fi
    URL="${BASE_URL}/${PACKAGES[$pkg]}"
    echo "📥 دانلود $pkg از $URL"
    wget -q --show-progress "$URL" -O "${pkg}.deb" || {
        echo -e "${RED}❌ دانلود $pkg ناموفق${NC}"
        INSTALL_OK=false
        continue
    }
    dpkg -i "${pkg}.deb" 2>/dev/null || {
        echo -e "${RED}❌ نصب $pkg با dpkg ناموفق${NC}"
        INSTALL_OK=false
    }
    rm -f "${pkg}.deb"
done

if [ "$INSTALL_OK" = true ]; then
    apt --fix-broken install -y
    echo -e "${GREEN}✅ نصب مستقیم تکمیل شد${NC}"
    check_installed node
    check_installed ffmpeg
    check_installed sox
    exit 0
fi

# ------------------------------------------------------------
# روش سوم: استفاده از mirror چینی (فقط HTTP)
# ------------------------------------------------------------
echo -e "\n${YELLOW}[3/3] روش سوم: تغییر به mirror چینی (USTC HTTP)...${NC}"
echo "deb http://mirrors.ustc.edu.cn/termux/apt/termux-main stable main" > "$BACKUP_SOURCE"
apt update 2>&1 | head -3
if apt install nodejs ffmpeg sox -y --allow-unauthenticated; then
    echo -e "${GREEN}✅ بسته‌ها با mirror چینی نصب شدند${NC}"
    check_installed node
    check_installed ffmpeg
    check_installed sox
    exit 0
fi

# ------------------------------------------------------------
# اگر هیچکدام کار نکرد
# ------------------------------------------------------------
echo -e "\n${RED}❌ متأسفانه هیچ روشی موفق نبود.${NC}"
echo -e "${YELLOW}پیشنهاد: از VPN روی گوشی استفاده کنید و سپس دوباره اجرا کنید.${NC}"
echo "برای برگرداندن مخازن به حالت اولیه:"
echo "  cp ${BACKUP_SOURCE}.bak $BACKUP_SOURCE"
exit 1
