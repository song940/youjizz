## youjizz [![youjizz](https://img.shields.io/npm/v/youjizz.svg)](https://npmjs.org/youjizz)

> simple youjizz api in javascript

### Installation

```bash
$ npm install youjizz
```

### Example

```js
const Youjizz = require('youjizz');

(async () => {

  const youjizz = new Youjizz();

  const videos = await youjizz.page(1);
  console.log(videos);

})();
```

### Contributing
- Fork this Repo first
- Clone your Repo
- Install dependencies by `$ npm install`
- Checkout a feature branch
- Feel free to add your features
- Make sure your features are fully tested
- Publish your local branch, Open a pull request
- Enjoy hacking <3

### MIT

This work is licensed under the [MIT license](./LICENSE).

---