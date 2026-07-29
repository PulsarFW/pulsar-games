// one shared Audio() element per sound so rapid repeats (e.g. ticking) restart cleanly instead of stacking.

import backUrl from '../assets/sounds/back.mp3';
import beepUrl from '../assets/sounds/beep.mp3';
import confirmUrl from '../assets/sounds/confirm.mp3';
import negativeUrl from '../assets/sounds/negative.mp3';
import positiveUrl from '../assets/sounds/positive.mp3';
import tickingUrl from '../assets/sounds/ticking.ogg';
import { SOUND_ENABLED, SOUND_VOLUME } from '../config';
import type { SoundName } from './types';

const SOURCES: Record<SoundName, string> = {
	back: backUrl,
	beep: beepUrl,
	confirm: confirmUrl,
	negative: negativeUrl,
	positive: positiveUrl,
	ticking: tickingUrl,
};

const elements = new Map<SoundName, HTMLAudioElement>();

function getElement(name: SoundName): HTMLAudioElement {
	let el = elements.get(name);
	if (!el) {
		el = new Audio(SOURCES[name]);
		el.volume = SOUND_VOLUME;
		elements.set(name, el);
	}
	return el;
}

export function playSound(name: SoundName): void {
	if (!SOUND_ENABLED) return;
	const el = getElement(name);
	el.currentTime = 0;
	void el.play().catch(() => {
		// browsers block autoplay before any user gesture — irrelevant once loaded in the NUI browser
	});
}

export function stopSound(name: SoundName): void {
	const el = elements.get(name);
	if (!el) return;
	el.pause();
	el.currentTime = 0;
}
