```
mild-days-vanilla-oop/
├── app/
│   ├── classes/
│   │   ├── Canvas.js           # Core WebGL context, concave cylinder math, & OGL render loop
│   │   ├── Component.js        # Base UI component class for lifecycle management
│   │   └── Page.js             # Base page controller for routing & DOM selection
│   ├── components/
│   │   ├── ClunkyReveal.js     # Split-text animation with 0.02em kerning sweet spot
│   │   └── CopyClipboard.js    # Bottom-left availability widget & clipboard API
│   ├── pages/
│   │   ├── Archive/
│   │   │   └── index.js        # Archive section layout controller
│   │   └── Home/
│   │       └── index.js        # Master vertical slider controller & ResizeObserver
│   └── index.js                # App entry point, smooth scroll accumulator, & master loop
├── archive/
│   └── index.html              # Static HTML shell for the Archive route
├── public/
│   └── images/                 # 6:4 aspect ratio landscape WebGL textures
│       ├── image-1.png
│       ├── image-2.png
│       ├── image-3.png
│       ├── image-4.png
│       ├── image-5.png
│       ├── image-6.png
│       └── project-7.jpg       # Mild Days project cover
├── styles/
│   ├── base.scss               # 4-corner UI layout, z-index stacking, & native scrollbar hiding
│   └── variables.scss          # Core brutalist color variables
├── index.html                  # Main entry UI, slider DOM bounds, & passive canvas
├── package.json                # Vite, GSAP, and OGL dependencies
└── vite.config.js              # Build tools, path aliases, & local network host config
```

# A quick tip for your README:

Since you are bypassing standard CMS themes to maintain absolute control over the browser rendering pipeline, you might want to add a brief note in your README explaining that the app/classes/Canvas.js is deliberately decoupled from the DOM. This highlights your focus on high-end, production-house performance where the HTML simply dictates the bounding boxes and the WebGL handles all kinetic motion!
