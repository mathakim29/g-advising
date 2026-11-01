<script>
  import { tick } from 'svelte';
  import { CreateMLCEngine } from '@mlc-ai/web-llm';

  // Context from the parent app so answers reflect the student's current state.
  export let programName = '';
  export let residency = '';
  export let availableCourses = [];   // [{ course, reqs, unlocks }]
  export let lockedCourses = [];      // [{ course, missing, reqs }]
  export let takenCourses = [];       // [{ course, unlocks }]
  export let earnedCredits = 0;
  export let creditGoal = 120;

  // Use the normal context model; the -1k variant cannot fit the advising data.
  const MODEL_ID = 'gemma-2-2b-it-q4f16_1-MLC';

  let open = false;
  let input = '';
  let scroller;
  let thinking = false;

  // Model lifecycle
  let engine = null;
  let engineState = 'idle';   // idle | loading | ready | unsupported | error
  let loadProgress = '';
  let loadPct = 0;

  let messages = [
    { from: 'bot', text: "Hi! I'm your advising assistant, powered by Gemma running right in your browser. Ask me anything — course planning, study tips, what to take next, or general computing questions." }
  ];

  // Keep a short conversation window so the on-device model can follow up
  // naturally without growing the prompt indefinitely.
  function modelHistory() {
    return messages
      .filter((m) => m.text?.trim())
      .slice(-8)
      .map((m) => ({ role: m.from === 'user' ? 'user' : 'assistant', content: m.text }));
  }

  const SUGGESTIONS = [
    'What should I take next and why?',
    'How do I prepare for a software job?',
    'Explain what cryptography is about.',
  ];

  const webgpuAvailable = typeof navigator !== 'undefined' && 'gpu' in navigator;

  // ---- Build a compact grounding context the model can reason over ----
  function courseLines(courses, withExtra) {
    return courses.map(e => {
      const c = e.course;
      let line = `${c.course_code} (${c.course_name}, ${c.credit_hours}cr, ${c.compulsory ? 'compulsory' : 'elective'})`;
      if (withExtra === 'missing' && e.missing?.length) line += ` — needs ${e.missing.join(', ')}`;
      if (withExtra === 'unlocks' && e.unlocks?.length) line += ` — unlocks ${e.unlocks.join(', ')}`;
      return line;
    }).join('\n');
  }

  function buildContext() {
    const left = Math.max(0, creditGoal - earnedCredits);
    return [
      `Student program: ${programName || 'not selected'} (${residency || 'unknown'} student).`,
      `Credits: ${earnedCredits} of ${creditGoal} earned, ${left} remaining.`,
      ``,
      `AVAILABLE NOW (prerequisites met):`,
      courseLines(availableCourses, 'unlocks') || '(none)',
      ``,
      `LOCKED (missing prerequisites):`,
      courseLines(lockedCourses, 'missing') || '(none)',
      ``,
      `ALREADY TAKEN:`,
      courseLines(takenCourses) || '(none)',
    ].join('\n');
  }

  const SYSTEM_PROMPT =
    "You are G-Advising, a friendly and knowledgeable academic advisor for computing students. " +
    "You help with course planning, study tips, career direction, and general questions about computing topics. " +
    "Use the STUDENT DATA in the user message as helpful context about their progress, but feel free to draw on your own knowledge to give advice, explanations, and suggestions. " +
    "When you mention specific courses, prefer the student's actual course codes if relevant. " +
    "Be warm, conversational, and genuinely helpful.";

  // ---- Model loading (lazy, on first open) ----
  async function ensureEngine() {
    if (engine || engineState === 'loading') return;
    if (!webgpuAvailable) { engineState = 'unsupported'; return; }
    engineState = 'loading';
    try {
      engine = await CreateMLCEngine(MODEL_ID, {
        context_window_size: 4096,
        initProgressCallback: (p) => {
          loadProgress = p.text || '';
          if (typeof p.progress === 'number') loadPct = Math.round(p.progress * 100);
        }
      });
      engineState = 'ready';
    } catch (e) {
      engineState = 'error';
      loadProgress = String(e?.message ?? e);
    }
  }

  async function retryModel() {
    engine = null;
    engineState = 'idle';
    loadProgress = '';
    loadPct = 0;
    await ensureEngine();
  }

  // ---- Send a message ----
  async function send(text) {
    const msg = (text ?? input).trim();
    if (!msg || thinking) return;
    messages = [...messages, { from: 'user', text: msg }];
    input = '';
    await scrollDown();

    if (!webgpuAvailable) {
      messages = [...messages, { from: 'bot', text: 'This AI requires a browser with WebGPU enabled. Please use a recent Chrome or Edge browser with hardware acceleration enabled.' }];
      await scrollDown();
      return;
    }

    if (engineState !== 'ready') {
      await ensureEngine();
      if (engineState !== 'ready') {
        messages = [...messages, { from: 'bot', text: `The AI model could not be loaded. ${loadProgress || 'Please retry the model download.'}` }];
        await scrollDown();
        return;
      }
    }

    // Stream the model's reply into a placeholder message.
    thinking = true;
    messages = [...messages, { from: 'bot', text: '' }];
    const idx = messages.length - 1;
    try {
      const chunks = await engine.chat.completions.create({
        stream: true,
        temperature: 0.8,
        max_tokens: 512,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: `(For context, here's my current progress — use it if helpful:)\n${buildContext().slice(0, 9000)}` },
          ...modelHistory().slice(0, -1),
          { role: 'user', content: msg }
        ]
      });
      let acc = '';
      for await (const chunk of chunks) {
        acc += chunk.choices[0]?.delta?.content ?? '';
        messages[idx].text = acc;
        messages = messages;
        await scrollDown();
      }
      if (!acc.trim()) messages[idx].text = 'The AI returned an empty response. Please try again.';
      messages = messages;
    } catch (e) {
      messages[idx].text = `The AI request failed: ${e?.message ?? e}`;
      messages = messages;
    } finally {
      thinking = false;
      await scrollDown();
    }
  }

  async function scrollDown() {
    await tick();
    if (scroller) scroller.scrollTop = scroller.scrollHeight;
  }

  function onKeydown(e) {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
  }

  function toggle() {
    open = !open;
    if (open) {
      ensureEngine();   // start downloading the model on first open
      scrollDown();
    }
  }
</script>

<!-- Launcher -->
<button
  class="fixed bottom-6 right-6 z-40 grid h-14 w-14 place-items-center rounded-full bg-primary text-white shadow-material transition hover:scale-105"
  aria-label={open ? 'Close assistant' : 'Open assistant'}
  on:click={toggle}>
  <span class="material-symbols-rounded text-2xl">{open ? 'close' : 'chat'}</span>
</button>

{#if open}
  <div class="fixed bottom-24 right-4 z-40 flex h-[480px] max-h-[calc(100vh-7rem)] w-[350px] max-w-[calc(100vw-2rem)] flex-col overflow-hidden rounded-3xl border border-[#e7e0ec] bg-white shadow-material sm:right-6">
    <!-- Header -->
    <div class="flex items-center gap-3 border-b border-[#e7e0ec] bg-primary px-4 py-3 text-white">
      <span class="grid h-9 w-9 place-items-center rounded-full bg-white/20">
        <span class="material-symbols-rounded text-xl">support_agent</span>
      </span>
      <div class="flex-1">
        <p class="text-sm font-semibold leading-tight">Advising assistant</p>
        <p class="text-xs text-white/80">
          {#if engineState === 'ready'}Gemma · on-device
          {:else if engineState === 'loading'}Loading Gemma… {loadPct}%
          {:else if engineState === 'unsupported'}WebGPU required
          {:else if engineState === 'error'}Model unavailable
          {:else}Gemma · in your browser{/if}
        </p>
      </div>
    </div>

    {#if engineState === 'error'}
      <div class="flex items-center justify-between gap-2 border-b border-[#f2b8b5] bg-[#fceeee] px-3 py-2 text-xs text-[#8c1d18]">
        <span>Gemma could not load. No fallback mode is enabled.</span>
        <button class="shrink-0 font-semibold underline" on:click={retryModel}>Retry</button>
      </div>
    {/if}

    <!-- Load progress bar -->
    {#if engineState === 'loading'}
      <div class="border-b border-[#e7e0ec] bg-[#faf7fd] px-4 py-2">
        <div class="h-1.5 w-full overflow-hidden rounded-full bg-[#eee8f0]">
          <div class="h-full rounded-full bg-primary transition-all" style="width: {loadPct}%"></div>
        </div>
        <p class="mt-1 truncate text-[11px] text-[#79747e]" title={loadProgress}>{loadProgress || 'Preparing model…'}</p>
      </div>
    {/if}

    <!-- Messages -->
    <div bind:this={scroller} class="flex-1 space-y-3 overflow-y-auto bg-[#faf7fd] p-4">
      {#each messages as m}
        <div class="flex {m.from === 'user' ? 'justify-end' : 'justify-start'}">
          <div class="max-w-[82%] whitespace-pre-line rounded-2xl px-3 py-2 text-sm
            {m.from === 'user' ? 'bg-primary text-white' : 'border border-[#e7e0ec] bg-white text-[#1d1b20]'}">
            {#if m.text}{m.text}{:else}<span class="inline-flex gap-1"><span class="dot"></span><span class="dot"></span><span class="dot"></span></span>{/if}
          </div>
        </div>
      {/each}
    </div>

    <!-- Suggestions -->
    {#if messages.length <= 1}
      <div class="flex flex-wrap gap-2 border-t border-[#e7e0ec] bg-white px-3 py-2">
        {#each SUGGESTIONS as s}
          <button class="rounded-full border border-[#cac4d0] px-3 py-1 text-xs text-[#49454f] hover:bg-[#f5eff7] disabled:opacity-40" disabled={thinking} on:click={() => send(s)}>{s}</button>
        {/each}
      </div>
    {/if}

    <!-- Input -->
    <div class="flex items-center gap-2 border-t border-[#e7e0ec] bg-white p-3">
      <input
        bind:value={input}
        on:keydown={onKeydown}
        disabled={thinking}
        class="h-10 flex-1 rounded-full border border-[#79747e] px-4 text-sm outline-none focus:border-primary disabled:bg-[#f5f5f5]"
        placeholder={thinking ? 'Gemma is thinking…' : 'Ask about your courses…'} />
      <button
        class="grid h-10 w-10 place-items-center rounded-full bg-primary text-white disabled:opacity-40"
        disabled={!input.trim() || thinking}
        on:click={() => send()}
        aria-label="Send">
        <span class="material-symbols-rounded text-xl">send</span>
      </button>
    </div>
  </div>
{/if}

<style>
  .dot {
    width: 6px; height: 6px; border-radius: 9999px; background: #9e9e9e;
    display: inline-block; animation: blink 1.2s infinite both;
  }
  .dot:nth-child(2) { animation-delay: 0.2s; }
  .dot:nth-child(3) { animation-delay: 0.4s; }
  @keyframes blink { 0%, 80%, 100% { opacity: 0.2; } 40% { opacity: 1; } }
</style>
