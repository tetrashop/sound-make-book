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
