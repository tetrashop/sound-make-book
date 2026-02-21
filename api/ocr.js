const { createWorker } = require('tesseract.js');
const fs = require('fs');

exports.extract = async function(imagePath) {
  const worker = await createWorker('fas');
  const { data: { text } } = await worker.recognize(imagePath);
  await worker.terminate();
  return text;
};
