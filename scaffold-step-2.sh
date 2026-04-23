#!/bin/bash

echo "Removing WebGL scale distortion and locking in 6:4 horizontal aspect ratio..."

# 1. Bulletproof the CSS landscape container
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
    width: 60vw;
    max-width: 900px;
    /* Explicit 1.5 ratio = 6:4 Landscape */
    aspect-ratio: 1.5; 
    margin: 8vh 0;
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
    transform: translate(-50%, -50%) rotate(-10deg);
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

# 2. Update Canvas.js to remove the 1.3 multiplier distortion
cat << 'EOF' > app/classes/Canvas.js
import { Renderer, Camera, Transform, Plane, Program, Mesh, Texture } from 'ogl';

export default class Canvas {
  constructor() {
    this.createRenderer();
    this.createCamera();
    this.createScene();
    
    this.geometry = new Plane(this.gl, { heightSegments: 50, widthSegments: 50 });
    
    this.medias = [];
    this.onResize();
    window.addEventListener('resize', this.onResize.bind(this));
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
      image.onload = () => texture.image = image;

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
            float distanceX = abs(pos.x);
            
            // Concave hollow cylinder curve
            float zBend = (distanceY * distanceY) * 6.0 + (distanceX * distanceX) * 3.5;
            pos.z += zBend; 
            
            // Shadows naturally deepen on the curved edges
            vShadow = 1.0 - smoothstep(0.0, 5.0, zBend);
            vShadow = clamp(vShadow, 0.4, 1.0);

            gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
          }
        `,
        fragment: `
          precision highp float;
          uniform sampler2D tMap;
          
          varying vec2 vUv;
          varying float vShadow; 
          
          void main() {
            vec4 tex = texture2D(tMap, vUv);
            vec3 shadedColor = tex.rgb * vShadow;
            gl_FragColor = vec4(shadedColor, tex.a);
          }
        `,
        uniforms: {
          uOffset: { value: 0 },
          tMap: { value: texture } 
        }
      });

      const mesh = new Mesh(this.gl, { geometry: this.geometry, program });
      
      mesh.rotation.x = -Math.PI / 6; 
      mesh.rotation.y = Math.PI / 24;
      mesh.rotation.z = Math.PI / 18; 

      mesh.position.z = index * 0.01;
      mesh.setParent(this.scene);
      
      return { element, mesh };
    });
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
      const bounds = media.element.getBoundingClientRect();
      
      // THE FIX: Removed the * 1.3 multiplier to enforce the true DOM bounding box!
      media.mesh.scale.x = this.viewport.width * bounds.width / this.screen.width;
      media.mesh.scale.y = this.viewport.height * bounds.height / this.screen.height; 
      
      const centerDistanceY = (bounds.top + bounds.height / 2) - (window.innerHeight / 2);
      
      media.mesh.position.y = (this.viewport.height / 2) - (this.viewport.height * (bounds.top + bounds.height / 2) / this.screen.height);
      
      const baseX = (this.viewport.width * (bounds.left + bounds.width / 2) / this.screen.width) - (this.viewport.width / 2);
      const diagonalDrift = centerDistanceY * 0.002; 
      media.mesh.position.x = baseX + diagonalDrift;
      
      const offsetValue = centerDistanceY / window.innerHeight;
      media.mesh.program.uniforms.uOffset.value = offsetValue;
    });

    this.renderer.render({ scene: this.scene, camera: this.camera });
  }
}
EOF

echo "WebGL scale distortion cleared! The 6:4 aspect ratio is beautifully synced."