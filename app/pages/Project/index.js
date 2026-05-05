import Page from 'classes/Page';

export default class Project extends Page {
  constructor() {
    super({
      id: 'project',
      element: '.app[data-template="project"]',
      elements: {
        // THE FIX: Tell the page class exactly what to translate
        scrollContent: '.scroll-content' 
      }
    });
    this.maxScroll = 0;
  }

  create() {
    super.create();
    
    // THE FIX: Tell the browser and Lenis exactly how tall the injected content is!
    if (this.elements.scrollContent) {
      this.resizeObserver = new ResizeObserver(() => {
        const height = this.elements.scrollContent.getBoundingClientRect().height;
        
        // Expands the native body scrollbar so Lenis can do its math
        document.body.style.height = `${height}px`;
        
        this.maxScroll = height - window.innerHeight;
      });
      
      this.resizeObserver.observe(this.elements.scrollContent);
    }
  }

  destroy() {
    // Clean up the observer when navigating away to prevent memory leaks
    if (this.resizeObserver && this.elements.scrollContent) {
      this.resizeObserver.unobserve(this.elements.scrollContent);
    }
    super.destroy();
  }
}
