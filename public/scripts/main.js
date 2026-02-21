// مدیریت تب‌ها
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById(btn.dataset.tab).classList.add('active');
  });
});

// تشخیص خودکار زبان
document.getElementById('detect-lang')?.addEventListener('click', async () => {
  const text = document.getElementById('text-input').value;
  if (!text) return alert('متن را وارد کنید');
  const res = await fetch('/api/detect-language', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text })
  });
  const data = await res.json();
  document.getElementById('detected-lang').innerText = `زبان: ${data.language}`;
});

// OCR
document.getElementById('ocr-upload')?.addEventListener('click', () => {
  document.getElementById('ocr-file').click();
});
document.getElementById('ocr-file')?.addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const formData = new FormData();
  formData.append('image', file);
  const res = await fetch('/api/ocr', { method: 'POST', body: formData });
  const data = await res.json();
  if (data.success) document.getElementById('text-input').value = data.text;
  else alert('خطا در OCR');
});

// پیش‌نمایش صدا
document.getElementById('preview-btn')?.addEventListener('click', async () => {
  const text = document.getElementById('text-input').value;
  if (!text) return alert('متن را وارد کنید');
  const res = await fetch('/api/preview', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text, voice: 'fa', settings: {} })
  });
  const data = await res.json();
  if (data.success) {
    const audio = document.getElementById('preview-audio');
    audio.src = data.previewUrl;
    audio.play();
  }
});

// تولید نهایی
document.getElementById('generate-final')?.addEventListener('click', async () => {
  const text = document.getElementById('text-input').value;
  const music = document.getElementById('music-type').value;
  const volume = document.getElementById('music-volume').value;
  if (!text) return alert('متن را وارد کنید');
  document.getElementById('progress').style.display = 'block';
  const res = await fetch('/api/generate-multi-voice', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      segments: [{ text, voice: 'fa', music: music !== 'none' ? music : null, musicVolume: volume }]
    })
  });
  const data = await res.json();
  document.getElementById('progress').style.display = 'none';
  if (data.success) {
    const audio = document.getElementById('preview-audio');
    audio.src = data.audioUrl;
    audio.play();
    // ذخیره خودکار در پروژه‌ها
    await fetch('/api/projects', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'پروژه جدید', audioUrl: data.audioUrl, settings: {} })
    });
    cargarProyectos();
  } else alert('خطا: ' + data.error);
});

// بخش چندصدایی
let segmentCount = 1;
document.getElementById('add-segment')?.addEventListener('click', () => {
  const div = document.createElement('div');
  div.innerHTML = `
    <h4>بخش ${segmentCount++}</h4>
    <textarea class="segment-text" placeholder="متن این بخش..."></textarea>
    <select class="segment-voice"><option value="fa">فارسی</option><option value="en">انگلیسی</option></select>
    <input type="file" class="segment-music" accept="audio/*">
  `;
  document.getElementById('segments').appendChild(div);
});

document.getElementById('generate-multi')?.addEventListener('click', async () => {
  const segments = [];
  document.querySelectorAll('#segments > div').forEach(div => {
    const text = div.querySelector('.segment-text').value;
    const voice = div.querySelector('.segment-voice').value;
    segments.push({ text, voice, music: null });
  });
  if (!segments.length) return alert('بخشی ایجاد نشده');
  const res = await fetch('/api/generate-multi-voice', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ segments })
  });
  const data = await res.json();
  if (data.success) {
    alert('فایل تولید شد!');
    document.getElementById('preview-audio').src = data.audioUrl;
  }
});

// پروژه‌ها
async function cargarProyectos() {
  const res = await fetch('/api/projects');
  const data = await res.json();
  const list = document.getElementById('project-list');
  list.innerHTML = data.projects.map(p => `
    <div class="project-item">
      <span>${p.name} (${new Date(p.createdAt).toLocaleDateString('fa-IR')})</span>
      <audio controls src="${p.audioUrl}"></audio>
      <button onclick="eliminarProyecto('${p.id}')">🗑️</button>
    </div>
  `).join('');
}
document.getElementById('refresh-projects')?.addEventListener('click', cargarProyectos);
cargarProyectos();

window.eliminarProyecto = async (id) => {
  await fetch(`/api/projects/${id}`, { method: 'DELETE' });
  cargarProyectos();
};

// تنظیمات پیشرفته
document.getElementById('generate-advanced')?.addEventListener('click', async () => {
  const text = document.getElementById('text-input').value;
  const speed = document.getElementById('speed').value;
  const pitch = document.getElementById('pitch').value;
  const gap = document.getElementById('gap').value;
  if (!text) return alert('متن را وارد کنید');
  const res = await fetch('/api/generate-advanced', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text, voice: 'fa', speed, pitch, gap })
  });
  const data = await res.json();
  if (data.success) {
    document.getElementById('preview-audio').src = data.audioUrl;
    document.getElementById('preview-audio').play();
  }
});
