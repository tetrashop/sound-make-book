// مدیریت تب‌ها
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(btn.dataset.tab).classList.add('active');
    });
});

// =============== صدای متنوع (نسخه نهایی) ===============
document.addEventListener('DOMContentLoaded', () => {
    const previewBtn = document.getElementById('preview-variety-btn');
    if (previewBtn) {
        previewBtn.addEventListener('click', async () => {
            const text = document.getElementById('variety-text')?.value;
            if (!text) { alert('متن را وارد کنید'); return; }
            const type = document.getElementById('voice-type')?.value || 'normal';
            const config = {
                normal: { speed: 1.0, pitch: 50 },
                low:    { speed: 0.9, pitch: 30 },
                high:   { speed: 1.1, pitch: 70 },
                fast:   { speed: 1.5, pitch: 50 },
                slow:   { speed: 0.7, pitch: 50 }
            };
            const { speed, pitch } = config[type];
            const statusDiv = document.getElementById('variety-status');
            statusDiv.innerHTML = '⏳ در حال تولید صدا...';
            try {
                const res = await fetch('/api/synthesize-custom', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ text, rate: speed, pitch })
                });
                const data = await res.json();
                if (res.ok && data.url) {
                    statusDiv.innerHTML = `<audio controls autoplay src="${data.url}"></audio>`;
                } else {
                    statusDiv.innerHTML = '❌ خطا: ' + (data.error || 'مشکل در سرور');
                }
            } catch(e) {
                statusDiv.innerHTML = '❌ خطا در ارتباط با سرور';
            }
        });
    }
});

// پروژه‌ها
function loadProjects() {
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    const list = document.getElementById('project-list');
    if (list) {
        list.innerHTML = projects.length ? projects.map(p => `<div>📁 ${p.name}</div>`).join('') : '<p>هیچ پروژه‌ای نیست</p>';
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
