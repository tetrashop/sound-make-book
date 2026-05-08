#!/bin/bash

echo "🔧 تعمیر قابلیت «صدای متنوع»..."

cd ~/sound-make-book

# 1. توقف سرور
pkill -f node 2>/dev/null
sleep 1

# 2. اطمینان از وجود endpoint در api/index.js
if ! grep -q "/api/synthesize-custom" api/index.js; then
    echo "➕ افزودن مسیر /api/synthesize-custom به api/index.js..."
    sed -i '/app.post("\/api\/synthesize"/a \
\
app.post("/api/synthesize-custom", async (req, res) => {\
    const { text, voice = "fa", rate = 1.0, pitch = 50 } = req.body;\
    if (!text) return res.status(400).json({ error: "text required" });\
    try {\
        const result = await advancedTTS.enqueue(text, { voice, rate, pitch });\
        res.json({ url: result.url });\
    } catch(err) {\
        res.status(500).json({ error: err.message });\
    }\
});' api/index.js
fi

# 3. بازنویسی کامل بخش صدای متنوع در public/index.html
echo "📄 تصحیح تب صدای متنوع در index.html..."
# حذف بخش قبلی اگر خراب باشد
sed -i '/<section id="voice-variety"/,/<\/section>/d' public/index.html
# اضافه کردن بخش جدید و سالم
cat >> public/index.html << 'HTML'
<section id="voice-variety" class="tab-content">
    <div class="card">
        <h2>🎭 انتخاب صدای متنوع (بدون اینترنت)</h2>
        <p>با تغییر زیر و بم و سرعت، صداهای مختلف را بشنوید.</p>
        <div class="voice-options">
            <label>🎙️ نوع صدا:</label>
            <select id="voice-type">
                <option value="normal">معمولی</option>
                <option value="low">بم (عمیق)</option>
                <option value="high">زیر (کودکانه)</option>
                <option value="fast">سریع</option>
                <option value="slow">آهسته</option>
            </select>
        </div>
        <textarea id="variety-text" placeholder="متن خود را وارد کنید..." rows="5"></textarea>
        <button id="preview-variety-btn" class="btn btn-primary">🎙️ تست صدا</button>
        <div id="variety-status" style="margin-top:15px"></div>
    </div>
</section>
HTML

# 4. اطمینان از وجود دکمه در نوار تب‌ها
if ! grep -q 'data-tab="voice-variety"' public/index.html; then
    sed -i '/<nav class="tabs">/a \                <button class="tab-btn" data-tab="voice-variety">🎭 صدای متنوع</button>' public/index.html
fi

# 5. بازنویسی کد جاوااسکریپت مربوط به صدای متنوع در main.js
echo "📜 تصحیح کد جاوااسکریپت..."
# حذف کدهای قدیمی صدای متنوع
sed -i '/\/\/ =============== صدای متنوع ===============/,/\/\/ ===============/d' public/scripts/main.js
# اضافه کردن کد جدید
cat >> public/scripts/main.js << 'JS'

// =============== صدای متنوع (نسخه تعمیر شده) ===============
document.addEventListener('DOMContentLoaded', () => {
    const previewBtn = document.getElementById('preview-variety-btn');
    if (!previewBtn) {
        console.warn("دکمه preview-variety-btn پیدا نشد");
        return;
    }
    previewBtn.addEventListener('click', async () => {
        const text = document.getElementById('variety-text').value;
        if (!text) {
            alert('لطفاً متن را وارد کنید');
            return;
        }
        const voiceType = document.getElementById('voice-type').value;
        const config = {
            normal: { speed: 1.0, pitch: 50 },
            low:    { speed: 0.9, pitch: 30 },
            high:   { speed: 1.1, pitch: 70 },
            fast:   { speed: 1.5, pitch: 50 },
            slow:   { speed: 0.7, pitch: 50 }
        }[voiceType];
        const statusDiv = document.getElementById('variety-status');
        statusDiv.innerHTML = '⏳ در حال تولید صدا...';
        try {
            const response = await fetch('/api/synthesize-custom', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text, rate: config.speed, pitch: config.pitch })
            });
            const data = await response.json();
            if (response.ok) {
                statusDiv.innerHTML = `<audio controls autoplay src="${data.url}"></audio>`;
            } else {
                statusDiv.innerHTML = '❌ خطا: ' + (data.error || 'مشکل در سرور');
            }
        } catch (err) {
            console.error(err);
            statusDiv.innerHTML = '❌ خطا در ارتباط با سرور (آیا سرور روشن است؟)';
        }
    });
});
JS

# 6. راه‌اندازی مجدد سرور روی پورت 3001 (برای جلوگیری از conflict)
echo "🚀 راه‌اندازی سرور روی پورت 3001..."
PORT=3001 node api/index.js &
sleep 3

echo ""
echo "✅ تعمیر کامل شد!"
echo "🔗 اکنون مرورگر را باز کنید: http://localhost:3001"
echo "به تب «صدای متنوع» بروید، متنی بنویسید و دکمه «تست صدا» را بزنید."
echo "اگر صدا پخش شد، مشکل حل شده است."
