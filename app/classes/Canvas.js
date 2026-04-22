import { Renderer, Camera, Transform, Plane, Program, Mesh, Texture } from 'ogl';

export default class Canvas {
  constructor() {
    this.createRenderer();
    this.createCamera();
    this.createScene();
    
    // Geometry can be shared across all meshes safely
    this.geometry = new Plane(this.gl, { heightSegments: 30, widthSegments: 30 });
    
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

      // CRITICAL FIX: Every mesh gets its own unique Program to prevent uniform overriding
      const program = new Program(this.gl, {
        vertex: `
          attribute vec3 position;
          attribute vec2 uv;
          uniform mat4 modelViewMatrix;
          uniform mat4 projectionMatrix;
          uniform float uOffset;
          varying vec2 vUv;
          
          void main() {
            vUv = uv;
            vec3 pos = position;
            
            // Carousel Math (Convex / Slot Machine)
            float screenY = uOffset + (pos.y * 0.5);
            float distance = abs(screenY);
            
            // Subtracting Z pushes the mesh AWAY from the camera at the top/bottom bounds
            pos.z -= (distance * distance) * 3.0; 

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
          uOffset: { value: 0 },
          tMap: { value: texture } // Bound specifically to this mesh's texture
        }
      });

      const mesh = new Mesh(this.gl, { geometry: this.geometry, program });
      
      mesh.rotation.x = -Math.PI / 6; 
      mesh.rotation.y = Math.PI / 24;
      mesh.rotation.z = Math.PI / 18; // Positive Math.PI = Counter-Clockwise

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
      media.mesh.scale.y = (this.viewport.height * bounds.height / this.screen.height) * 1.3; 
      
      const centerDistanceY = (bounds.top + bounds.height / 2) - (window.innerHeight / 2);
      
      media.mesh.position.y = (this.viewport.height / 2) - (this.viewport.height * (bounds.top + bounds.height / 2) / this.screen.height);
      
      const baseX = (this.viewport.width * (bounds.left + bounds.width / 2) / this.screen.width) - (this.viewport.width / 2);
      
      const diagonalDrift = centerDistanceY * 0.002; 
      media.mesh.position.x = baseX + diagonalDrift;
      
      // Pass normalized distance (-0.5 to 0.5) to the vertex shader
      const offsetValue = centerDistanceY / window.innerHeight;
      media.mesh.program.uniforms.uOffset.value = offsetValue;
    });

    this.renderer.render({ scene: this.scene, camera: this.camera });
  }
}
