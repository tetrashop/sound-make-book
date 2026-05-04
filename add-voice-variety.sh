#!/bin/bash
set -e
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🎧 افزودن قابلیت انتخاب صدای متنوع (بدون نیاز به اینترنت)...${NC}"

# اضافه کردن تب جدید به index.html اگر قبلاً voice-clone اضافه شده بود، آن را جایگزین می‌کنیم
# ابتدا اگر تب voice-clone وجود دارد آن را حذف می‌کنیم (اختیاری)
sed -i '/<section id="voice-clone"/,/<\/section>/d' public/index.html
sed -i '/<button class="tab-btn" data-tab="voice-clone">/d' public/index.html

# اضافه کردن تب جدید "صدای متنوع"
sed -i '/<section id="settings"/i \
<section id="voice-variety" class="tab-content">\
    <div class="card">\
        <h2>🎭 انتخاب صدای متنوع (بدون اینترنت)</h2>\
        <p>از بین صداهای مختلف با تغییر زیر و بم و سرعت انتخاب کنید. این قابلیت کاملاً داخلی است و به هیچ API خارجی نیاز ندارد.</p>\
        <div class="voice-options">\
            <label>🎙️ نوع صدا:</label>\
            <select id="voice-type">\
                <option value="normal">معمولی (پیش‌فرض)</option>\
                <option value="low">بم (عمیق)</option>\
                <option value="high">زیر (کودکانه)</option>\
                <option value="fast">سریع</option>\
                <option value="slow">آهسته و شمرده</option>\
            </select>\
        </div>\
        <textarea id="variety-text" placeholder="متن خود را وارد کنید..." rows="5"></textarea>\
        <button id="preview-variety-btn" class="btn btn-primary">🎙️ تست صدا</button>\
        <div id="variety-status" style="margin-top:15px"></div>\
    </div>\
</section>' public/index.html

# اضافه کردن دکمه تب به نوار tabs
sed -i '/<button class="tab-btn" data-tab="settings">/i <button class="tab-btn" data-tab="voice-variety">🎭 صدای متنوع</button>' public/index.html

# اضافه کردن کد جاوااسکریپت به انتهای main.js
cat >> public/scripts/main.js << 'EOFJS'

// =============== تنوع صدا با eSpeak (بدون اینترنت) ===============
const voiceTypeMap = {
    normal: { speed: 1.0, pitch: 50 },
    low:    { speed: 0.9, pitch: 30 },
    high:   { speed: 1.1, pitch: 70 },
    fast:   { speed: 1.5, pitch: 50 },
    slow:   { speed: 0.7, pitch: 50 }
};

document.getElementById('preview-variety-btn')?.addEventListener('click', async () => {
    const text = document.getElementById('variety-text').value;
    if (!text) return alert('متن را وارد کنید');
    const voiceType = document.getElementById('voice-type').value;
    const config = voiceTypeMap[voiceType];
    const statusDiv = document.getElementById('variety-status');
    statusDiv.innerHTML = '⏳ در حال تولید صدا...';
    
    try {
        const response = await fetch('/api/synthesize-custom', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                text: text,
                voice: 'fa',
                rate: config.speed,
                pitch: config.pitch
            })
        });
        const data = await response.json();
        if (response.ok) {
            statusDiv.innerHTML = `<audio controls autoplay src="${data.url}"></audio>`;
        } else {
            statusDiv.innerHTML = '❌ خطا: ' + data.error;
        }
    } catch (err) {
        statusDiv.innerHTML = '❌ خطا در ارتباط با سرور';
    }
});
EOFJS

# اضافه کردن مسیر جدید در api/index.js (در صورت نبود)
if ! grep -q "/api/synthesize-custom" api/index.js; then
    sed -i '/app.post("\/api\/synthesize"/a \
app.post("/api/synthesize-custom", async (req, res) => { \
    const { text, voice = "fa", rate = 1.0, pitch = 50 } = req.body; \
    if (!text) return res.status(400).json({ error: "text required" }); \
    try { \
        const result = await advancedTTS.enqueue(text, { voice, rate, pitch }); \
        res.json({ url: result.url, path: result.path }); \
    } catch (err) { \
        res.status(500).json({ error: err.message }); \
    } \
});' api/index.js
fi

echo -e "${GREEN}✅ قابلیت صدای متنوع با موفقیت اضافه شد!${NC}"
echo ""
echo "🔄 سرور را مجدداً راه‌اندازی کنید: node api/index.js"
echo "سپس در مرورگر به تب «صدای متنوع» بروید و بدون نیاز به اینترنت، صداهای مختلف را تست کنید."
