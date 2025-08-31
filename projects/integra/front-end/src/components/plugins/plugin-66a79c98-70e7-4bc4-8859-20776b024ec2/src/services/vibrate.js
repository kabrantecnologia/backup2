export async function vibrate({ vibrate_pattern }) {
    if (!('vibrate' in navigator)) {
        throw new Error('Vibration is not available.');
    }

    try {
        navigator.vibrate(vibrate_pattern);
    } catch (error) {
        throw new Error(error, 'Error while triggering vibration.');
    }
}
