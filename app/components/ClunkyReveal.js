import Component from 'classes/Component';
import gsap from 'gsap';

export default class ClunkyReveal extends Component {
  constructor({ element }) {
    super({ element });
    this.isVisible = false;
    this.setup();
  }

  setup() {
    this.element.style.letterSpacing = '0.02em';
    
    const text = this.element.textContent.trim();
    this.element.innerHTML = ''; 
    const chars = text.split('');
    
    chars.forEach(char => {
      const maskSpan = document.createElement('span');
      maskSpan.style.display = 'inline-block';
      maskSpan.style.overflow = 'hidden';
      maskSpan.style.verticalAlign = 'top';
      maskSpan.style.padding = '0.1em 0'; 
      maskSpan.style.marginTop = '-0.1em'; 
      
      const charSpan = document.createElement('span');
      charSpan.style.display = 'inline-block';
      charSpan.style.transformOrigin = 'left center';
      charSpan.classList.add('split-char');
      
      if (char === ' ') {
        charSpan.innerHTML = '&nbsp;';
      } else {
        charSpan.textContent = char;
      }
      
      maskSpan.appendChild(charSpan);
      this.element.appendChild(maskSpan);
    });

    this.chars = this.element.querySelectorAll('.split-char');
  }

  show() {
    gsap.set(this.element, { opacity: 1 });
    gsap.fromTo(this.chars, 
      { y: '100%', rotate: 10 }, 
      { y: '0%', rotate: 0, stagger: 0.04, duration: 1.4, ease: 'expo.out' }
    );
  }
}
