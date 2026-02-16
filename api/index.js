const express = require('express');
const cors = require('cors');
const path = require('path');
const espeakTTS = require('./tts-espeak');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// ایجاد پوشه audio-cache اگر وجود ندارد
const audioCacheDir = path.join(__dirname, '../audio-cache');
if (!fs.existsSync(audioCacheDir)) {
    fs.mkdirSync(audioCacheDir, { recursive: true });
}

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(express.static(path.join(__dirname, '../public')));
app.use('/audio-cache', express.static(audioCacheDir));

// مسیر سلامت
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        message: 'sound-make-book API is running (eSpeak version)',
        timestamp: new Date().toISOString()
    });
});

// مسیر دریافت صداها (فعلاً فقط فارسی با eSpeak)
app.get('/api/voices', (req, res) => {
    res.json({
        success: true,
        voices: [
            { id: 'fa', name: 'فارسی (eSpeak)', language: 'fa-IR', gender: 'male' }
        ]
    });
});

// مسیر تولید صدا
app.post('/api/generate-audio', express.json(), async (req, res) => {
    try {
        const { text, voiceId } = req.body;
        
        if (!text) {
            return res.status(400).json({ success: false, error: 'متن الزامی است' });
        }
        
        const filename = `espeak_${Date.now()}.wav`;
        const result = await espeakTTS.synthesize(text, filename);
        
        // تلاش برای تبدیل به MP3 (اگر ffmpeg نصب باشد)
        try {
            const mp3Path = await espeakTTS.convertToMp3(result.path);
            const mp3Filename = path.basename(mp3Path);
            result.url = `/audio-cache/${mp3Filename}`;
            console.log('✅ فایل به MP3 تبدیل شد');
        } catch (convertError) {
            console.log('تبدیل به MP3 انجام نشد، فایل WAV استفاده می‌شود');
        }
        
        res.json({
            success: true,
            audioUrl: result.url,
            message: 'صدا با موفقیت تولید شد'
        });
    } catch (error) {
        console.error('Error generating audio:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// مسیر اصلی وب
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/index.html'));
});

// همه مسیرهای دیگر به index.html بروند (برای SPA)
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 sound-make-book server running on port ${PORT}`);
    console.log(`📂 Public directory: ${path.join(__dirname, '../public')}`);
    console.log(`🌐 Open: http://localhost:${PORT}`);
    console.log(`🎤 TTS Engine: eSpeak (آفلاین، فارسی)`);
});

module.exports = app;
