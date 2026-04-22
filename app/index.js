import Canvas from 'classes/Canvas';
import ClunkyReveal from 'components/ClunkyReveal';
import CopyClipboard from 'components/CopyClipboard';
import Home from 'pages/Home';
import Archive from 'pages/Archive';

class App {
  constructor() {
    this.createContent();
    this.createPages();
    
    this.canvas = new Canvas();
    this.scroll = { current: 0, target: 0 };
    
    this.createComponents();
    this.createWebGL();
    this.update();
  }

  createContent() {
    this.content = document.querySelector('.app');
    this.template = this.content.getAttribute('data-template');
  }

  createPages() {
    this.pages = {
      home: new Home(),
      archive: new Archive()
    };
    this.page = this.pages[this.template];
    this.page.create();
    this.page.show();
  }

  createComponents() {
    this.reveals = Array.from(document.querySelectorAll('[data-animation="clunky-reveal"]')).map(element => {
      return new ClunkyReveal({ element });
    });

    this.copyWidgets = Array.from(document.querySelectorAll('[data-animation="copy-clipboard"]')).map(element => {
      return new CopyClipboard({ element });
    });
  }

  createWebGL() {
    if (this.page && this.page.elements.images) {
      const images = Array.isArray(this.page.elements.images) || this.page.elements.images instanceof NodeList 
        ? Array.from(this.page.elements.images) 
        : [this.page.elements.images];
      
      if (images.length > 0 && images[0] !== null) {
        this.canvas.createMedias(images);
      }
    }
  }

  update() {
    this.scroll.target = window.scrollY || 0;
    this.scroll.current += (this.scroll.target - this.scroll.current) * 0.08;

    if (this.page && this.page.elements.scrollContent) {
      this.page.elements.scrollContent.style.transform = `translateY(-${this.scroll.current}px)`;
    }

    if (this.page && this.page.update) {
      this.page.update(this.scroll);
    }

    // Mathematical trigger for text reveals synced perfectly with virtual scroll
    if (this.reveals) {
      this.reveals.forEach(reveal => {
        const bounds = reveal.element.getBoundingClientRect();
        // Check if the title has entered the middle 60% of the viewport
        if (!reveal.isVisible && bounds.top < window.innerHeight * 0.8 && bounds.bottom > window.innerHeight * 0.2) {
          reveal.show();
          reveal.isVisible = true;
        }
      });
    }

    this.canvas.update();
    window.requestAnimationFrame(this.update.bind(this));
  }
}

new App();
