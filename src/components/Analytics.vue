<template>
  <div v-if="false"></div>
</template>

<script>
import Axios from 'axios'

export default {
  name: 'Analytics',
  data () {
    return {
    }
  },
  watch: { // handle all route changes
    '$route' (to, from) {
      Axios.post('/nmr/analytics', {
        data: {
          url: window.location.pathname /* + '/' */ + to.path,
          referrer: (document.referrer ? document.referrer : '-')
        }
      })
        .then(function (data) {
          // nothing to do
        })
        .catch(function (err) {
          console.log('Analytics report error. Err: ' + err)
        })
    }
  },
  created: function () { // handle page load since it does not fire route change
    let vm = this
    let url = window.location.href.split('?')
    let q = (url.length === 2 ? url[1] : null)
    // console.log('stringified query: ' + q)
    Axios.post('/nmr/analytics', {
      data: {
        url: window.location.pathname /* + '/' */ + vm.$route.path + (q ? ('?' + q) : ''),
        referrer: (document.referrer ? document.referrer : '-')
      }
    })
      .then(function (data) {
        // nothing to do
      })
      .catch(function (err) {
        console.log('Analytics report error. Err: ' + err)
      })
  }
}
</script>

<style scoped>
  img {
    position: fixed;
    background-color: transparent;
    left: 0;
    top: 0;
  }
</style>
