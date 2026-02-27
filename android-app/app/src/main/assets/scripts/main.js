console.log("✅ main.js loaded");
alert("✅ JavaScript loaded");
window.testBridge = function() {
    if (window.AndroidBridge) {
        alert("✅ AndroidBridge found");
        window.AndroidBridge.speak("تست", "test_id");
    } else {
        alert("❌ AndroidBridge NOT found");
    }
}
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

// ==================== بررسی وضعیت TTS هنگام بارگذاری ====================
window.addEventListener('load', () => {
  if (window.AndroidBridge) {
    const status = window.AndroidBridge.getTtsStatus();
    const statusDiv = document.createElement('div');
    statusDiv.style.position = 'fixed';
    statusDiv.style.bottom = '10px';
    statusDiv.style.left = '10px';
    statusDiv.style.background = '#f0f0f0';
    statusDiv.style.padding = '5px 10px';
    statusDiv.style.borderRadius = '5px';
    statusDiv.style.fontSize = '12px';
    statusDiv.style.zIndex = '9999';
    statusDiv.id = 'tts-status';
    document.body.appendChild(statusDiv);

    if (status === 'ready_fa') {
      statusDiv.innerHTML = '✅ TTS فارسی آماده';
      statusDiv.style.background = '#d4edda';
    } else if (status === 'ready_en') {
      statusDiv.innerHTML = '⚠️ TTS فارسی موجود نیست، از انگلیسی استفاده می‌شود';
      statusDiv.style.background = '#fff3cd';
    } else if (status === 'unsupported') {
      statusDiv.innerHTML = '❌ TTS روی گوشی نصب نیست';
      statusDiv.style.background = '#f8d7da';
    } else {
      statusDiv.innerHTML = '⏳ TTS در حال آماده‌سازی...';
    }
  } else {
    alert('خطا: پل ارتباطی با اندروید برقرار نیست');
  }
});

// ==================== تشخیص خودکار زبان ====================
document.getElementById('detect-lang')?.addEventListener('click', () => {
  const text = document.getElementById('text-input').value;
  if (!text) {
    alert('لطفاً متن را وارد کنید');
    return;
  }
  if (window.AndroidBridge) {
    window.AndroidBridge.detectLanguage(text);
  } else {
    alert('خطا: پل ارتباطی با اندروید برقرار نیست');
  }
});

window.onLanguageDetected = function(lang) {
  const langMap = { fa: 'فارسی', en: 'انگلیسی' };
  document.getElementById('detected-lang').textContent = `زبان تشخیص‌داده‌شده: ${langMap[lang] || lang}`;
};

// ==================== پیش‌نمایش صدا ====================
document.getElementById('preview-btn')?.addEventListener('click', () => {
  const text = document.getElementById('text-input').value;
  if (!text) {
    alert('لطفاً متن را وارد کنید');
    return;
  }
  const utteranceId = 'preview_' + Date.now();
  if (window.AndroidBridge) {
    // نمایش پیام در حال پخش
    const statusDiv = document.getElementById('tts-status') || document.createElement('div');
    statusDiv.innerHTML = '🔊 در حال پخش صدا...';
    statusDiv.style.background = '#cce5ff';
    window.AndroidBridge.speak(text, utteranceId);
  } else {
    alert('خطا: پل ارتباطی با اندروید برقرار نیست');
  }
});

window.onSpeechDone = function(utteranceId) {
  const statusDiv = document.getElementById('tts-status');
  if (statusDiv) {
    statusDiv.innerHTML = '✅ پخش تمام شد';
    statusDiv.style.background = '#d4edda';
    setTimeout(() => {
      if (window.AndroidBridge) {
        const status = window.AndroidBridge.getTtsStatus();
        if (status === 'ready_fa') {
          statusDiv.innerHTML = '✅ TTS فارسی آماده';
        } else if (status === 'ready_en') {
          statusDiv.innerHTML = '⚠️ TTS فارسی موجود نیست، از انگلیسی استفاده می‌شود';
        } else {
          statusDiv.innerHTML = '✅ TTS آماده';
        }
      }
    }, 2000);
  }
};

window.onSpeechError = function(errorMsg) {
  const statusDiv = document.getElementById('tts-status');
  if (statusDiv) {
    statusDiv.innerHTML = '❌ خطا: ' + errorMsg;
    statusDiv.style.background = '#f8d7da';
  }
  alert('خطا در پخش صدا: ' + errorMsg);
};

document.getElementById('stop-speak')?.addEventListener('click', () => {
  if (window.AndroidBridge) {
    window.AndroidBridge.stopSpeaking();
    const statusDiv = document.getElementById('tts-status');
    if (statusDiv) statusDiv.innerHTML = '⏹️ پخش متوقف شد';
  }
});

// ==================== پروژه‌ها ====================
async function cargarProyectos() {
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
