#!/bin/bash

echo "Patching the Perspective Pop and Freezing Lenis Momentum..."

# 1. Patch Canvas.js to eliminate the Z-Axis scaling pop
cat << 'EOF' > app/classes/Canvas.js
import { Renderer, Camera, Transform, Plane, Program, Mesh, Texture } from 'ogl';
import gsap from 'gsap'; 

export default class Canvas {
  constructor() {
    this.createRenderer();
    this.createCamera();
    this.createScene();
    
    this.geometry = new Plane(this.gl, { heightSegments: 30, widthSegments: 30 });
    this.medias = [];
    
    this.onResize();
    window.addEventListener('resize', this.onResize.bind(this));

    window.addEventListener('project-transition', (e) => {
      this.animateToProject(e.detail.index);
    });

    window.addEventListener('swap-project', (e) => {
      this.swapProject(e.detail.index);
    });
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
    this.camera.position.z = 15; 
  }

  createScene() {
    this.scene = new Transform();
  }

  createMedias(domElements) {
    this.medias.forEach(media => media.mesh.setParent(null));
    this.medias = Array.from(domElements).map((element, index) => {
      
      const texture = new Texture(this.gl);
      const image = new Image();
      image.src = element.getAttribute('src');
      
      const program = new Program(this.gl, {
        vertex: `
          attribute vec3 position;
          attribute vec2 uv;
          uniform mat4 modelViewMatrix;
          uniform mat4 projectionMatrix;
          uniform float uOffset;
          
          varying vec2 vUv;
          varying float vShadow; 
          
          void main() {
            vUv = uv;
            vec3 pos = position;
            
            float screenY = uOffset + (pos.y * 0.5);
            float distanceY = abs(screenY);
            
            pos.x += pos.x * (distanceY * distanceY) * 0.4; 

            vShadow = 1.0 - smoothstep(0.0, 1.2, distanceY);
            vShadow = clamp(vShadow, 0.15, 0.80);

            gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
          }
        `,
        fragment: `
          precision highp float;
          uniform sampler2D tMap;
          uniform vec2 uMeshSize;
          uniform vec2 uImageSize;
          
          varying vec2 vUv;
          varying float vShadow; 
          
          void main() {
            vec2 ratio = vec2(
              min((uMeshSize.x / uMeshSize.y) / (uImageSize.x / uImageSize.y), 1.0),
              min((uMeshSize.y / uMeshSize.x) / (uImageSize.y / uImageSize.x), 1.0)
            );
            
            vec2 uv = vec2(
              vUv.x * ratio.x + (1.0 - ratio.x) * 0.5,
              vUv.y * ratio.y + (1.0 - ratio.y) * 0.5
            );
            
            vec4 tex = texture2D(tMap, uv);
            vec3 shadedColor = tex.rgb * vShadow;
            gl_FragColor = vec4(shadedColor, tex.a);
          }
        `,
        uniforms: {
          uOffset: { value: 0 },
          tMap: { value: texture },
          uMeshSize: { value: [0, 0] },
          uImageSize: { value: [0, 0] } 
        }
      });

      image.onload = () => {
        texture.image = image;
        program.uniforms.uImageSize.value = [image.naturalWidth, image.naturalHeight];
      };

      const mesh = new Mesh(this.gl, { geometry: this.geometry, program });
      
      mesh.rotation.x = 0; 
      mesh.rotation.y = 0;
      mesh.rotation.z = Math.PI / 18; 
      mesh.position.z = index * 0.01;
      
      mesh.setParent(this.scene);
      
      return { element, mesh, isTransitioning: false };
    });
  }

  animateToProject(index) {
    const targetMedia = this.medias[index];
    if (!targetMedia) return;

    targetMedia.isTransitioning = true;
    
    // THE FIX: Microscopic offset prevents Z-fighting without triggering a perspective pop!
    targetMedia.mesh.position.z = 0.05; 

    const fullWidth = this.viewport.width;
    const fullHeight = this.viewport.height;

    gsap.to(targetMedia.mesh.position, { x: 0, y: 0, duration: 1.2, ease: 'expo.inOut' });
    gsap.to(targetMedia.mesh.rotation, { z: 0, duration: 1.2, ease: 'expo.inOut' });
    gsap.to(targetMedia.mesh.scale, { x: fullWidth, y: fullHeight, duration: 1.2, ease: 'expo.inOut' });
    gsap.to(targetMedia.mesh.program.uniforms.uOffset, { value: 0, duration: 1.2, ease: 'expo.inOut' });
  }

  swapProject(index) {
    this.medias.forEach((media, i) => {
      media.isTransitioning = false;
      media.mesh.position.z = i * 0.01; 
      gsap.killTweensOf(media.mesh.position);
      gsap.killTweensOf(media.mesh.rotation);
      gsap.killTweensOf(media.mesh.scale);
      gsap.killTweensOf(media.mesh.program.uniforms.uOffset);
    });

    const targetMedia = this.medias[index];
    if (!targetMedia) return;

    targetMedia.isTransitioning = true;
    
    // THE FIX: Match the microscopic offset here too
    targetMedia.mesh.position.z = 0.05; 

    targetMedia.mesh.position.x = 0;
    targetMedia.mesh.position.y = 0;
    targetMedia.mesh.rotation.z = 0;
    targetMedia.mesh.scale.x = this.viewport.width;
    targetMedia.mesh.scale.y = this.viewport.height;
    targetMedia.mesh.program.uniforms.uOffset.value = 0;
    targetMedia.mesh.program.uniforms.uMeshSize.value = [this.viewport.width, this.viewport.height];
  }

  onResize() {
    this.screen = { width: window.innerWidth, height: window.innerHeight };
    this.renderer.setSize(this.screen.width, this.screen.height);
    this.camera.perspective({ aspect: this.gl.canvas.width / this.gl.canvas.height });
    
    const fov = this.camera.fov * (Math.PI / 180);
    const height = 2 * Math.tan(fov / 2) * this.camera.position.z;
    const width = height * this.camera.aspect;
    this.viewport = { height, width };
  }

  update() {
    this.medias.forEach(media => {
      media.mesh.program.uniforms.uMeshSize.value = [media.mesh.scale.x, media.mesh.scale.y];

      if (media.isTransitioning) return; 

      const bounds = media.element.getBoundingClientRect();
      media.mesh.scale.x = this.viewport.width * bounds.width / this.screen.width;
      media.mesh.scale.y = this.viewport.height * bounds.height / this.screen.height; 
      
      const centerDistanceY = (bounds.top + bounds.height / 2) - (window.innerHeight / 2);
      media.mesh.position.y = (this.viewport.height / 2) - (this.viewport.height * (bounds.top + bounds.height / 2) / this.screen.height);
      const baseX = (this.viewport.width * (bounds.left + bounds.width / 2) / this.screen.width) - (this.viewport.width / 2);
      media.mesh.position.x = baseX; 
      media.mesh.program.uniforms.uOffset.value = centerDistanceY / window.innerHeight;
      media.mesh.rotation.x = 0; 
    });

    this.renderer.render({ scene: this.scene, camera: this.camera });
  }
}
EOF

# 2. Patch Home.js to instantly freeze scroll momentum
cat << 'EOF' > app/pages/Home/index.js
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
        images: '.slider__image',
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

    // THE FIX: Dispatch a global command to instantly kill Lenis momentum
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
EOF

# 3. Patch App.js to execute the freeze and properly restart Lenis
cat << 'EOF' > app/index.js
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
EOF

echo "Stutter fixes applied! Refresh Vite to test."