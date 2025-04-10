import { createApp } from 'vue'
import App from './App.vue'
import process from 'process'
window.process = process
import router from './router';
createApp(App).use(router).mount('#app');
//createApp(App).mount('#app')
