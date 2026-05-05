import Canvas from 'classes/Canvas';
import ClunkyReveal from 'components/ClunkyReveal';
import CopyClipboard from 'components/CopyClipboard';
import Home from 'pages/Home';
import Archive from 'pages/Archive';
import Project from 'pages/Project'; 
import gsap from 'gsap';
import Lenis from '@studio-freight/lenis';

class App {
  constructor() {
    this.createContent();
    this.createPages();
    
    this.canvas = new Canvas();
    this.scroll = { current: 0, target: 0 };
    
    this.initLenis();
    this.createComponents();
    this.createWebGL();
    
    this.initPageTransitions(); 
    
    window.requestAnimationFrame((time) => this.update(time));
  }

  initLenis() {
    this.lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)), 
      direction: 'vertical',
      gestureDirection: 'vertical',
      smooth: true,
      mouseMultiplier: 1,
      smoothTouch: false,
    });

    this.lenis.on('scroll', (e) => {
      this.scroll.current = e.scroll;
      this.scroll.target = e.targetScroll;
    });

    // THE FIX: Kill scroll momentum immediately when requested
    window.addEventListener('freeze-scroll', () => {
      this.lenis.stop();
    });
  }

  createContent() {
    this.content = document.querySelector('.app');
    this.template = this.content.getAttribute('data-template');
  }

  createPages() {
    this.pages = {
      home: new Home(),
      archive: new Archive(),
      project: new Project() 
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

  initPageTransitions() {
    gsap.to('.page-transition', {
      x: '100%',
      duration: 1.2,
      ease: 'expo.inOut',
      onComplete: () => {
        gsap.set('.page-transition', { x: '-100%' });
      }
    });

    this.bindTransitionLinks();

    window.addEventListener('seamless-navigate', () => {
      this.createContent(); 
      this.createPages();
      this.createComponents(); 
      this.bindTransitionLinks(); 
      
      // THE FIX: We must restart Lenis after the navigation completes!
      this.lenis.start();
      this.lenis.scrollTo(0, { immediate: true });
    });
  }

  bindTransitionLinks() {
    const transitionLinks = document.querySelectorAll('.transition-link');
    transitionLinks.forEach(link => {
      const newLink = link.cloneNode(true);
      link.parentNode.replaceChild(newLink, link);
      
      newLink.addEventListener('click', (e) => {
        e.preventDefault();
        const targetUrl = newLink.getAttribute('href');
        
        this.lenis.stop(); 
        
        gsap.to('.page-transition', {
          x: '0%', 
          duration: 1.2,
          ease: 'expo.inOut',
          onComplete: () => {
            window.location.href = targetUrl; 
          }
        });
      });
    });
  }

  update(time) {
    this.lenis.raf(time);

    if (this.page && this.page.elements.scrollContent) {
      this.page.elements.scrollContent.style.transform = `translateY(-${this.scroll.current}px)`;
    }

    if (this.page && this.page.update) {
      this.page.update(this.scroll);
    }

    if (this.reveals) {
      this.reveals.forEach(reveal => {
        const bounds = reveal.element.getBoundingClientRect();
        if (!reveal.isVisible && bounds.top < window.innerHeight * 0.8 && bounds.bottom > window.innerHeight * 0.2) {
          reveal.show();
          reveal.isVisible = true;
        } else if (reveal.isVisible && (bounds.top > window.innerHeight || bounds.bottom < 0)) {
          reveal.hide();
          reveal.isVisible = false;
        }
      });
    }

    this.canvas.update();
    window.requestAnimationFrame((t) => this.update(t));
  }
}

new App();
