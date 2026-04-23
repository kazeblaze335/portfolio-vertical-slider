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
            
            // SOFTENED BEND: Reduced multipliers from 6.0/3.5 down to 2.0/1.0 
            // This eliminates the dramatic 'flipping' distortion while keeping the concave feel
            float zBend = (distanceY * distanceY) * 2.0 + (distanceX * distanceX) * 1.0;
            pos.z += zBend; 
            
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
      
      mesh.rotation.x = 0; 
      mesh.rotation.y = 0;
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
      
      media.mesh.scale.x = this.viewport.width * bounds.width / this.screen.width;
      media.mesh.scale.y = this.viewport.height * bounds.height / this.screen.height; 
      
      const centerDistanceY = (bounds.top + bounds.height / 2) - (window.innerHeight / 2);
      
      media.mesh.position.y = (this.viewport.height / 2) - (this.viewport.height * (bounds.top + bounds.height / 2) / this.screen.height);
      
      const baseX = (this.viewport.width * (bounds.left + bounds.width / 2) / this.screen.width) - (this.viewport.width / 2);
      
      media.mesh.position.x = baseX; 
      
      const offsetValue = centerDistanceY / window.innerHeight;
      media.mesh.program.uniforms.uOffset.value = offsetValue;
    });

    this.renderer.render({ scene: this.scene, camera: this.camera });
  }
}
