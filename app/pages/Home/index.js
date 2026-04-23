import Page from 'classes/Page';

export default class Home extends Page {
  constructor() {
    super({
      id: 'home',
      element: '.app[data-template="home"]',
      elements: { 
        scrollContent: '.scroll-content',
        images: '.slider__image',
        minimapProgress: '.minimap__progress',
        indicators: '.indicator-progress'
      }
    });
    this.maxScroll = 0;
  }

  create() {
    super.create();
    
    if (this.elements.scrollContent) {
      this.resizeObserver = new ResizeObserver(() => {
        // THE FIX: getBoundingClientRect() calculates the true height including our 50vh padding!
        const height = this.elements.scrollContent.getBoundingClientRect().height;
        document.body.style.height = `${height}px`;
        this.maxScroll = document.body.scrollHeight - window.innerHeight;
      });
      this.resizeObserver.observe(this.elements.scrollContent);
    }
  }

  update(scroll) {
    if (this.maxScroll > 0 && this.elements.minimapProgress) {
      const progress = Math.max(0, Math.min(scroll.current / this.maxScroll, 1));
      const trackHeight = 100 - 20; 
      this.elements.minimapProgress.style.transform = `translateY(${progress * trackHeight}px)`;
    }

    const images = Array.isArray(this.elements.images) || this.elements.images instanceof NodeList 
        ? Array.from(this.elements.images) 
        : [this.elements.images];

    const indicators = Array.isArray(this.elements.indicators) || this.elements.indicators instanceof NodeList 
        ? Array.from(this.elements.indicators) 
        : [this.elements.indicators];

    images.forEach((img, index) => {
      if (!img) return;
      const bounds = img.getBoundingClientRect();
      const indicator = indicators[index];
      if (!indicator) return;

      const centerOfScreen = window.innerHeight / 2;
      const centerOfImage = bounds.top + bounds.height / 2;
      const distanceFromCenter = Math.abs(centerOfScreen - centerOfImage);

      let fillProgress = 1 - (distanceFromCenter / 300);
      fillProgress = Math.max(0, Math.min(fillProgress, 1)); 

      const offset = 145 - (145 * fillProgress);
      indicator.style.strokeDashoffset = offset;
    });
  }
}
