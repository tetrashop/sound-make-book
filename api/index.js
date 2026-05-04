const express = require('express');
const cors = require('cors');
const path = require('path');
const advancedTTS = require('./advanced-tts');
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

app.listen(PORT, '0.0.0.0', () => {
    console.log(`✨ sound-make-book GOLDEN EDITION running on port ${PORT}`);
});
