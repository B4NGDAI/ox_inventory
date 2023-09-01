import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import checker from 'vite-plugin-checker';
const path = require("path");

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), checker({ typescript: true })],
  base: './',
  publicDir: false,
  build: {
    outDir: 'build',
    target: 'esnext',
  },
  define: {
    'process.env': {},
  },
  esbuild: {
    logOverride: { 'this-is-undefined-in-esm': 'silent' },
  },
  resolve: {
    alias: {
      $fonts: path.resolve('./assets/chinese-rocks.ttf')
    }
  }
});
