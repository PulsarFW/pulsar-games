<!-- swap a type's Placeholder for its real component as each game gets built -->
<script lang="ts">
	import { gameState } from './store/game.svelte';
	import Skillbar from './games/Skillbar.svelte';
	import RoundSkill from './games/RoundSkill.svelte';
	import Scanner from './games/Scanner.svelte';
	import Sequencer from './games/Sequencer.svelte';
	import Keypad from './games/Keypad.svelte';
	import Scrambler from './games/Scrambler.svelte';
	import Memory from './games/Memory.svelte';
	import Pattern from './games/Pattern.svelte';
	import Aim from './games/Aim.svelte';
	import Captcha from './games/Captcha.svelte';
	import Keymaster from './games/Keymaster.svelte';
	import Icons from './games/Icons.svelte';
	import Tracking from './games/Tracking.svelte';

	const type = $derived(gameState.game?.type);
</script>

{#if gameState.showing && gameState.game}
	{#if type === 'skillbar'}
		<Skillbar />
	{:else if type === 'round'}
		<RoundSkill />
	{:else if type === 'scanner'}
		<Scanner />
	{:else if type === 'sequencer'}
		<Sequencer />
	{:else if type === 'keypad'}
		<Keypad />
	{:else if type === 'scrambler'}
		<Scrambler />
	{:else if type === 'memory'}
		<Memory />
	{:else if type === 'aim'}
		<Aim />
	{:else if type === 'captcha'}
		<Captcha />
	{:else if type === 'keymaster'}
		<Keymaster />
	{:else if type === 'pattern'}
		<Pattern />
	{:else if type === 'icons'}
		<Icons />
	{:else if type === 'tracking'}
		<Tracking />
	{/if}
{/if}
