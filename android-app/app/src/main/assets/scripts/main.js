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
  if (!text) {
    alert('لطفاً متن را وارد کنید');
    return;
  }
  // فراخوانی تابع جاوا
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

// ==================== پیش‌نمایش صدا (با TTS اندروید) ====================
document.getElementById('preview-btn')?.addEventListener('click', () => {
  const text = document.getElementById('text-input').value;
  if (!text) {
    alert('لطفاً متن را وارد کنید');
    return;
  }
  const utteranceId = 'preview_' + Date.now();
  if (window.AndroidBridge) {
    window.AndroidBridge.speak(text, utteranceId);
  } else {
    alert('خطا: پل ارتباطی با اندروید برقرار نیست');
  }
});

document.getElementById('stop-speak')?.addEventListener('click', () => {
  if (window.AndroidBridge) {
    window.AndroidBridge.stopSpeaking();
  }
});

// ==================== OCR (غیرفعال) ====================
document.getElementById('ocr-extract')?.addEventListener('click', () => {
  alert('قابلیت OCR در این نسخه غیرفعال است. از نسخه وب با سرور Node.js استفاده کنید.');
});

// ==================== پروژه‌ها (ذخیره‌سازی موقت) ====================
async function cargarProyectos() {
  // در نسخه اندروید، از localStorage استفاده می‌کنیم
  const projects = JSON.parse(localStorage.getItem('projects') || '[]');
  const list = document.getElementById('project-list');
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

// ذخیره پروژه
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
});

// ==================== تنظیمات پیشرفته (اعمال روی TTS) ====================
// (در نسخه فعلی، تنظیمات مستقیماً روی TTS اعمال نمی‌شود. می‌توان بعداً پیاده‌سازی کرد)
document.getElementById('generate-advanced')?.addEventListener('click', () => {
  alert('تنظیمات پیشرفته در این نسخه فعال نیست. از نسخه وب استفاده کنید.');
});
