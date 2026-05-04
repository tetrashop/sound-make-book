#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[UPGRADE]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# پشتیبان‌گیری
BACKUP_DIR="../sound-make-book-backup-$(date +%Y%m%d-%H%M%S)"
log "ایجاد پشتیبان در $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r . "$BACKUP_DIR" 2>/dev/null || true
success "پشتیبان ساخته شد: $BACKUP_DIR"

# نصب وابستگی‌های Node.js (بدون ffmpeg)
log "نصب وابستگی‌های Node.js..."
npm install --save express cors franc tesseract.js axios
npm install --save-dev nodemon @types/node
success "وابستگی‌ها نصب شدند."

# ایجاد فایل advanced-tts.js
mkdir -p api
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
            const gap = opts.gap || 0;
            const outWav = path.join(this.cacheDir, `tts_${Date.now()}.wav`);
            const cmd = `espeak -v ${voice} -s ${Math.round(rate * 100)} -p ${pitch} -g ${gap} "${text.replace(/"/g, '\\"')}" -w ${outWav}`;
            exec(cmd, (err) => {
                if (err) return reject(err);
                // بدون ffmpeg، فایل wav را برمی‌گردانیم
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

# ایجاد bulk-generator.js
cat > api/bulk-generator.js << 'EOF'
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
EOF

# بازنویسی api/index.js (سرور اصلی)
cp api/index.js api/index.js.bak 2>/dev/null || true
cat > api/index.js << 'EOF'
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
EOF

# ایجاد cli.js
cat > cli.js << 'EOF'
#!/usr/bin/env node
const { execSync } = require('child_process');
const commands = {
    start: () => execSync('node api/index.js', { stdio: 'inherit' }),
    backup: () => {
        const date = new Date().toISOString().slice(0,19).replace(/:/g, '-');
        execSync(`mkdir -p ../backup-${date} && cp -r . ../backup-${date}`);
        console.log(`✅ پشتیبان: ../backup-${date}`);
    },
    clean: () => { execSync('rm -rf audio-cache/* node_modules/.cache'); console.log('✅ پاکسازی شد'); },
    status: () => {
        try {
            const queue = JSON.parse(execSync('curl -s http://localhost:3000/api/queue-status 2>/dev/null || echo "{}"').toString());
            console.log(`📊 صف: ${queue.pending || 0} در انتظار | پردازش: ${queue.processing ? 'فعال' : 'آماده'}`);
        } catch(e) { console.log('سرور در حال اجرا نیست'); }
    },
    help: () => console.log(`دستورات: start, backup, clean, status, help`)
};
const cmd = process.argv[2];
if (commands[cmd]) commands[cmd](); else commands.help();
EOF
chmod +x cli.js

# به‌روزرسانی package.json
npx json -I -f package.json -e 'this.scripts["start:golden"]="node api/index.js"' 2>/dev/null || echo "⚠️ json نصب نیست، اسکریپت‌ها را دستی اضافه کنید"
npx json -I -f package.json -e 'this.scripts["cli"]="node cli.js"' 2>/dev/null
npx json -I -f package.json -e 'this.scripts["dev"]="nodemon api/index.js"' 2>/dev/null

# بهبود frontend (اضافه کردن دکمه bulk و وضعیت صف)
if [ -f public/scripts/main.js ]; then
    cp public/scripts/main.js public/scripts/main.js.bak
    cat >> public/scripts/main.js << 'EOFJS'

// =============== بخش جدید: تولید انبوه و وضعیت صف ===============
async function checkQueueStatus() {
    try {
        const res = await fetch('/api/queue-status');
        const data = await res.json();
        const div = document.getElementById('queue-status');
        if (div) div.innerHTML = `📊 صف: ${data.pending} در انتظار | ${data.processing ? 'پردازش فعال' : 'آماده'}`;
    } catch(e) { console.warn(e); }
}

function injectQueueUI() {
    const header = document.querySelector('header');
    if (header && !document.getElementById('queue-status')) {
        const div = document.createElement('div');
        div.id = 'queue-status';
        div.style.cssText = 'margin:10px 0; padding:5px; background:#f0f0f0; border-radius:8px; text-align:center';
        header.appendChild(div);
        setInterval(checkQueueStatus, 3000);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    injectQueueUI();
    const projectsTab = document.getElementById('projects');
    if (projectsTab) {
        const bulkBtn = document.createElement('button');
        bulkBtn.id = 'bulk-generate-btn';
        bulkBtn.className = 'btn btn-primary';
        bulkBtn.textContent = '📚 تولید کتاب چندبخشی (انبوه)';
        bulkBtn.style.margin = '10px 0';
        bulkBtn.onclick = () => {
            const name = prompt('نام کتاب:');
            if (!name) return;
            const chapters = [];
            let i = 1;
            while (true) {
                let text = prompt(`متن بخش ${i} (خالی برای پایان):`);
                if (!text) break;
                chapters.push({ text, voice: 'fa', rate: 1.0 });
                i++;
            }
            if (chapters.length === 0) return;
            fetch('/api/bulk-projects', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name, chapters })
            })
            .then(r => r.json())
            .then(data => alert(`پروژه با ID ${data.id} ایجاد شد. وضعیت را در کنسول بررسی کنید.`));
        };
        const card = projectsTab.querySelector('.card');
        if (card) card.insertBefore(bulkBtn, card.children[2]);
    }
});
EOFJS
    success "فرانت‌اند بهبود یافت."
fi

success "تمامی بهبودهای طلایی اعمال شد!"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✨ پروژه ارتقا یافت! ✨${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📍 برای راه‌اندازی سرور: ${YELLOW}node api/index.js${NC} یا ${YELLOW}npm run start:golden${NC}"
echo -e "📍 ابزار CLI: ${YELLOW}node cli.js help${NC}"
echo -e "📍 پشتیبان در: ${YELLOW}$BACKUP_DIR${NC}"
echo ""
echo -e "${BLUE}ویژگی‌های جدید:${NC}"
echo "  • صف تولید هوشمند (حتی بدون ffmpeg)"
echo "  • API تولید انبوه کتاب چندبخشی"
echo "  • ابزار خط فرمان برای مدیریت"
echo "  • نمایش وضعیت صف در frontend"
echo ""

# اجرای خودکار سرور
log "در حال راه‌اندازی سرور..."
node api/index.js
