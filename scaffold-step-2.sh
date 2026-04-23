#!/bin/bash

echo "Removing text rotation and implementing dynamic off-axis diagonal tracking..."

# 1. Update SCSS: Remove the rotate(-10deg) from the text content wrapper
cat << 'EOF' > styles/base.scss
@use './variables' as *;

html, body {
  background-color: $color-bg;
  color: $color-text;
  margin: 0;
  overscroll-behavior: none;
  font-family: 'Circular Std', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  font-size: 14px;
  line-height: 1.2;
  -ms-overflow-style: none; 
  scrollbar-width: none; 
}

::-webkit-scrollbar {
  display: none; 
}

.brand, .navigation, .availability, .minimap {
  position: fixed;
  z-index: 10;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-weight: 500;
}

.brand {
  top: 2rem;
  left: 2rem;
  &__name { font-weight: 700; }
  &__title { color: rgba(1, 1, 1, 0.5); }
}

.navigation {
  top: 2rem;
  right: 2rem;
  display: flex;
  gap: 2rem;
  &__link {
    color: rgba(1, 1, 1, 0.5);
    text-decoration: none;
    transition: color 0.3s ease;
    &:hover, &.active { color: $color-text; }
  }
}

.availability {
  bottom: 2rem;
  left: 2rem;
  cursor: pointer;
  overflow: hidden;
  height: 2.4em;

  &__wrapper {
    position: relative;
    transition: transform 0.6s cubic-bezier(0.19, 1, 0.22, 1);
  }

  &__status, &__email {
    display: flex;
    flex-direction: column;
    height: 2.4em;
    justify-content: center;
  }

  &__email {
    position: absolute;
    top: 100%;
    left: 0;
    width: 100%;
    color: $color-accent;
  }
  
  .copy-alert {
    font-size: 0.8em;
    color: rgba(1,1,1,0.5);
  }

  &:hover &__wrapper {
    transform: translateY(-100%);
  }
}

.minimap {
  bottom: 2rem;
  right: 2rem;
  height: 100px;
  width: 2px;
  background: rgba(1, 1, 1, 0.2);

  &__progress {
    position: absolute;
    top: 0;
    left: -1px;
    width: 4px;
    height: 20px;
    background: $color-text;
    transform-origin: top;
    will-change: transform;
  }
}

.app {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  visibility: hidden;
  z-index: 1; 
}

.scroll-content {
  width: 100%;
  will-change: transform;
  padding: 50vh 0; 
}

[data-animation="clunky-reveal"] { opacity: 0; }

.slider {
  display: flex;
  flex-direction: column;
  align-items: center;

  &__item {
    position: relative;
    width: 50vw;
    max-width: 750px;
    aspect-ratio: 1.5; 
    margin: 8vh 0;
    will-change: transform; /* Optimized for our dynamic horizontal sliding */
  }

  &__image {
    opacity: 0; 
    width: 100%;
    height: 100%; 
    object-fit: cover; 
    display: block;
  }

  &__content {
    position: absolute;
    top: 50%;
    left: 50%;
    /* FIX: Keep text perfectly horizontal, removed the 10-degree rotation */
    transform: translate(-50%, -50%);
    display: flex;
    align-items: center;
    gap: 2rem;
    pointer-events: none;
    z-index: 2;
    width: 140%;
    justify-content: center;
  }

  &__title {
    font-size: clamp(3rem, 7vw, 9rem);
    font-weight: 700;
    color: $color-text; 
    margin: 0;
    text-transform: uppercase;
  }

  &__indicator {
    position: relative;
    width: 50px;
    height: 50px;
    display: flex;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    color: $color-text; 
    
    &-svg {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      transform: rotate(-90deg);
      
      circle {
        fill: none;
        stroke-width: 2;
      }
      .indicator-bg { stroke: rgba(1, 1, 1, 0.2); } 
      .indicator-progress {
        stroke: $color-text; 
        stroke-dasharray: 145;
        stroke-dashoffset: 145;
        transition: stroke-dashoffset 0.1s linear;
      }
    }
  }
}

.webgl-canvas {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  pointer-events: none; 
  z-index: 0; 
}
EOF

# 2. Update Home.js to dynamically map the diagonal track
cat << 'EOF' > app/pages/Home/index.js
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
EOF

echo "Diagonal off-axis slider implemented! Text is level and cards track mathematically."