<!-- temporary stand-in for a not-yet-built minigame -->
<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';

	function finish(state: 0 | 1 | 2) {
		Nui.finish(state);
		setTimeout(hideGame, 600);
	}
</script>

<div class="placeholder">
	<h2>{gameState.game?.type}</h2>
	<p>Not built yet — showing raw params below.</p>
	<pre>{JSON.stringify(gameState.game, null, 2)}</pre>
	<div class="actions">
		<button class="fail" onclick={() => finish(0)}>Force Fail</button>
		<button class="success" onclick={() => finish(1)}>Force Success</button>
		<button class="perfect" onclick={() => finish(2)}>Force Perfect</button>
	</div>
</div>

<style>
	.placeholder {
		position: fixed;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		pointer-events: auto;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 20px 24px;
		min-width: 320px;
		max-width: 480px;
		font-family: var(--font-body);
	}
	h2 {
		margin: 0 0 4px;
		text-transform: uppercase;
		font-family: var(--font-heading);
		color: var(--color-primary-light);
	}
	p {
		margin: 0 0 10px;
		color: var(--color-text-muted);
		font-size: 13px;
	}
	pre {
		max-height: 240px;
		overflow: auto;
		background: var(--color-bg);
		border-radius: var(--radius);
		padding: 8px;
		font-size: 11px;
		color: var(--color-text-muted);
	}
	.actions {
		display: flex;
		gap: 8px;
		margin-top: 12px;
	}
	button {
		flex: 1;
		border: none;
		border-radius: var(--radius);
		padding: 8px;
		cursor: pointer;
		color: #fff;
		font-weight: 600;
	}
	.fail {
		background: var(--color-error);
	}
	.success {
		background: var(--color-success);
	}
	.perfect {
		background: var(--color-info);
	}
</style>
