<template>
  <NavBar v-if="showNavBar" />
  <div :class="{ 'main-container': showNavBar }">
    <Sidebar v-if="showSidebar" />
    <div class="layout-body" :class="{ 'with-sidebar': showSidebar }">
      <router-view></router-view>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import NavBar from './components/NavBar.vue'
import Sidebar from './components/SideBar.vue'

const route = useRoute()
const showNavBar = computed(() => {
  const hiddenRoutes = ['Login', 'Register']
  return !hiddenRoutes.includes(route.name)
})
const showSidebar = computed(() => {
  const hiddenRoutes = ['Login', 'Register']
  return !hiddenRoutes.includes(route.name)
})

try {
  const saved = localStorage.getItem('sidebar-collapsed')
  const width = saved === '1' ? '64px' : '260px'
  document.documentElement.style.setProperty('--sidebar-width', width)
} catch {}
</script>

<style>
html, body, #app {
  height: 100%;
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  overflow: hidden;
}

.main-container {
  padding-top: 60px;
  height: 100vh;
  box-sizing: border-box;
  background-color: #f5f7fa;
  overflow: hidden;
}
.layout-body {
  height: calc(100vh - 60px);
  box-sizing: border-box;
  padding: 16px;
  overflow: hidden;
}
.layout-body.with-sidebar {
  margin-left: var(--sidebar-width, 260px);
}
</style>
