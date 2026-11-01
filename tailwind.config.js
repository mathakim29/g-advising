/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{html,js,svelte}'],
  theme: {
    extend: {
      colors: {
        primary: '#6750a4',
        'on-surface': '#1d1b20',
        surface: '#fffbfe'
      },
      boxShadow: { material: '0 1px 3px rgba(0,0,0,.12), 0 4px 8px rgba(0,0,0,.08)' }
    }
  },
  plugins: []
};
