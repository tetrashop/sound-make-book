// مدیریت تب‌ها
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(btn.dataset.tab).classList.add('active');
    });
});

// پیش‌نمایش با Web Speech API (مرورگر)
const previewBtn = document.getElementById('preview-btn');
const stopBtn = document.getElementById('stop-speak');
if (previewBtn) {
    previewBtn.addEventListener('click', () => {
        const text = document.getElementById('text-input').value;
        if (!text) return alert('متن را وارد کنید');
        if (!window.speechSynthesis) return alert('مرورگر پشتیبانی نمی‌کند');
        window.speechSynthesis.cancel();
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.lang = 'fa-IR';
        utterance.rate = 1;
        utterance.pitch = 1;
        window.speechSynthesis.speak(utterance);
    });
}
if (stopBtn) {
    stopBtn.addEventListener('click', () => window.speechSynthesis?.cancel());
}

// صدای متنوع با سرور (eSpeak)
const voiceTypeMap = {
    normal: { speed: 1.0, pitch: 50 },
    low:    { speed: 0.9, pitch: 30 },
    high:   { speed: 1.1, pitch: 70 },
    fast:   { speed: 1.5, pitch: 50 },
    slow:   { speed: 0.7, pitch: 50 }
};

const varietyBtn = document.getElementById('preview-variety-btn');
if (varietyBtn) {
    varietyBtn.addEventListener('click', async () => {
        const text = document.getElementById('variety-text').value;
        if (!text) return alert('متن را وارد کنید');
        const type = document.getElementById('voice-type').value;
        const { speed, pitch } = voiceTypeMap[type];
        const statusDiv = document.getElementById('variety-status');
        statusDiv.innerHTML = '⏳ در حال تولید صدا...';
        try {
            const res = await fetch('/api/synthesize-custom', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text, voice: 'fa', rate: speed, pitch })
            });
            const data = await res.json();
            if (res.ok) {
                statusDiv.innerHTML = `<audio controls autoplay src="${data.url}"></audio>`;
            } else {
                statusDiv.innerHTML = '❌ خطا: ' + (data.error || 'مشکل در سرور');
            }
        } catch (err) {
            statusDiv.innerHTML = '❌ خطا در ارتباط با سرور';
        }
    });
}

// مدیریت ساده پروژه‌ها (localStorage)
function loadProjects() {
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    const list = document.getElementById('project-list');
    if (list) {
        list.innerHTML = projects.map(p => `<div>📁 ${p.name} (${new Date(p.createdAt).toLocaleDateString('fa-IR')})</div>`).join('');
    }
}
document.getElementById('save-project')?.addEventListener('click', () => {
    const name = document.getElementById('project-name')?.value;
    if (!name) return alert('نام پروژه را وارد کنید');
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    projects.push({ id: Date.now(), name, createdAt: new Date().toISOString() });
    localStorage.setItem('projects', JSON.stringify(projects));
    loadProjects();
    document.getElementById('project-name').value = '';
});
loadProjects();
