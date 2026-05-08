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
