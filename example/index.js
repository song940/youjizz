const Youjizz = require('..');

(async () => {

  const youjizz = new Youjizz();

  const videos = await youjizz.page(1);
  console.log(videos);

})();