import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./lib/**/*.{js,ts,jsx,tsx,mdx}"
  ],
  theme: {
    extend: {
      colors: {
        poketto: {
          50: "#fff8f0",
          100: "#ffecd8",
          500: "#f28f33",
          600: "#e07e22",
          700: "#b85f15"
        },
        ink: "#172033",
        canvas: "#f5f7fb"
      },
      boxShadow: {
        soft: "0 18px 45px rgba(23, 32, 51, 0.08)"
      }
    }
  },
  plugins: []
};

export default config;
