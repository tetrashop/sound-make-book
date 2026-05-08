const fs = require('fs');
const path = require('path');
const axios = require('axios');

const PROJECTS_FILE = path.join(__dirname, '../projects/projects.json');

function readProjects() {
  if (!fs.existsSync(PROJECTS_FILE)) return [];
  return JSON.parse(fs.readFileSync(PROJECTS_FILE, 'utf8'));
}

function writeProjects(projects) {
  fs.writeFileSync(PROJECTS_FILE, JSON.stringify(projects, null, 2));
}

exports.listAll = function() {
  return readProjects();
};

exports.create = function({ name, audioUrl, settings }) {
  const projects = readProjects();
  const newProject = {
    id: Date.now().toString(),
    name,
    audioUrl,
    settings,
    createdAt: new Date().toISOString()
  };
  projects.push(newProject);
  writeProjects(projects);
  return newProject;
};

exports.delete = function(id) {
  let projects = readProjects();
  const filtered = projects.filter(p => p.id !== id);
  if (filtered.length === projects.length) return false;
  writeProjects(filtered);
  return true;
};

// ذخیره در گوگل درایو با API مستقیم (بدون کتابخانه سنگین)
exports.saveToDrive = async function(fileName, fileUrl, accessToken) {
  const filePath = path.join(__dirname, '..', fileUrl);
  const fileStream = fs.createReadStream(filePath);
  
  const response = await axios.post(
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
    {
      name: fileName
    },
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'multipart/related'
      },
      data: fileStream
    }
  );
  return response.data;
};
