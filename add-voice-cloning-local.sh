#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
echo -e "${GREEN}🎙️ افزودن قابلیت تقلید صدای شخص (بدون API) - نسخه پایدار${NC}"

# ایجاد پوشه‌های مورد نیاز
mkdir -p data temp_uploads

# 1. ماژول تحلیل صدا (ساده بدون نیاز به sox/ffmpeg در زمان اجرا)
cat > api/voice-profiler.js << 'EOF'
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

const PROFILE_FILE = path.join(__dirname, '../data/voice-profile.json');

// تابعی برای بررسی وجود ابزارها
async function hasTool(tool) {
    try {
        await execPromise(`which ${tool}`);
        return true;
    } catch { return false; }
}

// تحلیل ساده pitch با استفاده از sox (اختیاری)
async function analyzePitchWithSox(wavPath) {
    try {
        const hasSox = await hasTool('sox');
        if (!hasSox) return 50;
        const { stdout } = await execPromise(`sox "${wavPath}" -n stat pitch 2>&1`);
        const match = stdout.match(/Pitch:\s+(\d+(\.\d+)?)/);
        if (match) {
            let raw = parseFloat(match[1]);
            return Math.min(99, Math.max(0, Math.round((raw - 50) * 0.4 + 50)));
        }
    } catch(e) {}
    return 50;
}

async function analyzeVoiceSample(samplePath) {
    const ext = path.extname(samplePath).toLowerCase();
    let wavPath = samplePath;
    let tempWav = null;
    
    // اگر mp3 یا m4a بود، به wav تبدیل کن (در صورت وجود ffmpeg)
    if (['.mp3', '.m4a', '.ogg'].includes(ext)) {
        const hasFfmpeg = await hasTool('ffmpeg');
        if (hasFfmpeg) {
            tempWav = samplePath + '.wav';
            await execPromise(`ffmpeg -i "${samplePath}" -acodec pcm_s16le -ar 16000 "${tempWav}" -y`);
            wavPath = tempWav;
        }
    }
    
    const pitch = await analyzePitchWithSox(wavPath);
    const speed = 1.0; // سرعت پیش‌فرض، کاربر می‌تواند بعداً تنظیم کند
    
    // پاکسازی فایل موقت
    if (tempWav && fs.existsSync(tempWav)) fs.unlinkSync(tempWav);
    if (samplePath !== wavPath && fs.existsSync(wavPath) && wavPath !== samplePath) fs.unlinkSync(wavPath);
    
    const profile = { pitch, speed, createdAt: new Date().toISOString() };
    fs.writeFileSync(PROFILE_FILE, JSON.stringify(profile, null, 2));
    return profile;
}

function getProfile() {
    if (fs.existsSync(PROFILE_FILE)) {
        return JSON.parse(fs.readFileSync(PROFILE_FILE));
    }
    return null;
}

function clearProfile() {
    if (fs.existsSync(PROFILE_FILE)) fs.unlinkSync(PROFILE_FILE);
}

module.exports = { analyzeVoiceSample, getProfile, clearProfile };
EOF

# 2. اضافه کردن مسیرها به api/index.js
if ! grep -q "/api/upload-voice-profile" api/index.js; then
    # اضافه کردن require voiceProfiler
    if ! grep -q "voice-profiler" api/index.js; then
        sed -i '/const advancedTTS = require/a const voiceProfiler = require("./voice-profiler");' api/index.js
    fi
    
    # اضافه کردن مسیرها قبل از app.listen
    sed -i '/app\.listen/i \
// Voice Cloning routes\
const multer = require("multer");\
const upload = multer({ dest: "temp_uploads/" });\
\
app.post("/api/upload-voice-profile", upload.single("sample"), async (req, res) => {\
    if (!req.file) return res.status(400).json({ error: "فایلی ارسال نشده" });\
    try {\
        const profile = await voiceProfiler.analyzeVoiceSample(req.file.path);\
        fs.unlinkSync(req.file.path);\
        res.json({ profile });\
    } catch(err) {\
        res.status(500).json({ error: err.message });\
    }\
});\
\
app.post("/api/synthesize-with-profile", async (req, res) => {\
    const { text } = req.body;\
    if (!text) return res.status(400).json({ error: "text required" });\
    const profile = voiceProfiler.getProfile();\
    if (!profile) return res.status(404).json({ error: "پروفایل صدا یافت نشد" });\
    try {\
        const result = await advancedTTS.enqueue(text, { voice: "fa", rate: profile.speed, pitch: profile.pitch });\
        res.json({ url: result.url });\
    } catch(err) {\
        res.status(500).json({ error: err.message });\
    }\
});\
\
app.post("/api/clear-voice-profile", (req, res) => {\
    voiceProfiler.clearProfile();\
    res.json({ success: true });\
});' api/index.js
fi

# نصب multer در صورت نیاز
npm install multer --save 2>/dev/null || echo "multer already installed"

# 3. افزودن تب به public/index.html (اگر وجود ندارد)
if ! grep -q "voice-clone-local" public/index.html; then
    # حذف تب قبلی اگر خراب شده باشد (اختیاری)
    sed -i '/id="voice-clone-local"/,/<\/section>/d' public/index.html
    
    # اضافه کردن تب جدید به بخش tabs
    if ! grep -q 'data-tab="voice-clone-local"' public/index.html; then
        sed -i '/<nav class="tabs">/a \                <button class="tab-btn" data-tab="voice-clone-local">🎤 Clone صدا</button>' public/index.html
    fi
    
    # اضافه کردن محتوای تب
    cat >> public/index.html << 'EOFHTML'
<section id="voice-clone-local" class="tab-content">
    <div class="card">
        <h2>🎤 تقلید صدای شخص (بدون اینترنت)</h2>
        <p>یک فایل صوتی کوتاه (۳-۱۰ ثانیه، wav/mp3) از صدای خود آپلود کنید.</p>
        <input type="file" id="voice-sample-file" accept="audio/*">
        <button id="upload-profile-btn" class="btn">📤 تحلیل و ذخیره صدا</button>
        <button id="clear-profile-btn" class="btn" style="background:#ccc;">🗑️ حذف پروفایل</button>
        <div id="profile-status"></div>
        <hr>
        <textarea id="clone-local-text" placeholder="متن کتاب را وارد کنید..." rows="6"></textarea>
        <button id="speak-with-profile-btn" class="btn btn-primary">🗣️ تولید گفتار با صدای شخصی</button>
        <div id="profile-audio-player"></div>
    </div>
</section>
EOFHTML
fi

# 4. اضافه کردن کد جاوااسکریپت به public/scripts/main.js
if ! grep -q "upload-profile-btn" public/scripts/main.js; then
    cat >> public/scripts/main.js << 'EOFJS'

// =============== Voice Cloning محلی ===============
const uploadBtn = document.getElementById('upload-profile-btn');
const clearBtn = document.getElementById('clear-profile-btn');
const speakBtn = document.getElementById('speak-with-profile-btn');
const fileInput = document.getElementById('voice-sample-file');
const profileStatus = document.getElementById('profile-status');
const audioPlayer = document.getElementById('profile-audio-player');
const cloneText = document.getElementById('clone-local-text');

uploadBtn?.addEventListener('click', async () => {
    const file = fileInput?.files[0];
    if (!file) return alert('لطفاً فایل صوتی را انتخاب کنید');
    const formData = new FormData();
    formData.append('sample', file);
    if (profileStatus) profileStatus.innerHTML = '⏳ در حال تحلیل نمونه صدا...';
    try {
        const res = await fetch('/api/upload-voice-profile', { method: 'POST', body: formData });
        const data = await res.json();
        if (res.ok && profileStatus) {
            profileStatus.innerHTML = `✅ صدا تحلیل شد! (pitch=${data.profile.pitch}, speed=${data.profile.speed})`;
        } else if (profileStatus) {
            profileStatus.innerHTML = '❌ خطا: ' + (data.error || 'مشخص نیست');
        }
    } catch(e) {
        if (profileStatus) profileStatus.innerHTML = '❌ خطا در ارتباط با سرور';
    }
});

clearBtn?.addEventListener('click', async () => {
    try {
        await fetch('/api/clear-voice-profile', { method: 'POST' });
        if (profileStatus) profileStatus.innerHTML = '🗑️ پروفایل صدا پاک شد.';
    } catch(e) {}
});

speakBtn?.addEventListener('click', async () => {
    const text = cloneText?.value;
    if (!text) return alert('متن را وارد کنید');
    if (audioPlayer) audioPlayer.innerHTML = '⏳ در حال تولید صدا...';
    try {
        const res = await fetch('/api/synthesize-with-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text })
        });
        const data = await res.json();
        if (res.ok && audioPlayer) {
            audioPlayer.innerHTML = `<audio controls autoplay src="${data.url}"></audio>`;
        } else if (audioPlayer) {
            audioPlayer.innerHTML = '❌ خطا: ' + (data.error || 'پروفایل صدا یافت نشد');
        }
    } catch(e) {
        if (audioPlayer) audioPlayer.innerHTML = '❌ خطا در ارتباط با سرور';
    }
});
EOFJS
fi

echo -e "${GREEN}✅ قابلیت تقلید صدای شخص (بدون API) با موفقیت اضافه شد.${NC}"
echo ""
echo "🔄 سرور را مجدداً راه‌اندازی کنید: node api/index.js"
echo "سپس در مرورگر تب «🎤 Clone صدا» را باز کنید."
