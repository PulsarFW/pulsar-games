<script lang="ts">
	import { onMount } from 'svelte';
	import { attachMessageListener } from './lib/messages';
	import Minigames from './lib/Minigames.svelte';

	onMount(() => attachMessageListener());
</script>

<main>
	<Minigames />
</main>

<style>
	main {
		position: relative;
		width: 100vw;
		height: 100vh;
		overflow: hidden;
	}
</style>
