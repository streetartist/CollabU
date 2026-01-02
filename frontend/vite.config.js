import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vue-vendor': ['vue', 'vue-router', 'pinia', '@vueuse/core'],
          'element-plus': ['element-plus', '@element-plus/icons-vue'],
          'md-editor': ['md-editor-v3'],
          'gantt': ['@lee576/vue3-gantt'],
          'calendar': ['v-calendar']
        }
      }
    }
  },
  server: {
    proxy: {
      '/api': {
        // target: 'http://localhost:5000', 
        target: 'https://collabu.zeabur.app',
        changeOrigin: true,
      },
      '/socket.io': {
        // target: 'http://localhost:5000', 
        target: 'https://collabu.zeabur.app',
        changeOrigin: true,
        ws: true
      }
    }
  }
})
