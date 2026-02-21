const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');
const { exec, spawn } = require('child_process');
const crypto = require('crypto');

const PORT = 3000;
const AUDIO_CACHE = path.join(__dirname, '../audio-cache');
const PUBLIC_DIR = path.join(__dirname, '../public');
const PROJECTS_FILE = path.join(__dirname, '../projects/projects.json');

// اطمینان از وجود پوشه‌ها
[AUDIO_CACHE, path.dirname(PROJECTS_FILE)].forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});
if (!fs.existsSync(PROJECTS_FILE)) fs.writeFileSync(PROJECTS_FILE, '[]');

// تابع کمکی برای ارسال JSON
function sendJSON(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end(JSON.stringify(data, null, 2));
}

// تابع کمکی برای خواندن بدنه درخواست
function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => resolve(body));
    req.on('error', reject);
  });
}

// تابع کمکی برای سرو فایل‌های استاتیک
function serveStaticFile(res, filePath) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('404 Not Found');
    } else {
      const ext = path.extname(filePath);
      const contentType = {
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'text/javascript',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.mp3': 'audio/mpeg',
        '.wav': 'audio/wav'
      }[ext] || 'text/plain';
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
    }
  });
}

// توابع کمکی پروژه‌ها
function readProjects() {
  return JSON.parse(fs.readFileSync(PROJECTS_FILE, 'utf8'));
}
function writeProjects(projects) {
  fs.writeFileSync(PROJECTS_FILE, JSON.stringify(projects, null, 2));
}

// تابع تولید صدا با eSpeak
function generateAudio(text, voice = 'fa', options = {}, callback) {
  const id = crypto.randomBytes(8).toString('hex');
  const wavFile = path.join(AUDIO_CACHE, `${id}.wav`);
  const mp3File = path.join(AUDIO_CACHE, `${id}.mp3`);

  let cmd = `espeak -v ${voice}`;
  if (options.speed) cmd += ` -s ${options.speed * 100}`;
  if (options.pitch) cmd += ` -p ${options.pitch + 50}`;
  if (options.gap) cmd += ` -g ${options.gap}`;
  cmd += ` "${text}" -w ${wavFile}`;

  exec(cmd, (err) => {
    if (err) return callback(err);
    // تبدیل به MP3 با ffmpeg (اگر موجود باشد)
    exec(`ffmpeg -i ${wavFile} -codec:a libmp3lame -qscale:a 2 ${mp3File}`, (err) => {
      // اگر ffmpeg نبود، همان WAV را برگردانیم
      if (err) {
        fs.rename(wavFile, mp3File, () => {});
      } else {
        fs.unlink(wavFile, () => {});
      }
      callback(null, mp3File);
    });
  });
}

// ایجاد سرور
const server = http.createServer(async (req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  // ========== API routes ==========

  // صفحه اصلی
  if (pathname === '/' && req.method === 'GET') {
    return serveStaticFile(res, path.join(PUBLIC_DIR, 'index.html'));
  }

  // تشخیص زبان (mock)
  if (pathname === '/api/detect-language' && req.method === 'POST') {
    const body = await readBody(req);
    try {
      const { text } = JSON.parse(body);
      const lang = text.match(/[a-zA-Z]/) ? 'en' : 'fa'; // تشخیص ساده
      return sendJSON(res, 200, { success: true, language: lang });
    } catch {
      return sendJSON(res, 400, { error: 'Invalid request' });
    }
  }

  // OCR (mock)
  if (pathname === '/api/ocr' && req.method === 'POST') {
    // در این نسخه OCR واقعی نداریم، فقط یک متن آزمایشی برمی‌گردانیم
    return sendJSON(res, 200, { success: true, text: 'متن استخراج شده از تصویر (شبیه‌سازی)' });
  }

  // پیش‌نمایش صدا (۱۰ ثانیه اول)
  if (pathname === '/api/preview' && req.method === 'POST') {
    const body = await readBody(req);
    try {
      const { text } = JSON.parse(body);
      const previewText = text.slice(0, 100); // حدود ۱۰ ثانیه
      generateAudio(previewText, 'fa', {}, (err, file) => {
        if (err) return sendJSON(res, 500, { error: 'خطا در تولید صدا' });
        const filename = path.basename(file);
        sendJSON(res, 200, { success: true, previewUrl: `/audio-cache/${filename}` });
      });
    } catch {
      return sendJSON(res, 400, { error: 'Invalid request' });
    }
  }

  // تولید نهایی (چندبخشی ساده)
  if (pathname === '/api/generate-multi-voice' && req.method === 'POST') {
    const body = await readBody(req);
    try {
      const { segments } = JSON.parse(body);
      if (!segments || !segments.length) return sendJSON(res, 400, { error: 'No segments' });

      // فعلاً فقط اولین بخش را تولید می‌کنیم
      const seg = segments[0];
      generateAudio(seg.text, seg.voice || 'fa', {}, (err, file) => {
        if (err) return sendJSON(res, 500, { error: 'خطا در تولید صدا' });
        const filename = path.basename(file);
        sendJSON(res, 200, { success: true, audioUrl: `/audio-cache/${filename}` });
      });
    } catch {
      return sendJSON(res, 400, { error: 'Invalid request' });
    }
  }

  // تولید با تنظیمات پیشرفته
  if (pathname === '/api/generate-advanced' && req.method === 'POST') {
    const body = await readBody(req);
    try {
      const { text, voice, speed, pitch, gap } = JSON.parse(body);
      generateAudio(text, voice || 'fa', { speed, pitch, gap }, (err, file) => {
        if (err) return sendJSON(res, 500, { error: 'خطا در تولید صدا' });
        const filename = path.basename(file);
        sendJSON(res, 200, { success: true, audioUrl: `/audio-cache/${filename}` });
      });
    } catch {
      return sendJSON(res, 400, { error: 'Invalid request' });
    }
  }

  // مدیریت پروژه‌ها
  if (pathname === '/api/projects' && req.method === 'GET') {
    const projects = readProjects();
    return sendJSON(res, 200, { success: true, projects });
  }

  if (pathname === '/api/projects' && req.method === 'POST') {
    const body = await readBody(req);
    try {
      const { name, audioUrl, settings } = JSON.parse(body);
      const projects = readProjects();
      const newProject = {
        id: Date.now().toString(),
        name,
        audioUrl,
        settings: settings || {},
        createdAt: new Date().toISOString()
      };
      projects.push(newProject);
      writeProjects(projects);
      return sendJSON(res, 200, { success: true, project: newProject });
    } catch {
      return sendJSON(res, 400, { error: 'Invalid request' });
    }
  }

  if (pathname.startsWith('/api/projects/') && req.method === 'DELETE') {
    const id = pathname.split('/')[3];
    const projects = readProjects();
    const filtered = projects.filter(p => p.id !== id);
    if (filtered.length === projects.length) {
      return sendJSON(res, 404, { error: 'Project not found' });
    }
    writeProjects(filtered);
    return sendJSON(res, 200, { success: true });
  }

  // فایل‌های صوتی کش
  if (pathname.startsWith('/audio-cache/')) {
    const filePath = path.join(AUDIO_CACHE, pathname.replace('/audio-cache/', ''));
    return serveStaticFile(res, filePath);
  }

  // فایل‌های استاتیک عمومی
  let filePath = path.join(PUBLIC_DIR, pathname === '/' ? 'index.html' : pathname);
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    return serveStaticFile(res, filePath);
  }

  // 404
  sendJSON(res, 404, { error: 'Not found' });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 sound-make-book v2.0 با ۹ قابلیت روی پورت ${PORT} اجرا شد`);
  console.log(`🌐 آدرس: http://localhost:${PORT}`);
});
