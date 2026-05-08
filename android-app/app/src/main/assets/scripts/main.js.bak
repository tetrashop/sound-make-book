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
  // تشخیص ساده (در نسخه واقعی با API انجام می‌شود)
  const hasEnglish = /[a-zA-Z]/.test(text);
  const hasPersian = /[\u0600-\u06FF]/.test(text);
  
  let detected = 'نامشخص';
  if (hasPersian && !hasEnglish) detected = 'فارسی';
  else if (hasEnglish && !hasPersian) detected = 'انگلیسی';
  else if (hasPersian && hasEnglish) detected = 'ترکیبی (فارسی/انگلیسی)';
  
  document.getElementById('detected-lang').textContent = `زبان تشخیص‌داده‌شده: ${detected}`;
});

// ==================== OCR (شبیه‌سازی) ====================
document.getElementById('ocr-upload')?.addEventListener('click', () => {
  document.getElementById('ocr-file').click();
});

document.getElementById('ocr-file')?.addEventListener('change', function(e) {
  if (e.target.files[0]) {
    alert('⚠️ در حالت فایل محلی، OCR واقعی کار نمی‌کند.\nبرای تست، یک متن آزمایشی در کادر متن قرار داده می‌شود.');
    document.getElementById('text-input').value = 'این یک متن آزمایشی است که از تصویر استخراج شده است.\nدر نسخه سرور محلی با Node.js، OCR واقعی با Tesseract کار می‌کند.';
  }
});

// ==================== پیش‌نمایش صدا (شبیه‌سازی) ====================
document.getElementById('preview-btn')?.addEventListener('click', () => {
  const text = document.getElementById('text-input').value;
  if (!text) {
    alert('لطفاً متن را وارد کنید');
    return;
  }
  
  alert('🔊 در حالت فایل محلی، پیش‌نمایش صدا فقط با سرور Node.js کار می‌کند.\nبرای استفاده از قابلیت‌های کامل، سرور را با دستور "node api/index.js" اجرا کنید.');
});

// ==================== تولید نهایی (شبیه‌سازی) ====================
document.getElementById('generate-final')?.addEventListener('click', () => {
  const text = document.getElementById('text-input').value;
  if (!text) {
    alert('لطفاً متن را وارد کنید');
    return;
  }
  
  document.getElementById('progress').style.display = 'block';
  document.getElementById('progress').textContent = '⏳ در حال اتصال به سرور...';
  
  setTimeout(() => {
    document.getElementById('progress').style.display = 'none';
    alert('⚠️ در حالت فایل محلی، تولید صدا فقط با سرور Node.js کار می‌کند.\nبرای استفاده از قابلیت‌های کامل، سرور را با دستور "node api/index.js" اجرا کنید.');
  }, 1500);
});

// ==================== بخش چندصدایی (شبیه‌سازی) ====================
let segmentCount = 1;
document.getElementById('add-segment')?.addEventListener('click', () => {
  const container = document.getElementById('segments');
  const div = document.createElement('div');
  div.innerHTML = `
    <h4>بخش ${segmentCount}</h4>
    <textarea class="segment-text" placeholder="متن این بخش..." rows="3"></textarea>
    <select class="segment-voice">
      <option value="fa">فارسی</option>
      <option value="en">انگلیسی</option>
    </select>
    <button class="remove-segment btn" style="background:#ef4444; color:white; border:none; padding:5px 10px;">✖ حذف</button>
  `;
  container.appendChild(div);
  
  div.querySelector('.remove-segment').addEventListener('click', () => div.remove());
  segmentCount++;
});

document.getElementById('generate-multi')?.addEventListener('click', () => {
  alert('⚠️ در حالت فایل محلی، تولید چندصدایی فقط با سرور Node.js کار می‌کند.');
});

// ==================== پروژه‌ها (شبیه‌سازی) ====================
function cargarProyectos() {
  const list = document.getElementById('project-list');
  // در حالت فایل محلی، پروژه‌های آزمایشی نمایش داده می‌شوند
  list.innerHTML = `
    <div class="project-item">
      <span>📁 پروژه آزمایشی ۱</span>
      <audio controls src=""></audio>
      <button onclick="alert('در حالت فایل محلی، این قابلیت غیرفعال است.')">🗑️ حذف</button>
    </div>
    <div class="project-item">
      <span>📁 پروژه آزمایشی ۲</span>
      <audio controls src=""></audio>
      <button onclick="alert('در حالت فایل محلی، این قابلیت غیرفعال است.')">🗑️ حذف</button>
    </div>
    <p style="color: #ef4444; margin-top: 10px;">⚠️ برای ذخیره و مدیریت واقعی پروژه‌ها، سرور Node.js را اجرا کنید.</p>
  `;
}

document.getElementById('refresh-projects')?.addEventListener('click', cargarProyectos);
cargarProyectos();

// ==================== تنظیمات پیشرفته (شبیه‌سازی) ====================
document.getElementById('generate-advanced')?.addEventListener('click', () => {
  const text = document.getElementById('text-input').value;
  if (!text) {
    alert('لطفاً متن را وارد کنید');
    return;
  }
  
  const speed = document.getElementById('speed').value;
  const pitch = document.getElementById('pitch').value;
  const gap = document.getElementById('gap').value;
  
  alert(`🔧 تنظیمات پیشرفته:\nسرعت: ${speed}\nزیر و بم: ${pitch}\nفاصله: ${gap}\n\n⚠️ تولید واقعی با این تنظیمات فقط با سرور Node.js کار می‌کند.`);
});

// ==================== هشدار اولیه ====================
window.addEventListener('load', () => {
  console.log('⚠️ sound-make-book در حالت فایل محلی اجرا شده است.');
  console.log('✅ برای استفاده از تمام ۹ قابلیت، سرور را با دستور "node api/index.js" اجرا کنید.');
  console.log('🌐 سپس به آدرس http://localhost:3000 بروید.');
});
