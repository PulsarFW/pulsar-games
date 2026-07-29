// outbound UI -> Lua transport, fire-and-forget

import type { FinishState } from './types';

const RESOURCE_NAME = 'pulsar_games';

async function send(event: string, data: unknown = {}): Promise<void> {
	if (import.meta.env.DEV) {
		window.dispatchEvent(new CustomEvent('nui:send', { detail: { event, data } }));
		return;
	}
	try {
		await fetch(`https://${RESOURCE_NAME}/${event}`, {
			method: 'post',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data),
		});
	} catch {
		// Expected to fail outside the actual NUI browser
	}
}

export const Nui = {
	/** state: 0 = fail, 1 = success, 2 = perfect. extra gets merged into the Lua-side events.data. */
	finish: (state: FinishState, extra?: Record<string, unknown>) => send('Minigame:Finish', { state, ...extra }),
	end: () => send('Minigame:End'),
};
