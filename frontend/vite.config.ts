import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      // Forward API requests to your Node.js backend
      '/api': 'http://localhost:3000',
      '/startSession': 'http://localhost:3000',
      '/speak': 'http://localhost:3000',
      '/stopSpeaking': 'http://localhost:3000', 
      '/stopSession': 'http://localhost:3000'
    }
  }
})