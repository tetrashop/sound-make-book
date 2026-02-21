const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

function runCommand(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, (err, stdout, stderr) => {
      if (err) reject(err);
      else resolve(stdout);
    });
  });
}

// تابع کمکی برای تولید صدا با eSpeak (فعلاً شبیه‌سازی می‌کنیم)
exports.generateAudio = async function(text, voice, outputPath) {
  const cmd = `espeak -v ${voice} "${text}" -w ${outputPath.replace('.mp3', '.wav')} && ffmpeg -i ${outputPath.replace('.mp3', '.wav')} -codec:a libmp3lame -qscale:a 2 ${outputPath}`;
  await runCommand(cmd);
};

exports.addBackgroundMusic = async function(audioPath, musicType, volume, outputPath) {
  // مسیر فایل موسیقی (باید از قبل در سرور وجود داشته باشد)
  const musicPath = path.join(__dirname, '../public/music', `${musicType}.mp3`);
  const cmd = `ffmpeg -i ${audioPath} -i ${musicPath} -filter_complex "[0:a]volume=1[a0];[1:a]volume=${volume}[a1];[a0][a1]amix=inputs=2:duration=longest" -codec:a libmp3lame ${outputPath}`;
  await runCommand(cmd);
};

exports.combineAudioFiles = async function(fileList, outputPath) {
  const listFile = path.join('/tmp', 'filelist.txt');
  fs.writeFileSync(listFile, fileList.map(f => `file '${f}'`).join('\n'));
  const cmd = `ffmpeg -f concat -safe 0 -i ${listFile} -codec copy ${outputPath}`;
  await runCommand(cmd);
  fs.unlinkSync(listFile);
};

exports.generatePreview = async function(text, voice, settings, outputPath) {
  // فقط ۱۰ ثانیه اول
  const shortText = text.slice(0, 100);
  await this.generateAudio(shortText, voice, outputPath);
};

exports.generateWithSettings = async function(text, voice, { speed=1.0, pitch=0, gap=0 }, outputPath) {
  // تنظیمات eSpeak
  const cmd = `espeak -v ${voice} -s ${speed*100} -p ${pitch+50} -g ${gap} "${text}" -w ${outputPath.replace('.mp3', '.wav')} && ffmpeg -i ${outputPath.replace('.mp3', '.wav')} -codec:a libmp3lame -qscale:a 2 ${outputPath}`;
  await runCommand(cmd);
};
