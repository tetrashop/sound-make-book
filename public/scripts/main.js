// ==================== مدیریت وضعیت ====================
let appState = {
    currentStep: 1,
    extractedText: '',
    textChunks: [],
    selectedVoice: null,
    audioSettings: {
        backgroundMusic: 'none',
        musicVolume: 0.3,
        speechRate: 1.0,
        pitch: 0
    }
};

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

// ==================== ویرایشگر متن ====================
const textInput = document.getElementById('text-input');
const charCount = document.getElementById('char-count');
const wordCount = document.getElementById('word-count');

if (textInput) {
    textInput.addEventListener('input', updateTextStats);
}

function updateTextStats() {
    if (!textInput) return;
    const text = textInput.value;
    const chars = text.length;
    const words = text.split(/\s+/).filter(w => w.length > 0).length;
    
    if (charCount) charCount.textContent = chars.toLocaleString('fa-IR');
    if (wordCount) wordCount.textContent = words.toLocaleString('fa-IR');
}

// ==================== تولید صدا با Web Speech API ====================
document.getElementById('preview-btn')?.addEventListener('click', () => {
    const text = textInput?.value;
    if (!text) {
        alert('لطفاً متن را وارد کنید');
        return;
    }

    const statusDiv = document.getElementById('tts-status');
    if (statusDiv) statusDiv.textContent = '🔄 در حال پخش...';

    if (!window.speechSynthesis) {
        if (statusDiv) statusDiv.textContent = '❌ مرورگر شما پشتیبانی نمی‌کند';
        return;
    }

    window.speechSynthesis.cancel();

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'fa-IR';
    utterance.rate = parseFloat(document.getElementById('speech-rate')?.value || 1);
    utterance.pitch = parseFloat(document.getElementById('pitch')?.value || 1);

    // تنظیم صدا
    const voices = window.speechSynthesis.getVoices();
    const persianVoice = voices.find(v => v.lang.includes('fa') || v.lang.includes('ar'));
    if (persianVoice) utterance.voice = persianVoice;

    utterance.onstart = () => {
        if (statusDiv) statusDiv.textContent = '🔊 در حال پخش...';
    };

    utterance.onend = () => {
        if (statusDiv) statusDiv.textContent = '✅ پخش تمام شد';
    };

    utterance.onerror = (event) => {
        if (statusDiv) statusDiv.textContent = '❌ خطا: ' + event.error;
    };

    window.speechSynthesis.speak(utterance);
});

document.getElementById('stop-speak')?.addEventListener('click', () => {
    window.speechSynthesis?.cancel();
    const statusDiv = document.getElementById('tts-status');
    if (statusDiv) statusDiv.textContent = '⏹️ پخش متوقف شد';
});

// ==================== تشخیص خودکار زبان ====================
document.getElementById('detect-lang')?.addEventListener('click', () => {
    const text = textInput?.value;
    if (!text) {
        alert('لطفاً متن را وارد کنید');
        return;
    }

    const hasPersian = /[\u0600-\u06FF]/.test(text);
    const hasEnglish = /[a-zA-Z]/.test(text);
    const detectedLang = document.getElementById('detected-lang');

    if (hasPersian && hasEnglish) {
        detectedLang.textContent = 'زبان: ترکیبی (فارسی/انگلیسی)';
    } else if (hasPersian) {
        detectedLang.textContent = 'زبان: فارسی';
    } else if (hasEnglish) {
        detectedLang.textContent = 'زبان: انگلیسی';
    } else {
        detectedLang.textContent = 'زبان نامشخص';
    }
});

// ==================== تنظیمات پیشرفته ====================
const speechRate = document.getElementById('speech-rate');
const rateDisplay = document.getElementById('rate-display');
const pitch = document.getElementById('pitch');
const pitchDisplay = document.getElementById('pitch-display');

if (speechRate) {
    speechRate.addEventListener('input', () => {
        if (rateDisplay) rateDisplay.textContent = speechRate.value + 'x';
    });
}

if (pitch) {
    pitch.addEventListener('input', () => {
        if (pitchDisplay) pitchDisplay.textContent = pitch.value;
    });
}

// ==================== پروژه‌ها (ذخیره در localStorage) ====================
function loadProjects() {
    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    const list = document.getElementById('project-list');
    if (!list) return;

    if (projects.length === 0) {
        list.innerHTML = '<p class="feature-note">📭 پروژه‌ای ذخیره نشده است</p>';
        return;
    }

    list.innerHTML = projects.map(p => `
        <div class="project-item">
            <span>📁 ${p.name}</span>
            <span>${new Date(p.createdAt).toLocaleDateString('fa-IR')}</span>
            <button class="btn" onclick="deleteProject('${p.id}')" style="background:#ef4444; color:white; border:none;">🗑️ حذف</button>
        </div>
    `).join('');
}

window.deleteProject = function(id) {
    let projects = JSON.parse(localStorage.getItem('projects') || '[]');
    projects = projects.filter(p => p.id !== id);
    localStorage.setItem('projects', JSON.stringify(projects));
    loadProjects();
};

document.getElementById('save-project')?.addEventListener('click', () => {
    const name = document.getElementById('project-name')?.value;
    if (!name) {
        alert('نام پروژه را وارد کنید');
        return;
    }

    const projects = JSON.parse(localStorage.getItem('projects') || '[]');
    const newProject = {
        id: Date.now().toString(),
        name: name,
        createdAt: new Date().toISOString(),
        settings: appState.audioSettings
    };
    
    projects.push(newProject);
    localStorage.setItem('projects', JSON.stringify(projects));
    loadProjects();
    if (document.getElementById('project-name')) document.getElementById('project-name').value = '';
});

document.getElementById('refresh-projects')?.addEventListener('click', loadProjects);

// بارگذاری اولیه
document.addEventListener('DOMContentLoaded', () => {
    updateTextStats();
    loadProjects();
    
    // نمایش وضعیت اولیه TTS
    const statusDiv = document.getElementById('tts-status');
    if (statusDiv) {
        if (window.speechSynthesis) {
            statusDiv.textContent = '✅ آماده به کار';
        } else {
            statusDiv.textContent = '⚠️ Web Speech API در دسترس نیست';
        }
    }
});
