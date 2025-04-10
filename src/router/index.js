import { createRouter, createWebHistory } from 'vue-router';
import LoginPage from '@/components/LoginPage.vue';
import CrowdfundPage from '@/components/CrowdfundPage.vue';

const routes = [
    { path: '/', name: 'Login', component: LoginPage },
    { path: '/crowdfund', name: 'Crowdfund', component: CrowdfundPage }
];

const router = createRouter({
    history: createWebHistory(),
    routes
});

export default router;

