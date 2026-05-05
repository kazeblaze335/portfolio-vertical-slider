#!/bin/bash

echo "Flipping the scroll indicator to a solid fill by default..."

cat << 'EOF' > patch-indicator.js
import fs from 'fs';

let scss = fs.readFileSync('styles/base.scss', 'utf8');

// Strip out the old indicator styles
scss = scss.replace(/\.scroll-indicator\s*\{[\s\S]*?\}/g, '');
scss = scss.replace(/\.scroll-indicator:hover\s*\{[\s\S]*?\}/g, '');

// Inject the new Solid-Fill default and Outline-Hover state
const newCSS = `
.scroll-indicator {
  position: absolute;
  top: calc(75vh + 2rem);
  left: 50%;
  transform: translateX(-50%);
  width: 60px;
  height: 60px;
  border-radius: 50%;
  border: 1px solid $color-text;
  background-color: $color-text; /* THE FIX: Filled by default! */
  color: #000000; /* Dark icon so it reads clearly on the light fill */
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  z-index: 100;
  animation: indicatorBounce 2s infinite cubic-bezier(0.19, 1, 0.22, 1);
  transition: background-color 0.4s ease, color 0.4s ease, transform 0.4s ease;
  cursor: pointer;
  pointer-events: auto;
}

.scroll-indicator:hover {
  background-color: transparent; /* Wipes away the fill on hover */
  color: $color-text; /* Turns the arrow light to match the outline */
  transform: translateX(-50%) scale(1.05); /* Keeps that satisfying pop */
}
`;

fs.writeFileSync('styles/base.scss', scss + newCSS);
console.log('✅ base.scss updated: Button is now filled by default!');
EOF

node patch-indicator.js
rm patch-indicator.js

echo "Style flipped! Give Vite a quick refresh."