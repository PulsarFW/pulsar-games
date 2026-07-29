<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import keymap from '../keymap';
	import type { ActiveGame, RoundGame } from '../types';

	const game = $derived(gameState.game as ActiveGame & RoundGame & { key: string[] });

	let canvas: HTMLCanvasElement | undefined = $state();
	let degrees = $state(0);
	let correct = $state(false);
	let pressed = $state(false);
	let visible = $state(true);
	let arcStart = 0;
	let arcEnd = 0;

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function getRandomInt(min: number, max: number): number {
		min = Math.ceil(min);
		max = Math.floor(max);
		return Math.floor(Math.random() * (max - min + 1) + min);
	}

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		tickTimer = null;
	}

	function onFinished(success: boolean) {
		pressed = true;
		correct = success;
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
		if (pressed) return;

		if (game.key.includes(e.key)) {
			const dStart = (180 / Math.PI) * arcStart;
			const dEnd = (180 / Math.PI) * arcEnd + 5;
			onFinished(degrees >= dStart && degrees <= dEnd);
		} else if (keymap.includes(e.key.toLowerCase())) {
			onFinished(false);
		}
	}

	// compensates for the thin needle reading slower than the old fat-wedge one at the same game.rate
	const SPEED_MULTIPLIER = 1.5;

	function tick() {
		if (gameState.failed || gameState.finished) return;
		const step = game.rate * SPEED_MULTIPLIER;
		if (degrees + step > 360) {
			onFinished(false);
		} else {
			degrees += step;
		}
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		arcStart = getRandomInt(20, 40) / 10;
		arcEnd = arcStart + game.difficulty / 10;
		degrees = 0;
		correct = false;
		pressed = false;
		visible = true;
		tickTimer = setInterval(tick, 10);
		return clearTimers;
	});

	$effect(() => {
		window.addEventListener('keydown', onKeydown);
		return () => window.removeEventListener('keydown', onKeydown);
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	$effect(() => {
		void degrees; void correct; void pressed; // dependency tracking
		draw();
	});

	function cssVar(name: string): string {
		return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
	}

	function draw() {
		if (!canvas) return;
		const ctx = canvas.getContext('2d');
		if (!ctx) return;
		const W = canvas.width;
		const H = canvas.height;
		const cx = W / 2;
		const cy = H / 2;

		// proportional to buffer size so it scales regardless of CSS display size
		const radius = W * 0.36;
		const ringWidth = W * 0.05;
		const fontSize = Math.round(W * 0.22);

		ctx.clearRect(0, 0, W, H);
		ctx.lineCap = 'round';
		ctx.shadowBlur = 0;

		ctx.beginPath();
		ctx.strokeStyle = cssVar('--color-bg-panel-alt');
		ctx.lineWidth = ringWidth;
		ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
		ctx.stroke();

		ctx.beginPath();
		ctx.strokeStyle = correct ? cssVar('--color-success') : pressed ? cssVar('--color-error') : cssVar('--color-primary');
		ctx.lineWidth = ringWidth;
		ctx.arc(cx, cy, radius, arcStart - (90 * Math.PI) / 180, arcEnd - (90 * Math.PI) / 180, false);
		ctx.stroke();

		const radians = (degrees * Math.PI) / 180 - (90 * Math.PI) / 180;
		const handInner = radius * 0.4;
		const handOuter = radius + ringWidth * 0.6;
		const hx1 = cx + Math.cos(radians) * handInner;
		const hy1 = cy + Math.sin(radians) * handInner;
		const hx2 = cx + Math.cos(radians) * handOuter;
		const hy2 = cy + Math.sin(radians) * handOuter;

		ctx.beginPath();
		ctx.strokeStyle = cssVar('--color-text');
		ctx.lineWidth = W * 0.02;
		ctx.moveTo(hx1, hy1);
		ctx.lineTo(hx2, hy2);
		ctx.stroke();

		ctx.beginPath();
		ctx.fillStyle = cssVar('--color-text');
		ctx.arc(hx2, hy2, W * 0.022, 0, Math.PI * 2, false);
		ctx.fill();

		ctx.fillStyle = cssVar('--color-text');
		ctx.font = `${fontSize}px 'Space Grotesk'`;
		ctx.shadowColor = 'black';
		ctx.shadowBlur = 8;
		const label = game.key[0] ?? '';
		const textWidth = ctx.measureText(label).width;
		ctx.fillText(label, cx - textWidth / 2, cy + fontSize * 0.36);
	}
</script>

{#if visible}
	<div class="wrapper">
		<canvas bind:this={canvas} width="320" height="320"></canvas>
	</div>
{/if}

<style>
	.wrapper {
		width: fit-content;
		height: fit-content;
		position: absolute;
		inset: 0;
		margin: auto;
	}
	canvas {
		/* floor/ceiling so it can't shrink on short windows or balloon on 4K */
		width: clamp(220px, 30vh, 340px);
		height: clamp(220px, 30vh, 340px);
	}
</style>
