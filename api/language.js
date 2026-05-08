const franc = require('franc');

const langMap = {
  'fas': 'fa',
  'eng': 'en',
  'ara': 'ar',
  'fra': 'fr',
  'deu': 'de',
  'spa': 'es',
  'rus': 'ru',
  'tur': 'tr',
  'urd': 'ur',
  'kur': 'ku'
};

exports.detect = function(text) {
  const detected = franc(text, { minLength: 3 });
  return langMap[detected] || 'fa'; // پیش‌فرض فارسی
};
