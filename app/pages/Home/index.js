import Page from 'classes/Page';

export default class Home extends Page {
  constructor() {
    super({
      id: 'home',
      element: '.app[data-template="home"]',
      elements: { 
        scrollContent: '.scroll-content',
        items: '.slider__item', // Grab the wrapper elements for our diagonal math
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

    const items = Array.isArray(this.elements.items) || this.elements.items instanceof NodeList 
        ? Array.from(this.elements.items) 
        : [this.elements.items];

    const indicators = Array.isArray(this.elements.indicators) || this.elements.indicators instanceof NodeList 
        ? Array.from(this.elements.indicators) 
        : [this.elements.indicators];

    // Calculate the physical diagonal shift for every item individually
    items.forEach((item, index) => {
      if (!item) return;
      const bounds = item.getBoundingClientRect();
      const centerDistanceY = (bounds.top + bounds.height / 2) - (window.innerHeight / 2);
      
      // OFF-AXIS MATH: 
      // Translate the X position based on the Y position to lock them into a 10-degree slanted track
      const angle = 10 * (Math.PI / 180);
      const xOffset = centerDistanceY * Math.tan(angle);
      
      // Physically shift the DOM container. WebGL naturally inherits this in the next rendering loop!
      item.style.transform = `translateX(${xOffset}px)`;
      
      // Indicator drawing math based on distance from center
      const indicator = indicators[index];
      if (indicator) {
        const distanceFromCenter = Math.abs(centerDistanceY);
        let fillProgress = 1 - (distanceFromCenter / 300);
        fillProgress = Math.max(0, Math.min(fillProgress, 1)); 
        const offset = 145 - (145 * fillProgress);
        indicator.style.strokeDashoffset = offset;
      }
    });
  }
}
