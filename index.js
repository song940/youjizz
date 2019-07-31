const https = require('https');

const get = url =>
  new Promise(done => https.get(url, done));

const readStream = stream =>
  new Promise((resolve, reject) => {
    stream
      .on('error', reject)
      .on('data', chunk => buffer += chunk)
      .on('end', () => resolve(buffer))
  });

const parseHTML = html => cheerio.load(html);

class Youjizz {
  page(n) {
    return Promise
      .resolve(`https://www.youjizz.com/page/${n}`)
      .then(get)
      .then(readStream)
      .then(parseHTML)
  }
}

module.exports = Youjizz;