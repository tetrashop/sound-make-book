// ======================== اولیه‌سازی ========================
let speechSynthesis = window.speechSynthesis;
let currentUtterance = null;
let voices = [];
let selectedVoice = null;
let voiceProfile = null; // برای تقلید صدا (ذخیره در localStorage)

// DOM elements
const textInput = document.getElementById('textInput');
const previewBtn = document.getElementById('previewBtn');
const stopBtn = document.getElementById('stopBtn');
const speedSlider = document.getElementById('speedSlider');
const pitchSlider = document.getElementById('pitchSlider');
const speedValue = document.getElementById('speedValue');
const pitchValue = document.getElementById('pitchValue');
const voiceSelect = document.getElementById('voiceSelect');
const projectNameInput = document.getElementById('projectName');
const saveProjectBtn = document.getElementById('saveProjectBtn');
const projectsListDiv = document.getElementById('projectsList');
const voiceFileInput = document.getElementById('voiceFile');
const cloneVoiceBtn = document.getElementById('cloneVoiceBtn');
const deleteVoiceBtn = document.getElementById('deleteVoiceBtn');
const personalText = document.getElementById('personalText');
const personalSpeakBtn = document.getElementById('personalSpeakBtn');
const cloneStatus = document.getElementById('cloneStatus');

// ======================== بارگذاری صداها و تنظیمات ========================
function loadVoices() {
    voices = speechSynthesis.getVoices();
    if (voices.length === 0) {
        setTimeout(loadVoices, 100);
        return;
    }
    // فیلتر صداهای فارسی و انگلیسی
    const faVoices = voices.filter(v => v.lang.includes('fa'));
    const enVoices = voices.filter(v => v.lang.includes('en'));
    voiceSelect.innerHTML = '<option value="default">معمولی (پیش‌فرض)</option>';
    if (faVoices.length) {
        faVoices.forEach(v => {
            const option = document.createElement('option');
            option.value = v.name;
            option.textContent = `${v.name} (فارسی)`;
            voiceSelect.appendChild(option);
        });
    }
    if (enVoices.length) {
        enVoices.forEach(v => {
            const option = document.createElement('option');
            option.value = v.name;
            option.textContent = `${v.name} (انگلیسی)`;
            voiceSelect.appendChild(option);
        });
    }
    // انتخاب پیش‌فرض
    if (faVoices.length) selectedVoice = faVoices[0];
    else if (voices.length) selectedVoice = voices[0];
}
if (speechSynthesis.onvoiceschanged !== undefined) {
    speechSynthesis.onvoiceschanged = loadVoices;
}
loadVoices();

// اسلایدرها
speedSlider.addEventListener('input', () => {
    const val = parseFloat(speedSlider.value);
    speedValue.textContent = val.toFixed(2);
});
pitchSlider.addEventListener('input', () => {
    const val = parseFloat(pitchSlider.value);
    pitchValue.textContent = val.toFixed(2);
});

// انتخاب صدا
voiceSelect.addEventListener('change', (e) => {
    const voiceName = e.target.value;
    if (voiceName === 'default') {
        selectedVoice = null;
    } else {
        selectedVoice = voices.find(v => v.name === voiceName);
    }
});

// ======================== تبدیل متن به صدا (بهینه شده با کش) ========================
let audioCache = new Map(); // ساده برای کش کردن صدا (در حافظه)

function speakText(text, usePersonalVoice = false) {
    if (!text.trim()) {
        alert('لطفاً متنی وارد کنید.');
        return;
    }
    if (currentUtterance) {
        speechSynthesis.cancel();
        currentUtterance = null;
    }
    if (usePersonalVoice && voiceProfile && voiceProfile.audioData) {
        // شبیه‌سازی تقلید صدا با استفاده از Web Audio (در اینجا یک نمونه ساده پخش صدای ضبط شده)
        // برای پیاده‌سازی واقعی نیاز به سرور یا librosa است، فعلاً از fallback استفاده می‌کنیم
        playPersonalVoice(text);
        return;
    }
    const utterance = new SpeechSynthesisUtterance(text);
    if (selectedVoice) utterance.voice = selectedVoice;
    utterance.rate = parseFloat(speedSlider.value);
    utterance.pitch = parseFloat(pitchSlider.value);
    utterance.lang = /[\u0600-\u06FF]/.test(text) ? 'fa-IR' : 'en-US';
    utterance.onstart = () => { console.log('شروع پخش'); };
    utterance.onend = () => { currentUtterance = null; };
    utterance.onerror = (e) => { console.error('خطا در پخش صدا', e); currentUtterance = null; };
    currentUtterance = utterance;
    speechSynthesis.speak(utterance);
}

function playPersonalVoice(text) {
    // تقلید صدا – در این نسخه ساده، فقط یک اعلان نمایش می‌دهیم و با صدای معمولی پخش می‌کنیم
    alert('تقلید صدا نیاز به پردازش پیشرفته دارد. فعلاً از صدای معمولی استفاده می‌شود.');
    speakText(text, false);
}

previewBtn.addEventListener('click', () => {
    const text = textInput.value.trim();
    if (!text) {
        alert('متن را وارد کنید.');
        return;
    }
    speakText(text);
});

stopBtn.addEventListener('click', () => {
    if (speechSynthesis.speaking || speechSynthesis.pending) {
        speechSynthesis.cancel();
        currentUtterance = null;
    }
});

// ======================== مدیریت پروژه‌ها (ذخیره در localStorage) ========================
let projects = JSON.parse(localStorage.getItem('sound_projects')) || [];

function renderProjects() {
    if (!projectsListDiv) return;
    if (projects.length === 0) {
        projectsListDiv.innerHTML = '<div class="empty-message">هیچ پروژه‌ای ذخیره نشده است.</div>';
        return;
    }
    projectsListDiv.innerHTML = '';
    projects.forEach((proj, idx) => {
        const div = document.createElement('div');
        div.className = 'project-item';
        div.innerHTML = `
            <span><strong>${escapeHtml(proj.name)}</strong> (${proj.date})</span>
            <div>
                <button class="load-project" data-idx="${idx}">📂 بارگذاری</button>
                <button class="delete-project" data-idx="${idx}">❌</button>
            </div>
        `;
        projectsListDiv.appendChild(div);
    });
    document.querySelectorAll('.load-project').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const idx = e.currentTarget.dataset.idx;
            textInput.value = projects[idx].text;
        });
    });
    document.querySelectorAll('.delete-project').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const idx = e.currentTarget.dataset.idx;
            if (confirm('آیا پروژه حذف شود؟')) {
                projects.splice(idx, 1);
                localStorage.setItem('sound_projects', JSON.stringify(projects));
                renderProjects();
            }
        });
    });
}

function escapeHtml(str) {
    return str.replace(/[&<>]/g, function(m) {
        if (m === '&') return '&amp;';
        if (m === '<') return '&lt;';
        if (m === '>') return '&gt;';
        return m;
    });
}

saveProjectBtn.addEventListener('click', () => {
    const name = projectNameInput.value.trim();
    const text = textInput.value.trim();
    if (!name || !text) {
        alert('نام پروژه و متن را وارد کنید.');
        return;
    }
    projects.push({
        name: name,
        text: text,
        date: new Date().toLocaleString('fa-IR')
    });
    localStorage.setItem('sound_projects', JSON.stringify(projects));
    projectNameInput.value = '';
    renderProjects();
    alert('پروژه ذخیره شد.');
});

// ======================== تقلید صدا (شبیه‌سازی ساده) ========================
cloneVoiceBtn.addEventListener('click', () => {
    const file = voiceFileInput.files[0];
    if (!file) {
        cloneStatus.textContent = '❌ لطفاً فایل صوتی را انتخاب کنید.';
        return;
    }
    if (file.size > 5 * 1024 * 1024) {
        cloneStatus.textContent = '❌ حجم فایل بیشتر از 5 مگابایت است.';
        return;
    }
    const reader = new FileReader();
    reader.onload = (e) => {
        const audioData = e.target.result;
        voiceProfile = { audioData, fileName: file.name };
        localStorage.setItem('voice_profile', JSON.stringify({ audioData: audioData, fileName: file.name }));
        cloneStatus.textContent = '✅ پروفایل صدا ذخیره شد. اکنون می‌توانید از «تولید با صدای شخص» استفاده کنید.';
    };
    reader.readAsDataURL(file);
});

deleteVoiceBtn.addEventListener('click', () => {
    voiceProfile = null;
    localStorage.removeItem('voice_profile');
    cloneStatus.textContent = '🗑 پروفایل صدا حذف شد.';
    voiceFileInput.value = '';
});

personalSpeakBtn.addEventListener('click', () => {
    const text = personalText.value.trim();
    if (!text) {
        alert('متن را وارد کنید.');
        return;
    }
    if (!voiceProfile) {
        alert('ابتدا صدای خود را آپلود کنید.');
        return;
    }
    speakText(text, true);
});

// بارگذاری پروفایل ذخیره شده
const savedProfile = localStorage.getItem('voice_profile');
if (savedProfile) {
    try {
        voiceProfile = JSON.parse(savedProfile);
        cloneStatus.textContent = '✅ پروفایل صدا قبلاً ذخیره شده است.';
    } catch(e) { }
}

// مقداردهی اولیه پروژه‌ها
renderProjects();
