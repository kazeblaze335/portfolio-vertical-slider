import Page from 'classes/Page';

export default class Archive extends Page {
  constructor() {
    super({
      id: 'archive',
      element: '.app[data-template="archive"]',
      elements: {}
    });
  }
}
