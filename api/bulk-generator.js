const express = require('express');
const router = express.Router();
const advancedTTS = require('./advanced-tts');
const fs = require('fs');
const path = require('path');

const PROJECTS_FILE = path.join(__dirname, '../projects/bulk_projects.json');
if (!fs.existsSync(PROJECTS_FILE)) fs.writeFileSync(PROJECTS_FILE, '[]');

router.get('/bulk-projects', (req, res) => {
    const projects = JSON.parse(fs.readFileSync(PROJECTS_FILE));
    res.json(projects);
});

router.post('/bulk-projects', (req, res) => {
    const { name, chapters } = req.body;
    if (!name || !chapters || !chapters.length) {
        return res.status(400).json({ error: 'name and chapters required' });
    }
    const project = {
        id: Date.now().toString(),
        name,
        chapters,
        createdAt: new Date().toISOString(),
        status: 'pending',
        outputs: []
    };
    const projects = JSON.parse(fs.readFileSync(PROJECTS_FILE));
    projects.push(project);
    fs.writeFileSync(PROJECTS_FILE, JSON.stringify(projects, null, 2));

    process.nextTick(async () => {
        for (let i = 0; i < project.chapters.length; i++) {
            const ch = project.chapters[i];
            try {
                const result = await advancedTTS.enqueue(ch.text, {
                    voice: ch.voice || 'fa',
                    rate: ch.rate || 1,
                    pitch: ch.pitch || 50
                });
                project.outputs.push({ chapter: i, path: result.path, url: result.url });
                const idx = projects.findIndex(p => p.id === project.id);
                if (idx !== -1) {
                    projects[idx].outputs = project.outputs;
                    projects[idx].status = i === project.chapters.length-1 ? 'completed' : 'processing';
                    fs.writeFileSync(PROJECTS_FILE, JSON.stringify(projects, null, 2));
                }
            } catch (err) {
                const idx = projects.findIndex(p => p.id === project.id);
                if (idx !== -1) {
                    projects[idx].status = 'failed';
                    fs.writeFileSync(PROJECTS_FILE, JSON.stringify(projects, null, 2));
                }
                break;
            }
        }
    });
    res.json({ id: project.id, status: 'started' });
});

router.get('/bulk-projects/:id', (req, res) => {
    const projects = JSON.parse(fs.readFileSync(PROJECTS_FILE));
    const project = projects.find(p => p.id === req.params.id);
    if (!project) return res.status(404).json({ error: 'not found' });
    res.json(project);
});

module.exports = router;
