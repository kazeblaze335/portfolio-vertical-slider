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
            gl_FragColor = vec4(tex.rgb * vShadow, tex.a);
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
    targetMedia.mesh.position.z = 0.05; 

    gsap.to(targetMedia.mesh.position, { x: 0, y: 0, duration: 1.2, ease: 'expo.inOut' });
    gsap.to(targetMedia.mesh.rotation, { z: 0, duration: 1.2, ease: 'expo.inOut' });
    gsap.to(targetMedia.mesh.scale, { x: this.viewport.width, y: this.viewport.height, duration: 1.2, ease: 'expo.inOut' });
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
