#!/bin/bash

# ============================================================
# sound-make-book - نصب کامل و تعمیر Termux
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 شروع فرآیند نصب کامل sound-make-book${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# ============================================================
# 1. تعمیر مخازن Termux
# ============================================================
echo -e "\n${YELLOW}[1/8] تعمیر مخازن Termux...${NC}"

# پشتیبان از sources.list
cp $PREFIX/etc/apt/sources.list $PREFIX/etc/apt/sources.list.bak 2>/dev/null || true

# استفاده از mirror معتبر (Termux Official Mirror)
cat > $PREFIX/etc/apt/sources.list << EOF
deb https://packages.termux.org/apt/termux-main stable main
EOF

# اضافه کردن کلید GPG (برای رفع NO_PUBKEY)
curl -fsSL https://packages.termux.org/termux-main/key.asc | apt-key add - 2>/dev/null || true

# به‌روزرسانی
apt update --allow-insecure-repositories -y 2>/dev/null || true
apt update -y

echo -e "${GREEN}✅ مخازن تنظیم شدند.${NC}"

# ============================================================
# 2. نصب بسته‌های سیستمی مورد نیاز
# ============================================================
echo -e "\n${YELLOW}[2/8] نصب بسته‌های سیستمی...${NC}"

packages="nodejs git espeak ffmpeg sox termux-tools procps lsof curl wget"

for pkg in $packages; do
    if ! command -v $pkg &>/dev/null && ! dpkg -l | grep -q "^ii  $pkg "; then
        echo -e "📦 نصب $pkg ..."
        apt install $pkg -y --fix-missing || echo -e "${RED}⚠️ خطا در نصب $pkg${NC}"
    else
        echo -e "✅ $pkg از قبل نصب است."
    fi
done

# نصب killall اگر نبود
if ! command -v killall &>/dev/null; then
    apt install procps -y
fi

echo -e "${GREEN}✅ بسته‌های سیستمی نصب شدند.${NC}"

# ============================================================
# 3. آماده‌سازی پروژه
# ============================================================
echo -e "\n${YELLOW}[3/8] آماده‌سازی پروژه...${NC}"

cd ~
if [ -d "sound-make-book" ]; then
    echo "پروژه قبلاً وجود دارد. به‌روزرسانی می‌شود..."
    cd sound-make-book
    git pull origin main 2>/dev/null || echo "از گیت کشیده نشد، ادامه می‌دهیم..."
else
    git clone https://github.com/tetrashop/sound-make-book.git
    cd sound-make-book
fi

# ============================================================
# 4. حذف وابستگی‌های قبلی و نصب مجدد
# ============================================================
echo -e "\n${YELLOW}[4/8] نصب وابستگی‌های Node.js...${NC}"

rm -rf node_modules package-lock.json 2>/dev/null
npm cache clean --force 2>/dev/null

# نصب با --legacy-peer-deps برای جلوگیری از خطا
npm install --legacy-peer-deps

# نصب وابستگی‌های اضافی که ممکن است گم شده باشند
npm install express cors multer franc tesseract.js axios nodemon @types/node json --legacy-peer-deps

echo -e "${GREEN}✅ وابستگی‌های Node.js نصب شدند.${NC}"

# ============================================================
# 5. اضافه کردن مسیر synthesize-custom به api/index.js (اگر نبود)
# ============================================================
echo -e "\n${YELLOW}[5/8] بررسی و تکمیل API سرور...${NC}"

if ! grep -q "/api/synthesize-custom" api/index.js; then
    echo "➕ افزودن مسیر /api/synthesize-custom..."
    sed -i '/app.post("\/api\/synthesize"/a \
\
app.post("/api/synthesize-custom", async (req, res) => {\
    const { text, voice = "fa", rate = 1.0, pitch = 50 } = req.body;\
    if (!text) return res.status(400).json({ error: "text required" });\
    try {\
        const result = await advancedTTS.enqueue(text, { voice, rate, pitch });\
        res.json({ url: result.url });\
    } catch(err) {\
        res.status(500).json({ error: err.message });\
    }\
});' api/index.js
fi

# ============================================================
# 6. اطمینان از وجود فایل advanced-tts.js
# ============================================================
if [ ! -f "api/advanced-tts.js" ]; then
    echo "➕ ایجاد فایل advanced-tts.js..."
    cat > api/advanced-tts.js << 'EOF'
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');

class AdvancedTTS extends EventEmitter {
    constructor() {
        super();
        this.queue = [];
        this.processing = false;
        this.cacheDir = path.join(__dirname, '../audio-cache');
        if (!fs.existsSync(this.cacheDir)) fs.mkdirSync(this.cacheDir, { recursive: true });
    }

    enqueue(text, options = {}) {
        return new Promise((resolve, reject) => {
            const taskId = Date.now() + '-' + Math.random().toString(36).substr(2, 6);
            this.queue.push({ taskId, text, options, resolve, reject });
            this.emit('queued', taskId);
            if (!this.processing) this._processQueue();
        });
    }

    async _processQueue() {
        if (this.queue.length === 0) {
            this.processing = false;
            return;
        }
        this.processing = true;
        const task = this.queue.shift();
        this.emit('start', task.taskId);
        try {
            const result = await this._generate(task.text, task.options);
            task.resolve(result);
            this.emit('complete', task.taskId);
        } catch (err) {
            task.reject(err);
            this.emit('error', task.taskId, err);
        }
        await new Promise(r => setTimeout(r, 100));
        this._processQueue();
    }

    _generate(text, opts = {}) {
        return new Promise((resolve, reject) => {
            const voice = opts.voice || 'fa';
            const rate = opts.rate || 1.0;
            const pitch = opts.pitch || 50;
            const outWav = path.join(this.cacheDir, `tts_${Date.now()}.wav`);
            const cmd = `espeak -v ${voice} -s ${Math.round(rate * 100)} -p ${pitch} "${text.replace(/"/g, '\\"')}" -w ${outWav}`;
            exec(cmd, (err) => {
                if (err) return reject(err);
                resolve({ path: outWav, url: `/audio-cache/${path.basename(outWav)}` });
            });
        });
    }

    getQueueStatus() {
        return { pending: this.queue.length, processing: this.processing };
    }
}

module.exports = new AdvancedTTS();
EOF
fi

# ============================================================
# 7. بازنویسی main.js با نسخه نهایی (برای موبایل)
# ============================================================
echo -e "\n${YELLOW}[6/8] به‌روزرسانی فایل‌های frontend...${NC}"

cat > public/scripts/main.js << 'EOF'
// مدیریت تب‌ها
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(btn.dataset.tab).classList.add('active');
    });
});

// =============== صدای متنوع (نسخه نهایی) ===============
document.addEventListener('DOMContentLoaded', () => {
    const previewBtn = document.getElementById('preview-variety-btn');
    if (previewBtn) {
        previewBtn.addEventListener('click', async () => {
            const text = document.getElementById('variety-text')?.value;
            if (!text) { alert('متن را وارد کنید'); return; }
            const type = document.getElementById('voice-type')?.value || 'normal';
            const config = {
                normal: { speed: 1.0, pitch: 50 },
                low:    { speed: 0.9, pitch: 30 },
                high:   { speed: 1.1, pitch: 70 },
                fast:   { speed: 1.5, pitch: 50 },
                slow:   { speed: 0.7, pitch: 50 }
            };
            const { speed, pitch } = config[type];
            const statusDiv = document.getElementById('variety-status');
            statusDiv.innerHTML = '⏳ در حال تولید صدا...';
            try {
                const res = await fetch('/api/synthesize-custom', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ text, rate: speed, pitch })
                });
                const data = await res.json();
                if (res.ok && data.url) {
                    statusDiv.innerHTML = `<audio controls autoplay src="${data.url}"></audio>`;
                } else {
                    statusDiv.innerHTML = '❌ خطا: ' + (data.error || 'مشکل در سرور');
                }
            } catch(e) {
                statusDiv.innerHTML = '❌ خطا در ارتباط با سرور';
            }
        });
    }
});

// پروژه‌ها
function loadProjects() {
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    const list = document.getElementById('project-list');
    if (list) {
        list.innerHTML = projects.length ? projects.map(p => `<div>📁 ${p.name}</div>`).join('') : '<p>هیچ پروژه‌ای نیست</p>';
    }
}
document.getElementById('save-project')?.addEventListener('click', () => {
    const name = document.getElementById('project-name')?.value;
    if (!name) return alert('نام پروژه را وارد کنید');
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    projects.push({ id: Date.now(), name, createdAt: new Date().toISOString() });
    localStorage.setItem('projects', JSON.stringify(projects));
    loadProjects();
    document.getElementById('project-name').value = '';
});
loadProjects();
EOF

# ============================================================
# 8. راه‌اندازی سرور
# ============================================================
echo -e "\n${YELLOW}[7/8] آماده‌سازی برای اجرای سرور...${NC}"

# کشتن تمام فرآیندهای Node.js
killall -9 node 2>/dev/null || true
pkill -9 node 2>/dev/null || true

# اطمینان از خالی بودن پورت 3000
sleep 2

echo -e "\n${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ نصب کامل شد! در حال راه‌اندازی سرور...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""

# اجرای سرور
node api/index.js
