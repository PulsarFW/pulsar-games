<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import Icon from '../Icon.svelte';
	import type { ActiveGame, SkillbarGame } from '../types';

	const game = $derived(gameState.game as ActiveGame & SkillbarGame);

	let curr = $state(0);
	let pressed = $state(false);
	let visible = $state(true);
	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		tickTimer = null;
	}

	function onFinished(success: boolean) {
		if (success) {
			gameState.finished = true;
			Nui.finish(1);
			playSound('positive');
		} else {
			gameState.failed = true;
			Nui.finish(0);
			playSound('negative');
		}
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = setTimeout(() => {
			visible = false;
		}, 2000);
	}

	function onKeydown(e: KeyboardEvent) {
		if (pressed || (e.key !== 'e' && e.key !== 'E')) return;
		pressed = true;

		const pct = Math.ceil((curr / game.timer) * 100);
		onFinished(pct >= (game.chance as number) && pct <= (game.chance as number) + game.difficulty);
	}

	function tick() {
		if (gameState.failed || gameState.finished) return;
		if (curr + 5 > game.timer) {
			onFinished(false);
		} else {
			curr += 5;
		}
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		curr = 0;
		pressed = false;
		visible = true;
		tickTimer = setInterval(tick, 5);
		return clearTimers;
	});

	$effect(() => {
		window.addEventListener('keydown', onKeydown);
		return () => window.removeEventListener('keydown', onKeydown);
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	const progress = $derived(gameState.finished || gameState.failed ? 100 : (curr / game.timer) * 100);
	const resultState = $derived(gameState.finished ? 'success' : gameState.failed ? 'error' : 'active');
	const label = $derived(gameState.finished ? 'Success' : gameState.failed ? 'Failed' : 'Press [E] When Bar Hits Highlighted Area');
	const barColor = $derived(gameState.failed ? 'var(--color-error)' : gameState.finished ? 'var(--color-success)' : 'var(--color-primary)');
</script>

{#if visible}
	<div class="wrapper">
		<div class="label">
			{#if resultState === 'success'}
				<Icon name="check" size="13px" />
			{:else if resultState === 'error'}
				<Icon name="xmark" size="13px" />
			{/if}
			<span>{label}</span>
		</div>
		<div class="track">
			<div class="fill" style:width="{progress}%" style:background={barColor}></div>
			{#if !gameState.finished && !gameState.failed}
				<div
					class="marker"
					style:max-width="{game.difficulty}%"
					style:left="{(game.chance as number) - game.difficulty / 4}%"
				></div>
			{/if}
		</div>
	</div>
{/if}

<style>
	.wrapper {
		width: 100%;
		max-width: 30vw;
		height: fit-content;
		position: absolute;
		bottom: 10%;
		left: 0;
		right: 0;
		margin: auto;
		pointer-events: none;
	}
	.label {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 6px;
		color: var(--color-text);
		font-family: var(--font-heading);
		font-size: 15px;
		letter-spacing: 0.02em;
		text-shadow: 0 0 5px #000;
		margin-bottom: 7px;
	}
	.track {
		position: relative;
		height: 10px;
		border-radius: var(--radius);
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		overflow: visible;
	}
	.fill {
		position: relative;
		z-index: 1;
		height: 100%;
		border-radius: var(--radius);
		transition: none;
	}
	.marker {
		width: 100%;
		height: 100%;
		background: var(--color-primary);
		opacity: 0.8;
		position: absolute;
		bottom: 0;
		z-index: 0;
	}
</style>
