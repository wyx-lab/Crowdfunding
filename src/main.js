import { createApp } from 'vue'
import App from './App.vue'
import process from 'process'
window.process = process
createApp(App).mount('#app')
