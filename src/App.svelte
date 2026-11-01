<script>
  import { onMount } from 'svelte';
  import initSqlJs from 'sql.js';
  import wasmUrl from 'sql.js/dist/sql-wasm.wasm?url';
  import TomSelect from 'tom-select';
  import 'tom-select/dist/css/tom-select.css';
  import Chatbot from './Chatbot.svelte';
  import TreeNode from './TreeNode.svelte';

  const PROGRAMS = [
    { code: 'CS', name: 'Cyber Security' },
    { code: 'SN', name: 'Systems & Networking' },
    { code: 'BSW', name: 'Software Engineering' },
    { code: 'AI', name: 'Artificial Intelligence' }
  ];

  let rows = [];
  let internshipReqs = {};   // { CS: ['CSEB2213', ...], ... }
  let loading = true;
  let error = '';

  const CREDIT_GOAL = 120;
  const STORAGE_KEY = 'g-advising-state';

  let loggedIn = false;         // mock auth gate
  let studentId = '';           // entered student id
  let password = '';            // entered password (never checked — mock)
  let loginError = '';          // shown only after the user presses Sign in

  let residency = '';        // '' | 'local' | 'international'
  let program = '';          // selected bachelor code
  let taken = new Set();     // set of course_code strings the student has completed
  let takenUI = 0;           // bump to force reactivity when the Set mutates
  let activeTab = 'available';  // 'available' | 'locked' | 'taken' | 'tree'
  let treeCourse = '';       // course_code whose prerequisite tree is shown
  let restored = false;      // becomes true once localStorage has been read

  // Infer the bachelor from the student id. Check longer codes first so e.g.
  // "BSW" isn't mistaken, and codes are matched case-insensitively anywhere in the id.
  function detectProgramFromId(id) {
    const s = String(id).toUpperCase();
    for (const code of ['BSW', 'CS', 'SN', 'AI']) {
      if (s.includes(code)) return code;
    }
    return '';
  }

  function login() {
    // Mock auth: the password is never validated. We only check the ID carries
    // a recognisable program code, and we reveal the result on submit (not live).
    const detected = detectProgramFromId(studentId);
    if (!detected) {
      loginError = 'That student ID is not recognised. It must contain your program code (CS, SN, BSW, or AI).';
      return;
    }
    loginError = '';
    program = detected;            // auto-select program from the id
    taken = new Set();
    takenUI++;
    activeTab = 'available';
    treeCourse = '';
    loggedIn = true;
  }

  function logout() {
    loggedIn = false;
    studentId = '';
    password = '';
    loginError = '';
    residency = '';
    program = '';
    taken = new Set();
    takenUI++;
    activeTab = 'available';
    treeCourse = '';
    try { localStorage.removeItem(STORAGE_KEY); } catch {}
  }



  // Quick lookup: course_code -> course row (across all programs).
  let byCode = new Map();

  onMount(async () => {
    try {
      const SQL = await initSqlJs({ locateFile: () => wasmUrl });
      const text = await (await fetch('/courses.sql')).text();
      const db = new SQL.Database();
      db.run(text);
      const info = db.exec('PRAGMA table_info(subjects)')[0].values.map(v => v[1]);
      rows = db.exec('SELECT * FROM subjects')[0].values.map(
        v => Object.fromEntries(v.map((x, i) => [info[i], x]))
      );
      byCode = new Map(rows.map(r => [r.course_code, r]));

      // Internship requirements per program.
      const intRes = db.exec('SELECT course, prerequisites FROM internship');
      if (intRes.length) {
        for (const [code, prereq] of intRes[0].values) internshipReqs[code] = prereqList(prereq);
      }

      restoreState();
      loading = false;
    } catch (e) {
      error = `Could not load courses.sql: ${e.message}`;
      loading = false;
    }
  });

  // ---- Persistence ----
  function restoreState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const s = JSON.parse(raw);
        loggedIn = !!s.loggedIn;
        studentId = s.studentId || '';
        residency = s.residency || '';
        program = s.program || '';
        taken = new Set(Array.isArray(s.taken) ? s.taken : []);
        takenUI++;
      }
    } catch {}
    restored = true;
  }

  function saveState() {
    if (!restored) return; // don't overwrite before we've loaded
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        loggedIn, studentId, residency, program, taken: [...taken]
      }));
    } catch {}
  }

  // Persist whenever the meaningful state changes.
  $: (loggedIn, studentId, residency, program, takenUI, saveState());

  // Parse a prerequisite string into an array of course codes.
  function prereqList(value) {
    if (!value || String(value).trim().toLowerCase() === 'none') return [];
    return String(value).split(',').map(s => s.trim()).filter(Boolean);
  }

  // `international = TRUE` courses are for international students only.
  function matchesResidency(course) {
    const intlOnly = course.international === 1 || course.international === true;
    return residency === 'international' ? true : !intlOnly;
  }

  // Courses belonging to the chosen bachelor, filtered by residency.
  $: programCourses = program
    ? rows.filter(r =>
        String(r.available_for).split(',').map(s => s.trim()).includes(program)
        && matchesResidency(r))
    : [];

  $: programCodes = new Set(programCourses.map(r => r.course_code));

  function evaluate(course) {
    takenUI;
    const reqs = prereqList(course.prerequisite);
    const missing = reqs.filter(code => !taken.has(code));
    if (taken.has(course.course_code)) return { state: 'taken', missing: [], reqs };
    return { state: missing.length === 0 ? 'available' : 'locked', missing, reqs };
  }

  function unlocksFor(code) {
    takenUI;
    return programCourses
      .filter(c => !taken.has(c.course_code))
      .filter(c => prereqList(c.prerequisite).includes(code))
      .map(c => c.course_code);
  }

  const STATE_ORDER = { available: 0, locked: 1, taken: 2 };

  // Reference `taken` and `takenUI` directly so Svelte tracks them as dependencies
  // of this reactive statement (it can't see the reads inside evaluate()/unlocksFor()).
  $: evaluated = (taken, takenUI, programCourses
    .map(c => ({ course: c, ...evaluate(c), unlocks: unlocksFor(c.course_code) }))
    .sort((a, b) =>
      (STATE_ORDER[a.state] - STATE_ORDER[b.state])
      || a.course.course_code.localeCompare(b.course.course_code)));

  // Split courses into tables: available now, still locked, already taken.
  $: availableCourses = evaluated.filter(e => e.state === 'available');
  $: lockedCourses = evaluated.filter(e => e.state === 'locked');
  $: takenCourses = evaluated.filter(e => e.state === 'taken');

  $: counts = {
    total: programCourses.length,
    taken: takenCourses.length,
    available: availableCourses.length,
    locked: lockedCourses.length
  };

  // Credit tally toward the 120-hour goal (sum of taken program courses).
  $: earnedCredits = (takenUI, takenCourses.reduce((sum, e) => sum + (Number(e.course.credit_hours) || 0), 0));
  $: creditPct = Math.min(100, Math.round((earnedCredits / CREDIT_GOAL) * 100));
  $: creditsLeft = Math.max(0, CREDIT_GOAL - earnedCredits);

  // Compulsory vs elective credit split (earned).
  $: coreCredits = (takenUI, takenCourses.filter(e => e.course.compulsory).reduce((s, e) => s + (Number(e.course.credit_hours) || 0), 0));
  $: electiveCredits = earnedCredits - coreCredits;

  // ---- Internship eligibility (from the internship table) ----
  $: internshipPrereqs = (takenUI, internshipReqs[program] ?? []);
  $: internshipDone = internshipPrereqs.filter(c => taken.has(c));
  $: internshipMissing = internshipPrereqs.filter(c => !taken.has(c));
  $: internshipEligible = internshipPrereqs.length > 0 && internshipMissing.length === 0;

  // ---- Prerequisite tree for a selected course ----
  // Returns a nested node { code, name, state, children } following the prereq chain.
  function buildTree(code, seen = new Set()) {
    const course = byCode.get(code);
    const state = taken.has(code)
      ? 'taken'
      : (prereqList(course?.prerequisite).every(r => taken.has(r)) ? 'available' : 'locked');
    const node = { code, name: course?.course_name ?? '(unknown course)', state, children: [], exists: !!course };
    if (!course || seen.has(code)) return node;
    seen.add(code);
    for (const req of prereqList(course.prerequisite)) {
      node.children.push(buildTree(req, new Set(seen)));
    }
    return node;
  }
  $: tree = (takenUI, treeCourse ? buildTree(treeCourse) : null);

  // Collect a course plus its full prerequisite chain (only codes that exist).
  function withPrereqChain(code, acc = new Set()) {
    if (acc.has(code)) return acc;
    acc.add(code);
    const course = byCode.get(code);
    if (course) {
      for (const req of prereqList(course.prerequisite)) {
        if (byCode.has(req)) withPrereqChain(req, acc);
      }
    }
    return acc;
  }

  function choose(code) {
    program = code;
    taken = new Set();
    takenUI++;
    activeTab = 'available';
    treeCourse = '';
  }

  function chooseResidency(value) {
    // Program is already set from the student ID at login — keep it.
    residency = value;
    activeTab = 'available';
    treeCourse = '';
  }

  function restart() {
    residency = '';
    program = '';
    taken = new Set();
    takenUI++;
    activeTab = 'available';
    treeCourse = '';
    try { localStorage.removeItem(STORAGE_KEY); } catch {}
  }

  function clearTaken() {
    taken = new Set();
    takenUI++;
    if (tomInstance) tomInstance.clear(true);
  }

  const programName = code => PROGRAMS.find(p => p.code === code)?.name ?? code;

  // ---- Tom Select wiring ----
  let tomInstance = null;

  // Svelte action: turn a native <select multiple> into a Tom Select control.
  function tomSelect(node) {
    tomInstance = new TomSelect(node, {
      plugins: ['remove_button'],
      maxItems: null,
      valueField: 'code',
      labelField: 'label',
      searchField: ['code', 'label'],
      placeholder: 'Search and add courses you have completed…',
      hideSelected: true,
      render: {
        option: (data, escape) =>
          `<div class="ts-opt"><span class="ts-code">${escape(data.code)}</span><span class="ts-sep">|</span><span class="ts-name">${escape(data.name)}</span></div>`,
        item: (data, escape) =>
          `<div class="ts-item"><span class="ts-code">${escape(data.code)}</span><span class="ts-sep">|</span><span class="ts-name">${escape(data.name)}</span></div>`
      },
      onItemAdd: (value) => {
        // Adding a course pulls in its full prerequisite chain.
        for (const c of withPrereqChain(value)) taken.add(c);
        taken = taken;
        takenUI++;
        syncTomToTaken();
      },
      onItemRemove: (value) => {
        taken.delete(value);
        taken = taken;
        takenUI++;
      }
    });
    return { destroy() { tomInstance?.destroy(); tomInstance = null; } };
  }

  // Keep the Tom Select control's options and current items aligned with program + taken.
  function rebuildOptions(courses) {
    if (!tomInstance) return;
    tomInstance.clearOptions();
    tomInstance.addOptions(
      courses.map(c => ({ code: c.course_code, name: c.course_name, label: `${c.course_code} ${c.course_name}` }))
    );
    syncTomToTaken();
  }

  // Ensure every taken code is shown as a selected item (covers auto-added prereqs).
  function syncTomToTaken() {
    if (!tomInstance) return;
    for (const code of taken) {
      if (!tomInstance.options[code]) {
        const c = byCode.get(code);
        if (c) tomInstance.addOption({ code, name: c.course_name, label: `${code} ${c.course_name}` });
      }
      tomInstance.addItem(code, true); // silent: don't retrigger onItemAdd
    }
  }

  // Rebuild the option list whenever the active program's course set changes.
  $: if (tomInstance && program) rebuildOptions(programCourses);
</script>

{#if loading}
  <!-- Boot screen while the course database loads -->
  <div class="grid min-h-screen place-items-center bg-surface text-[#79747e]">
    <div class="text-center">
      <span class="material-symbols-rounded animate-spin text-3xl">progress_activity</span>
      <p class="mt-3">Loading courses…</p>
    </div>
  </div>

{:else if !loggedIn}
  <!-- Mock login with campus background -->
  <div class="login-bg relative grid min-h-screen place-items-center p-6">
    <div class="absolute inset-0 bg-black/55"></div>
    <div class="relative z-10 w-full max-w-md">
      <div class="mb-6 text-center text-white">
        <div class="mx-auto mb-4 grid h-14 w-14 place-items-center rounded-2xl bg-primary shadow-material">
          <span class="material-symbols-rounded text-3xl">school</span>
        </div>
        <h1 class="text-3xl font-semibold tracking-tight">Sign in to G-Advising</h1>
        <p class="mt-2 text-white/80">Use your student ID and password.</p>
      </div>

      <form class="space-y-4 rounded-3xl bg-white/95 p-6 shadow-material backdrop-blur" on:submit|preventDefault={login}>
        <div>
          <label for="student-id" class="mb-1 block text-sm font-medium text-[#49454f]">Student ID</label>
          <input
            id="student-id"
            bind:value={studentId}
            on:input={() => (loginError = '')}
            autocomplete="username"
            placeholder="e.g. BSW2024001"
            class="h-11 w-full rounded-xl border border-[#79747e] px-4 text-sm outline-none focus:border-primary" />
        </div>

        <div>
          <label for="password" class="mb-1 block text-sm font-medium text-[#49454f]">Password</label>
          <input
            id="password"
            type="password"
            bind:value={password}
            autocomplete="current-password"
            placeholder="••••••••"
            class="h-11 w-full rounded-xl border border-[#79747e] px-4 text-sm outline-none focus:border-primary" />
        </div>

        {#if loginError}
          <p class="flex items-center gap-1 text-sm text-[#8c1d18]">
            <span class="material-symbols-rounded text-base">error</span>{loginError}
          </p>
        {/if}

        <button
          type="submit"
          disabled={!studentId.trim() || !password}
          class="grid h-11 w-full place-items-center rounded-full bg-primary text-sm font-semibold text-white transition hover:opacity-90 disabled:opacity-40">
          Sign in
        </button>
        <p class="text-center text-xs text-[#9e9e9e]">Demo login — any password works. Your ID must contain your program code (CS, SN, BSW, or AI).</p>
      </form>
    </div>
  </div>

{:else}
<div class="min-h-screen bg-surface pb-16">
  <header class="flex flex-wrap items-center justify-between gap-3 border-b border-[#e7e0ec] bg-white px-4 py-3 sm:px-6 lg:px-10">
    <div class="flex items-center gap-3">
      <div class="grid h-10 w-10 place-items-center rounded-2xl bg-primary text-white shadow-material sm:h-11 sm:w-11">
        <span class="material-symbols-rounded">school</span>
      </div>
      <div>
        <p class="text-base font-semibold sm:text-lg">G-Advising</p>
        <p class="hidden text-xs text-[#79747e] sm:block">Plan what you can take next</p>
      </div>
    </div>
    {#if loggedIn}
      <div class="flex flex-wrap items-center justify-end gap-2">
        {#if studentId}
          <span class="badge bg-[#f3edf7] text-[#49454f]" title="Student ID">{studentId}</span>
        {/if}
        {#if residency}
          <span class="badge {residency === 'international' ? 'bg-[#e8f0fe] text-[#1b3a6b]' : 'bg-[#d8f3dc] text-[#1b4332]'}">
            {residency === 'international' ? 'International' : 'Local'}
          </span>
        {/if}
        {#if program}
          <button class="hidden rounded-full border border-[#cac4d0] px-3 py-2 text-sm font-medium hover:bg-[#f5eff7] sm:inline-block" on:click={() => choose('')}>
            Change program
          </button>
        {/if}
        <button class="rounded-full border border-[#cac4d0] px-3 py-2 text-sm font-medium hover:bg-[#f5eff7] sm:px-4" on:click={logout}>
          Log out
        </button>
      </div>
    {/if}
  </header>

  <main class="mx-auto max-w-[1200px] p-4 sm:p-6 lg:p-10">
    {#if !residency}
      <!-- Residency step (asked after login) -->
      <div class="mb-8">
        <p class="mb-2 text-sm font-medium text-primary">{programName(program)} ({program})</p>
        <h1 class="text-2xl font-semibold tracking-tight sm:text-3xl lg:text-4xl">Are you a local or international student?</h1>
        <p class="mt-2 text-[#79747e]">This adjusts which courses apply to you.</p>
      </div>
      <div class="grid gap-4 sm:grid-cols-2">
        <button
          class="card flex items-center justify-between p-6 text-left transition hover:border-primary hover:shadow-material"
          on:click={() => chooseResidency('local')}>
          <div>
            <p class="text-xl font-semibold">Local student</p>
            <p class="mt-1 text-sm text-[#79747e]">Malaysian / domestic enrolment</p>
          </div>
          <span class="material-symbols-rounded text-primary">home</span>
        </button>
        <button
          class="card flex items-center justify-between p-6 text-left transition hover:border-primary hover:shadow-material"
          on:click={() => chooseResidency('international')}>
          <div>
            <p class="text-xl font-semibold">International student</p>
            <p class="mt-1 text-sm text-[#79747e]">Includes international-only courses</p>
          </div>
          <span class="material-symbols-rounded text-primary">public</span>
        </button>
      </div>

    {:else if !program}
      <!-- Step 2: choose a bachelor -->
      <div class="mb-8">
        <p class="mb-2 text-sm font-medium text-primary">Step 2 of 3</p>
        <h1 class="text-2xl font-semibold tracking-tight sm:text-3xl lg:text-4xl">Which bachelor are you in?</h1>
        <p class="mt-2 text-[#79747e]">Pick your program to see its courses.</p>
      </div>
      <div class="grid gap-4 sm:grid-cols-2">
        {#each PROGRAMS as p}
          <button
            class="card flex items-center justify-between p-6 text-left transition hover:border-primary hover:shadow-material"
            on:click={() => choose(p.code)}>
            <div>
              <p class="text-xs font-semibold uppercase tracking-wide text-primary">{p.code}</p>
              <p class="mt-1 text-xl font-semibold">{p.name}</p>
              <p class="mt-1 text-sm text-[#79747e]">
                {rows.filter(r => String(r.available_for).split(',').map(s => s.trim()).includes(p.code) && matchesResidency(r)).length} courses
              </p>
            </div>
            <span class="material-symbols-rounded text-primary">arrow_forward</span>
          </button>
        {/each}
      </div>

    {:else}
      <!-- Step 3: pick taken courses, see what's available -->
      <div class="mb-6">
        <p class="mb-2 text-sm font-medium text-primary">Step 3 of 3 · {programName(program)} · {residency === 'international' ? 'International' : 'Local'}</p>
        <h1 class="text-2xl font-semibold tracking-tight sm:text-3xl lg:text-4xl">Which courses have you taken?</h1>
        <p class="mt-2 text-[#79747e]">Add the courses you've completed. Prerequisites are added automatically, and the table below shows what you can take next.</p>
      </div>

      <!-- Tom Select multi-select -->
      <div class="card mb-6 p-5">
        <div class="flex items-center justify-between">
          <label for="taken-select" class="text-sm font-medium text-[#49454f]">Courses completed</label>
          {#if counts.taken}
            <button class="text-sm font-semibold text-primary hover:underline" on:click={clearTaken}>Clear all</button>
          {/if}
        </div>
        <select id="taken-select" multiple use:tomSelect></select>
      </div>

      <!-- Credit progress + internship eligibility -->
      <div class="mb-6 grid gap-4 lg:grid-cols-2">
        <!-- Credits -->
        <div class="card p-6">
          <div class="flex items-end justify-between">
            <div>
              <p class="text-sm font-medium text-[#79747e]">Credit hours earned</p>
              <p class="mt-1 text-3xl font-semibold">{earnedCredits}<span class="text-lg font-normal text-[#79747e]"> / {CREDIT_GOAL}</span></p>
            </div>
            <span class="badge {earnedCredits >= CREDIT_GOAL ? 'bg-[#d8f3dc] text-[#1b4332]' : 'bg-[#eaddff] text-[#21005d]'}">
              {earnedCredits >= CREDIT_GOAL ? 'Goal reached' : creditsLeft + ' to go'}
            </span>
          </div>
          <div class="mt-4 h-3 w-full overflow-hidden rounded-full bg-[#eee8f0]">
            <div class="h-full rounded-full bg-primary transition-all" style="width: {creditPct}%"></div>
          </div>
          <div class="mt-3 flex flex-wrap gap-2 text-xs">
            <span class="badge bg-[#eaddff] text-[#21005d]">Core {coreCredits}</span>
            <span class="badge bg-[#e8f0fe] text-[#1b3a6b]">Electives {electiveCredits}</span>
            <span class="text-[#79747e]">· {creditPct}% of graduation credits</span>
          </div>
        </div>

        <!-- Internship eligibility -->
        <div class="card p-6">
          <div class="flex items-center justify-between">
            <p class="text-sm font-medium text-[#79747e]">Internship eligibility · {program}</p>
            {#if internshipPrereqs.length === 0}
              <span class="badge bg-[#e0e0e0] text-[#333]">No data</span>
            {:else if internshipEligible}
              <span class="badge bg-[#d8f3dc] text-[#1b4332]">● Eligible</span>
            {:else}
              <span class="badge bg-[#ffe8cc] text-[#7a3e00]">● Not yet</span>
            {/if}
          </div>
          {#if internshipPrereqs.length}
            <p class="mt-2 text-sm text-[#49454f]">
              {#if internshipEligible}
                You've met all internship requirements. 🎉
              {:else}
                {internshipDone.length} of {internshipPrereqs.length} required courses completed.
              {/if}
            </p>
            <div class="mt-3 flex flex-wrap gap-1.5">
              {#each internshipPrereqs as req}
                <span class="badge text-xs {taken.has(req) ? 'bg-[#d8f3dc] text-[#1b4332]' : 'bg-[#fde2e1] text-[#8c1d18]'}" title={byCode.get(req)?.course_name ?? req}>
                  {taken.has(req) ? '✓ ' : ''}{req}
                </span>
              {/each}
            </div>
          {/if}
        </div>
      </div>

      <!-- Tabs -->
      <div class="mb-4 flex flex-wrap gap-2">
        {#each [['available', 'Available', counts.available], ['locked', 'Locked', counts.locked], ['taken', 'Taken', counts.taken]] as [id, label, n]}
          <button
            class="rounded-full px-4 py-2 text-sm font-medium transition"
            class:active={activeTab === id}
            class:idle={activeTab !== id}
            on:click={() => activeTab = id}>{label} ({n})</button>
        {/each}
        <button
          class="rounded-full px-4 py-2 text-sm font-medium transition"
          class:active={activeTab === 'tree'}
          class:idle={activeTab !== 'tree'}
          on:click={() => activeTab = 'tree'}>Prerequisite tree</button>
      </div>

      {#if activeTab === 'available'}
        <!-- Available table: courses you can take now -->
        <div class="card overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[760px] text-left text-sm">
              <thead class="bg-[#f7f2fa] text-xs uppercase tracking-wide text-[#79747e]">
                <tr>
                  <th class="px-3 py-3 font-semibold sm:px-5">Course</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Credits</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Type</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Prerequisites</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Unlocks</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-[#eee8f0]">
                {#each availableCourses as { course, reqs, unlocks } (course.course_code)}
                  <tr class="transition hover:bg-[#fbf8fc]">
                    <td class="px-3 py-4 sm:px-5">
                      <p class="font-semibold text-primary">{course.course_code}</p>
                      <p class="text-[#1d1b20]">{course.course_name}</p>
                    </td>
                    <td class="px-3 py-4 sm:px-5">{course.credit_hours}</td>
                    <td class="px-3 py-4 sm:px-5">
                      {#if course.compulsory}
                        <span class="badge bg-[#eaddff] text-[#21005d]">Compulsory</span>
                      {:else}
                        <span class="badge bg-[#e8f0fe] text-[#1b3a6b]">Elective</span>
                      {/if}
                    </td>
                    <td class="px-3 py-4 sm:px-5">
                      {#if reqs.length === 0}
                        <span class="text-xs text-[#79747e]">None</span>
                      {:else}
                        <div class="flex flex-wrap gap-1.5">
                          {#each reqs as req}
                            <span class="badge text-xs bg-[#d8f3dc] text-[#1b4332]" title={byCode.get(req)?.course_name ?? req}>✓ {req}</span>
                          {/each}
                        </div>
                      {/if}
                    </td>
                    <td class="px-3 py-4 sm:px-5">
                      {#if unlocks.length}
                        <div class="flex flex-wrap gap-1" title={'Unlocks: ' + unlocks.join(', ')}>
                          {#each unlocks as u}
                            <span class="badge bg-[#eef7f0] text-xs text-[#1b4332]">{u}</span>
                          {/each}
                        </div>
                      {:else}
                        <span class="text-xs text-[#79747e]">—</span>
                      {/if}
                    </td>
                  </tr>
                {:else}
                  <tr><td colspan="5" class="px-3 py-12 text-center text-[#79747e] sm:px-5">Nothing available yet. Add the courses you've completed above.</td></tr>
                {/each}
              </tbody>
            </table>
          </div>
        </div>

      {:else if activeTab === 'locked'}
        <!-- Locked table: courses still missing prerequisites -->
        <div class="card overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[760px] text-left text-sm">
              <thead class="bg-[#f7f2fa] text-xs uppercase tracking-wide text-[#79747e]">
                <tr>
                  <th class="px-3 py-3 font-semibold sm:px-5">Course</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Credits</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Type</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Prerequisites</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Missing</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-[#eee8f0]">
                {#each lockedCourses as { course, missing, reqs } (course.course_code)}
                  <tr class="locked transition hover:bg-[#fbf8fc]">
                    <td class="px-3 py-4 sm:px-5">
                      <p class="font-semibold text-primary">{course.course_code}</p>
                      <p>{course.course_name}</p>
                    </td>
                    <td class="px-3 py-4 sm:px-5">{course.credit_hours}</td>
                    <td class="px-3 py-4 sm:px-5">
                      {#if course.compulsory}
                        <span class="badge bg-[#eaddff] text-[#21005d]">Compulsory</span>
                      {:else}
                        <span class="badge bg-[#e8f0fe] text-[#1b3a6b]">Elective</span>
                      {/if}
                    </td>
                    <td class="px-3 py-4 sm:px-5">
                      <div class="flex flex-wrap gap-1.5">
                        {#each reqs as req}
                          <span
                            class="badge text-xs {taken.has(req) ? 'bg-[#d8f3dc] text-[#1b4332]' : 'bg-[#fde2e1] text-[#8c1d18]'}"
                            title={taken.has(req) ? 'Completed' : (programCodes.has(req) ? 'Not yet taken' : 'Prerequisite outside this program')}>
                            {taken.has(req) ? '✓ ' : ''}{req}
                          </span>
                        {/each}
                      </div>
                    </td>
                    <td class="px-3 py-4 sm:px-5">
                      <span class="badge bg-[#ffe8cc] text-[#7a3e00]" title={'Missing: ' + missing.join(', ')}>
                        Needs {missing.length} prereq{missing.length > 1 ? 's' : ''}
                      </span>
                    </td>
                  </tr>
                {:else}
                  <tr><td colspan="5" class="px-3 py-12 text-center text-[#79747e] sm:px-5">Nothing locked — everything left is available.</td></tr>
                {/each}
              </tbody>
            </table>
          </div>
        </div>

      {:else if activeTab === 'taken'}
        <!-- Taken table: completed courses -->
        <div class="card overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[640px] text-left text-sm">
              <thead class="bg-[#f7f2fa] text-xs uppercase tracking-wide text-[#79747e]">
                <tr>
                  <th class="px-3 py-3 font-semibold sm:px-5">Course</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Credits</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Type</th>
                  <th class="px-3 py-3 font-semibold sm:px-5">Unlocks</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-[#eee8f0]">
                {#each takenCourses as { course, unlocks } (course.course_code)}
                  <tr class="transition hover:bg-[#fbf8fc]">
                    <td class="px-3 py-4 sm:px-5">
                      <p class="font-semibold text-primary">{course.course_code}</p>
                      <p class="text-[#1d1b20]">{course.course_name}</p>
                    </td>
                    <td class="px-3 py-4 sm:px-5">{course.credit_hours}</td>
                    <td class="px-3 py-4 sm:px-5">
                      {#if course.compulsory}
                        <span class="badge bg-[#eaddff] text-[#21005d]">Compulsory</span>
                      {:else}
                        <span class="badge bg-[#e8f0fe] text-[#1b3a6b]">Elective</span>
                      {/if}
                    </td>
                    <td class="px-3 py-4 sm:px-5">
                      {#if unlocks.length}
                        <div class="flex flex-wrap gap-1" title={'Unlocks: ' + unlocks.join(', ')}>
                          {#each unlocks as u}
                            <span class="badge bg-[#eef7f0] text-xs text-[#1b4332]">{u}</span>
                          {/each}
                        </div>
                      {:else}
                        <span class="text-xs text-[#79747e]">—</span>
                      {/if}
                    </td>
                  </tr>
                {:else}
                  <tr><td colspan="4" class="px-3 py-12 text-center text-[#79747e] sm:px-5">No courses marked as taken yet.</td></tr>
                {/each}
              </tbody>
            </table>
          </div>
        </div>

      {:else}
        <!-- Prerequisite tree -->
        <div class="card p-5">
          <label for="tree-pick" class="text-sm font-medium text-[#49454f]">Pick a course to see its prerequisite chain</label>
          <select id="tree-pick" bind:value={treeCourse} class="mt-2 h-11 w-full max-w-md rounded-xl border border-[#79747e] bg-white px-3 text-sm outline-none focus:border-primary">
            <option value="">Select a course…</option>
            {#each programCourses as c}
              <option value={c.course_code}>{c.course_code} — {c.course_name}</option>
            {/each}
          </select>

          {#if tree}
            <div class="mt-4 flex flex-wrap gap-3 text-xs text-[#79747e]">
              <span class="inline-flex items-center gap-1"><span class="h-3 w-3 rounded-full bg-[#d8f3dc]"></span> Completed</span>
              <span class="inline-flex items-center gap-1"><span class="h-3 w-3 rounded-full bg-[#eaddff]"></span> Available</span>
              <span class="inline-flex items-center gap-1"><span class="h-3 w-3 rounded-full bg-[#fde2e1]"></span> Locked / missing</span>
            </div>
            <div class="mt-4 overflow-x-auto">
              <TreeNode node={tree} />
            </div>
            {#if tree.children.length === 0}
              <p class="mt-3 text-sm text-[#79747e]">This course has no prerequisites — you can take it any time.</p>
            {/if}
          {:else}
            <p class="mt-4 text-sm text-[#79747e]">Choose a course above to visualise everything it depends on.</p>
          {/if}
        </div>
      {/if}
    {/if}
  </main>

  {#if program}
    <Chatbot
      programName={programName(program)}
      {residency}
      {availableCourses}
      {lockedCourses}
      {takenCourses}
      {earnedCredits}
      creditGoal={CREDIT_GOAL}
      {byCode} />
  {/if}
</div>
{/if}

<style>
  :global(.card) { @apply rounded-3xl border border-[#e7e0ec] bg-white shadow-sm; }
  :global(.badge) { @apply inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium; }
  .login-bg {
    background-image: url('https://selangor.travel/wp-content/uploads/2019/09/Universiti_Tenaga_Nasional_Information_Resource_Centre_Tourism_Selangor.jpg');
    background-size: cover;
    background-position: center;
  }
  :global(.active) { @apply bg-primary text-white; }
  :global(.idle) { @apply border border-[#cac4d0] bg-white text-[#49454f] hover:bg-[#f5eff7]; }
  /* Locked courses are greyed out and muted */
  :global(tr.locked) { @apply bg-[#f5f5f5] text-[#9e9e9e]; }
  :global(tr.locked .text-primary) { color: #9e9e9e !important; }
  :global(tr.locked .badge) { opacity: 0.6; }

  /* Tom Select theming to match the Material look */
  :global(.ts-wrapper) { margin-top: 0.5rem; }
  :global(.ts-control) {
    border-radius: 0.75rem;
    border-color: #79747e;
    padding: 0.5rem 0.75rem;
    min-height: 3rem;
  }
  :global(.ts-control.focus) { border-color: #6750a4; box-shadow: 0 0 0 1px #6750a4; }
  :global(.ts-control .item) {
    background: #eaddff;
    color: #21005d;
    border: none;
    border-radius: 9999px;
    padding: 2px 6px 2px 10px;
    font-weight: 600;
    font-size: 0.8rem;
  }
  :global(.ts-dropdown) { border-radius: 0.75rem; border-color: #e7e0ec; }
  :global(.ts-code) { font-weight: 600; color: #6750a4; }
  :global(.ts-sep) { margin: 0 0.4rem; color: #cac4d0; }
  :global(.ts-name) { color: #49454f; }
  :global(.ts-opt) { padding: 2px 0; }
  :global(.ts-item) { display: inline-flex; align-items: center; }
  /* Inside a selected pill, keep text readable on the purple background */
  :global(.ts-control .item .ts-code) { color: #21005d; }
  :global(.ts-control .item .ts-sep) { color: #6750a4; opacity: 0.5; }
  :global(.ts-control .item .ts-name) { color: #21005d; font-weight: 500; }
</style>
