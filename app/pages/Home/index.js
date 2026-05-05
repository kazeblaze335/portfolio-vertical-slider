import Page from 'classes/Page';
import gsap from 'gsap'; 

export default class Home extends Page {
  constructor() {
    super({
      id: 'home',
      element: '.app[data-template="home"]',
      elements: { 
        scrollContent: '.scroll-content',
        items: '.slider__item', 
        images: '.slider__image', /* RESTORED IMAGE SELECTOR */
        minimapProgress: '.minimap__progress',
        indicators: '.indicator-progress'
      }
    });
    this.maxScroll = 0;
    this.isTransitioning = false; 
  }

  create() {
    super.create();
    
    if (this.elements.scrollContent) {
      this.resizeObserver = new ResizeObserver(() => {
        const height = this.elements.scrollContent.getBoundingClientRect().height;
        document.body.style.height = `${height}px`;
        this.maxScroll = height - window.innerHeight;
      });
      this.resizeObserver.observe(this.elements.scrollContent);
    }

    const items = this.elements.items instanceof NodeList || Array.isArray(this.elements.items) 
        ? Array.from(this.elements.items) 
        : [this.elements.items];

    items.forEach((item, index) => {
      if (!item) return;
      const title = item.querySelector('.slider__title');
      const indicator = item.querySelector('.slider__indicator');
      
      const onSelect = () => {
        if (!this.isTransitioning) this.transitionToProject(index);
      };

      if (title) title.addEventListener('click', onSelect);
      if (indicator) indicator.addEventListener('click', onSelect);
    });
  }

  transitionToProject(index) {
    this.isTransitioning = true;
    window.dispatchEvent(new CustomEvent('freeze-scroll'));
    window.dispatchEvent(new CustomEvent('project-transition', { detail: { index } }));

    gsap.to('.scroll-content, .brand, .navigation, .minimap, .availability', {
      opacity: 0,
      duration: 0.8,
      ease: 'power3.inOut'
    });

    fetch('/project.html')
      .then(res => res.text())
      .then(html => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        
        const newApp = doc.querySelector('.app[data-template="project"]');
        const oldApp = document.querySelector('.app[data-template="home"]');

        setTimeout(() => {
          if (oldApp) oldApp.remove();
          document.body.appendChild(newApp);

          const oldNav = document.querySelector('.navigation');
          const newNav = doc.querySelector('.navigation');
          if (oldNav && newNav) {
            oldNav.innerHTML = newNav.innerHTML;
            gsap.to(oldNav, { opacity: 1, duration: 0.5 }); 
          }

          window.history.pushState({}, '', `/project.html?id=${index}`);
          window.scrollTo(0, 0);
          window.dispatchEvent(new CustomEvent('seamless-navigate'));
          window.dispatchEvent(new CustomEvent('play-hero-text'));

        }, 1200); 
      });
  }

  update(scroll) {
    if (this.isTransitioning) return; 

    if (this.maxScroll > 0 && this.elements.minimapProgress) {
      const progress = Math.max(0, Math.min(scroll.current / this.maxScroll, 1));
      const trackHeight = 100 - 20; 
      this.elements.minimapProgress.style.transform = `translateY(${progress * trackHeight}px)`;
    }

    const items = this.elements.items instanceof NodeList || Array.isArray(this.elements.items) 
        ? Array.from(this.elements.items) 
        : [this.elements.items];
        
    const indicators = this.elements.indicators instanceof NodeList || Array.isArray(this.elements.indicators) 
        ? Array.from(this.elements.indicators) 
        : [this.elements.indicators];

    items.forEach((item, index) => {
      if (!item) return;
      const bounds = item.getBoundingClientRect();
      const centerDistanceY = (bounds.top + bounds.height / 2) - (window.innerHeight / 2);
      const angle = 10 * (Math.PI / 180);
      item.style.transform = `translateX(${centerDistanceY * Math.tan(angle)}px)`;
      
      const indicator = indicators[index];
      if (indicator) {
        const distanceFromCenter = Math.abs(centerDistanceY);
        let fillProgress = Math.max(0, Math.min(1 - (distanceFromCenter / 300), 1)); 
        indicator.style.strokeDashoffset = 145 - (145 * fillProgress);
      }
    });
  }
}
