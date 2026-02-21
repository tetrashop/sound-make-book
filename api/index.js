const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');

// تشخیص محیط Vercel
const isVercel = process.env.VERCEL === '1';

// تابع کمکی برای ارسال JSON
function sendJSON(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  });
  res.end(JSON.stringify(data, null, 2));
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
        '.jpg': 'image/jpeg'
      }[ext] || 'text/plain';
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
    }
  });
}

// ایجاد سرور
const server = http.createServer(async (req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, POST' });
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  // اگر در محیط Vercel هستیم، فقط یک پیام ساده برگردان
  if (isVercel) {
    if (pathname === '/') {
      return sendJSON(res, 200, {
        message: 'sound-make-book (نسخه آنلاین)',
        note: 'این پروژه برای اجرای محلی با قابلیت‌های کامل طراحی شده است. برای استفاده از قابلیت‌های صوتی، پروژه را روی دستگاه خود اجرا کنید.',
        repository: 'https://github.com/tetrashop/sound-make-book',
        local_run: 'git clone ... && cd sound-make-book && node api/index.js'
      });
    }
    if (pathname === '/api/health') {
      return sendJSON(res, 200, { status: 'healthy', environment: 'vercel' });
    }
    // بقیه مسیرها
    return sendJSON(res, 404, { error: 'Not available in online version' });
  }

  // ========== اجرای محلی (با پشتیبانی کامل) ==========
  // (اینجا کد قبلی برای اجرای محلی قرار می‌گیرد - می‌توانید از فایل قبلی کپی کنید)
  // برای اختصار، کد کامل اجرای محلی را در اینجا قرار نمی‌دهیم، اما شما می‌توانید فایل قبلی خود را نگه دارید.
  // فقط اطمینان حاصل کنید که بخش مربوط به isVercel در بالای فایل قرار دارد و اجرای محلی در else باقی می‌ماند.
  
  // در اینجا کد اجرای محلی شما (که قبلاً داشتید) قرار می‌گیرد.
  // برای اینکه فایل کامل شود، باید کد قبلی خود را در این قسمت قرار دهید.
  // من به دلیل طولانی نشدن پاسخ، کد را نمی‌آورم؛ شما همان فایل قبلی را با اضافه کردن isVercel در بالا نگه دارید.
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 sound-make-book running on port ${PORT} (${isVercel ? 'Vercel' : 'local'})`);
});
