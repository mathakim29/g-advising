<script>
  import Self from './TreeNode.svelte';
  export let node;
  export let depth = 0;

  const STATE = {
    taken:     { bg: 'bg-[#d8f3dc]', text: 'text-[#1b4332]', icon: 'check_circle', label: 'Completed' },
    available: { bg: 'bg-[#eaddff]', text: 'text-[#21005d]', icon: 'lock_open',    label: 'Available' },
    locked:    { bg: 'bg-[#fde2e1]', text: 'text-[#8c1d18]', icon: 'lock',          label: 'Locked' }
  };
  $: s = STATE[node.state] ?? STATE.locked;
</script>

<div class="relative" style="margin-left: {depth === 0 ? 0 : 1.25}rem">
  {#if depth > 0}
    <span class="absolute -left-3 top-4 h-px w-3 bg-[#cac4d0]"></span>
  {/if}
  <div class="inline-flex items-center gap-2 rounded-xl border border-[#e7e0ec] bg-white px-3 py-2 shadow-sm">
    <span class="grid h-6 w-6 place-items-center rounded-full {s.bg} {s.text}">
      <span class="material-symbols-rounded text-base">{s.icon}</span>
    </span>
    <span class="font-semibold text-primary">{node.code}</span>
    <span class="text-sm text-[#49454f]">{node.name}</span>
    <span class="badge {s.bg} {s.text}">{node.exists ? s.label : 'Not in catalogue'}</span>
  </div>

  {#if node.children.length}
    <div class="mt-2 space-y-2 border-l border-[#cac4d0] pl-3">
      {#each node.children as child (child.code)}
        <Self node={child} depth={depth + 1} />
      {/each}
    </div>
  {/if}
</div>
