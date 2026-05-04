const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');

class AdvancedTTS extends EventEmitter {
    constructor() {
        super();
        this.queue = [];
        this.processing = false;
        this.cacheDir = path.join(__dirname, '../audio-cache');
        if (!fs.existsSync(this.cacheDir)) fs.mkdirSync(this.cacheDir, { recursive: true });
    }

    enqueue(text, options = {}) {
        return new Promise((resolve, reject) => {
            const taskId = Date.now() + '-' + Math.random().toString(36).substr(2, 6);
            this.queue.push({ taskId, text, options, resolve, reject });
            this.emit('queued', taskId);
            if (!this.processing) this._processQueue();
        });
    }

    async _processQueue() {
        if (this.queue.length === 0) {
            this.processing = false;
            return;
        }
        this.processing = true;
        const task = this.queue.shift();
        this.emit('start', task.taskId);
        try {
            const result = await this._generate(task.text, task.options);
            task.resolve(result);
            this.emit('complete', task.taskId);
        } catch (err) {
            task.reject(err);
            this.emit('error', task.taskId, err);
        }
        await new Promise(r => setTimeout(r, 100));
        this._processQueue();
    }

    _generate(text, opts = {}) {
        return new Promise((resolve, reject) => {
            const voice = opts.voice || 'fa';
            const rate = opts.rate || 1.0;
            const pitch = opts.pitch || 50;
            const gap = opts.gap || 0;
            const outWav = path.join(this.cacheDir, `tts_${Date.now()}.wav`);
            const cmd = `espeak -v ${voice} -s ${Math.round(rate * 100)} -p ${pitch} -g ${gap} "${text.replace(/"/g, '\\"')}" -w ${outWav}`;
            exec(cmd, (err) => {
                if (err) return reject(err);
                resolve({ path: outWav, url: `/audio-cache/${path.basename(outWav)}` });
            });
        });
    }

    getQueueStatus() {
        return { pending: this.queue.length, processing: this.processing };
    }
}

module.exports = new AdvancedTTS();
