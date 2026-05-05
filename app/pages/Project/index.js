import Page from 'classes/Page';
import gsap from 'gsap';

const PROJECTS = [
  { title: 'Mild Days', location: 'London, UK', nextTitle: 'Secret Level' },
  { title: 'Secret Level', location: 'Tokyo, JP', nextTitle: 'Design is Funny' },
  { title: 'Design is Funny', location: 'New York, USA', nextTitle: 'Concave Spaces' },
  { title: 'Concave Spaces', location: 'Berlin, DE', nextTitle: 'Digital Brutalism' },
  { title: 'Digital Brutalism', location: 'Paris, FR', nextTitle: 'The Archive' },
  { title: 'The Archive', location: 'Seoul, KR', nextTitle: 'Mild Days' }
];

export default class Project extends Page {
  constructor() {
    super({
      id: 'project',
      element: '.app[data-template="project"]',
      elements: { scrollContent: '.scroll-content' }
    });
    this.maxScroll = 0;
    this.currentIndex = 0;
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

    const params = new URLSearchParams(window.location.search);
    this.currentIndex = parseInt(params.get('id')) || 0;
    this.updateDOM(this.currentIndex);

    const nextBtn = this.element.querySelector('.next-project');
    if (nextBtn) {
      nextBtn.onclick = (e) => {
        e.preventDefault(); 
        this.transitionToNext();
      };
    }

    // THE UPGRADE: Wire the indicator to scroll down when clicked!
    const indicator = this.element.querySelector('.scroll-indicator');
    if (indicator) {
      indicator.onclick = () => {
        window.dispatchEvent(new CustomEvent('scroll-to-content'));
      };
    }

    this.playHeroText = () => {
      const chars = this.element.querySelectorAll('.char');
      const currentIndicator = this.element.querySelector('.scroll-indicator');
      
      gsap.set(chars, { y: '110%' });
      
      const tl = gsap.timeline();

      tl.to(chars, {
        y: '0%',
        duration: 1.4,
        stagger: 0.03,
        ease: 'expo.out',
        delay: 0.2 
      });

      // Bulletproof GSAP fade using fromTo
      if (currentIndicator) {
        tl.fromTo(currentIndicator, 
          { opacity: 0 }, 
          { opacity: 1, duration: 1, ease: 'power2.out' }, 
          "-=0.8"
        );
      }
    };
    
    window.addEventListener('play-hero-text', this.playHeroText);
  }

  updateDOM(index) {
    const data = PROJECTS[index];
    if (!data) return;

    const title = this.element.querySelector('.project-hero-title');
    const location = this.element.querySelector('.project-details p:nth-child(2)');
    const nextTitle = this.element.querySelector('.next-project__title');

    if (title) { title.innerText = data.title; this.splitText(title); }
    if (location) location.innerText = data.location;
    if (nextTitle) nextTitle.innerText = data.nextTitle;
  }

  splitText(element) {
    const text = element.innerText;
    element.innerHTML = '';
    text.split(' ').forEach((word) => {
      const wordDiv = document.createElement('div');
      wordDiv.className = 'word';
      word.split('').forEach((char) => {
        const charSpan = document.createElement('span');
        charSpan.className = 'char';
        charSpan.innerText = char;
        wordDiv.appendChild(charSpan);
      });
      element.appendChild(wordDiv);
    });
  }

  transitionToNext() {
    const nextIndex = (this.currentIndex + 1) % PROJECTS.length;

    gsap.to('.page-transition', {
      x: '0%',
      duration: 1.0,
      ease: 'expo.inOut',
      onComplete: () => {
        window.dispatchEvent(new CustomEvent('swap-project', { detail: { index: nextIndex } }));
        window.history.pushState({}, '', `/project.html?id=${nextIndex}`);
        window.scrollTo(0, 0);

        this.updateDOM(nextIndex);
        this.currentIndex = nextIndex;

        gsap.to('.page-transition', {
          x: '-100%',
          duration: 1.0,
          ease: 'expo.inOut',
          delay: 0.1,
          onStart: () => { window.dispatchEvent(new CustomEvent('play-hero-text')); }
        });
      }
    });
  }

  destroy() {
    window.removeEventListener('play-hero-text', this.playHeroText);
    if (this.resizeObserver && this.elements.scrollContent) {
      this.resizeObserver.unobserve(this.elements.scrollContent);
    }
    super.destroy();
  }
}
