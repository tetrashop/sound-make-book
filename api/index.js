const express = require('express');
const cors = require('cors');
const path = require('path');
const advancedTTS = require('./advanced-tts');
const voiceProfiler = require("./voice-profiler");
const bulkRouter = require('./bulk-generator');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

app.post('/api/synthesize', async (req, res) => {
    const { text, voice = 'fa', rate = 1.0, pitch = 50 } = req.body;
    if (!text) return res.status(400).json({ error: 'text required' });
    try {
        const result = await advancedTTS.enqueue(text, { voice, rate, pitch });
        res.json({ url: result.url, path: result.path });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
app.post("/api/synthesize-custom", async (req, res) => {
    const { text, voice = "fa", rate = 1.0, pitch = 50 } = req.body;
    if (!text) return res.status(400).json({ error: "text required" });
    try {
        const result = await advancedTTS.enqueue(text, { voice, rate, pitch });
        res.json({ url: result.url, path: result.path });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
app.get('/api/queue-status', (req, res) => {
    res.json(advancedTTS.getQueueStatus());
});

app.use('/api', bulkRouter);

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Voice Cloning routes
const multer = require("multer");
const upload = multer({ dest: "temp_uploads/" });

app.post("/api/upload-voice-profile", upload.single("sample"), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: "فایلی ارسال نشده" });
    try {
        const profile = await voiceProfiler.analyzeVoiceSample(req.file.path);
        fs.unlinkSync(req.file.path);
        res.json({ profile });
    } catch(err) {
        res.status(500).json({ error: err.message });
    }
});

app.post("/api/synthesize-with-profile", async (req, res) => {
    const { text } = req.body;
    if (!text) return res.status(400).json({ error: "text required" });
    const profile = voiceProfiler.getProfile();
    if (!profile) return res.status(404).json({ error: "پروفایل صدا یافت نشد" });
    try {
        const result = await advancedTTS.enqueue(text, { voice: "fa", rate: profile.speed, pitch: profile.pitch });
        res.json({ url: result.url });
    } catch(err) {
        res.status(500).json({ error: err.message });
    }
});

app.post("/api/clear-voice-profile", (req, res) => {
    voiceProfiler.clearProfile();
    res.json({ success: true });
});
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✨ sound-make-book GOLDEN EDITION running on port ${PORT}`);
});
