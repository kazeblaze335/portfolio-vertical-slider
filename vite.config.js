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
