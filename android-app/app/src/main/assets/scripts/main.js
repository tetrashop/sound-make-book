// ==================== مدیریت وضعیت TTS ====================
function updateTtsStatus(status) {
    const statusDiv = document.getElementById('tts-status');
    if (!statusDiv) return;
    const messages = {
        'initializing': '⏳ در حال آماده‌سازی TTS...',
        'fa_ready': '✅ TTS فارسی آماده',
        'fa_missing': '⚠️ TTS فارسی موجود نیست، از انگلیسی استفاده می‌شود',
        'tts_unavailable': '❌ TTS در دسترس نیست',
        'failed': '❌ خطا در راه‌اندازی TTS',
        'timeout': '❌ زمان آماده‌سازی TPS به پایان رسید'
    };
    statusDiv.textContent = messages[status] || `⚠️ وضعیت ناشناخته: ${status}`;
    statusDiv.className = 'tts-status ' + status;
}

window.onTtsStatusUpdate = updateTtsStatus;

// ==================== مدیریت تب‌ها ====================
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        const tabId = btn.dataset.tab;
        document.getElementById(tabId).classList.add('active');
    });
});

// ==================== تشخیص خودکار زبان ====================
document.getElementById('detect-lang')?.addEventListener('click', () => {
    const text = document.getElementById('text-input').value;
    if (!text) return alert('لطفاً متن را وارد کنید');
    if (window.AndroidBridge) {
        window.AndroidBridge.detectLanguage(text);
    } else {
        alert('❌ پل ارتباطی با اندروید برقرار نیست');
    }
});

window.onLanguageDetected = function(lang) {
    const langMap = { fa: 'فارسی', en: 'انگلیسی' };
    document.getElementById('detected-lang').textContent = `زبان: ${langMap[lang] || lang}`;
};

// ==================== پیش‌نمایش صدا ====================
document.getElementById('preview-btn')?.addEventListener('click', () => {
    const text = document.getElementById('text-input').value;
    if (!text) return alert('متن را وارد کنید');
    if (window.AndroidBridge) {
        window.AndroidBridge.speak(text, 'preview_' + Date.now());
    } else {
        alert('❌ پل ارتباطی برقرار نیست');
    }
});

document.getElementById('stop-speak')?.addEventListener('click', () => {
    if (window.AndroidBridge) {
        window.AndroidBridge.stopSpeaking();
    }
});

window.onSpeechDone = function(utteranceId) {
    console.log('پخش تمام شد:', utteranceId);
};

window.onSpeechError = function(errorMsg) {
    alert('خطا در پخش صدا: ' + errorMsg);
};

// ==================== تولید نهایی (در اندروید غیرفعال) ====================
document.getElementById('generate-final')?.addEventListener('click', () => {
    alert('تولید کتاب صوتی کامل در نسخه اندروید پشتیبانی نمی‌شود. از نسخه وب استفاده کنید.');
});

// ==================== پروژه‌ها (ذخیره در localStorage) ====================
function cargarProyectos() {
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    const list = document.getElementById('project-list');
    if (!list) return;
    list.innerHTML = projects.map(p => `
        <div class="project-item">
            <span>${p.name} (${new Date(p.createdAt).toLocaleDateString('fa-IR')})</span>
            <button onclick="eliminarProyecto('${p.id}')">🗑️</button>
        </div>
    `).join('');
}

document.getElementById('refresh-projects')?.addEventListener('click', cargarProyectos);
cargarProyectos();

window.eliminarProyecto = function(id) {
    let projects = JSON.parse(localStorage.getItem('projects') || '[]');
    projects = projects.filter(p => p.id !== id);
    localStorage.setItem('projects', JSON.stringify(projects));
    cargarProyectos();
};

document.getElementById('save-project')?.addEventListener('click', () => {
    const name = document.getElementById('project-name').value;
    if (!name) return alert('نام پروژه را وارد کنید');
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    const newProject = {
        id: Date.now().toString(),
        name: name,
        createdAt: new Date().toISOString(),
        settings: {}
    };
    projects.push(newProject);
    localStorage.setItem('projects', JSON.stringify(projects));
    cargarProyectos();
    document.getElementById('project-name').value = '';
});

// ==================== تنظیمات پیشرفته (غیرفعال) ====================
document.getElementById('generate-advanced')?.addEventListener('click', () => {
    alert('تنظیمات پیشرفته در نسخه اندروید اعمال نمی‌شوند.');
});

// ==================== درخواست وضعیت TTS هنگام بارگذاری ====================
window.addEventListener('load', () => {
    if (window.AndroidBridge) {
        const status = window.AndroidBridge.getTtsStatus();
        updateTtsStatus(status);
    }
});
