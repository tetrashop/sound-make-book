const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

class EspeakTTS {
    async synthesize(text, filename = null) {
        return new Promise((resolve, reject) => {
            try {
                if (!filename) {
                    filename = `espeak_${Date.now()}.wav`;
                }
                
                const filePath = path.join(__dirname, '../audio-cache', filename);
                
                // استفاده از espeak (موجود در Termux)
                const command = `espeak -v fa "${text}" -w ${filePath}`;
                
                exec(command, (error, stdout, stderr) => {
                    if (error) {
                        console.error('eSpeak error:', error);
                        reject(error);
                        return;
                    }
                    
                    console.log(`✅ فایل صوتی ساخته شد: ${filePath}`);
                    resolve({
                        path: filePath,
                        url: `/audio-cache/${filename}`
                    });
                });
            } catch (error) {
                reject(error);
            }
        });
    }
    
    async convertToMp3(wavPath) {
        return new Promise((resolve, reject) => {
            const mp3Path = wavPath.replace('.wav', '.mp3');
            const command = `ffmpeg -i ${wavPath} -codec:a libmp3lame -qscale:a 2 ${mp3Path}`;
            
            exec(command, (error) => {
                if (error) {
                    console.error('FFmpeg error:', error);
                    reject(error);
                } else {
                    // حذف فایل WAV اصلی
                    fs.unlinkSync(wavPath);
                    resolve(mp3Path);
                }
            });
        });
    }
}

module.exports = new EspeakTTS();
