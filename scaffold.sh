#!/bin/bash

echo "Bootstrapping Floema-Style Vanilla OOP Application..."

# 1. Initialize Project & Directories
npm init -y
npm pkg set type="module"
npm install gsap ogl
npm install -D vite sass

mkdir -p app/classes app/components app/pages/Home app/pages/Archive styles public/images archive

# 2. Vite Configuration
cat << 'EOF' > vite.config.js
import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  resolve: {
    alias: {
      'classes': path.resolve(__dirname, './app/classes'),
      'components': path.resolve(__dirname, './app/components'),
      'pages': path.resolve(__dirname, './app/pages')
    }
  },
  server: {
    host: true // Expose to local network for mobile testing
  }
});
EOF

# 3. SCSS Foundation
cat << 'EOF' > styles/variables.scss
$color-bg: #e5e5e5;
$color-text: #010101; 
$color-accent: #ff0000;
EOF

cat << 'EOF' > styles/base.scss
@use './variables' as *;

body {
  background-color: $color-bg;
  color: $color-text;
  margin: 0;
  overscroll-behavior: none;
  font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
  height: 300vh; /* Force scrollable area */
  -webkit-font-smoothing: antialiased;
}

.app {
  visibility: hidden; 
}

[data-animation="clunky-reveal"] {
  opacity: 0;
}

.navigation {
  position: fixed;
  top: 2rem;
  left: 2rem;
  z-index: 10;
  
  &__link {
    color: $color-text;
    text-decoration: none;
    text-transform: uppercase;
    font-size: 0.85rem;
    font-weight: 500;
    letter-spacing: 0.05em;
  }
}

.slider {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 30vh;

  &__item {
    position: relative;
    width: 85vw;
    max-width: 600px;
    margin: 0 0 40vh 0;
  }

  &__image {
    opacity: 0; /* Let OGL handle the image */
    width: 100%;
    height: auto;
    aspect-ratio: 4/5;
    display: block;
  }

  &__title {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-size: clamp(3rem, 8vw, 8rem);
    font-weight: bold;
    color: $color-bg;
    mix-blend-mode: difference;
    margin: 0;
    white-space: nowrap;
    pointer-events: none;
    text-transform: uppercase;
  }
}

.webgl-canvas {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  pointer-events: none;
  z-index: -1; 
}
EOF

# 4. HTML Templates
cat << 'EOF' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Mild Days - Index</title>
  <link rel="stylesheet" href="/styles/base.scss" />
</head>
<body>
  <main class="app" data-template="home">
    <nav class="navigation">
      <a href="/archive" class="navigation__link">Archive</a>
    </nav>

    <div class="slider">
      <div class="slider__wrapper">
        <figure class="slider__item">
          <img class="slider__image" src="/images/project-7.jpg" alt="Mild Days" />
          <figcaption class="slider__title" data-animation="clunky-reveal">Mild Days</figcaption>
        </figure>
      </div>
    </div>
  </main>
  <canvas class="webgl-canvas"></canvas>
  <script type="module" src="/app/index.js"></script>
</body>
</html>
EOF

cat << 'EOF' > archive/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Mild Days - Archive</title>
  <link rel="stylesheet" href="/styles/base.scss" />
  <style>
    .archive-layout {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      width: 100vw;
    }
    .archive-layout__title {
      font-size: clamp(2.5rem, 6vw, 5rem);
      text-transform: uppercase;
      color: #010101;
      margin: 0;
    }
  </style>
</head>
<body>
  <main class="app" data-template="archive">
    <nav class="navigation">
      <a href="/" class="navigation__link">Back to Index</a>
    </nav>

    <div class="archive-layout">
      <h1 class="archive-layout__title" data-animation="clunky-reveal">Archive</h1>
    </div>
  </main>
  <canvas class="webgl-canvas"></canvas>
  <script type="module" src="/app/index.js"></script>
</body>
</html>
EOF

# 5. Core OOP Classes
cat << 'EOF' > app/classes/Component.js
export default class Component {
  constructor({ element }) {
    this.element = element;
  }
}
EOF

cat << 'EOF' > app/classes/Page.js
import gsap from 'gsap';

export default class Page {
  constructor({ id, element, elements }) {
    this.id = id;
    this.selector = element;
    this.selectorChildren = { ...elements };
    this.elements = {};
  }

  create() {
    this.element = document.querySelector(this.selector);
    for (const [key, entry] of Object.entries(this.selectorChildren)) {
      if (entry instanceof window.HTMLElement || entry instanceof window.NodeList || Array.isArray(entry)) {
        this.elements[key] = entry;
      } else {
        const nodes = document.querySelectorAll(entry);
        if (nodes.length === 0) {
          this.elements[key] = null;
        } else if (nodes.length === 1) {
          this.elements[key] = document.querySelector(entry);
        } else {
          this.elements[key] = nodes;
        }
      }
    }
  }

  show() {
    return new Promise((resolve) => {
      gsap.fromTo(this.element,
        { autoAlpha: 0 },
        { autoAlpha: 1, duration: 1.2, ease: 'expo.out', onComplete: resolve }
      );
    });
  }

  hide() {
    return new Promise((resolve) => {
      gsap.to(this.element, {
        autoAlpha: 0, duration: 0.8, ease: 'expo.in', onComplete: resolve
      });
    });
  }
}
EOF

cat << 'EOF' > app/components/ClunkyReveal.js
import Component from 'classes/Component';
import gsap from 'gsap';

export default class ClunkyReveal extends Component {
  constructor({ element }) {
    super({ element });
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
      { y: '0%', rotate: 0, stagger: 0.04, duration: 1.4, ease: 'expo.out', delay: 0.2 }
    );
  }
}
EOF

# 6. WebGL Layer
cat << 'EOF' > app/classes/Canvas.js
import { Renderer, Camera, Transform, Plane, Program, Mesh, Texture } from 'ogl';

export default class Canvas {
  constructor() {
    this.createRenderer();
    this.createCamera();
    this.createScene();
    this.createGeometry();
    this.medias = [];
    this.onResize();
  }

  createRenderer() {
    this.renderer = new Renderer({ alpha: true, dpr: Math.min(window.devicePixelRatio, 2) });
    this.gl = this.renderer.gl;
    const canvas = document.querySelector('.webgl-canvas');
    if(canvas) canvas.replaceWith(this.gl.canvas);
    this.gl.canvas.classList.add('webgl-canvas');
  }

  createCamera() {
    this.camera = new Camera(this.gl);
    this.camera.position.z = 5;
  }

  createScene() {
    this.scene = new Transform();
  }

  createGeometry() {
    this.geometry = new Plane(this.gl, { heightSegments: 20, widthSegments: 20 });
    this.program = new Program(this.gl, {
      vertex: `
        attribute vec3 position;
        attribute vec2 uv;
        uniform mat4 modelViewMatrix;
        uniform mat4 projectionMatrix;
        uniform float uScrollVelocity;
        varying vec2 vUv;
        
        void main() {
          vUv = uv;
          vec3 pos = position;
          pos.y += sin(pos.x * 3.14159) * uScrollVelocity * 0.003;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
        }
      `,
      fragment: `
        precision highp float;
        uniform sampler2D tMap;
        varying vec2 vUv;
        
        void main() {
          vec4 tex = texture2D(tMap, vUv);
          float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
          gl_FragColor = vec4(vec3(gray), tex.a);
        }
      `,
      uniforms: {
        uScrollVelocity: { value: 0 },
        tMap: { value: new Texture(this.gl) }
      }
    });
  }

  createMedias(domElements) {
    this.medias.forEach(media => media.mesh.setParent(null));
    this.medias = Array.from(domElements).map(element => {
      const texture = new Texture(this.gl);
      const image = new Image();
      image.src = element.getAttribute('src');
      image.onload = () => texture.image = image;

      const mesh = new Mesh(this.gl, { geometry: this.geometry, program: this.program });
      mesh.program.uniforms.tMap.value = texture;
      mesh.setParent(this.scene);
      return { element, mesh, texture };
    });
  }

  onResize() {
    this.screen = {
      width: window.innerWidth,
      height: window.innerHeight
    };
    
    this.renderer.setSize(this.screen.width, this.screen.height);
    this.camera.perspective({ aspect: this.gl.canvas.width / this.gl.canvas.height });
    const fov = this.camera.fov * (Math.PI / 180);
    const height = 2 * Math.tan(fov / 2) * this.camera.position.z;
    const width = height * this.camera.aspect;

    this.viewport = { height, width };
  }

  update(scroll) {
    this.medias.forEach(media => {
      const bounds = media.element.getBoundingClientRect();
      
      media.mesh.scale.x = this.viewport.width * bounds.width / this.screen.width;
      media.mesh.scale.y = this.viewport.height * bounds.height / this.screen.height;
      
      media.mesh.position.y = (this.viewport.height / 2) - (this.viewport.height * (bounds.top + bounds.height / 2) / this.screen.height);
      media.mesh.position.x = (this.viewport.width * (bounds.left + bounds.width / 2) / this.screen.width) - (this.viewport.width / 2);

      media.mesh.program.uniforms.uScrollVelocity.value = scroll.velocity;
    });

    this.renderer.render({ scene: this.scene, camera: this.camera });
  }
}
EOF

# 7. Page Controllers
cat << 'EOF' > app/pages/Home/index.js
import Page from 'classes/Page';

export default class Home extends Page {
  constructor() {
    super({
      id: 'home',
      element: '.app[data-template="home"]',
      elements: { images: '.slider__image' }
    });
  }
}
EOF

cat << 'EOF' > app/pages/Archive/index.js
import Page from 'classes/Page';

export default class Archive extends Page {
  constructor() {
    super({
      id: 'archive',
      element: '.app[data-template="archive"]',
      elements: {}
    });
  }
}
EOF

# 8. App Conductor
cat << 'EOF' > app/index.js
import Canvas from 'classes/Canvas';
import ClunkyReveal from 'components/ClunkyReveal';
import Home from 'pages/Home';
import Archive from 'pages/Archive';

class App {
  constructor() {
    this.createContent();
    this.createPages();
    
    this.canvas = new Canvas();
    this.scroll = { current: 0, target: 0, velocity: 0 };
    
    this.createComponents();
    this.createWebGL();
    this.addEventListeners();
    this.update();
  }

  createContent() {
    this.content = document.querySelector('.app');
    this.template = this.content.getAttribute('data-template');
  }

  createPages() {
    this.pages = {
      home: new Home(),
      archive: new Archive()
    };
    this.page = this.pages[this.template];
    this.page.create();
    this.page.show();
  }

  createComponents() {
    this.reveals = Array.from(document.querySelectorAll('[data-animation="clunky-reveal"]')).map(element => {
      const reveal = new ClunkyReveal({ element });
      reveal.show();
      return reveal;
    });
  }

  createWebGL() {
    if (this.page.elements.images) {
      const images = Array.isArray(this.page.elements.images) || this.page.elements.images instanceof NodeList 
        ? this.page.elements.images 
        : [this.page.elements.images];
      this.canvas.createMedias(images);
    }
  }

  addEventListeners() {
    window.addEventListener('resize', () => {
      if (this.canvas && this.canvas.onResize) {
        this.canvas.onResize();
      }
    });

    window.addEventListener('wheel', (e) => {
      this.scroll.target += e.deltaY;
    });
  }

  update() {
    this.scroll.current += (this.scroll.target - this.scroll.current) * 0.08;
    this.scroll.velocity = this.scroll.target - this.scroll.current;

    this.canvas.update(this.scroll);
    window.requestAnimationFrame(this.update.bind(this));
  }
}

new App();
EOF

# 9. Download Assets
echo "Fetching project image..."
curl -L -s -o public/images/project-7.jpg "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=800&auto=format&fit=crop"

echo "Bootstrapping complete! Run 'npm run dev' to start."