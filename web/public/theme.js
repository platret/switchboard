;(function () {
  var stored = null
  try {
    stored = JSON.parse(localStorage.getItem('switchboard.theme'))
  } catch (error) {
    stored = null
  }
  var dark = stored === 'dark' || (stored !== 'light' && window.matchMedia('(prefers-color-scheme: dark)').matches)
  document.documentElement.dataset.theme = dark ? 'dark' : 'light'
})()
