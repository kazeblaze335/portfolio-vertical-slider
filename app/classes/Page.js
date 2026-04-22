import gsap from 'gsap';

export default class Page {
  constructor({ id, element, elements }) {
    this.id = id;
    this.selector = element;
    this.selectorChildren = { ...elements };
    this.elements = {};
  }

  create() {
    this.element = document.querySelector(this.selector);
    for (const [key, entry] of Object.entries(this.selectorChildren)) {
      if (entry instanceof window.HTMLElement || entry instanceof window.NodeList || Array.isArray(entry)) {
        this.elements[key] = entry;
      } else {
        const nodes = document.querySelectorAll(entry);
        if (nodes.length === 0) {
          this.elements[key] = null;
        } else if (nodes.length === 1) {
          this.elements[key] = document.querySelector(entry);
        } else {
          this.elements[key] = nodes;
        }
      }
    }
  }

  show() {
    return new Promise((resolve) => {
      gsap.fromTo(this.element,
        { autoAlpha: 0 },
        { autoAlpha: 1, duration: 1.2, ease: 'expo.out', onComplete: resolve }
      );
    });
  }

  hide() {
    return new Promise((resolve) => {
      gsap.to(this.element, {
        autoAlpha: 0, duration: 0.8, ease: 'expo.in', onComplete: resolve
      });
    });
  }
}
