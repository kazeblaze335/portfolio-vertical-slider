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
      elements: {
        scrollContent: '.scroll-content'
      }
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

    // THE FIX: Direct assignment to .onclick ensures the listener survives the DOM injection
    // and brutally overrides any default HTML link behaviors.
    const nextBtn = this.element.querySelector('.next-project');
    if (nextBtn) {
      nextBtn.onclick = (e) => {
        e.preventDefault(); 
        this.transitionToNext();
      };
    }
  }

  updateDOM(index) {
    const data = PROJECTS[index];
    if (!data) return;

    const title = this.element.querySelector('.project-title');
    const location = this.element.querySelector('.project-details p:nth-child(2)');
    const nextTitle = this.element.querySelector('.next-project__title');

    if (title) title.innerText = data.title;
    if (location) location.innerText = data.location;
    if (nextTitle) nextTitle.innerText = data.nextTitle;
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
          delay: 0.1 
        });
      }
    });
  }

  destroy() {
    if (this.resizeObserver && this.elements.scrollContent) {
      this.resizeObserver.unobserve(this.elements.scrollContent);
    }
    super.destroy();
  }
}
