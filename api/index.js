const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const PUBLIC_DIR = path.join(__dirname, '../public');

const server = http.createServer((req, res) => {
    // مشخص کردن مسیر فایل درخواستی
    let filePath = path.join(PUBLIC_DIR, req.url === '/' ? 'index.html' : req.url);
    
    // خواندن فایل
    fs.readFile(filePath, (err, data) => {
        if (err) {
            // اگر فایل پیدا نشد، صفحه 404 برگردون
            res.writeHead(404, { 'Content-Type': 'text/html' });
            res.end('<h1>404 - صفحه پیدا نشد</h1>');
            return;
        }
        
        // تعیین نوع محتوا بر اساس پسوند فایل
        let contentType = 'text/html';
        if (filePath.endsWith('.css')) contentType = 'text/css';
        if (filePath.endsWith('.js')) contentType = 'application/javascript';
        if (filePath.endsWith('.json')) contentType = 'application/json';
        if (filePath.endsWith('.png')) contentType = 'image/png';
        if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) contentType = 'image/jpeg';
        
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 sound-make-book روی پورت ${PORT} روشن شد`);
    console.log(`🌐 آدرس: http://localhost:${PORT}`);
});
