# G-Advising

G-Advising is a lightweight academic course-planning app for computing
students. It helps students explore courses, track completed credits, check
prerequisites, and understand what they can take next.

The app is built with Svelte and Vite. It is a client-side app and does not
use SvelteKit.

## Features

- Mock student sign-in using a student ID and program code
- Course filtering for Cyber Security, Systems & Networking, Software Engineering, and AI
- Local student progress persistence with `localStorage`
- Available, locked, and completed course views
- Credit progress toward the 120-credit goal
- Internship prerequisite checking
- Interactive prerequisite trees
- In-browser advising chatbot powered by WebLLM and WebGPU

## Requirements

- Node.js 18+ (or a recent compatible version)
- npm
- A modern browser for the chatbot; WebGPU is required for the on-device AI

## Run locally

```bash
npm install
npm run dev
```

Open the local URL printed by Vite, usually <http://localhost:5173>.

## Build

```bash
npm run build
npm run preview
```

The production files are generated in `dist/`.

## Data

Course data is loaded from [public/courses.sql](public/courses.sql) in the
browser using `sql.js`. To change the catalogue, update that SQL file and
restart the development server.

## Project structure

```text
src/
  App.svelte       Main application and course-planning state
  Chatbot.svelte   In-browser advising assistant
  TreeNode.svelte  Recursive prerequisite tree node
  app.css          Global styles and Tailwind setup
  main.js          Svelte entry point
public/
  courses.sql      Course and internship data
```

## Notes

The sign-in flow is a demo gate only. Passwords are not validated, and the
student ID is used to infer the program code. The chatbot downloads a local
model in the browser and may require hardware acceleration.
