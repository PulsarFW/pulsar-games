<!-- dev-only, mounted by mock.ts, never bundled into production -->
<script lang="ts">
	import { gameState } from './store/game.svelte';
	import { DEMO_GAMES, launchGame } from './mock';
	import type { MinigameType } from './types';

	const types = Object.keys(DEMO_GAMES) as MinigameType[];
</script>

{#if !gameState.showing}
	<div class="dev-menu">
		<h3>Minigame Dev Launcher</h3>
		<div class="grid">
			{#each types as type (type)}
				<button onclick={() => launchGame(type)}>{type}</button>
			{/each}
		</div>
	</div>
{/if}

<style>
	.dev-menu {
		position: fixed;
		top: 12px;
		left: 12px;
		z-index: 9999;
		pointer-events: auto;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 10px;
		font-family: var(--font-body);
	}
	h3 {
		margin: 0 0 8px;
		color: var(--color-text);
		font-size: 12px;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		font-family: var(--font-heading);
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 6px;
	}
	button {
		background: var(--color-primary);
		color: var(--color-text);
		border: none;
		border-radius: var(--radius);
		padding: 6px 8px;
		font-size: 11px;
		cursor: pointer;
		text-transform: capitalize;
	}
	button:hover {
		background: var(--color-primary-light);
	}
</style>
