/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#6C63FF', // Mobil uygulamadaki Mor renk
        secondary: '#2D2D3A', // Koyu tema rengi
        background: '#F9F9FB',
      }
    },
  },
  plugins: [],
}