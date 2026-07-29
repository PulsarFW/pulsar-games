// central NUI message router, forwards SendNUIMessage calls from client/minigame.lua to the game store

import { handleGameMessage } from './store/game.svelte';

interface InboundMessage {
	type?: string;
	data?: unknown;
}

function route(type: string, data: unknown) {
	handleGameMessage(type, data);
}

/** Returns an unsubscribe function */
export function attachMessageListener(): () => void {
	const handler = (event: MessageEvent<InboundMessage>) => {
		if (!event.isTrusted) return;
		if (event.data?.type) route(event.data.type, event.data.data);
	};
	window.addEventListener('message', handler);
	return () => window.removeEventListener('message', handler);
}

export { route as applyMessage };
