import Component from 'classes/Component';
import gsap from 'gsap';

export default class CopyClipboard extends Component {
  constructor({ element }) {
    super({ element });
    this.email = 'johnmilner335@gmail.com';
    this.alertElement = this.element.querySelector('.copy-alert');
    this.addEventListeners();
  }

  addEventListeners() {
    this.element.addEventListener('click', () => {
      navigator.clipboard.writeText(this.email).then(() => {
        // Provide visual feedback
        const originalText = this.alertElement.innerText;
        this.alertElement.innerText = "Copied!";
        this.alertElement.style.color = "#ff0000";
        
        // Reset after 2 seconds
        setTimeout(() => {
          this.alertElement.innerText = originalText;
          this.alertElement.style.color = "";
        }, 2000);
      }).catch(err => {
        console.error('Failed to copy text: ', err);
      });
    });
  }
}
